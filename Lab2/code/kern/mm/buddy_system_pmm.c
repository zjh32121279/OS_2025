#include <pmm.h>
#include <list.h>
#include <string.h>
#include <assert.h>

// Buddy System 内存管理器结构体
typedef struct {
    unsigned int max_order;       // 代表最大页数的2的幂次
    list_entry_t free_array[16];  // 串联不同幂次大小的内存块 (0-15阶)
    unsigned int nr_free;         // 空闲页总数
} buddy_system_t;

// 全局buddy system实例
static buddy_system_t buddy_system;

// 计算给定大小n的最小2的幂上界对应的阶数
static inline int
get_order(size_t size)
{
    int order = 0;
    size_t n = size - 1;
    // 计算n的二进制中1的最高位位置
    while (n > 0) {
        order++;
        n >>= 1;
    }
    // 确保order不超过最大阶数
    return (order > buddy_system.max_order) ? buddy_system.max_order : order;
}

// 计算buddy块的索引
static inline struct Page *
get_buddy(struct Page *page, int order)
{
    uintptr_t pa = page2pa(page);
    size_t block_size = (1 << order) * PGSIZE;  // 块大小（字节）
    
    // 通过异或运算找到buddy块的物理地址
    // 如果当前块是偶数块，buddy是下一个块；如果是奇数块，buddy是前一个块
    uintptr_t buddy_pa = pa ^ block_size;
    
    return pa2page(buddy_pa);
}

// 判断页是否在有效范围内
static inline bool
is_page_valid(struct Page *page)
{
    return page >= pages && page < pages + npage;
}

// 初始化buddy system
static void
buddy_init(void)
{
    // 最大阶数为15，因为2^15 = 32768页，对应128MB内存
    buddy_system.max_order = 15;
    buddy_system.nr_free = 0;
    
    // 初始化所有空闲链表
    for (int i = 0; i <= buddy_system.max_order; i++) {
        list_init(&buddy_system.free_array[i]);
    }
}

static void
buddy_init_memmap(struct Page *base, size_t n)
{
    assert(n > 0);
    
    // 完全非递归实现
    size_t remaining = n;
    struct Page *current = base;
    
    while (remaining > 0) {
        size_t order = 0;
        size_t max_block = 1;
        
        // 找到适合的最大块
        while (order < buddy_system.max_order && 
               (max_block << 1) <= remaining) {
            order++;
            max_block <<= 1;
        }
        
        // 初始化这个块
        for (size_t i = 0; i < max_block; i++) {
            struct Page *p = current + i;
            p->flags = 0;           // 清除所有标志
            set_page_ref(p, 0);     // 引用计数为0
        }
        
        // 设置块头
        current->property = order;
        SetPageProperty(current);
        list_add(&buddy_system.free_array[order], &(current->page_link));
        buddy_system.nr_free += max_block;
        
        current += max_block;
        remaining -= max_block;
    }
}

// 分配内存页
static struct Page *
buddy_alloc_pages(size_t n)
{
    assert(n > 0);
    
    // 检查是否有足够的空闲页
    if (n > buddy_system.nr_free) {
        return NULL;
    }
    
    // 计算需要的最小阶数
    int order = get_order(n);
    
    // 从所需阶数开始查找可用块
    int current_order = order;
    while (current_order <= buddy_system.max_order) {
        if (!list_empty(&buddy_system.free_array[current_order])) {
            // 找到合适的块，从链表中取出
            list_entry_t *le = list_next(&buddy_system.free_array[current_order]);
            struct Page *page = le2page(le, page_link);
            list_del(le);
            
            // 更新空闲页计数
            buddy_system.nr_free -= (1 << current_order);
            
            // 如果当前阶数大于所需阶数，需要拆分块
            while (current_order > order) {
                current_order--;
                size_t half_size = 1 << current_order;
                
                // 创建buddy块
                struct Page *buddy = page + half_size;
                buddy->property = current_order;
                SetPageProperty(buddy);
                ClearPageReserved(buddy);  // 确保buddy不是保留页面
                
                // 将buddy块加入下一级空闲链表
                list_add(&buddy_system.free_array[current_order], &(buddy->page_link));
                buddy_system.nr_free += half_size;
            }
            
            // 标记分配的块 - 正确设置页面状态
            ClearPageProperty(page);
            ClearPageReserved(page);  // 确保页面不是保留状态
            set_page_ref(page, 1);    // 设置引用计数
            
            return page;
        }
        current_order++;
    }
    
    return NULL;
}

// 释放内存页
static void
buddy_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);
    
    // 初始化要释放的页
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    
    // 计算释放块的阶数
    int order = get_order(n);
    
    // 设置块属性
    base->property = order;
    SetPageProperty(base);
    
    // 将块加入对应阶数的空闲链表
    list_add(&buddy_system.free_array[order], &(base->page_link));
    buddy_system.nr_free += (1 << order);
    
    // 尝试合并buddy块
    struct Page *current = base;
    while (order < buddy_system.max_order) {
        struct Page *buddy = get_buddy(current, order);
        
        // 检查buddy块是否有效且空闲
        if (!is_page_valid(buddy) || !PageProperty(buddy)) {
            break;
        }
        
        // 检查buddy块是否与current块大小相同
        if (buddy->property != order) {
            break;
        }
        
        // 从当前阶数的链表中移除两个块
        list_del(&(current->page_link));
        list_del(&(buddy->page_link));
        buddy_system.nr_free -= 2 * (1 << order);
        
        // 确定合并后的块的起始地址
        if (buddy < current) {
            current = buddy;
        }
        
        // 增加阶数，准备合并为更大的块
        order++;
        current->property = order;
        SetPageProperty(current);
        
        // 将合并后的块加入更高阶数的空闲链表
        list_add(&buddy_system.free_array[order], &(current->page_link));
        buddy_system.nr_free += (1 << order);
    }
}

// 获取空闲页数量
static size_t
buddy_nr_free_pages(void)
{
    return buddy_system.nr_free;
}

// 检查buddy system的正确性
static void
buddy_check(void)
{
    // 验证空闲页数量是否正确
    size_t total_free = 0;
    for (int i = 0; i <= buddy_system.max_order; i++) {
        int count = 0;
        list_entry_t *le = &buddy_system.free_array[i];
        while ((le = list_next(le)) != &buddy_system.free_array[i]) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            assert(p->property == i);  // 确保块的阶数正确
            count++;
        }
        total_free += count * (1 << i);
    }
    assert(total_free == buddy_system.nr_free);
    
    // 基本功能测试
    struct Page *p0, *p1, *p2, *p3;
    p0 = p1 = p2 = p3 = NULL;
    
    // 测试分配
    assert((p0 = buddy_alloc_pages(1)) != NULL);
    assert((p1 = buddy_alloc_pages(1)) != NULL);
    assert((p2 = buddy_alloc_pages(2)) != NULL);
    assert((p3 = buddy_alloc_pages(4)) != NULL);
    
    // 测试释放和合并
    buddy_free_pages(p0, 1);
    buddy_free_pages(p1, 1);
    // p0和p1应该被合并为一个2页的块
    
    // 测试再次分配
    struct Page *p_merged = buddy_alloc_pages(2);
    assert(p_merged != NULL);
    
    // 释放所有块
    buddy_free_pages(p_merged, 2);
    buddy_free_pages(p2, 2);
    buddy_free_pages(p3, 4);
}

// 注册buddy system内存管理器
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};