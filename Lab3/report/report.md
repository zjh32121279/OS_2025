# Lab 3：中断与中断处理流程
>小组成员：邹佳衡（2312322）、张宇（2312034）、蒲天轶（2112311）

## 实验内容

实验3主要讲解的是中断处理机制。通过本章的学习，我们了解了 riscv 的中断处理机制、相关寄存器与指令。我们知道在中断前后需要恢复上下文环境，用一个名为中断帧（TrapFrame）的结构体存储了要保存的各寄存器，并用了很大篇幅解释如何通过精巧的汇编代码实现上下文环境保存与恢复机制。最终，我们通过处理断点和时钟中断验证了我们正确实现了中断机制。

## 实验目的

实验3主要讲解的是中断处理机制。操作系统是计算机系统的监管者，必须能对计算机系统状态的突发变化做出反应，这些系统状态可能是程序执行出现异常，或者是突发的外设请求。当计算机系统遇到突发情况时，不得不停止当前的正常工作，应急响应一下，这是需要操作系统来接管，并跳转到对应处理函数进行处理，处理结束后再回到原来的地方继续执行指令。这个过程就是中断处理过程。
本章你将学到：
- riscv 的中断相关知识
- 中断前后如何进行上下文环境的保存与恢复
- 处理最简单的断点中断和时钟中断

## 练习1：完善中断处理

**1. 实验内容**

请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。
要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。

**2. 代码分析**

首先，找到我们需要修改的位置，在interrupt_handler函数中的分支选项中，中断类型为case IRQ_S_TIMER的部分：

```cpp
case IRQ_S_TIMER:
    break;
```

首先调用clock_set_next_event()，重新设置定时器，确保下一次时钟中断能按时发生。由于我们要定时输出，因此需要ticks这个全局变量，用于记录系统启动以来的时钟中断次数，每次发生时钟中断时，ticks的值加1。

```cpp
clock_set_next_event();
ticks++
```

**3. 定时输出和关机逻辑**

```cpp
if (ticks % TICK_NUM == 0) { 
    print_ticks(); 
    print_count++; 

    // 当打印次数为10时，调用关机函数 
    if (print_count == 10) { 
        sbi_shutdown(); 
    }
}
```

我们在此前已经将全局变量TICK_NUM设置为100，当全局时钟计时器ticks的值为100的倍数时，首先调用print_ticks();向控制台中输出“100ticks”，再增加一次打印的次数print_count，接着判断print_count的值是否为10，如果print_count等于10，说明打印次数达到了10次，此时调用sbi_shutdown()执行关机。

**3.测试结果**

首先，我们登入虚拟机使用make指令进行编译，编译完成后，输入make qemu指令进行运行，如果顺利的话，它会每一秒输出一次提示文本，总共输出十次。为了展示清晰，我省略了OpenSBI开机时的提示信息。
```
DTB Init
HartID: 0
DTB Address: 0x82200000
Physical Memory from DTB:
  Base: 0x0000000080000000
  Size: 0x0000000008000000 (128 MB)
  End:  0x0000000087ffffff
DTB init completed
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc0200054 (virtual)
  etext  0xffffffffc0201fa6 (virtual)
  edata  0xffffffffc0207028 (virtual)
  end    0xffffffffc02074a0 (virtual)
Kernel executable memory footprint: 30KB
memory management: default_pmm_manager
physcial memory map:
  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0206000
satp physical address: 0x0000000080206000
++ setup timer interrupts
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
```
可以看到它顺利输出了我们想要的结果。接着，我们输入make grade进行测试：
```
zoujiaheng@zoujiaheng-virtual-machine:~/桌面/labcode/labcode/lab3$ make grade
: not found.sh: 2: tools/grade.sh:
tools/grade.sh: 166: tools/grade.sh: Syntax error: ")" unexpected (expecting "then")
Makefile:206: recipe for target 'grade' failed
make: *** [grade] Error 2
```
我将报错信息发给大模型进行分析，返回的结果是由于脚本文件的格式问题导致的，通常是 Windows/Linux行尾符不兼容或者脚本语法错误。

