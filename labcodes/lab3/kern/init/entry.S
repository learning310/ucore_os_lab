#include <mmu.h>
#include <memlayout.h>

# KERNBASE->0xC0000000 it will set the base address 
#define REALLOC(x) (x - KERNBASE)

.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax
    movl %eax, %cr3	
	# 这里实现了cr3（PDBR）寄存器的更新，也就是内存的高地址中存放的页表PDE地址
	
    # enable paging
    movl %cr0, %eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
    andl $~(CR0_TS | CR0_EM), %eax
    movl %eax, %cr0
	# 配置CR0寄存器的标志位

    # update eip
    # now, eip = 0x1.....
    leal next,%eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax
next:

    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax,%eax
    movl %eax,__boot_pgdir

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
# mark: 
# 		1.这里很关键，因为这里是一级页表（PDE）初始化的动作和所处于的位置
#		2.'.space size, fill' thats mean it will filled n bytes with <fill>. default number is zero.
#		3.'.long' 

.section .data.pgdir
.align PGSIZE
.globl __boot_pgdir
__boot_pgdir:
    # map va 0 ~ 4M to pa 0 ~ 4M (temporary)
    .long REALLOC(__boot_pt1)+(PTE_P | PTE_U | PTE_W)	#这个数值也就代表了__boot_pgdir的值
    .space (KERNBASE / PGSIZE / 1024 * 4)-(. - __boot_pgdir) # pad to PDE of KERNBASE
	
    # map va KERNBASE + (0 ~ 4M) to pa 0 ~ 4M
    .long REALLOC(__boot_pt1)+(PTE_P | PTE_U | PTE_W)
    .space PGSIZE-(. - __boot_pgdir) # pad to PGSIZE

.set i, 0
__boot_pt1:
.rept 1024
    .long i*PGSIZE+(PTE_P | PTE_W)
    .set i, i + 1
.endr

