# Lab 2：物理内存和页表
>小组成员：邹佳衡（2312322）、张宇（2312034）、蒲天轶（2112311）

## 实验内容

实验一过后大家做出来了一个可以启动的系统，实验二主要涉及操作系统的物理内存管理。操作系统为了使用内存，还需高效地管理内存资源。本次实验我们会了解如何发现系统中的物理内存，然后学习如何建立对物理内存的初步管理，即了解连续物理内存管理，最后掌握页表相关的操作，即如何建立页表来实现虚拟内存到物理内存之间的映射，帮助我们对段页式内存管理机制有一个比较全面的了解。本次的实验主要是在实验一的基础上完成物理内存管理，并建立一个最简单的页表映射。

## 实验目的

- 理解页表的建立和使用方法
- 理解物理内存的管理方法
- 理解页面分配算法

## 实验内容

### 练习1：理解first-fit 连续物理内存分配算法

** 实现原理 **

first-fit 算法是指在收到内存分配申请时，算法扫描空闲内存块链表，直到找到第一个足够大的内存块来满足要求。优点在于计算速度快，实现简单，缺点在于容易在链表开头处产生大量小碎片。

** 代码分析 **

首先我们先从初始化开始，也就是default_init函数：

** 1.default_init **

```cpp
static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}
```

让我们从头开始一点点分析，free_area_t是一个结构体：

```cpp
typedef struct {
    list_entry_t free_list;         // the list header
    unsigned int nr_free;           // number of free pages in this free list
} free_area_t;
```

list_entry_t是结构体list_entry的别名：

```cpp
struct list_entry {
    struct list_entry *prev, *next;
};
```

这里面有两个指向自身类对象的指针，合理推测这次实现的空闲内存块链表是一个双向链表，prev指针指向前方，next指向后方，free_list是链表头，nr_free是链表中有几个节点。

紧接着，这里有一个list_init函数：

```cpp
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
}
```

初始化时，链表头的两个指针都指向自身，节点数为零，因此这个链表很可能不只是一个双向链表，还有可能是个循环链表。

** 2.default_init_memmap **

```cpp
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
```

在这个函数中，有一个结构体至关重要，它就是Page:

```cpp
struct Page {
    int ref;                        // page frame's reference counter
    uint64_t flags;                 // array of flags that describe the status of the page frame
    unsigned int property;          // the num of free block, used in first fit pm manager
    list_entry_t page_link;         // free list link
};

/* Flags describing the status of a page frame */
#define PG_reserved                 0       // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0 
#define PG_property                 1       // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page.

```

其中ref是引用计数器，当引用计数为0时，表示该页帧是空闲的，可以被分配。当分配一个页帧时，其引用计数会被设置为1；当释放时，引用计数减1，如果减到0则将该页帧回收。当多个虚拟页面映射到同一个物理页帧时，引用计数会大于1。

flag是一个64位的无符号整数，用于描述页帧的状态。目前定义了两个标志位：
- PG_reserved（保留位）：如果被设置，表示该页帧被内核保留，不能用于分配和释放。
- PG_property（属性位）：如果被设置，表示该页帧是一个空闲内存块的头页面（即该页帧是一个连续空闲内存块的第一个页帧），并且可以被用于分配。

标志位通过位操作来设置和清除，例如：
- SetPageReserved(page)：设置保留位。
- ClearPageReserved(page)：清除保留位。
- PageReserved(page)：检查保留位是否被设置。

类似地，也有对PG_property的操作。

property用于记录以该页为开头的连续空闲页的数量，非头页这个值为零。

page_link用于将这个空闲块连入链表中。

当我们能够理解Page结构体时，也就能理解default_inin_memmap函数：

首先保证n大于0，将base作为空闲内存块的起始地址，在循环代码块中，空闲内存块被分为n页，通过base到base+n-1进行索引，这个循环先确保保留位设置，然后将flag和property设置为零，再将引用次数ref设置为零，表明这个页还没有被虚拟内存映射。

