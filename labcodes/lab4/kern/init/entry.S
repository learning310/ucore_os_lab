#include <mmu.h>
#include <memlayout.h>

#define REALLOC(x) (x - KERNBASE)

.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax
    movl %eax, %cr3

    # enable paging
    movl %cr0, %eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
    andl $~(CR0_TS | CR0_EM), %eax
    movl %eax, %cr0

    # update eip
    # now, eip = 0x1.....
    leal next, %eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax
next:

    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax, %eax
    movl %eax, __boot_pgdir

    # set ebp, esp
    movl $0x0, %ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
    # now kernel stack is ready , call the first C function
    call kern_init

# should never get here
spin:
    jmp spin

.data
.align PGSIZE
    .globl bootstack
bootstack:
    .space KSTACKSIZE
    .globl bootstacktop
bootstacktop:

# kernel builtin pgdir
# an initial page directory (Page Directory Table, PDT)
# These page directory table and page table can be reused!
.section .data.pgdir
.align PGSIZE
__boot_pgdir:
.globl __boot_pgdir
    # map va 0 ~ 4M to pa 0 ~ 4M (temporary)
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W)
    .space (KERNBASE / PGSIZE / 1024 * 4) - (. - __boot_pgdir) # pad to PDE of KERNBASE
    # map va KERNBASE + (0 ~ 4M) to pa 0 ~ 4M
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W)
    .space PGSIZE - (. - __boot_pgdir) # pad to PGSIZE

.set i, 0
__boot_pt1:
.rept 1024
    .long i * PGSIZE + (PTE_P | PTE_W)
    .set i, i + 1
.endr
# 关于对页目录表和页表在entry.s文件中的建立过程
# 预先知识
# 1. __boot_pgdir、__boot_pt1 代表为一个数组，其名字也就代表其第一项
# 2. '.long' 代表的是一个32位的数据
# 3. '.space' 代表的是以字节为单位申请内存空间，默认填充值为零 
# 关于页目标表
# 1. 第一个页表项其管理的 va 0~4MB物理内存空间,由于需要临时映射va 0~4M -> pa 0~4M 目的：设备？
#    故采用 .long来指明,其内容将通过__boot_pt1的循环建立页表的地址加权限为填入
# 2. 4M~KERNBASE-4M 的虚拟内存空间的页目录表通过 .space填入
# 	 大小通过KERNBASE算出其需要多少页表项来管理，并算出其大小(以字节为单位)但要减去前面已经填入的那一项
# 3. 由于其需要完成 va KERNBASE ~ KERNBASE+4M -> pa 0~4M 的映射
#    故采用 .long来指明,其内容将通过__boot_pt1的循环建立页表的地址加权限为填入,即和前面第一项相同
# 4. KERNBASE+4M ~ 4G 的虚拟内存空间的页目录表的内容通过.space填入
#	 大小计算方式即:由于管理4G空间的页目录表大小为PGSIZE,同时此时的__boot_pgdir已经有前面填入的那么多的空间，故减法即可
# 关于页表
# 1，只有物理地址0~4M有页表,其余都不存在
# 2. 方法为数值计算。即已知为按页进行管理物理内存,故一个类似for循环的办法计算出实际的物理地址并填入即可
# 流程
# 1.（best-core）这里已经开启了页表的机制,后面的函数调用的内存空间由bootstacktop所对应的8KB的空间来完成函数调用、局部变量等处理
# 2. 取消那个临时的映射va 0~4M -> pa 0~4M 其方法很简单,因为已经是页映射机制,故只需要修改所对应的页目标表即可
#    具体做法：也就是清空eax寄存器，通过类似数组的方法将eax传入__boot_pgdir[0]
# 3. 关于具体开启页映射机制的相关寄存器信息的配置见实验参考手册
# 4. 后面GDT内容更新的目的是更新虚拟地址(也就是逻辑地址)和线性地址的映射关系？见pmm.c的gdt_init()函数
