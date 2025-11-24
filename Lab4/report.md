# Lab4：进程管理

> 实验人员：邹佳衡（2312322）、张宇（2312034）、蒲天轶（2112311）

## 练习1：分配并初始化一个进程控制块

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

### 代码实现

```cpp

static struct proc_struct *
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        proc->state = PROC_UNINIT;
        proc->pid = -1;
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&proc->context, 0, sizeof(struct context));
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN + 1);
        list_init(&proc->list_link);
        list_init(&proc->hash_link);
    }
    return proc;
}
```

主要功能
1. 内存分配 ：使用 kmalloc 函数分配一个 proc_struct 结构体的内存空间
2. 字段初始化 ：将进程控制块的关键字段初始化为合适的初始值
3. 错误处理 ：如果内存分配失败，返回 NULL 指针

其中比较重要的字段包括：

- state (进程状态)：表示进程的当前状态。这是进程生命周期的起点，标识进程尚未完全初始化。后续通过wakeup_proc等函数，进程状态会转变为 PROC_RUNNABLE 等其他状态。

- pid (进程ID)：唯一标识一个进程。初始化为-1表示进程尚未分配有效的PID。在 do_fork 函数中，通过调用 get_pid() 会为进程分配一个唯一的有效PID。

- kstack (内核栈地址)：指向进程内核栈的起始地址。内核栈是进程在内核态运行时使用的栈空间，用于保存函数调用、中断处理等上下文信息。初始化为0，表示栈空间尚未分配，后续在 setup_kstack 函数中会实际分配并设置。

- need_resched (重新调度标志)：标记进程是否需要被重新调度。当此标志为1时，调度器会在适当的时候重新选择一个进程运行。这是实现抢占式调度的重要机制。

- parent (父进程指针)：指向创建当前进程的父进程。维护进程间的父子关系，父进程负责回收子进程资源。在 do_fork 函数中，会将其设置为当前进程。

- mm (内存管理结构)：管理进程的内存空间。

- context (上下文结构)：保存进程的上下文信息，包括ra(返回地址)、sp(栈指针)和s0-s11寄存器。在进程切换时， switch_to 函数会保存当前进程的context并恢复目标进程的context，实现上下文的保存和恢复。在 copy_thread 函数中会进一步设置context.ra指向forkret函数。

- tf (中断帧)：指向进程内核栈顶的中断帧结构。保存进程的完整寄存器状态，包括通用寄存器、status、epc等。在 copy_thread 函数中会为其分配空间并初始化，这是进程被中断后能够正确恢复执行的关键。

### struct context context

含义：

context 结构体定义在proc.h中，包含了RISC-V架构下的关键寄存器集合，主要包括：ra（返回地址寄存器），sp （栈指针寄存器），s0-s11 （12个保存寄存器）

作用：

- 进程上下文切换：这是进程切换的核心数据结构，在switch_to汇编函数中直接使用
- 寄存器保存与恢复：当CPU从一个进程切换到另一个进程时，需要保存当前进程的这些寄存器值，并加载下一个进程的寄存器值

### struct trapframe *tf

含义：

- trapframe 结构体定义在trap.h中，包含了更完整的寄存器集合，主要包括：
  
  1.所有通用寄存器（通过 struct pushregs gpr ）
  
  2.状态寄存器 status
  
  3.程序计数器 epc
  
  4.错误地址 badvaddr
  
  5.异常原因 cause

作用：

- 中断/异常处理：保存进程在发生中断或异常时的完整执行环境
- 进程创建与初始化：在创建新进程（如通过do_fork）时，用于设置子进程的执行环境
- 完整执行现场：包含比context更全面的执行状态信息，能够完全恢复进程的执行状态

## 练习2：为新创建的内核线程分配资源

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用do_fork函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是stack和trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。

### 代码实现

```cpp
    // 1. 调用alloc_proc分配进程控制块
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }

    // 2. 调用setup_kstack为子进程分配内核栈
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }

    // 3. 调用copy_mm复制或共享内存管理信息
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }

    // 4. 调用copy_thread设置tf和context
    copy_thread(proc, stack, tf);

    // 5. 为进程分配pid并设置父进程
    proc->pid = get_pid();
    proc->parent = current;
    proc->runs = 0;
    proc->flags = clone_flags;

    // 6. 将proc_struct插入到hash_list和proc_list
    hash_proc(proc);
    list_add(&proc_list, &proc->list_link);
    nr_process++;

    // 7. 调用wakeup_proc使新进程可运行
    wakeup_proc(proc);

    // 8. 设置返回值为子进程的pid
    ret = proc->pid;
```

### 设计实现过程
在ucore操作系统中，线程的创建主要通过do_fork函数实现，该函数负责为新进程分配进程控制块、内核栈、内存管理结构、设置上下文，并分配唯一的PID。

关键实现步骤包括：

1. 调用alloc_proc分配进程控制块
2. 调用setup_kstack为子进程分配内核栈
3. 调用copy_mm复制或共享内存管理信息
4. 调用copy_thread设置中断帧和上下文
5. 调用get_pid分配唯一的PID
6. 将进程插入到进程列表和哈希表
7. 唤醒新进程使其可运行

