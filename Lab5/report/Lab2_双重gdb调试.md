# 双重gdb调试

## Exercise 1

**1**

make debug

**3**
```
(gdb) hbreak *0x80200000
Hardware assisted breakpoint 2 at 0x80200000
(gdb) c
Continuing.
```
**2**
```
pgrep -f qemu-system-riscv64
# 记下数字，比如 12345

# 启动 GDB 附加
sudo gdb
```
```
attach 12345
handle SIGPIPE nostop noprint
b riscv_cpu_tlb_fill
c
```
### 第一步：在终端2中找到访存指令

```
# 终端2现在应该停在 0x80200000
(gdb) si          # 单步执行第一条指令
(gdb) si          # 再执行一条

# 查找访存指令（load/store）
(gdb) x/20i $pc   # 查看后续20条指令

# 找到类似这样的指令：
# sd a0, 0(t0)    # 存储指令
# ld a1, 8(sp)    # 加载指令

# 记下访存指令的地址，比如：0x80200008
```
```
(gdb) x/20i $pc
=> 0x80200008:	sd	a0,0(t0)
   0x8020000c:	auipc	t0,0xb
   0x80200010:	addi	t0,t0,-4
   0x80200014:	sd	a1,0(t0)
   0x80200018:	lui	t0,0xc020a
   0x8020001c:	addiw	t1,zero,-3
   0x80200020:	slli	t1,t1,0x1e
   0x80200022:	sub	t0,t0,t1
   0x80200026:	srli	t0,t0,0xc
   0x8020002a:	addiw	t1,zero,-1
   0x8020002e:	slli	t1,t1,0x3f
   0x80200030:	or	t0,t0,t1
   0x80200034:	csrw	satp,t0
   0x80200038:	sfence.vma
   0x8020003c:	lui	sp,0xc020a
   0x80200040:	lui	t0,0xc0200
   0x80200044:	addi	t0,t0,74
   0x80200048:	jr	t0
   0x8020004a:	auipc	a0,0xa6
   0x8020004e:	addi	a0,a0,710
```
现在你停在了 0x80200008，这是一条访存指令：sd a0, 0(t0)（存储指令）。

这意味着：

你要把寄存器 a0 的值存储到地址 t0 指向的内存位置

这会触发 QEMU 的地址翻译过程,执行后，你应该会看到终端3（QEMU GDB）触发断点，因为 sd a0, 0(t0) 会调用 QEMU 的地址翻译函数。

