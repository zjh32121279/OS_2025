# Lab 5：用户程序
>小组成员：邹佳衡（2312322）、张宇（2312034）、蒲天轶（2112311）

- [Lab 5：用户程序](#lab-5用户程序)
  - [实验内容](#实验内容)
  - [实验目的](#实验目的)
  - [练习1：加载应用程序并执行](#练习1加载应用程序并执行)
    - [实现步骤](#实现步骤)
  - [练习2：父进程复制自己的内存空间给子进程](#练习2父进程复制自己的内存空间给子进程)
    - [页复制流程的核心实现分析](#页复制流程的核心实现分析)
    - [物理页到内核虚拟地址的转换](#物理页到内核虚拟地址的转换)
  - [练习3：阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现](#练习3阅读分析源代码理解进程执行-forkexecwaitexit-的实现以及系统调用的实现)
    - [函数分析](#函数分析)
    - [内核态与用户态程序是如何交错执行的](#内核态与用户态程序是如何交错执行的)
    - [内核态执行结果是如何返回给用户程序的](#内核态执行结果是如何返回给用户程序的)
    - [uCore 用户态进程的执行状态生命周期图](#ucore-用户态进程的执行状态生命周期图)
  - [扩展练习](#扩展练习)
    - [1、实现 Copy on Write （COW）机制](#1实现-copy-on-write-cow机制)
      - [设计目标](#设计目标)
      - [COW 的状态转换模型（有限状态自动机）](#cow-的状态转换模型有限状态自动机)
      - [机制关键实现细节与源码说明](#机制关键实现细节与源码说明)
    - [2、说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？](#2说明该用户程序是何时被预先加载到内存中的与我们常用操作系统的加载有何区别原因是什么)


## 实验内容

实验4完成了内核线程，但到目前为止，所有的运行都在内核态执行。实验5将创建用户进程，让用户进程在用户态执行，且在需要ucore支持时，可通过系统调用来让ucore提供服务。为此需要构造出第一个用户进程，并通过系统调用sys_fork/sys_exec/sys_exit/sys_wait来支持运行不同的应用程序，完成对用户进程的执行过程的基本管理。

## 实验目的

1. 了解第一个用户进程创建过程

2. 了解系统调用框架的实现机制

3. 了解ucore如何实现系统调用sys_fork/sys_exec/sys_exit/sys_wait来进行进程管理

## 练习1：加载应用程序并执行

load_icode 函数的主要作用是将一个 ELF 格式的用户程序加载到当前进程的地址空间中，并完成从内核态向用户态执行过渡所需的全部准备工作。该函数负责创建并初始化进程的内存管理结构（mm_struct）、构建页表、加载程序的代码段和数据段、建立用户栈，最终设置好用户态执行所需的陷阱帧（trapframe），使进程在从内核返回时能够正确进入用户态并从程序入口开始执行。

首先，内核为当前进程创建并初始化了新的 mm_struct，建立了页目录；随后解析 ELF 文件头和程序头表，将用户程序的 TEXT、DATA 段复制到用户虚拟地址空间中，并正确构造了 BSS 段；在此基础上，还为进程映射并分配了用户栈空间，并将新的页目录切换为当前使用的地址空间。

### 实现步骤

在完成上述步骤后，接下来是本实验需要完成的部分。我们需要初始化进程的陷阱帧（trapframe），设置用户态执行的上下文信息，包括用户栈指针、程序入口地址以及处理器状态寄存器的关键位，从而保证进程能够在中断返回时正确地从内核态切换到用户态并开始执行用户程序。

首先，将用户栈指针设置为用户栈顶地址：

```cpp
tf->gpr.sp = USTACKTOP;
```

USTACKTOP 表示用户栈在虚拟地址空间中的最高地址。此前函数已经为用户栈分配并映射了相应的内存页，因此将 sp 设置为 USTACKTOP，可以保证用户程序在进入用户态后，栈指针指向一块合法且可用的用户栈空间。

接下来，设置用户程序的执行入口地址：

```cpp
tf->epc = elf->e_entry;
```

elf->e_entry 是从 ELF 文件头中解析得到的程序入口点地址。将该值赋给陷阱帧中的 epc（异常程序计数器），可以确保在从内核态返回到用户态时，CPU 从用户程序的入口函数开始执行。

最后，设置处理器状态寄存器 status，以保证正确的特权级切换和中断状态：

```cpp
tf->status = sstatus & ~SSTATUS_SPP | SSTATUS_SPIE;
```

其中：

1. SSTATUS_SPP 表示上一次运行的特权级，将其清零可以保证 sret 指令返回到用户态；

2. SSTATUS_SPIE 用于控制中断使能状态，将其置位可以保证在进入用户态后能够正确响应中断；

3. 通过保留原有 sstatus 中的其他位，避免破坏系统已有的状态信息。

通过上述设置，陷阱帧中包含了完整且正确的用户态执行上下文信息。当内核执行 sret 指令时，处理器将依据该陷阱帧中的内容切换到用户态，设置好栈指针和程序计数器，从而使用户程序得以正常开始执行。

## 练习2：父进程复制自己的内存空间给子进程

从整体结构上看，`copy_range` 以页为基本单位遍历虚拟地址区间。对于每一个虚拟页，函数首先通过页表查找判断该页是否存在以及是否有效；若对应页表项不存在，则跳过当前页表范围；若页表项存在且有效，则进入实际的页复制流程。整个函数的执行逻辑可以概括为以下几个步骤：

1. 根据父进程页表，查找当前虚拟地址对应的页表项（PTE），判断该页是否已经映射；
2. 若该虚拟页有效，则为子进程分配一块新的物理页；
3. 将父进程物理页中的内容复制到子进程的新物理页中；
4. 在子进程的页表中建立虚拟地址到新物理页的映射，并设置相应的访问权限。

通过上述流程，`copy_range` 实现了对用户地址空间的逐页“深拷贝”，保证父子进程在逻辑上拥有相同的初始内存内容，但在物理内存层面相互独立。

### 页复制流程的核心实现分析

在 copy_range 函数中，内核以页为单位遍历父进程在 [start, end) 范围内的用户虚拟地址空间。对于每一个已经映射且有效的虚拟页，内核需要完成以下三个关键步骤：

1. 定位父进程虚拟页对应的物理页，并为子进程分配一块新的物理页；
2. 将父进程物理页中的内容完整复制到子进程的新物理页中，以保证子进程获得与父进程一致的初始内存数据；
3. 在子进程的页表中建立虚拟地址到新物理页的映射关系，并正确设置访问权限，使该页在子进程地址空间中生效。

### 物理页到内核虚拟地址的转换

由于cpu只能通过虚拟地址访问内存，因此我们要将父进程和子进程的物理内存描述符page和npage转化成内核虚拟地址，在 `copy_range` 中，这一转换通过 `page2kva` 函数完成。该函数将物理页描述符对应的物理地址映射为内核虚拟地址，使内核能够直接对该页进行读写操作。具体实现如下：

```cpp
void *src = page2kva(page);
void *dst = page2kva(npage);
```

其中，src 指向父进程物理页在内核地址空间中的映射地址，dst 指向子进程新分配物理页在内核地址空间中的映射地址。

在获得父子进程物理页对应的内核虚拟地址后，内核即可通过普通的内存拷贝操作完成页内容的复制。在 libs/string.c 中，可以找到 memcpy 函数的定义如下：

```cpp
void *memcpy(void *dst, const void *src, size_t n) {
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
```

在未使用架构相关优化实现（__HAVE_ARCH_MEMCPY）的情况下，memcpy 通过逐字节复制的方式，将从地址 src 开始的 n 个字节复制到 dst 指向的内存区域，并最终返回目标地址 dst。

在 copy_range 中，内核利用该函数将父进程的一整页内容复制到子进程的新物理页中：

```cpp
memcpy(dst, src, PGSIZE);
```

在完成物理页内容的复制之后，还需要在子进程的页表中建立虚拟地址到新物理页的映射关系。该操作通过 page_insert 函数完成

```cpp
ret = page_insert(to, npage, start, perm);
```

该语句的作用是将物理页 npage 插入到子进程的页目录 to 中，使虚拟地址 start 映射到该物理页，并设置相应的访问权限 perm。page_insert 在内部会负责页表项的创建或更新、物理页引用计数的维护以及必要的 TLB 刷新操作，从而保证该映射在子进程地址空间中正确生效。

至此，子进程在虚拟地址 start 处即可访问一页与父进程内容一致、但物理上相互独立的内存，实现了用户地址空间的正确复制。

## 练习3：阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现

### 函数分析

1、fork——创建新进程

fork 用于创建一个新的子进程。子进程获得父进程地址空间的一个副本（或共享，取决于实现），并从 fork 调用点开始执行。在用户态中，用户程序调用fork()，通过 ecall 指令陷入内核态，触发系统调用号 SYS_fork。

sys_fork的代码实现如下：

```cpp
static int
sys_fork(uint64_t arg[]) {
    struct trapframe *tf = current->tf;
    uintptr_t stack = tf->gpr.sp;
    return do_fork(0, stack, tf);
}
```

执行流程：
1. 取得当前进程的陷阱帧 trapframe
2. 获取当前用户栈指针
3. 调用 do_fork 执行真正的进程复制，在do_fork 内部，会执行以下步骤：
 - 分配新的 PCB
 - 复制或共享父进程地址空间
 - 复制 trapframe
 - 设置父子进程返回值
 - 将子进程加入调度队列

 fork的执行过程中，fork()接口的调用是在用户态完成的，sys_fork和do_fork的调用在内核态完成，最后，子进程在用户态开始运行

2、sys_exec

exec 用于用一个新的程序替换当前进程的地址空间和执行内容。进程本身并不会消失（PID 不变），但原有的用户程序、代码段、数据段和栈都会被新程序完全替换。在用户态，用户程序用exec(name, len, binary, size)用户程序请求加载新程序，进入内核态sys_exec。


sys_exec的代码如下：

```cpp
static int
sys_exec(uint64_t arg[]) {
    const char *name = (const char *)arg[0];
    size_t len = (size_t)arg[1];
    unsigned char *binary = (unsigned char *)arg[2];
    size_t size = (size_t)arg[3];
    return do_execve(name, len, binary, size);
}
```

在sys_exec中，内核首先从寄存器中取出程序名、ELF 二进制地址，再调用 do_execve，do_execve的流程为：

 - 销毁当前进程原有地址空间
 - 解析 ELF 文件
 - 调用 load_icode
 - 构建新的页表
 - 初始化 trapframe
 - 准备返回用户态执行新程序

exec的执行过程中，首先exec()接口的调用在用户态中完成，sys_exec和do_execve的调用在内核态中完成，最后，新进程在用户态中执行。

3、sys_wait

wait 使父进程阻塞，直到指定的子进程（或任意子进程）退出，并回收其资源，防止产生僵尸进程。sys_wait的代码如下：

```cpp
static int
sys_wait(uint64_t arg[]) {
    int pid = (int)arg[0];
    int *store = (int *)arg[1];
    return do_wait(pid, store);
}
```

在sys_wait中，内核先获取等待的pid和保存退出码的地址，再调用 do_wait，do_wait的执行逻辑：

 - 查找目标子进程
 - 若未退出 → 阻塞当前进程
 - 若已退出 → 回收 PCB 和资源
 - 将退出状态写回用户空间

wait的执行过程中，wait()调用在用户态中完成，sys_wait和do_wait的调用在内核态中完成，返回父进程在用户态中执行。

4、sys_exit

exit 用于结束当前进程的执行，释放进程占用的资源，并向其父进程发送退出状态。sys_exit的代码如下：

```cpp
static int
sys_exit(uint64_t arg[]) {
    int error_code = (int)arg[0];
    return do_exit(error_code);
}
```

sys_exit的核心为do_exit，do_exit的执行流程如下：

 - 保存退出码
 - 释放用户地址空间
 - 唤醒等待的父进程
 - 将进程状态置为 ZOMBIE
 - 触发调度切换

exit的执行过程中，exit()调用在用户态中完成，sys_exit和do_exit的调用在内核态中完成。

### 内核态与用户态程序是如何交错执行的

用户态程序负责“发起请求”，内核态程序负责“完成特权操作”，二者通过系统调用（trap）与中断机制交错执行。用户态与内核态的执行呈现出如下流程：

1. 用户态程序执行
2. 陷入内核态（trap）
3. 内核态执行系统调用处理逻辑
4. 返回用户态（sret）
5. 用户态程序继续执行

### 内核态执行结果是如何返回给用户程序的

在 uCore 中，当用户程序通过系统调用或异常陷入内核态时，处理器会自动将当前用户态的执行上下文（包括程序计数器和通用寄存器等）保存到该进程的陷阱帧（trapframe）中。内核在内核态完成相应的处理逻辑后，会将系统调用的返回结果写入陷阱帧中约定的返回值寄存器（在 RISC-V 架构下为 a0），并根据需要更新陷阱帧中的程序计数器和处理器状态寄存器，以确保返回到用户态并处于正确的特权级。随后，内核执行 sret 指令，处理器依据陷阱帧中保存的信息恢复用户态寄存器状态、切换回用户态特权级，并从用户程序的下一条指令继续执行，此时用户程序即可从寄存器中读取系统调用的返回值，从而完成内核态执行结果向用户态程序的返回。

### uCore 用户态进程的执行状态生命周期图

uCore 中用户态与内核态通过系统调用和中断机制交错执行，内核通过陷阱帧和 sret 指令将执行结果返回给用户程序；进程在 fork、exec、wait 和 exit 的驱动下，在 RUNNABLE、RUNNING、SLEEPING 和 ZOMBIE 等状态之间转换，构成完整的用户态进程生命周期。以下是用户态进程的执行状态生命周期图：

            fork / do_fork
        +--------------------+
        |                    |
        v                    |
    +--------+          +--------+
    | UNINIT |          | RUNNING|
    +--------+          +--------+
         |                    |
         | wakeup / schedule  |
         v                    |
    +-----------+ <------------+
    | RUNNABLE  |
    +-----------+
         |
         | schedule()
         v
    +-----------+
    | RUNNING   |
    +-----------+
         |
         | wait / sleep
         v
    +-----------+
    | SLEEPING  |
    +-----------+
         |
         | wakeup()
         v
    +-----------+
    | RUNNABLE  |
    +-----------+

         RUNNING
            |
            | exit / do_exit
            v
        +---------+
        | ZOMBIE  |
        +---------+
            |
            | wait / do_wait
            v
         (资源回收，进程消失)


## 扩展练习

### 1、实现 Copy on Write （COW）机制

#### 设计目标

1. 在 `fork` 时：
   - 父子进程共享用户空间页面
   - 页面权限设置为 **只读**
   - 增加物理页的引用计数

2. 在写访问触发 page fault 时：
   - 判断是否为 COW 场景
   - 为当前进程分配新物理页
   - 拷贝原页面内容
   - 修改页表权限为可写
   - 更新引用计数

3. 保证：
   - 父子进程互不影响
   - 页引用计数正确维护
   - fork / exec / exit 等路径下内存安全

#### COW 的状态转换模型（有限状态自动机）

1. 页面状态定义

每个用户页在 COW 机制下可抽象为以下状态：

- **P（Private）**：独占页，可读可写
- **S（Shared-RO）**：共享页，只读（COW 页）
- **C（Copied）**：因写触发复制后的新私有页
- **F（Freed）**：页已释放

2. 状态转换图
```
┌───────────────┐
│ ▼
[P: Private] ──→ [S: Shared-RO]
▲ │
│ │ write fault
│ ▼
└─────────── [C: Copied]
```
#### 机制关键实现细节与源码说明

1. Page 结构扩展（物理页引用计数）

```c
// kern/mm/pmm.h
struct Page {
    int ref;            // 物理页引用计数
    uint32_t flags;
    uintptr_t pra_vaddr;
    list_entry_t page_link;
};
```

2. 在 RISC-V 页表中选择一个 software reserved bit：

```cpp
#define PTE_COW  (1 << 8) 
```

3. 修改 copy_range

```cpp
int
copy_range(pde_t *to, pde_t *from,
           uintptr_t start, uintptr_t end, bool share) {
    uintptr_t addr;
    for (addr = start; addr < end; addr += PGSIZE) {
        pte_t *ptep = get_pte(from, addr, 0);
        if (ptep == NULL || !(*ptep & PTE_V)) {
            continue;
        }

        struct Page *page = pte2page(*ptep);
        page->ref++;

        // 清除写权限，设置 COW
        *ptep &= ~PTE_W;
        *ptep |= PTE_COW;

        pte_t *new_ptep = get_pte(to, addr, 1);
        *new_ptep = *ptep;
    }
    return 0;
}
```

4. Page Fault 判断条件

在 do_pgfault() 中增加判断：
```cpp
if ((error_code & PF_WRITE) && (*ptep & PTE_COW)) {
    return cow_pgfault(mm, addr, ptep);
}
```
5. COW Page Fault 处理逻辑
```cpp
int cow_pgfault(struct mm_struct *mm,
                uintptr_t addr, pte_t *ptep) {
    struct Page *old_page = pte2page(*ptep);

    if (old_page->ref > 1) {
        struct Page *new_page = alloc_page();
        memcpy(page2kva(new_page), page2kva(old_page), PGSIZE);

        old_page->ref--;

        *ptep = page2pa(new_page)
              | PTE_V | PTE_U | PTE_R | PTE_W;
    } else {
        // 只有一个引用，直接升级为可写
        *ptep |= PTE_W;
        *ptep &= ~PTE_COW;
    }

    tlb_invalidate(mm->pgdir, addr);
    return 0;
}
```

6. 有限状态自动机（FSM）分析

单页状态机
```
        ┌────────────┐
        │ Private RW │
        └─────┬──────┘
              │ fork
              ▼
        ┌────────────┐
        │ Shared RO  │
        │  (COW)     │
        └─────┬──────┘
              │ write fault
              ▼
        ┌────────────┐
        │ Private RW │
        └────────────┘
```

状态转换说明
事件	                动作
fork	                清 PTE_W，设 PTE_COW，ref++
写 fault（ref > 1）	    分配新页，复制，ref--
写 fault（ref == 1）	直接恢复写权限

### 2、说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

在 uCore 中，用户程序是在内核启动完成后、由内核中的 initproc 进程通过 kernel_execve → do_execve → load_icode 主动加载到内存中的：内核在编译阶段就把所有用户程序的 ELF 二进制直接链接进内核镜像，运行时只需从内核内存中拷贝到新进程的用户地址空间即可；这与常用操作系统（如 Linux）在用户态通过文件系统按需从磁盘读取可执行文件并结合页缓存进行懒加载（demand paging）的方式不同。造成这种差异的原因是 uCore 作为教学操作系统，没有完整的文件系统、磁盘驱动和页缓存机制，因此采用“预先打包进内核、一次性加载”的方式来简化实现、降低实验复杂度，同时突出虚拟内存、进程与异常处理等核心机制的教学重点。