### PID唯一性分析
通过分析代码实现，可以确认ucore确实为每个新fork的线程分配了唯一的ID。这主要通过get_pid函数保证，其设计具有以下特点：

1.递增分配pid：
   
   - 使用静态变量last_pid追踪下一个要分配的PID
   - 每次调用时递增last_pid，如果超过MAX_PID则重新从1开始

2.唯一性验证：
   
   - 在分配PID时，会遍历所有已存在的进程（通过proc_list）
   - 检查新PID是否已被使用，如果已使用则跳过并尝试下一个PID
   - 通过list_for_each和le2proc宏遍历进程列表，比较每个进程的PID

3.优化搜索：
   
   - 维护next_safe变量记录下一个可用PID范围
   - 利用这个变量可以在多数情况下避免遍历整个进程列表

4.保证唯一性的核心代码：
```cpp
while ((le = list_next(le)) != list) {
    proc = le2proc(le, list_link);
    if (proc->pid == last_pid) {
        if (++last_pid >= next_safe) {
            if (last_pid >= MAX_PID) {
                last_pid = 1;
            }
            next_safe = MAX_PID;
            goto repeat;
        }
    }
    else if (proc->pid > last_pid && next_safe > proc->pid) {
        next_safe = proc->pid;
    }
}
```
5.边界条件处理：
   - 通过静态断言static_assert(MAX_PID > MAX_PROCESS)确保PID空间足够大
   - 当PID达到最大值时，会重新从1开始搜索可用PID

### 结论
ucore操作系统通过精心设计的get_pid函数，确保了每个新fork的线程都能获得一个唯一的ID。该实现不仅考虑了正常情况，还处理了PID回绕、进程终止后PID回收等场景，同时通过优化搜索策略提高了分配效率。因此，ucore确实做到了为每个新fork的线程分配唯一的ID。

## 练习3: 编写proc_run 函数

### 实现思路

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

1、检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。

2、禁用中断。你可以使用/kern/sync/sync.h中定义好的宏local_intr_save(x)和local_intr_restore(x)来实现关、开中断。

3、切换当前进程为要运行的进程。

4、切换页表，以便使用新进程的地址空间。/libs/riscv.h中提供了lsatp(unsigned int pgdir)函数，可实现修改SATP寄存器值的功能。

5、实现上下文切换。/kern/process中已经预先编写好了switch.S，其中定义了switch_to()函数。可实现两个进程的context切换。

6、允许中断。

### 实现过程

首先，我们要使用local_intr_save函数关闭中断，我们找到/kern/sync/sync.h中定义好的宏local_intr_save(x):

```cpp
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
```

local_intr_save(x)接受一个bool类型的变量，记录调用函数__intr_save前，是否启动了中断，因此，在函数proc的实现中，我们先定义一个bool类型的变量flag，再调用宏local_intr_save(flag)来关闭中断。

```cpp
bool flag;
local_intr_save(flag);
```

接下来，我们需要使用lsatp(unsigned int pgdir)函数，修改SATP寄存器的值，以实现页表的切换。我们找到/libs/riscv.h中提供的lsatp(unsigned int pgdir)函数。

```cpp
static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
}
```

lsatp函数的参数是页目录的基址pgdir，而页目录的基址存在结构体proc_struct中：

```cpp
struct proc_struct
{
    enum proc_state state;        // Process state
    int pid;                      // Process ID
    int runs;                     // the running times of Proces
    uintptr_t kstack;             // Process kernel stack
    volatile bool need_resched;   // bool value: need to be rescheduled to release CPU?
    struct proc_struct *parent;   // the parent process
    struct mm_struct *mm;         // Process's memory management field
    struct context context;       // Switch here to run process
    struct trapframe *tf;         // Trap frame for current interrupt
    uintptr_t pgdir;              // the base addr of Page Directroy Table(PDT)
    uint32_t flags;               // Process flag
    char name[PROC_NAME_LEN + 1]; // Process name
    list_entry_t list_link;       // Process link list
    list_entry_t hash_link;       // Process hash list
};
```
切换当前进程为要运行的进程
```cpp
struct proc_struct *prev = current;
current = proc;
```

保存当前进程指针：struct proc_struct *prev = current;

更新全局当前进程指针：current = proc;

因此，在函数的实现中，我们首先获取要切换的进程proc的页表基址，再使用lsatp函数进行页表的切换

```cpp
lsatp(proc->pgdir);
```

接下来，我们需要使用函数switch_to实现上下文切换，switch_to函数需要当前进程current和要切换的进程proc的上下文指针作为参数

```cpp
switch_to(&(current->context), &(proc->context));
```

完成上述操作后，将当前的进程切换为要运行的线程

```cpp
current = proc;
```

最后，使用local_intr_restore(flag)函数重新打开中断，我们找到/kern/sync/sync.h中定义好的宏local_intr_restore(x):

```cpp
static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_restore(x) __intr_restore(x);
```