### 第二步：终端二触发端点，开始调试地址翻译过程
查看当前状态
```
# 查看参数值
(gdb) p/x address
# 这会显示虚拟地址，应该是 0x8020a000 或类似值

(gdb) p access_type
# 应该是 MMU_DATA_STORE (存储操作)

(gdb) p size
# 应该是 8 (sd指令是64位存储)
```
查看栈调用
```
(gdb) bt
```
```
(gdb) p/x address
$1 = 0x8020b000
(gdb) p access_type
$2 = MMU_DATA_STORE
(gdb) p size
$3 = 8
(gdb) bt
#0  riscv_cpu_tlb_fill (cs=0x556af9b394f0, address=2149625856, size=8, 
    access_type=MMU_DATA_STORE, mmu_idx=1, probe=false, 
    retaddr=139871513350466)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/target/riscv/cpu_helper.c:438
#1  0x0000556af7649ec0 in tlb_fill (cpu=0x556af9b394f0, addr=2149625856, 
    size=8, access_type=MMU_DATA_STORE, mmu_idx=1, retaddr=139871513350466)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/accel/tcg/cputlb.c:878
#2  0x0000556af76501d5 in store_helper (big_endian=false, size=8, 
    retaddr=139871513350466, oi=49, val=0, addr=2149625856, env=0x556af9b41f00)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/accel/tcg/cputlb.c:1522
#3  helper_le_stq_mmu (env=0x556af9b41f00, addr=2149625856, val=0, oi=49, 
    retaddr=139871513350466)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/accel/tcg/cputlb.c:1672
#4  0x00007f365fde1142 in code_gen_buffer ()
#5  0x0000556af766e269 in cpu_tb_exec (cpu=0x556af9b394f0, 
    itb=0x7f365fde1040 <code_gen_buffer+19>)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/accel/tcg/cpu-exec.c:173
#6  0x0000556af766f05a in cpu_loop_exec_tb (cpu=0x556af9b394f0, 
    tb=0x7f365fde1040 <code_gen_buffer+19>, last_tb=0x7f365fddf9b8, 
    tb_exit=0x7f365fddf9b0)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/accel/tcg/cpu-exec.c:621
#7  0x0000556af766f368 in cpu_exec (cpu=0x556af9b394f0)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/accel/tcg/cpu-exec.c:732
---Type <return> to continue, or q <return> to quit---
#8  0x0000556af76234fd in tcg_cpu_exec (cpu=0x556af9b394f0)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/cpus.c:1435
#9  0x0000556af7623d53 in qemu_tcg_cpu_thread_fn (arg=0x556af9b394f0)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/cpus.c:1743
#10 0x0000556af7a85578 in qemu_thread_start (args=0x556af9b4fbd0)
    at util/qemu-thread-posix.c:502
#11 0x00007f3662c4b6db in start_thread (arg=0x7f365fde0700)
    at pthread_create.c:463
#12 0x00007f366297461f in clone ()
    at ../sysdeps/unix/sysv/linux/x86_64/clone.S:95

```
完整的调用栈过程：

helper_le_stq_mmu() → store_helper() → tlb_fill() → riscv_cpu_tlb_fill()

```
# 页表基址
(gdb) p/x ((RISCVCPU *)cs)->env.satp
$4 = 0x0
```
点n单步执行找ret
```
(gdb) n
440	    RISCVCPU *cpu = RISCV_CPU(cs);
(gdb) n
441	    CPURISCVState *env = &cpu->env;
(gdb) n
442	    hwaddr pa = 0;
(gdb) n
444	    bool pmp_violation = false;
(gdb) n
445	    int ret = TRANSLATE_FAIL;
(gdb) n
446	    int mode = mmu_idx;
(gdb) n
448	    qemu_log_mask(CPU_LOG_MMU, "%s ad %" VADDR_PRIx " rw %d mmu_idx %d\n",
(gdb) n
451	    ret = get_physical_address(env, &pa, &prot, address, access_type, mmu_idx);
```
现在执行到了关键位置：第451行，准备调用 get_physical_address 函数进行地址翻译。

点s单步进入get_physical_address，进入后，先查看参数：

```
(gdb) p/x addr
$5 = 0x8020b000
(gdb) p/x env->satp
$6 = 0x0
```

env->satp = 0x0 这意味着：

satp 寄存器为0：页表机制还没启用或者还在实模式

虚拟地址 0x8020b000 将直接被当作物理地址使用

不会进行页表翻译

继续点n单步，观察 get_physical_address 函数如何处理 satp=0 的情况。

```
(gdb) n
163	    int mode = mmu_idx;
(gdb) n
165	    if (mode == PRV_M && access_type != MMU_INST_FETCH) {
(gdb) n
171	    if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
(gdb) n
177	    *prot = 0;
(gdb) n
181	    int mxr = get_field(env->mstatus, MSTATUS_MXR);
(gdb) n
183	    if (env->priv_ver >= PRIV_VERSION_1_10_0) {
(gdb) n
184	        base = get_field(env->satp, SATP_PPN) << PGSHIFT;
(gdb) n
185	        sum = get_field(env->mstatus, MSTATUS_SUM);
(gdb) n
186	        vm = get_field(env->satp, SATP_MODE);
(gdb) n
187	        switch (vm) {
(gdb) n
197	            *physical = addr;
(gdb) n
198	            *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
(gdb) n
199	            return TRANSLATE_SUCCESS;
(gdb) n
353	}
```
**观察到的流程：**