由于疏忽，我忘记保存原始的grade.sh文件，但我记录了报错信息所在函数：
```cpp
run_qemu() {
    echo "try to run qemu"
    # Run qemu with serial output redirected to $qemu_out. If $brkfun is non-empty,
    # wait until $brkfun is reached or $timeout expires, then kill QEMU
    qemuextra=
    if [ "$brkfun" ]; then
        qemuextra="-S $qemugdb"
    fi

    if [ -z "$timeout" ] || [ $timeout -le 0 ]; then
        timeout=$default_timeout;
    fi

    t0=$(get_time)
    (

        ulimit -t $timeout
        exec $qemu -nographic $qemuopts -serial file:$qemu_out -monitor null -no-reboot $qemuextra
    ) > $out 2> $err &
    pid=$!
    echo "qemu pid=$pid"

    # wait for QEMU to start
    sleep 1

    if [ -n "$brkfun" ]; then
        # find the address of the kernel $brkfun function
        brkaddr=`$grep " $brkfun\$" $sym_table | $sed -e's/ .*$//g'`
        brkaddr_phys=`echo $brkaddr | sed "s/^c0/00/g"`
        (
            echo "target remote localhost:$gdbport"
            echo "break *0x$brkaddr"
            if [ "$brkaddr" != "$brkaddr_phys" ]; then
                echo "break *0x$brkaddr_phys"
            fi
            echo "continue"
        ) > $gdb_in						//报错位置166行在这里

        $gdb -batch -nx -x $gdb_in > /dev/null 2>&1

        # make sure that QEMU is dead
        # on OS X, exiting gdb doesn't always exit qemu
        kill $pid > /dev/null 2>&1
    fi
}
```
我在上方标注了grade.sh的报错位置，下面我进行了grade.sh文件的修复，按以下顺序执行命令行：
```
# 安装dos2unix工具
sudo apt-get update
sudo apt-get install dos2unix

# 转换grade.sh脚本的行尾符
dos2unix tools/grade.sh

# 重新运行
make grade
```
重新运行后，结果如下：
```
zoujiaheng@zoujiaheng-virtual-machine:~/桌面/labcode/labcode/lab3$ make grade
>>>>>>>>>> here_make>>>>>>>>>>>
make[1]: 进入目录“/home/zoujiaheng/桌面/labcode/labcode/lab3” + cc kern/init/entry.S + cc kern/init/init.c + cc kern/libs/stdio.c + cc kern/debug/panic.c + cc kern/debug/kdebug.c + cc kern/debug/kmonitor.c + cc kern/driver/dtb.c + cc kern/driver/clock.c + cc kern/driver/console.c + cc kern/driver/intr.c + cc kern/trap/trap.c + cc kern/trap/trapentry.S + cc kern/mm/pmm.c + cc kern/mm/default_pmm.c + cc kern/mm/best_fit_pmm.c + cc libs/string.c + cc libs/printfmt.c + cc libs/sbi.c + cc libs/readline.c + ld bin/kernel riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img make[1]: 离开目录“/home/zoujiaheng/桌面/labcode/labcode/lab3”
>>>>>>>>>> here_make>>>>>>>>>>>
<<<<<<<<<<<<<<< here_run_qemu <<<<<<<<<<<<<<<<<<
try to run qemu
qemu pid=11539
<<<<<<<<<<<<<<< here_run_check <<<<<<<<<<<<<<<<<<
  -check physical_memory_map_information:    WRONG
   -e !! error: missing 'memory management: best_fit_pmm_manager'

  -check_best_fit:                           WRONG
   -e !! error: missing 'satp virtual address: 0xffffffffc0205000'
   !! error: missing 'satp physical address: 0x0000000080205000'

  -check ticks:                              OK
Total Score: 5/30
Makefile:206: recipe for target 'grade' failed
make: *** [grade] Error 1
```
观察错误信息，我们发现它希望使用的是best_fit_pmm_manager，根据上次实验的经验，我们前往pmm.c文件，将default_pmm_manager改为相应的内存管理器，然后我们前往best_fit_pmm.c文件检查代码是否完整，发现需要我们填入Lab2中的代码，这些问题全部修复后，我们运行的最终结果是：
```
zoujiaheng@zoujiaheng-virtual-machine:~/桌面/labcode/labcode/lab3$ make grade
>>>>>>>>>> here_make>>>>>>>>>>>
make[1]: 进入目录“/home/zoujiaheng/桌面/labcode/labcode/lab3” + cc kern/init/entry.S + cc kern/init/init.c + cc kern/libs/stdio.c + cc kern/debug/panic.c + cc kern/debug/kdebug.c + cc kern/debug/kmonitor.c + cc kern/driver/dtb.c + cc kern/driver/clock.c + cc kern/driver/console.c + cc kern/driver/intr.c + cc kern/trap/trap.c + cc kern/trap/trapentry.S + cc kern/mm/pmm.c + cc kern/mm/default_pmm.c + cc kern/mm/best_fit_pmm.c + cc libs/string.c + cc libs/printfmt.c + cc libs/sbi.c + cc libs/readline.c + ld bin/kernel riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img make[1]: 离开目录“/home/zoujiaheng/桌面/labcode/labcode/lab3”
>>>>>>>>>> here_make>>>>>>>>>>>
<<<<<<<<<<<<<<< here_run_qemu <<<<<<<<<<<<<<<<<<
try to run qemu
qemu pid=11983
<<<<<<<<<<<<<<< here_run_check <<<<<<<<<<<<<<<<<<
  -check physical_memory_map_information:    OK
  -check_best_fit:                           OK
  -check ticks:                              OK
Total Score: 30/30
```
我们通过了全部的测试信息，圆满成功。