随后通过头页也就是base记录有多少页，再将base属性位设置表明它的头页身份，再将nr_free也就是链表页数加上n。

随后的分支语句先检查空闲内存块链表是否是空，如果是的话，将这个内存块插入到表头的后方，形成free_list<——>base->page_link<——>free_list的双向循环链表。如果空闲链表不为空，则遍历链表，找到第一个地址大于base的页面，将base插入到该页面之前。如果遍历完整个链表（即直到链表头）都没有找到地址大于base的页面，则将base插入到链表尾部。

总而言之，default_init_memmap将一个内存块按照地址由低到高，通过page_link链入到空闲块链表中，这个内存块分为base到base+n-1个页，头页记录这个内存块有多少页。

** default_alloc_pages **

```cpp
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

首先检查空闲内存块链表是否足够大，如果n>nr_free的话，返回空指针，因此我合理推测这是有关响应空闲内存块申请的函数。

接着进行整个链表的扫描，le2page(le, page_link)的作用是：给定一个指向Page结构体中page_link成员的指针（le），计算出这个Page结构体的起始地址。如果le指向的这个Page内存块的页数不小于要求的页数n，就将这个内存块的指针赋值给page。

随后是找到合适大小的内存块后的处理，将page_link的前指针赋给临时变量prev，list_del函数用于将page_link的前指针指向的内存块中的后指针改为指向page_link的后一个内存块，将page_link的后指针指向的内存块的前指针改为指向page_link的前一个内存块。简单来说，就是将这个我们选中的内存块从链表上拿下来。

如果我们选中的内存块（即page指向的内存块）页数多余我们请求的，那么还要进行一次切分工作，将page+n的页设置为头页，并进行属性的修改，再重新将这个分割剩下的内存块链入到链表中。

最后，链表页数nr_free减去我们申请的页数，并清除属性位。

总而言之，这个函数应该是first-fit算法的具体实现，他是要将我们第一个符合要求的内存块用于响应空闲块申请，如果这个内存块较大，还要进行切分，将多余的部分重新链入到链表中。

** default_free_pages **

```cpp
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```

通过函数名default_free_pages合理推测该函数可能是用来释放已分配内存块的函数。

首先第一部分和函数default_init_memmap函数基本一样，首先通过验证保留位和属性位确保释放的页面有效，将flag和ref重新置零，由于非头页property在default_init_memmap函数中就已经设置好了，因此暂时不用设置。接着就是和前面的函数类似的操作，这里不再展开。

紧接着是与default_init_memmap相同的分支指令，功能是确保链表按物理地址升序排列，具体实现不在展开。

紧接着，是将指向base的前一个内存块的page_link的指针记录下来，如果它不是链表头的话，记录这个内存块的起始地址p，如果前一个内存块的尾地址刚好是base的首地址，那么就将base合并到前一个内存块，具体做法是将前一个内存块的页数加上base的页数，消除base的头页身份，紧接着将base从链表中摘出来，也就是类似于default_alloc_pages中的操作，切断base->page_link的两个指针并将前后两个内存块连接起来。随后将当前块起始地址base赋值为p。

最后是向后合并的代码，与向前合并原理基本一致，除了最后base不变以外基本没区别，这里不再赘述。

总的来说，这个函数实现了将已分配内存块重新回收到空闲内存块链表中，并将它与前后内存地址连续的块实现合并。

** basic_check **

```cpp
static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}
```

这个函数主要进行一些电脑基本功能的检查，通过三个Page样例进行检测：
1.分配功能检查：单页分配（alloc_page）是否有效，连续分配能否成功，返回指针是否为空。
2.页面唯一性检查：确保被分配的Page不是同一个。
3.初始状态检查：确保分配的Page引用计数ref都是零。
4.地址检查：确保返回的地址在合理范围内。
5.链表状态重置：保存当前链表状态，设置链表为空并设置计数器为0。
6.释放功能检查：释放三个样例并检查计数器是否正常工作。
7.重分配检查：为三个样例重新分配，分配所有空闲页面后，再次分配应该失败。
8.部分释放检查：部分释放后链表是否非空，重新分配是否返回最近释放的页面，验证分配器能否正常工作。
9.状态恢复：将链表恢复到原来的状态并释放三个样例。

** default_check **

```cpp
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}
```

这个函数主要验证的是first-fit算法的一些复杂功能：
1.确保每个块头页都有PG_property标志，验证空闲页数是否与计数器吻合。
2.进行basic_check验证。
3.验证分配多个页时的功能并检查是否有PG_property标志。
4.保存链表状态并重置链表为空。
5.释放p0块的后三页回到空链表并试图在链表中分配出4页，检查p0的状态，将这三页重新分配成p1，验证地址是否连续。
6.验证两个不连续的块无法合并（被p1隔开）。
7.验证单页分配并检查地址。
8.所有页释放后应该成功合并。
9.链表状态还原。

** pmm_manager **
```cpp
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};
```
这个结构体用于内存管理相关的功能，其中包含了多个函数指针和一个字符串成员。方便后续的调用和调整。

** 程序在进行物理内存分配的过程以及各个函数的作用 **

- default_init：初始化链表为空，计数器置零。
- default_init_memmap：将一个空闲内存块按地址链入到链表中，分为n页。
- default_alloc_pages：first-fit算法的具体实现。
- default_free_pages：释放内存块并将地址相邻的内存块合并。
- basic_check：内存分配基本功能检查。
- default_check：内存分配复杂功能检查。
- pmm_manager：封装结构体，方便调用和管理。

** 你的first-fit算法是否有进一步的改进空间 **

1.算法按照地址组织内存块，可能在低地址处产生大量小碎片，可以向堆表一样按照大小组织内存块，减少碎片，加快运算速度。
2.设置与请求大小对应的阈值，只有大于阈值时才分割内存块，否则直接分配整块，可以减少碎片。
3.考虑局部性原理，将刚刚释放的内存块载入缓存，不立刻链入链表，在下一次请求到来时先考虑刚刚释放的内存块。
4.根据以往的内存调用经验进行预分配。

** first-fit运行结果 **
```
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc02000d8 (virtual)
  etext  0xffffffffc020172c (virtual)
  edata  0xffffffffc0206018 (virtual)
  end    0xffffffffc0206078 (virtual)