检查 satp：env->satp = 0x0

获取模式：vm = get_field(env->satp, SATP_MODE) = 0

进入 switch 语句：case 0:（无分页模式）

直接映射：*physical = addr（虚拟地址直接作为物理地址）

设置权限：*prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC

返回成功：return TRANSLATE_SUCCESS

关键代码在switch这里：
```
switch (vm) {
    case 0:  // 无分页模式
        *physical = addr;
        *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
        return TRANSLATE_SUCCESS;
    case 8:  // SV39 模式
        // 这里会有三级页表遍历
        // ...
    default:
        // 其他模式
}
```
因为 satp=0，所以进入 case 0:，直接返回虚拟地址作为物理地址。

### 回答问题：

1. 关键调用路径
   1. helper_le_stq_mmu()     # 64位小端存储模拟
   2. store_helper()          # 存储辅助函数
   3. tlb_fill()              # TLB填充入口 (cputlb.c:878)
   4. riscv_cpu_tlb_fill()    # RISC-V实现 (cpu_helper.c:438)
   5. get_physical_address()  # 物理地址获取 (cpu_helper.c:155)
2. 关键分支语句（在 get_physical_address 中）
```
vm = get_field(env->satp, SATP_MODE);  // 获取分页模式
switch (vm) {
    case 0:  // Bare 模式，无分页
        *physical = addr;  // 直接映射：虚拟地址=物理地址
        *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
        return TRANSLATE_SUCCESS;
        
    case 8:  // SV39 模式
        // 这里会有三级页表遍历代码
        // 包括：PTE_V检查、权限检查、叶子节点判断等
        // ...
        
    default:
        // 不支持的MMU模式
        return TRANSLATE_FAIL;
}
```
3. 地址翻译演示，当前情况（satp=0）：
```
虚拟地址: 0x8020b000
satp: 0x0 (MODE=0, Bare模式)
处理流程：
  1. 检查 satp.mode == 0
  2. 进入 case 0 分支
  3. 直接设置 physical = 0x8020b000
  4. 设置全权限（可读、可写、可执行）
  5. 返回成功
物理地址: 0x8020b000
```
## Exercise 2

**1**

make debug

**3**

make gdb

b *0x80200000

c

**2**

sudo gdb

### 设置断点

在QEMU GDB:
```
attach <PID>
handle SIGPIPE nostop noprint

# 设置页表翻译断点
b get_physical_address
c
```

### 进入QEMU GDB

在终端三中输入x/5i $pc,会进入get_physical_address

```
(gdb) p/x addr
$1 = 0x80200000
(gdb) p/x env->satp
$2 = 0x0
(gdb) list 158 180
malformed linespec error: unexpected number, "180"
(gdb) list l58,180
Function "l58" not defined.
(gdb) list 158,180
158	{
159	    /* NOTE: the env->pc value visible here will not be
160	     * correct, but the value visible to the exception handler
161	     * (riscv_cpu_do_interrupt) is correct */
162	
163	    int mode = mmu_idx;
164	
165	    if (mode == PRV_M && access_type != MMU_INST_FETCH) {
166	        if (get_field(env->mstatus, MSTATUS_MPRV)) {
167	            mode = get_field(env->mstatus, MSTATUS_MPP);
168	        }
169	    }
170	
171	    if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
172	        *physical = addr;
173	        *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
174	        return TRANSLATE_SUCCESS;
175	    }
176	
177	    *prot = 0;
178	
179	    target_ulong base;
180	    int levels, ptidxbits, ptesize, vm, sum;
```
satp = 0,这里不是进行分页的地方

### 快速定位 satp 设置代码

```
grep -n "satp" kern/init/entry.S
```

