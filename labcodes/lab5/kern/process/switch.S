.text
.globl switch_to
switch_to:                      # switch_to(FROM, TO)

    # save from's registers
    movl 4(%esp), %eax          # eax points to FROM
    popl 0(%eax)                # save eip !popl (esp--> return address, so save return addr in FROM’s context)
    movl %esp, 4(%eax)          # save esp::context of FROM
    movl %ebx, 8(%eax)          # save ebx::context of FROM
    movl %ecx, 12(%eax)         # save ecx::context of FROM
    movl %edx, 16(%eax)         # save edx::context of FROM
    movl %esi, 20(%eax)         # save esi::context of FROM
    movl %edi, 24(%eax)         # save edi::context of FROM
    movl %ebp, 28(%eax)         # save ebp::context of FROM

    # restore to's registers
    movl 4(%esp), %eax          # not 8(%esp): popped return address already
                                # eax now points to TO
    movl 28(%eax), %ebp         # restore ebp::context of TO
    movl 24(%eax), %edi         # restore edi::context of TO
    movl 20(%eax), %esi         # restore esi::context of TO
    movl 16(%eax), %edx         # restore edx::context of TO
    movl 12(%eax), %ecx         # restore ecx::context of TO
    movl 8(%eax), %ebx          # restore ebx::context of TO
    movl 4(%eax), %esp          # restore esp::context of TO

    pushl 0(%eax)               # push eip	这样就ret会跳转至pcb->context.eip所指向的地址去

    ret