Kernel executable memory footprint: 24KB
memory management: default_pmm_manager
physcial memory map:
  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0205000
satp physical address: 0x0000000080205000
```

内核启动程序init.c:

```cpp
void print_kerninfo(void) {
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
    cprintf("  etext  0x%016lx (virtual)\n", etext);
    cprintf("  edata  0x%016lx (virtual)\n", edata);
    cprintf("  end    0x%016lx (virtual)\n", end);
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
}

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    dtb_init();
    cons_init();  // init the console
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);

    print_kerninfo();

    // grade_backtrace();
    pmm_init();  // init physical memory management

    /* do nothing */
    while (1)
        ;
}
```

在这个程序运行结果中，entry是程序入口地址，etext是代码段结尾，edata是数据段结尾，end是.bss段结尾，内核可执行文件的内存占用大小为24KB（向上取整）。0x0000000008000000是内核可支配物理内存的大小，地址从0x0000000008000000到0x0000000087ffffff总共128MB 。在执行pmm_init函数时，先执行.init，实现链表初始化，再执行page_init将内存块载入到链表中，再执行check_alloc_page检查功能是否完好。

### 练习2：实现 Best-Fit 连续物理内存分配算法

** 实现原理 **

Best-Fit算法是一种内存分配策略，其核心思想是在所有空闲内存块中找到与请求大小最接近的块进行分配，以尽量减少内存碎片，但是运算时间较长。

** 实现步骤 **

本实验只需要更改best_fit_alloc_pages函数即可，其他函数都可以复用first-fit的。

```cpp
/*LAB2 EXERCISE 2: YOUR CODE*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    // Best-Fit 核心：遍历所有空闲块，找到最合适的大小
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if(p->property >= n && p->property < min_size){
            page = p;
            min_size = p->property;
        }
    }
```

这个代码块很好理解，如果le指向的内存块大小足够且页数小于之前记录的页数最小值min_size，就将这个块的位置记录下来，等待下一步分割。min_size初始化为nr_free+1。

在这之后，将pmm.c中的init_pmm_manager中的pmm_manager初始化为best_fit_pmm_manager，即可进行编译和测试。

** 实验结果 **

程序编译结果如下：
```
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc02000d8 (virtual)
  etext  0xffffffffc0201660 (virtual)
  edata  0xffffffffc0205018 (virtual)
  end    0xffffffffc0205078 (virtual)
Kernel executable memory footprint: 20KB
memory management: best_fit_pmm_manager
physcial memory map:
  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0204000
satp physical address: 0x0000000080204000

```
make grade 测试结果如下：
```
zoujiaheng@zoujiaheng-virtual-machine:~/桌面/labcode/labcode/lab2$ make grade
>>>>>>>>>> here_make>>>>>>>>>>>
make[1]: 进入目录“/home/zoujiaheng/桌面/labcode/labcode/lab2” + cc kern/init/entry.S + cc kern/init/init.c + cc kern/libs/stdio.c + cc kern/debug/panic.c + cc kern/driver/dtb.c + cc kern/driver/console.c + cc kern/mm/pmm.c + cc kern/mm/default_pmm.c + cc kern/mm/best_fit_pmm.c + cc libs/string.c + cc libs/printfmt.c + cc libs/sbi.c + cc libs/readline.c + ld bin/kernel riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img make[1]: 离开目录“/home/zoujiaheng/桌面/labcode/labcode/lab2”
>>>>>>>>>> here_make>>>>>>>>>>>
<<<<<<<<<<<<<<< here_run_qemu <<<<<<<<<<<<<<<<<<
try to run qemu
qemu pid=7361
<<<<<<<<<<<<<<< here_run_check <<<<<<<<<<<<<<<<<<
  -check physical_memory_map_information:    OK
  -check_best_fit:                           OK
Total Score: 25/25
```
证明我们成功实现了best-fit算法。

** 你的 Best-Fit 算法是否有进一步的改进空间 **

由于我们只更改了best_fit_alloc_pages，所以一些原先first-fit算法存在的问题我们这里也有，比如还是没有解决算法需要遍历整个链表的问题，合并时可以考虑前中后三个块被合并。

### 扩展练习Challenge：buddy system（伙伴系统）分配算法

** 实现原理 ** 

Buddy System（伙伴系统）是一种内存分配算法，它将内存划分为多个块，每个块的大小为2的幂次方。当请求分配内存时，系统会找到一个大小合适的块（即大于或等于请求大小的最小2的幂次方块）。如果找不到正好大小的块，就将一个较大的块分裂成两个相等的部分（这两个部分互为伙伴），直到得到合适大小的块。

** 实现过程 **

首先，在前面的测试中，我们已经知道，这个ucore的最大物理内存的大小是128MB，按照一个页4KB的大小算，一共需要32768页，最大阶数为15（2^15=32768），因此，我们需要16个链表来存储这些内存块。

```cpp
typedef struct {
	unsigned int max_order;
	list_entry_t free_array[16];
	unsigned int nr_free;
} buddy_system_t;
```
在这个结构体的基础上，我进行了编程和调试，但最后qemu运行没能成功，失败的代码放在文件夹里了，这里不再赘述。

### 扩展练习Challenge：硬件的可用物理内存范围的获取方法

1.通过BIOS中断调用，适用于传统的x86结构，BIOS在启动阶段会初始化硬件，并构建一个系统信息表。OS引导程序（如 Bootloader）可以通过调用特定的软件中断（int 指令）来查询这些信息。
2.可以通过配置DMA控制器，指定内存地址和数据长度，让DMA执行内存操作。若数据传输失败，则该内存地址可能无效或不存在。