分页开启的关键指令：
```
# 行号：设置 satp 寄存器
csrw    satp, t0           # 开启SV39分页
sfence.vma                # 刷新TLB

# 行号：设置栈指针（开启分页后）
lui sp, %hi(bootstacktop) # 使用虚拟地址

# 行号：跳转到 kern_init（虚拟地址）
lui t0, %hi(kern_init)
addi t0, t0, %lo(kern_init)
jr t0
```
```
(gdb) x/30i 0x80200000
=> 0x80200000:	auipc	t0,0xb
   0x80200004:	mv	t0,t0
   0x80200008:	sd	a0,0(t0)
   0x8020000c:	auipc	t0,0xb
   0x80200010:	addi	t0,t0,-4
   0x80200014:	sd	a1,0(t0)
   0x80200018:	lui	t0,0xc020a
   0x8020001c:	addiw	t1,zero,-3
   0x80200020:	slli	t1,t1,0x1e
   0x80200022:	sub	t0,t0,t1
   0x80200026:	srli	t0,t0,0xc
   0x8020002a:	addiw	t1,zero,-1
   0x8020002e:	slli	t1,t1,0x3f
   0x80200030:	or	t0,t0,t1
   0x80200034:	csrw	satp,t0
   0x80200038:	sfence.vma
   0x8020003c:	lui	sp,0xc020a
```
现在有了精确地址：

csrw satp, t0：0x80200034 ← 开启分页

sfence.vma：0x80200038 ← 刷新TLB

lui sp, 0xc020a：0x8020003c ← 开启分页后的第一条指令（使用虚拟地址）

```
(gdb) delete
(gdb) b *0x80200034
Breakpoint 1 at 0x80200034
(gdb) c
Continuing.

Breakpoint 1, 0x0000000080200034 in ?? ()
```
现在停在了 csrw satp, t0 指令前（0x80200034）。下一步就是开启分页。

```
(gdb) break get_physical_address
Breakpoint 1 at 0x55ed1969dafe: file /home/zoujiaheng/opt/qemu/qemu-4.1.1/target/riscv/cpu_helper.c, line 158.
(gdb) c
Continuing.

Thread 1 "qemu-system-ris" hit Breakpoint 1, get_physical_address (
    env=0x55ed1b75bf00, physical=0x7fff3178e818, prot=0x7fff3178e810, 
    addr=2149580800, access_type=0, mmu_idx=1)
    at /home/zoujiaheng/opt/qemu/qemu-4.1.1/target/riscv/cpu_helper.c:158
158	{
(gdb) p/x env->satp
$1 = 0x800000000008020a
```
satp = 0x800000000008020a
二进制分析：
  最高4位 (MODE): 1000 = 8 (SV39模式！)
  中间44位 (PPN): 0x8020a (物理页号)
  最低12位: 0x20a