## 扩展练习3：完善异常中断

**1.代码实现**

首先我们要处理非法指令异常，找到exception_handler函数，这是处理各个异常的函数，在switch代码块中找到CAUSE_ILLEGAL_INSTRUCTION部分，代表非法指令异常，编写如下代码：
```cpp
cprintf("Exception type: Illegal instruction\n");
cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
tf->epc += 4;
```
其中第一行是输出异常的类型为非法指令异常，第二行是输出异常指令地址，tf是类trapframe的对象，其内部如下：
```cpp
struct trapframe {
    struct pushregs gpr;
    uintptr_t status;
    uintptr_t epc;
    uintptr_t badvaddr;
    uintptr_t cause;
};
```
其中epc是发生异常的指令地址，处理完异常后，CPU会重新从epc处执行程序。经过测试，我们的非法指令异常长度为四字节，因此要在处理完成后加四。

然后我们要处理断点异常，在switch代码块中找到CAUSE_BREAKPOINT部分，编写如下代码：
```cpp
cprintf("Exception type: breakpoint\n");
cprintf("ebreak caught at 0x%08x\n", tf->epc);
tf->epc += 2;
```
同样的道理，这一次指令测试结果表明断点异常指令长度为二字节，所以最后epc加二。

为了进行测试，我们需要在kern_init中增加两个样例：
```cpp
asm("mret");
asm("ebreak");
```
这两行代码需要加到intr_enable之后，其中mret是RISC-V架构中的机器模式返回指令，这个指令要在M态下运行，而我们的操作系统只能运行在S态，因此会触发非法指令异常，ebreak是RISC-V架构中的环境断点指令，用于故意触发一个断点异常。

**2.测试结果**

我们在终端中输入make进行编译，编译完成后输入make qemu进行测试，输出结果如下：
```
DTB Init
HartID: 0
DTB Address: 0x82200000
Physical Memory from DTB:
  Base: 0x0000000080000000
  Size: 0x0000000008000000 (128 MB)
  End:  0x0000000087ffffff
DTB init completed
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc0200054 (virtual)
  etext  0xffffffffc0201faa (virtual)
  edata  0xffffffffc0207028 (virtual)
  end    0xffffffffc02074a0 (virtual)
Kernel executable memory footprint: 30KB
memory management: default_pmm_manager
physcial memory map:
  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0206000
satp physical address: 0x0000000080206000
++ setup timer interrupts
sbi_emulate_csr_read: hartid0: invalid csr_num=0x302
Exception type: Illegal instruction
Illegal instruction caught at 0xc020009c
Exception type: breakpoint
ebreak caught at 0xc02000a0
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
```
我们可以看到他正常输出了异常指令的物理地址0xc020009c和0xc02000a0，以及每隔大约1秒输出一个100tick，总共十个。