local_intr_restore(x)会恢复调用local_intr_save之前的状态，我们只需要将之前获取的flag作为参数即可，flag==1表示之前中断是打开的的，__intr_restore将会打开中断，flag==0表示之前中断时关闭的，接下来保持关闭即可。

```cpp
local_intr_restore(flag);
```

## 扩展练习Challenge

### local_intr_save/restore中断开关机制

其源码位于kern/sync/sync.h:
```cpp
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);
```
1.保存中断状态：local_intr_save(intr_flag)

- 调用__intr_save()函数读取当前的sstatus寄存器值，检查中断使能位(SIE)
- 如果中断当前是开启的(SIE=1)，则调用intr_disable()关闭中断，并返回true(1)
- 如果中断当前是关闭的(SIE=0)，则直接返回false(0)
- 将返回值保存在传入的intr_flag变量中，记录原始中断状态

2.恢复中断状态：local_intr_restore(intr_flag)

- 调用__intr_restore(flag)函数，并传入之前保存的中断状态标志
- 如果flag为true(1)，表示在local_intr_save之前中断是开启的，因此调用intr_enable()重新开启中断
- 如果flag为false(0)，表示在local_intr_save之前中断就是关闭的，因此保持中断关闭状态

### 分页模式的基本原理
RISC-V架构支持多种分页模式，包括SV32(二级)、SV39(三级)和SV48(四级)，用于不同的虚拟地址空间大小需求：

|分页模式|虚拟地址位数|页表级数|每级索引位数|最大虚拟地址空间|
|------|------|------|------|------| 
|SV32|32|2|10|4GB| 
|SV39|39|3|9|512GB| 
|SV48|48|4|9|256TB|

### 为什么get_pte中的两段代码相似
```cpp
    pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
```
这是因为RISC-V的SV39分页模式采用多级页表，每级页表的结构相似且每级页表的查找/创建过程遵循相同模式：

- 检查页表项是否有效（V位是否设置）；
- 如果无效且create=true，则分配新页；
- 设置页表项引用计数；
- 初始化页表内容（清0）；
- 创建页表项并设置权限；

这种相似的结构设计使得代码可以更容易地扩展到更多级别的页表（如SV48的第四级页表）。虚拟地址解析是从高位到低位依次进行的，每级处理一部分地址位，结构自然相似。

### 评价get_pte函数：
将页表项查找和创建合并在一个函数中有其优缺点：

优点：

1. 接口简洁 ：单一函数处理完整的页表项获取流程，使用方便；
2. 减少重复代码 ：避免了拆分后可能出现的重复逻辑；
3. 错误处理一致 ：统一的错误处理机制，减少错误情况遗漏；

缺点：

1. 功能耦合 ：查找和创建两个不同功能耦合在一起，违反单一职责原则；
2. 代码复用性降低 ：对于只需要查找不需要创建的场景，仍需传入create参数；
3. 扩展性受限 ：当需要改变查找或创建逻辑时，可能会相互影响；

## 运行结果
make qemu运行结果：
```
zoujiaheng@zoujiaheng-virtual-machine:~/winShare/OS_shared/lab4/lab4$ make qemu

OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
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
  entry  0xc020004a (virtual)
  etext  0xc0203eae (virtual)
  edata  0xc0209030 (virtual)
  end    0xc020d4ec (virtual)
Kernel executable memory footprint: 54KB
memory management: default_pmm_manager
physcial memory map:
  memory: 0x08000000, [0x80000000, 0x87ffffff].
vapaofset is 18446744070488326144
check_alloc_page() succeeded!
check_pgdir() succeeded!
check_boot_pgdir() succeeded!
use SLOB allocator
kmalloc_init() succeeded!
check_vma_struct() succeeded!
check_vmm() succeeded.
alloc_proc() correct!
++ setup timer interrupts
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
kernel panic at kern/process/proc.c:404:
    process exit!!.

Welcome to the kernel debug monitor!!
Type 'help' for a list of commands.
```
make grade运行结果：
```
make[1]: 进入目录“/home/zoujiaheng/winShare/OS_shared/lab4/lab4” + cc kern/init/entry.S + cc kern/init/init.c + cc kern/libs/stdio.c + cc kern/libs/readline.c + cc kern/debug/panic.c + cc kern/debug/kdebug.c + cc kern/debug/kmonitor.c + cc kern/driver/dtb.c + cc kern/driver/clock.c + cc kern/driver/console.c + cc kern/driver/picirq.c + cc kern/driver/intr.c + cc kern/trap/trap.c + cc kern/trap/trapentry.S + cc kern/mm/pmm.c + cc kern/mm/vmm.c + cc kern/mm/kmalloc.c + cc kern/mm/default_pmm.c + cc kern/process/entry.S + cc kern/process/switch.S + cc kern/process/proc.c + cc kern/schedule/sched.c + cc libs/string.c + cc libs/printfmt.c + cc libs/hash.c + ld bin/kernel riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img make[1]: 离开目录“/home/zoujiaheng/winShare/OS_shared/lab4/lab4”
  -check alloc proc:                         OK
  -check initproc:                           OK
Total Score: 30/30
```