```
(gdb) list 158,200
158	{
159	    /* NOTE: the env->pc value visible here will not be
160	     * correct, but the value visible to the exception handler
161	     * (riscv_cpu_do_interrupt) is correct */
162	
163	    int mode = mmu_idx;
164	
165	    if (mode == PRV_M && access_type != MMU_INST_FETCH) {
166	        if (get_field(env->mstatus, MSTATUS_MPRV)) {
167	            mode = get_field(env->mstatus, MSTATUS_MPP);
168	        }
169	    }
170	
171	    if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
172	        *physical = addr;
173	        *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
174	        return TRANSLATE_SUCCESS;
175	    }
176	
177	    *prot = 0;
178	
179	    target_ulong base;
180	    int levels, ptidxbits, ptesize, vm, sum;
---Type <return> to continue, or q <return> to quit---
181	    int mxr = get_field(env->mstatus, MSTATUS_MXR);
182	
183	    if (env->priv_ver >= PRIV_VERSION_1_10_0) {
184	        base = get_field(env->satp, SATP_PPN) << PGSHIFT;
185	        sum = get_field(env->mstatus, MSTATUS_SUM);
186	        vm = get_field(env->satp, SATP_MODE);
187	        switch (vm) {
188	        case VM_1_10_SV32:
189	          levels = 2; ptidxbits = 10; ptesize = 4; break;
190	        case VM_1_10_SV39:
191	          levels = 3; ptidxbits = 9; ptesize = 8; break;
192	        case VM_1_10_SV48:
193	          levels = 4; ptidxbits = 9; ptesize = 8; break;
194	        case VM_1_10_SV57:
195	          levels = 5; ptidxbits = 9; ptesize = 8; break;
196	        case VM_1_10_MBARE:
197	            *physical = addr;
198	            *prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
199	            return TRANSLATE_SUCCESS;
200	        default:
```
点n执行到switch(vm):
```
(gdb) n
163	    int mode = mmu_idx;
(gdb) n
165	    if (mode == PRV_M && access_type != MMU_INST_FETCH) {
(gdb) n
171	    if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
(gdb) n
177	    *prot = 0;
(gdb) n
181	    int mxr = get_field(env->mstatus, MSTATUS_MXR);
(gdb) n
183	    if (env->priv_ver >= PRIV_VERSION_1_10_0) {
(gdb) n
184	        base = get_field(env->satp, SATP_PPN) << PGSHIFT;
(gdb) n
185	        sum = get_field(env->mstatus, MSTATUS_SUM);
(gdb) n
186	        vm = get_field(env->satp, SATP_MODE);
(gdb) n
187	        switch (vm) {
(gdb) n
191	          levels = 3; ptidxbits = 9; ptesize = 8; break;
(gdb) 
```
行号191：设置了SV39参数：

levels = 3（三级页表）

ptidxbits = 9（每级9位索引）

ptesize = 8（PTE大小8字节)

```
(gdb) n
237	    for (i = 0; i < levels; i++, ptshift -= ptidxbits) {
(gdb) n
238	        target_ulong idx = (addr >> (PGSHIFT + ptshift)) &
(gdb) n
239	                           ((1 << ptidxbits) - 1);
(gdb) n
238	        target_ulong idx = (addr >> (PGSHIFT + ptshift)) &
(gdb) n
242	        target_ulong pte_addr = base + idx * ptesize;
(gdb) n
244	        if (riscv_feature(env, RISCV_FEATURE_PMP) &&
```
现在我们进入了页表遍历循环！
```
(gdb) p/x &boot_page_table_sv39
$1 = 0xffffffffc020a000
(gdb) x/10gx &boot_page_table_sv39
0xffffffffc020a000:	0x0000000000000000	0x0000000000000000
0xffffffffc020a010:	0x0000000000000000	0x0000000000000000
0xffffffffc020a020:	0x0000000000000000	0x0000000000000000
0xffffffffc020a030:	0x0000000000000000	0x0000000000000000
0xffffffffc020a040:	0x0000000000000000	0x0000000000000000
(gdb) x/gx &boot_page_table_sv39 + 511*8
Cannot perform pointer math on incomplete type "<data variable, no debug info>", try casting to a known type, or void *.
(gdb) x/20gx &boot_page_table_sv39 + 500*8 
Cannot perform pointer math on incomplete type "<data variable, no debug info>", try casting to a known type, or void *.
(gdb) x/10gx &boot_page_table_sv39 + 0xfe0  # 511*8 = 0xfe0
Invalid character '#' in expression.
(gdb) p/x (unsigned long long)&boot_page_table_sv39 + 0xfe0
$2 = 0xffffffffc020afe0
(gdb) x/gx 0xffffffffc020afe0
0xffffffffc020afe0:	0x0000000000000000
```
页表最后一项也是0，说明整个页表完全没有被初始化。

SV39模式下页表翻译的完整流程：

触发条件,执行访存指令（如 sd a0, 0(t0)）

satp.mode = 8（SV39模式启用）

调用栈

```
helper_le_stq_mmu()     # 访存模拟
  → store_helper()      # 存储辅助
    → tlb_fill()        # TLB填充
      → riscv_cpu_tlb_fill()  # RISC-V实现
        → get_physical_address()  # 物理地址获取（核心翻译函数）
```

