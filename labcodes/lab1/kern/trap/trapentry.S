#include <memlayout.h>

# vectors.S sends all traps here.
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
    pushl %es
    pushl %fs
    pushl %gs
    pushal
    #pushal: Push EAX, ECX, EDX, EBX, original ESP, EBP, ESI, and EDI

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
    movw %ax, %ds
    movw %ax, %es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp

    # call trap(tf), where tf=%esp
    call trap

    # pop the pushed stack pointer
	# mark: 这句话给建立临时的trapframe解决缺失由于中断引发的缺失ss和esp而提供了可能
    popl %esp	

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal

    # restore %ds, %es, %fs and %gs
    popl %gs
    popl %fs
    popl %es
    popl %ds

    # get rid of the trap number and error code 因为在vector.s中有将trap number压入栈中的动作，所以需要释放
    addl $0x8, %esp
    iret

