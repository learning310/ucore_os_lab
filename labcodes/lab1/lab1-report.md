练习一：
===

+ cc kern/init/init.c  //编译 init.c

+ cc kern/libs/readline.c //编译 readline.c

+ cc kern/libs/stdio.c //编译 stdio.c

+ cc kern/debug/kdebug.c//编译 kdebug.c 

+ cc kern/debug/kmonitor.c //编译 kmonitor

+ cc kern/debug/panic.c//编译 panic.c

+ cc kern/driver/clock.c //编译 clock.c

+ cc kern/driver/console.c //编译 console.c

+ cc kern/driver/intr.c//编译 intr.c

+ cc kern/driver/picirq.c //编译 picirq.c

+ cc kern/trap/trap.c //编译 trap.c

+ cc kern/trap/trapentry.S //编译 trapentry.S

+ cc kern/trap/vectors.S //编译 vector.S

+ cc kern/mm/pmm.c//编译 pmm.c

+ cc libs/printfmt.c // printgmt.c

+ cc libs/string.c //编译 string.c

+ ld bin/kernel	//接下来用ld合并目标文件(object) 和 库文件(archive),生成kernel程序

  > 第一部分完成，对内核的编译完成

+ cc boot/bootasm.S //编译 bootasm.S

+ cc boot/bootmain.c //编译 bootmain.c

+ cc tools/sign.c //编译 sign.c

+ ld bin/bootblock//接下来连接源文件与目标文件，生成bootblock程序

  > 第二部分完成，BootLoader编译完成，生成bootblock。

- dd if=/dev/zero of=bin/ucore.img count=10000

- dd if=bin/bootblock of=bin/ucore.img conv=notrunc

- dd if=bin/kernel of=bin/ucore.img seek=1 conv=notrunc

	> 最后将bootloader放入虚拟硬盘ucore.img中去。 