执行流程:
```
(gdb) n
163	    int mode = mmu_idx;
(gdb) n
165	    if (mode == PRV_M && access_type != MMU_INST_FETCH) {
(gdb) n
171	    if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
(gdb) n
177	    *prot = 0;
(gdb) n
181	    int mxr = get_field(env->mstatus, MSTATUS_MXR);
(gdb) n
183	    if (env->priv_ver >= PRIV_VERSION_1_10_0) {
(gdb) n
184	        base = get_field(env->satp, SATP_PPN) << PGSHIFT;
(gdb) n
185	        sum = get_field(env->mstatus, MSTATUS_SUM);
(gdb) n
186	        vm = get_field(env->satp, SATP_MODE);
(gdb) n
187	        switch (vm) {
(gdb) n
191	          levels = 3; ptidxbits = 9; ptesize = 8; break;
(gdb) n
223	    CPUState *cs = env_cpu(env);
(gdb) n
224	    int va_bits = PGSHIFT + levels * ptidxbits;
(gdb) n
225	    target_ulong mask = (1L << (TARGET_LONG_BITS - (va_bits - 1))) - 1;
(gdb) n
226	    target_ulong masked_msbs = (addr >> (va_bits - 1)) & mask;
(gdb) n
227	    if (masked_msbs != 0 && masked_msbs != mask) {
(gdb) n
231	    int ptshift = (levels - 1) * ptidxbits;
(gdb) n
237	    for (i = 0; i < levels; i++, ptshift -= ptidxbits) {
(gdb) n
238	        target_ulong idx = (addr >> (PGSHIFT + ptshift)) &
(gdb) n
239	                           ((1 << ptidxbits) - 1);
(gdb) n
238	        target_ulong idx = (addr >> (PGSHIFT + ptshift)) &
(gdb) n
242	        target_ulong pte_addr = base + idx * ptesize;
(gdb) n
244	        if (riscv_feature(env, RISCV_FEATURE_PMP) &&
```
```
int mode = mmu_idx;                      // 获取MMU模式
if (mode == PRV_M && access_type != MMU_INST_FETCH) {
    // 特殊权限处理
}
if (mode == PRV_M || !riscv_feature(env, RISCV_FEATURE_MMU)) {
    // 直接模式处理（Bare模式）
    *physical = addr;
    return TRANSLATE_SUCCESS;
}
*prot = 0;  // 初始化权限
```
```
base = get_field(env->satp, SATP_PPN) << PGSHIFT;  // 获取页表基址
vm = get_field(env->satp, SATP_MODE);              // 获取分页模式
switch (vm) {
case VM_1_10_SV39:  // case 8:
    levels = 3;      // 三级页表
    ptidxbits = 9;   // 每级9位索引
    ptesize = 8;     // PTE大小8字节
    break;
// ... 其他模式
}
```
核心循环
```
for (i = 0; i < levels; i++, ptshift -= ptidxbits) {
    // 1. 计算VPN索引
    idx = (addr >> (PGSHIFT + ptshift)) & ((1 << ptidxbits) - 1);
    
    // 2. 计算PTE地址
    pte_addr = base + idx * ptesize;
    
    // 3. 读取PTE（64位系统用ldq_phys）
    pte = ldq_phys(cs->as, pte_addr);
    
    // 4. 提取PPN
    ppn = pte >> PTE_PPN_SHIFT;
    
    // 5. 检查PTE有效性
    if (!(pte & PTE_V)) {
        return TRANSLATE_FAIL;  // 无效PTE
    } 
    // 6. 检查是否是内部PTE（非叶子节点）
    else if (!(pte & (PTE_R | PTE_W | PTE_X))) {
        // 内部PTE，继续遍历下一级
        base = ppn << PGSHIFT;  // 更新基址
        continue;
    }
    // 7. 叶子节点：进行各种检查...
}
```