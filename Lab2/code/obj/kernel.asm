
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	61450513          	addi	a0,a0,1556 # ffffffffc0201660 <etext>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	61e50513          	addi	a0,a0,1566 # ffffffffc0201680 <etext+0x20>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	5f258593          	addi	a1,a1,1522 # ffffffffc0201660 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	62a50513          	addi	a0,a0,1578 # ffffffffc02016a0 <etext+0x40>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	63650513          	addi	a0,a0,1590 # ffffffffc02016c0 <etext+0x60>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	64250513          	addi	a0,a0,1602 # ffffffffc02016e0 <etext+0x80>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005597          	auipc	a1,0x5
ffffffffc02000ae:	3cd58593          	addi	a1,a1,973 # ffffffffc0205477 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	63450513          	addi	a0,a0,1588 # ffffffffc0201700 <etext+0xa0>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00005517          	auipc	a0,0x5
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0205018 <free_area>
ffffffffc02000e0:	00005617          	auipc	a2,0x5
ffffffffc02000e4:	f9860613          	addi	a2,a2,-104 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	156010ef          	jal	ra,ffffffffc0201246 <memset>
    dtb_init();
ffffffffc02000f4:	122000ef          	jal	ra,ffffffffc0200216 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	4ce000ef          	jal	ra,ffffffffc02005c6 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	63450513          	addi	a0,a0,1588 # ffffffffc0201730 <etext+0xd0>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	4e8000ef          	jal	ra,ffffffffc02005f4 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	4ae000ef          	jal	ra,ffffffffc02005c8 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	184010ef          	jal	ra,ffffffffc02012c4 <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0204028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	14e010ef          	jal	ra,ffffffffc02012c4 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	430000ef          	jal	ra,ffffffffc02005c8 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	41a000ef          	jal	ra,ffffffffc02005c8 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00005317          	auipc	t1,0x5
ffffffffc02001c6:	e6e30313          	addi	t1,t1,-402 # ffffffffc0205030 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	55e50513          	addi	a0,a0,1374 # ffffffffc0201750 <etext+0xf0>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	52050513          	addi	a0,a0,1312 # ffffffffc0201728 <etext+0xc8>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200216:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200218:	00001517          	auipc	a0,0x1
ffffffffc020021c:	55850513          	addi	a0,a0,1368 # ffffffffc0201770 <etext+0x110>
void dtb_init(void) {
ffffffffc0200220:	fc86                	sd	ra,120(sp)
ffffffffc0200222:	f8a2                	sd	s0,112(sp)
ffffffffc0200224:	e8d2                	sd	s4,80(sp)
ffffffffc0200226:	f4a6                	sd	s1,104(sp)
ffffffffc0200228:	f0ca                	sd	s2,96(sp)
ffffffffc020022a:	ecce                	sd	s3,88(sp)
ffffffffc020022c:	e4d6                	sd	s5,72(sp)
ffffffffc020022e:	e0da                	sd	s6,64(sp)
ffffffffc0200230:	fc5e                	sd	s7,56(sp)
ffffffffc0200232:	f862                	sd	s8,48(sp)
ffffffffc0200234:	f466                	sd	s9,40(sp)
ffffffffc0200236:	f06a                	sd	s10,32(sp)
ffffffffc0200238:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020023a:	f13ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023e:	00005597          	auipc	a1,0x5
ffffffffc0200242:	dc25b583          	ld	a1,-574(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200246:	00001517          	auipc	a0,0x1
ffffffffc020024a:	53a50513          	addi	a0,a0,1338 # ffffffffc0201780 <etext+0x120>
ffffffffc020024e:	effff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	00005417          	auipc	s0,0x5
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc0205008 <boot_dtb>
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00001517          	auipc	a0,0x1
ffffffffc0200260:	53450513          	addi	a0,a0,1332 # ffffffffc0201790 <etext+0x130>
ffffffffc0200264:	ee9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026c:	00001517          	auipc	a0,0x1
ffffffffc0200270:	53c50513          	addi	a0,a0,1340 # ffffffffc02017a8 <etext+0x148>
    if (boot_dtb == 0) {
ffffffffc0200274:	120a0463          	beqz	s4,ffffffffc020039c <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200278:	57f5                	li	a5,-3
ffffffffc020027a:	07fa                	slli	a5,a5,0x1e
ffffffffc020027c:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200280:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200286:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200288:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020028c:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200294:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029c:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029e:	8ec9                	or	a3,a3,a0
ffffffffc02002a0:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002a4:	1b7d                	addi	s6,s6,-1
ffffffffc02002a6:	0167f7b3          	and	a5,a5,s6
ffffffffc02002aa:	8dd5                	or	a1,a1,a3
ffffffffc02002ac:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002ae:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b2:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002b4:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedae75>
ffffffffc02002b8:	10f59163          	bne	a1,a5,ffffffffc02003ba <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002bc:	471c                	lw	a5,8(a4)
ffffffffc02002be:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002c0:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002c6:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002ca:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002da:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002de:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ec:	01146433          	or	s0,s0,a7
ffffffffc02002f0:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002f4:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f8:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002fe:	8c49                	or	s0,s0,a0
ffffffffc0200300:	0166f6b3          	and	a3,a3,s6
ffffffffc0200304:	00ca6a33          	or	s4,s4,a2
ffffffffc0200308:	0167f7b3          	and	a5,a5,s6
ffffffffc020030c:	8c55                	or	s0,s0,a3
ffffffffc020030e:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200314:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200316:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200318:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200320:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200324:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200326:	00001917          	auipc	s2,0x1
ffffffffc020032a:	4d290913          	addi	s2,s2,1234 # ffffffffc02017f8 <etext+0x198>
ffffffffc020032e:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200330:	4d91                	li	s11,4
ffffffffc0200332:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200334:	00001497          	auipc	s1,0x1
ffffffffc0200338:	4bc48493          	addi	s1,s1,1212 # ffffffffc02017f0 <etext+0x190>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033c:	000a2703          	lw	a4,0(s4)
ffffffffc0200340:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200344:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200348:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020034c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200350:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200354:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200358:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200362:	8fd5                	or	a5,a5,a3
ffffffffc0200364:	00eb7733          	and	a4,s6,a4
ffffffffc0200368:	8fd9                	or	a5,a5,a4
ffffffffc020036a:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020036c:	09778c63          	beq	a5,s7,ffffffffc0200404 <dtb_init+0x1ee>
ffffffffc0200370:	00fbea63          	bltu	s7,a5,ffffffffc0200384 <dtb_init+0x16e>
ffffffffc0200374:	07a78663          	beq	a5,s10,ffffffffc02003e0 <dtb_init+0x1ca>
ffffffffc0200378:	4709                	li	a4,2
ffffffffc020037a:	00e79763          	bne	a5,a4,ffffffffc0200388 <dtb_init+0x172>
ffffffffc020037e:	4c81                	li	s9,0
ffffffffc0200380:	8a56                	mv	s4,s5
ffffffffc0200382:	bf6d                	j	ffffffffc020033c <dtb_init+0x126>
ffffffffc0200384:	ffb78ee3          	beq	a5,s11,ffffffffc0200380 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200388:	00001517          	auipc	a0,0x1
ffffffffc020038c:	4e850513          	addi	a0,a0,1256 # ffffffffc0201870 <etext+0x210>
ffffffffc0200390:	dbdff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200394:	00001517          	auipc	a0,0x1
ffffffffc0200398:	51450513          	addi	a0,a0,1300 # ffffffffc02018a8 <etext+0x248>
}
ffffffffc020039c:	7446                	ld	s0,112(sp)
ffffffffc020039e:	70e6                	ld	ra,120(sp)
ffffffffc02003a0:	74a6                	ld	s1,104(sp)
ffffffffc02003a2:	7906                	ld	s2,96(sp)
ffffffffc02003a4:	69e6                	ld	s3,88(sp)
ffffffffc02003a6:	6a46                	ld	s4,80(sp)
ffffffffc02003a8:	6aa6                	ld	s5,72(sp)
ffffffffc02003aa:	6b06                	ld	s6,64(sp)
ffffffffc02003ac:	7be2                	ld	s7,56(sp)
ffffffffc02003ae:	7c42                	ld	s8,48(sp)
ffffffffc02003b0:	7ca2                	ld	s9,40(sp)
ffffffffc02003b2:	7d02                	ld	s10,32(sp)
ffffffffc02003b4:	6de2                	ld	s11,24(sp)
ffffffffc02003b6:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003b8:	bb51                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003ba:	7446                	ld	s0,112(sp)
ffffffffc02003bc:	70e6                	ld	ra,120(sp)
ffffffffc02003be:	74a6                	ld	s1,104(sp)
ffffffffc02003c0:	7906                	ld	s2,96(sp)
ffffffffc02003c2:	69e6                	ld	s3,88(sp)
ffffffffc02003c4:	6a46                	ld	s4,80(sp)
ffffffffc02003c6:	6aa6                	ld	s5,72(sp)
ffffffffc02003c8:	6b06                	ld	s6,64(sp)
ffffffffc02003ca:	7be2                	ld	s7,56(sp)
ffffffffc02003cc:	7c42                	ld	s8,48(sp)
ffffffffc02003ce:	7ca2                	ld	s9,40(sp)
ffffffffc02003d0:	7d02                	ld	s10,32(sp)
ffffffffc02003d2:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003d4:	00001517          	auipc	a0,0x1
ffffffffc02003d8:	3f450513          	addi	a0,a0,1012 # ffffffffc02017c8 <etext+0x168>
}
ffffffffc02003dc:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	b3bd                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003e0:	8556                	mv	a0,s5
ffffffffc02003e2:	5eb000ef          	jal	ra,ffffffffc02011cc <strlen>
ffffffffc02003e6:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	4619                	li	a2,6
ffffffffc02003ea:	85a6                	mv	a1,s1
ffffffffc02003ec:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003ee:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f0:	631000ef          	jal	ra,ffffffffc0201220 <strncmp>
ffffffffc02003f4:	e111                	bnez	a0,ffffffffc02003f8 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02003f6:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003f8:	0a91                	addi	s5,s5,4
ffffffffc02003fa:	9ad2                	add	s5,s5,s4
ffffffffc02003fc:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200400:	8a56                	mv	s4,s5
ffffffffc0200402:	bf2d                	j	ffffffffc020033c <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200404:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200408:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040c:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200410:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200414:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200418:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200420:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200424:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200428:	0087979b          	slliw	a5,a5,0x8
ffffffffc020042c:	00eaeab3          	or	s5,s5,a4
ffffffffc0200430:	00fb77b3          	and	a5,s6,a5
ffffffffc0200434:	00faeab3          	or	s5,s5,a5
ffffffffc0200438:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020043a:	000c9c63          	bnez	s9,ffffffffc0200452 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020043e:	1a82                	slli	s5,s5,0x20
ffffffffc0200440:	00368793          	addi	a5,a3,3
ffffffffc0200444:	020ada93          	srli	s5,s5,0x20
ffffffffc0200448:	9abe                	add	s5,s5,a5
ffffffffc020044a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020044e:	8a56                	mv	s4,s5
ffffffffc0200450:	b5f5                	j	ffffffffc020033c <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200452:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200456:	85ca                	mv	a1,s2
ffffffffc0200458:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020045e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200462:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200466:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020046a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020046e:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200470:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200478:	8d59                	or	a0,a0,a4
ffffffffc020047a:	00fb77b3          	and	a5,s6,a5
ffffffffc020047e:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200480:	1502                	slli	a0,a0,0x20
ffffffffc0200482:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200484:	9522                	add	a0,a0,s0
ffffffffc0200486:	57d000ef          	jal	ra,ffffffffc0201202 <strcmp>
ffffffffc020048a:	66a2                	ld	a3,8(sp)
ffffffffc020048c:	f94d                	bnez	a0,ffffffffc020043e <dtb_init+0x228>
ffffffffc020048e:	fb59f8e3          	bgeu	s3,s5,ffffffffc020043e <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200492:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200496:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020049a:	00001517          	auipc	a0,0x1
ffffffffc020049e:	36650513          	addi	a0,a0,870 # ffffffffc0201800 <etext+0x1a0>
           fdt32_to_cpu(x >> 32);
ffffffffc02004a2:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a6:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004aa:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ae:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004b2:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ba:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004be:	0187d693          	srli	a3,a5,0x18
ffffffffc02004c2:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004c6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004ca:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004d2:	010f6f33          	or	t5,t5,a6
ffffffffc02004d6:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004da:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004de:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e2:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e6:	0186f6b3          	and	a3,a3,s8
ffffffffc02004ea:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004ee:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f2:	0107581b          	srliw	a6,a4,0x10
ffffffffc02004f6:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fa:	8361                	srli	a4,a4,0x18
ffffffffc02004fc:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200504:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200508:	00cb7633          	and	a2,s6,a2
ffffffffc020050c:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200510:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200514:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200518:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051c:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200520:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200524:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200528:	011b78b3          	and	a7,s6,a7
ffffffffc020052c:	005eeeb3          	or	t4,t4,t0
ffffffffc0200530:	00c6e733          	or	a4,a3,a2
ffffffffc0200534:	006c6c33          	or	s8,s8,t1
ffffffffc0200538:	010b76b3          	and	a3,s6,a6
ffffffffc020053c:	00bb7b33          	and	s6,s6,a1
ffffffffc0200540:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200544:	016c6b33          	or	s6,s8,s6
ffffffffc0200548:	01146433          	or	s0,s0,a7
ffffffffc020054c:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc020054e:	1702                	slli	a4,a4,0x20
ffffffffc0200550:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200552:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200554:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200556:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	0167eb33          	or	s6,a5,s6
ffffffffc0200560:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200562:	bebff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200566:	85a2                	mv	a1,s0
ffffffffc0200568:	00001517          	auipc	a0,0x1
ffffffffc020056c:	2b850513          	addi	a0,a0,696 # ffffffffc0201820 <etext+0x1c0>
ffffffffc0200570:	bddff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200574:	014b5613          	srli	a2,s6,0x14
ffffffffc0200578:	85da                	mv	a1,s6
ffffffffc020057a:	00001517          	auipc	a0,0x1
ffffffffc020057e:	2be50513          	addi	a0,a0,702 # ffffffffc0201838 <etext+0x1d8>
ffffffffc0200582:	bcbff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200586:	008b05b3          	add	a1,s6,s0
ffffffffc020058a:	15fd                	addi	a1,a1,-1
ffffffffc020058c:	00001517          	auipc	a0,0x1
ffffffffc0200590:	2cc50513          	addi	a0,a0,716 # ffffffffc0201858 <etext+0x1f8>
ffffffffc0200594:	bb9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200598:	00001517          	auipc	a0,0x1
ffffffffc020059c:	31050513          	addi	a0,a0,784 # ffffffffc02018a8 <etext+0x248>
        memory_base = mem_base;
ffffffffc02005a0:	00005797          	auipc	a5,0x5
ffffffffc02005a4:	a887bc23          	sd	s0,-1384(a5) # ffffffffc0205038 <memory_base>
        memory_size = mem_size;
ffffffffc02005a8:	00005797          	auipc	a5,0x5
ffffffffc02005ac:	a967bc23          	sd	s6,-1384(a5) # ffffffffc0205040 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005b0:	b3f5                	j	ffffffffc020039c <dtb_init+0x186>

ffffffffc02005b2 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005b2:	00005517          	auipc	a0,0x5
ffffffffc02005b6:	a8653503          	ld	a0,-1402(a0) # ffffffffc0205038 <memory_base>
ffffffffc02005ba:	8082                	ret

ffffffffc02005bc <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005bc:	00005517          	auipc	a0,0x5
ffffffffc02005c0:	a8453503          	ld	a0,-1404(a0) # ffffffffc0205040 <memory_size>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02005c6:	8082                	ret

ffffffffc02005c8 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc02005c8:	0ff57513          	zext.b	a0,a0
ffffffffc02005cc:	07a0106f          	j	ffffffffc0201646 <sbi_console_putchar>

ffffffffc02005d0 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02005d0:	00005797          	auipc	a5,0x5
ffffffffc02005d4:	a887b783          	ld	a5,-1400(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc02005d8:	6f9c                	ld	a5,24(a5)
ffffffffc02005da:	8782                	jr	a5

ffffffffc02005dc <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02005dc:	00005797          	auipc	a5,0x5
ffffffffc02005e0:	a7c7b783          	ld	a5,-1412(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc02005e4:	739c                	ld	a5,32(a5)
ffffffffc02005e6:	8782                	jr	a5

ffffffffc02005e8 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02005e8:	00005797          	auipc	a5,0x5
ffffffffc02005ec:	a707b783          	ld	a5,-1424(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc02005f0:	779c                	ld	a5,40(a5)
ffffffffc02005f2:	8782                	jr	a5

ffffffffc02005f4 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02005f4:	00001797          	auipc	a5,0x1
ffffffffc02005f8:	75c78793          	addi	a5,a5,1884 # ffffffffc0201d50 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02005fc:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02005fe:	7179                	addi	sp,sp,-48
ffffffffc0200600:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200602:	00001517          	auipc	a0,0x1
ffffffffc0200606:	2be50513          	addi	a0,a0,702 # ffffffffc02018c0 <etext+0x260>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020060a:	00005417          	auipc	s0,0x5
ffffffffc020060e:	a4e40413          	addi	s0,s0,-1458 # ffffffffc0205058 <pmm_manager>
void pmm_init(void) {
ffffffffc0200612:	f406                	sd	ra,40(sp)
ffffffffc0200614:	ec26                	sd	s1,24(sp)
ffffffffc0200616:	e44e                	sd	s3,8(sp)
ffffffffc0200618:	e84a                	sd	s2,16(sp)
ffffffffc020061a:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020061c:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020061e:	b2fff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200622:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200624:	00005497          	auipc	s1,0x5
ffffffffc0200628:	a4c48493          	addi	s1,s1,-1460 # ffffffffc0205070 <va_pa_offset>
    pmm_manager->init();
ffffffffc020062c:	679c                	ld	a5,8(a5)
ffffffffc020062e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200630:	57f5                	li	a5,-3
ffffffffc0200632:	07fa                	slli	a5,a5,0x1e
ffffffffc0200634:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200636:	f7dff0ef          	jal	ra,ffffffffc02005b2 <get_memory_base>
ffffffffc020063a:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020063c:	f81ff0ef          	jal	ra,ffffffffc02005bc <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200640:	14050c63          	beqz	a0,ffffffffc0200798 <pmm_init+0x1a4>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200644:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200646:	00001517          	auipc	a0,0x1
ffffffffc020064a:	2c250513          	addi	a0,a0,706 # ffffffffc0201908 <etext+0x2a8>
ffffffffc020064e:	affff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200652:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200656:	864e                	mv	a2,s3
ffffffffc0200658:	fffa0693          	addi	a3,s4,-1
ffffffffc020065c:	85ca                	mv	a1,s2
ffffffffc020065e:	00001517          	auipc	a0,0x1
ffffffffc0200662:	2c250513          	addi	a0,a0,706 # ffffffffc0201920 <etext+0x2c0>
ffffffffc0200666:	ae7ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020066a:	c80007b7          	lui	a5,0xc8000
ffffffffc020066e:	8652                	mv	a2,s4
ffffffffc0200670:	0d47e363          	bltu	a5,s4,ffffffffc0200736 <pmm_init+0x142>
ffffffffc0200674:	00006797          	auipc	a5,0x6
ffffffffc0200678:	a0378793          	addi	a5,a5,-1533 # ffffffffc0206077 <end+0xfff>
ffffffffc020067c:	757d                	lui	a0,0xfffff
ffffffffc020067e:	8d7d                	and	a0,a0,a5
ffffffffc0200680:	8231                	srli	a2,a2,0xc
ffffffffc0200682:	00005797          	auipc	a5,0x5
ffffffffc0200686:	9cc7b323          	sd	a2,-1594(a5) # ffffffffc0205048 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020068a:	00005797          	auipc	a5,0x5
ffffffffc020068e:	9ca7b323          	sd	a0,-1594(a5) # ffffffffc0205050 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200692:	000807b7          	lui	a5,0x80
ffffffffc0200696:	002005b7          	lui	a1,0x200
ffffffffc020069a:	02f60563          	beq	a2,a5,ffffffffc02006c4 <pmm_init+0xd0>
ffffffffc020069e:	00261593          	slli	a1,a2,0x2
ffffffffc02006a2:	00c586b3          	add	a3,a1,a2
ffffffffc02006a6:	fec007b7          	lui	a5,0xfec00
ffffffffc02006aa:	97aa                	add	a5,a5,a0
ffffffffc02006ac:	068e                	slli	a3,a3,0x3
ffffffffc02006ae:	96be                	add	a3,a3,a5
ffffffffc02006b0:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc02006b2:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02006b4:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9fafb0>
        SetPageReserved(pages + i);
ffffffffc02006b8:	00176713          	ori	a4,a4,1
ffffffffc02006bc:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02006c0:	fef699e3          	bne	a3,a5,ffffffffc02006b2 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006c4:	95b2                	add	a1,a1,a2
ffffffffc02006c6:	fec006b7          	lui	a3,0xfec00
ffffffffc02006ca:	96aa                	add	a3,a3,a0
ffffffffc02006cc:	058e                	slli	a1,a1,0x3
ffffffffc02006ce:	96ae                	add	a3,a3,a1
ffffffffc02006d0:	c02007b7          	lui	a5,0xc0200
ffffffffc02006d4:	0af6e663          	bltu	a3,a5,ffffffffc0200780 <pmm_init+0x18c>
ffffffffc02006d8:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02006da:	77fd                	lui	a5,0xfffff
ffffffffc02006dc:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006e0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02006e2:	04b6ed63          	bltu	a3,a1,ffffffffc020073c <pmm_init+0x148>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02006e6:	601c                	ld	a5,0(s0)
ffffffffc02006e8:	7b9c                	ld	a5,48(a5)
ffffffffc02006ea:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02006ec:	00001517          	auipc	a0,0x1
ffffffffc02006f0:	2bc50513          	addi	a0,a0,700 # ffffffffc02019a8 <etext+0x348>
ffffffffc02006f4:	a59ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02006f8:	00004597          	auipc	a1,0x4
ffffffffc02006fc:	90858593          	addi	a1,a1,-1784 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200700:	00005797          	auipc	a5,0x5
ffffffffc0200704:	96b7b423          	sd	a1,-1688(a5) # ffffffffc0205068 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200708:	c02007b7          	lui	a5,0xc0200
ffffffffc020070c:	0af5e263          	bltu	a1,a5,ffffffffc02007b0 <pmm_init+0x1bc>
ffffffffc0200710:	6090                	ld	a2,0(s1)
}
ffffffffc0200712:	7402                	ld	s0,32(sp)
ffffffffc0200714:	70a2                	ld	ra,40(sp)
ffffffffc0200716:	64e2                	ld	s1,24(sp)
ffffffffc0200718:	6942                	ld	s2,16(sp)
ffffffffc020071a:	69a2                	ld	s3,8(sp)
ffffffffc020071c:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020071e:	40c58633          	sub	a2,a1,a2
ffffffffc0200722:	00005797          	auipc	a5,0x5
ffffffffc0200726:	92c7bf23          	sd	a2,-1730(a5) # ffffffffc0205060 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020072a:	00001517          	auipc	a0,0x1
ffffffffc020072e:	29e50513          	addi	a0,a0,670 # ffffffffc02019c8 <etext+0x368>
}
ffffffffc0200732:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200734:	bc21                	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200736:	c8000637          	lui	a2,0xc8000
ffffffffc020073a:	bf2d                	j	ffffffffc0200674 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020073c:	6705                	lui	a4,0x1
ffffffffc020073e:	177d                	addi	a4,a4,-1
ffffffffc0200740:	96ba                	add	a3,a3,a4
ffffffffc0200742:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200744:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200748:	02c7f063          	bgeu	a5,a2,ffffffffc0200768 <pmm_init+0x174>
    pmm_manager->init_memmap(base, n);
ffffffffc020074c:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020074e:	fff80737          	lui	a4,0xfff80
ffffffffc0200752:	973e                	add	a4,a4,a5
ffffffffc0200754:	00271793          	slli	a5,a4,0x2
ffffffffc0200758:	97ba                	add	a5,a5,a4
ffffffffc020075a:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020075c:	8d95                	sub	a1,a1,a3
ffffffffc020075e:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200760:	81b1                	srli	a1,a1,0xc
ffffffffc0200762:	953e                	add	a0,a0,a5
ffffffffc0200764:	9702                	jalr	a4
}
ffffffffc0200766:	b741                	j	ffffffffc02006e6 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200768:	00001617          	auipc	a2,0x1
ffffffffc020076c:	21060613          	addi	a2,a2,528 # ffffffffc0201978 <etext+0x318>
ffffffffc0200770:	06a00593          	li	a1,106
ffffffffc0200774:	00001517          	auipc	a0,0x1
ffffffffc0200778:	22450513          	addi	a0,a0,548 # ffffffffc0201998 <etext+0x338>
ffffffffc020077c:	a47ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200780:	00001617          	auipc	a2,0x1
ffffffffc0200784:	1d060613          	addi	a2,a2,464 # ffffffffc0201950 <etext+0x2f0>
ffffffffc0200788:	05e00593          	li	a1,94
ffffffffc020078c:	00001517          	auipc	a0,0x1
ffffffffc0200790:	16c50513          	addi	a0,a0,364 # ffffffffc02018f8 <etext+0x298>
ffffffffc0200794:	a2fff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200798:	00001617          	auipc	a2,0x1
ffffffffc020079c:	14060613          	addi	a2,a2,320 # ffffffffc02018d8 <etext+0x278>
ffffffffc02007a0:	04600593          	li	a1,70
ffffffffc02007a4:	00001517          	auipc	a0,0x1
ffffffffc02007a8:	15450513          	addi	a0,a0,340 # ffffffffc02018f8 <etext+0x298>
ffffffffc02007ac:	a17ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02007b0:	86ae                	mv	a3,a1
ffffffffc02007b2:	00001617          	auipc	a2,0x1
ffffffffc02007b6:	19e60613          	addi	a2,a2,414 # ffffffffc0201950 <etext+0x2f0>
ffffffffc02007ba:	07900593          	li	a1,121
ffffffffc02007be:	00001517          	auipc	a0,0x1
ffffffffc02007c2:	13a50513          	addi	a0,a0,314 # ffffffffc02018f8 <etext+0x298>
ffffffffc02007c6:	9fdff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02007ca <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02007ca:	00005797          	auipc	a5,0x5
ffffffffc02007ce:	84e78793          	addi	a5,a5,-1970 # ffffffffc0205018 <free_area>
ffffffffc02007d2:	e79c                	sd	a5,8(a5)
ffffffffc02007d4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02007d6:	0007a823          	sw	zero,16(a5)
}
ffffffffc02007da:	8082                	ret

ffffffffc02007dc <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02007dc:	00005517          	auipc	a0,0x5
ffffffffc02007e0:	84c56503          	lwu	a0,-1972(a0) # ffffffffc0205028 <free_area+0x10>
ffffffffc02007e4:	8082                	ret

ffffffffc02007e6 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02007e6:	cd49                	beqz	a0,ffffffffc0200880 <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc02007e8:	00005617          	auipc	a2,0x5
ffffffffc02007ec:	83060613          	addi	a2,a2,-2000 # ffffffffc0205018 <free_area>
ffffffffc02007f0:	01062803          	lw	a6,16(a2)
ffffffffc02007f4:	86aa                	mv	a3,a0
ffffffffc02007f6:	02081793          	slli	a5,a6,0x20
ffffffffc02007fa:	9381                	srli	a5,a5,0x20
ffffffffc02007fc:	08a7e063          	bltu	a5,a0,ffffffffc020087c <best_fit_alloc_pages+0x96>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200800:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200802:	0018059b          	addiw	a1,a6,1
ffffffffc0200806:	1582                	slli	a1,a1,0x20
ffffffffc0200808:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc020080a:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc020080c:	06c78763          	beq	a5,a2,ffffffffc020087a <best_fit_alloc_pages+0x94>
        if(p->property >= n && p->property < min_size){
ffffffffc0200810:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200814:	00d76763          	bltu	a4,a3,ffffffffc0200822 <best_fit_alloc_pages+0x3c>
ffffffffc0200818:	00b77563          	bgeu	a4,a1,ffffffffc0200822 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc020081c:	fe878513          	addi	a0,a5,-24
ffffffffc0200820:	85ba                	mv	a1,a4
ffffffffc0200822:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200824:	fec796e3          	bne	a5,a2,ffffffffc0200810 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200828:	c929                	beqz	a0,ffffffffc020087a <best_fit_alloc_pages+0x94>
        if (page->property > n) {
ffffffffc020082a:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc020082e:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200830:	710c                	ld	a1,32(a0)
ffffffffc0200832:	02089793          	slli	a5,a7,0x20
ffffffffc0200836:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200838:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc020083a:	e198                	sd	a4,0(a1)
            p->property = page->property - n;
ffffffffc020083c:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc0200840:	02f6f563          	bgeu	a3,a5,ffffffffc020086a <best_fit_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0200844:	00269793          	slli	a5,a3,0x2
ffffffffc0200848:	97b6                	add	a5,a5,a3
ffffffffc020084a:	078e                	slli	a5,a5,0x3
ffffffffc020084c:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc020084e:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc0200850:	406888bb          	subw	a7,a7,t1
ffffffffc0200854:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc0200858:	0026e693          	ori	a3,a3,2
ffffffffc020085c:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc020085e:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200862:	e194                	sd	a3,0(a1)
ffffffffc0200864:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200866:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc0200868:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc020086a:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc020086c:	4068083b          	subw	a6,a6,t1
ffffffffc0200870:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc0200874:	9bf5                	andi	a5,a5,-3
ffffffffc0200876:	e51c                	sd	a5,8(a0)
ffffffffc0200878:	8082                	ret
}
ffffffffc020087a:	8082                	ret
        return NULL;
ffffffffc020087c:	4501                	li	a0,0
ffffffffc020087e:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200880:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200882:	00001697          	auipc	a3,0x1
ffffffffc0200886:	18668693          	addi	a3,a3,390 # ffffffffc0201a08 <etext+0x3a8>
ffffffffc020088a:	00001617          	auipc	a2,0x1
ffffffffc020088e:	18660613          	addi	a2,a2,390 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200892:	06900593          	li	a1,105
ffffffffc0200896:	00001517          	auipc	a0,0x1
ffffffffc020089a:	19250513          	addi	a0,a0,402 # ffffffffc0201a28 <etext+0x3c8>
best_fit_alloc_pages(size_t n) {
ffffffffc020089e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008a0:	923ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02008a4 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02008a4:	715d                	addi	sp,sp,-80
ffffffffc02008a6:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02008a8:	00004417          	auipc	s0,0x4
ffffffffc02008ac:	77040413          	addi	s0,s0,1904 # ffffffffc0205018 <free_area>
ffffffffc02008b0:	641c                	ld	a5,8(s0)
ffffffffc02008b2:	e486                	sd	ra,72(sp)
ffffffffc02008b4:	fc26                	sd	s1,56(sp)
ffffffffc02008b6:	f84a                	sd	s2,48(sp)
ffffffffc02008b8:	f44e                	sd	s3,40(sp)
ffffffffc02008ba:	f052                	sd	s4,32(sp)
ffffffffc02008bc:	ec56                	sd	s5,24(sp)
ffffffffc02008be:	e85a                	sd	s6,16(sp)
ffffffffc02008c0:	e45e                	sd	s7,8(sp)
ffffffffc02008c2:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008c4:	26878963          	beq	a5,s0,ffffffffc0200b36 <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc02008c8:	4481                	li	s1,0
ffffffffc02008ca:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02008cc:	ff07b703          	ld	a4,-16(a5)
ffffffffc02008d0:	8b09                	andi	a4,a4,2
ffffffffc02008d2:	26070663          	beqz	a4,ffffffffc0200b3e <best_fit_check+0x29a>
        count ++, total += p->property;
ffffffffc02008d6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02008da:	679c                	ld	a5,8(a5)
ffffffffc02008dc:	2905                	addiw	s2,s2,1
ffffffffc02008de:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008e0:	fe8796e3          	bne	a5,s0,ffffffffc02008cc <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02008e4:	89a6                	mv	s3,s1
ffffffffc02008e6:	d03ff0ef          	jal	ra,ffffffffc02005e8 <nr_free_pages>
ffffffffc02008ea:	33351a63          	bne	a0,s3,ffffffffc0200c1e <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02008ee:	4505                	li	a0,1
ffffffffc02008f0:	ce1ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02008f4:	8a2a                	mv	s4,a0
ffffffffc02008f6:	36050463          	beqz	a0,ffffffffc0200c5e <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02008fa:	4505                	li	a0,1
ffffffffc02008fc:	cd5ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200900:	89aa                	mv	s3,a0
ffffffffc0200902:	32050e63          	beqz	a0,ffffffffc0200c3e <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200906:	4505                	li	a0,1
ffffffffc0200908:	cc9ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc020090c:	8aaa                	mv	s5,a0
ffffffffc020090e:	2c050863          	beqz	a0,ffffffffc0200bde <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200912:	253a0663          	beq	s4,s3,ffffffffc0200b5e <best_fit_check+0x2ba>
ffffffffc0200916:	24aa0463          	beq	s4,a0,ffffffffc0200b5e <best_fit_check+0x2ba>
ffffffffc020091a:	24a98263          	beq	s3,a0,ffffffffc0200b5e <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020091e:	000a2783          	lw	a5,0(s4)
ffffffffc0200922:	24079e63          	bnez	a5,ffffffffc0200b7e <best_fit_check+0x2da>
ffffffffc0200926:	0009a783          	lw	a5,0(s3)
ffffffffc020092a:	24079a63          	bnez	a5,ffffffffc0200b7e <best_fit_check+0x2da>
ffffffffc020092e:	411c                	lw	a5,0(a0)
ffffffffc0200930:	24079763          	bnez	a5,ffffffffc0200b7e <best_fit_check+0x2da>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200934:	00004797          	auipc	a5,0x4
ffffffffc0200938:	71c7b783          	ld	a5,1820(a5) # ffffffffc0205050 <pages>
ffffffffc020093c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200940:	870d                	srai	a4,a4,0x3
ffffffffc0200942:	00001597          	auipc	a1,0x1
ffffffffc0200946:	6965b583          	ld	a1,1686(a1) # ffffffffc0201fd8 <nbase+0x8>
ffffffffc020094a:	02b70733          	mul	a4,a4,a1
ffffffffc020094e:	00001617          	auipc	a2,0x1
ffffffffc0200952:	68263603          	ld	a2,1666(a2) # ffffffffc0201fd0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200956:	00004697          	auipc	a3,0x4
ffffffffc020095a:	6f26b683          	ld	a3,1778(a3) # ffffffffc0205048 <npage>
ffffffffc020095e:	06b2                	slli	a3,a3,0xc
ffffffffc0200960:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200962:	0732                	slli	a4,a4,0xc
ffffffffc0200964:	22d77d63          	bgeu	a4,a3,ffffffffc0200b9e <best_fit_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200968:	40f98733          	sub	a4,s3,a5
ffffffffc020096c:	870d                	srai	a4,a4,0x3
ffffffffc020096e:	02b70733          	mul	a4,a4,a1
ffffffffc0200972:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200974:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200976:	3ed77463          	bgeu	a4,a3,ffffffffc0200d5e <best_fit_check+0x4ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020097a:	40f507b3          	sub	a5,a0,a5
ffffffffc020097e:	878d                	srai	a5,a5,0x3
ffffffffc0200980:	02b787b3          	mul	a5,a5,a1
ffffffffc0200984:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200986:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200988:	3ad7fb63          	bgeu	a5,a3,ffffffffc0200d3e <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc020098c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020098e:	00043c03          	ld	s8,0(s0)
ffffffffc0200992:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200996:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020099a:	e400                	sd	s0,8(s0)
ffffffffc020099c:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020099e:	00004797          	auipc	a5,0x4
ffffffffc02009a2:	6807a523          	sw	zero,1674(a5) # ffffffffc0205028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02009a6:	c2bff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009aa:	36051a63          	bnez	a0,ffffffffc0200d1e <best_fit_check+0x47a>
    free_page(p0);
ffffffffc02009ae:	4585                	li	a1,1
ffffffffc02009b0:	8552                	mv	a0,s4
ffffffffc02009b2:	c2bff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p1);
ffffffffc02009b6:	4585                	li	a1,1
ffffffffc02009b8:	854e                	mv	a0,s3
ffffffffc02009ba:	c23ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p2);
ffffffffc02009be:	4585                	li	a1,1
ffffffffc02009c0:	8556                	mv	a0,s5
ffffffffc02009c2:	c1bff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(nr_free == 3);
ffffffffc02009c6:	4818                	lw	a4,16(s0)
ffffffffc02009c8:	478d                	li	a5,3
ffffffffc02009ca:	32f71a63          	bne	a4,a5,ffffffffc0200cfe <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02009ce:	4505                	li	a0,1
ffffffffc02009d0:	c01ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009d4:	89aa                	mv	s3,a0
ffffffffc02009d6:	30050463          	beqz	a0,ffffffffc0200cde <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009da:	4505                	li	a0,1
ffffffffc02009dc:	bf5ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009e0:	8aaa                	mv	s5,a0
ffffffffc02009e2:	2c050e63          	beqz	a0,ffffffffc0200cbe <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009e6:	4505                	li	a0,1
ffffffffc02009e8:	be9ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009ec:	8a2a                	mv	s4,a0
ffffffffc02009ee:	2a050863          	beqz	a0,ffffffffc0200c9e <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc02009f2:	4505                	li	a0,1
ffffffffc02009f4:	bddff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009f8:	28051363          	bnez	a0,ffffffffc0200c7e <best_fit_check+0x3da>
    free_page(p0);
ffffffffc02009fc:	4585                	li	a1,1
ffffffffc02009fe:	854e                	mv	a0,s3
ffffffffc0200a00:	bddff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200a04:	641c                	ld	a5,8(s0)
ffffffffc0200a06:	1a878c63          	beq	a5,s0,ffffffffc0200bbe <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc0200a0a:	4505                	li	a0,1
ffffffffc0200a0c:	bc5ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a10:	52a99763          	bne	s3,a0,ffffffffc0200f3e <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0200a14:	4505                	li	a0,1
ffffffffc0200a16:	bbbff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a1a:	50051263          	bnez	a0,ffffffffc0200f1e <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc0200a1e:	481c                	lw	a5,16(s0)
ffffffffc0200a20:	4c079f63          	bnez	a5,ffffffffc0200efe <best_fit_check+0x65a>
    free_page(p);
ffffffffc0200a24:	854e                	mv	a0,s3
ffffffffc0200a26:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200a28:	01843023          	sd	s8,0(s0)
ffffffffc0200a2c:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200a30:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200a34:	ba9ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p1);
ffffffffc0200a38:	4585                	li	a1,1
ffffffffc0200a3a:	8556                	mv	a0,s5
ffffffffc0200a3c:	ba1ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p2);
ffffffffc0200a40:	4585                	li	a1,1
ffffffffc0200a42:	8552                	mv	a0,s4
ffffffffc0200a44:	b99ff0ef          	jal	ra,ffffffffc02005dc <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200a48:	4515                	li	a0,5
ffffffffc0200a4a:	b87ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a4e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200a50:	48050763          	beqz	a0,ffffffffc0200ede <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc0200a54:	651c                	ld	a5,8(a0)
ffffffffc0200a56:	8b89                	andi	a5,a5,2
ffffffffc0200a58:	46079363          	bnez	a5,ffffffffc0200ebe <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200a5c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a5e:	00043b03          	ld	s6,0(s0)
ffffffffc0200a62:	00843a83          	ld	s5,8(s0)
ffffffffc0200a66:	e000                	sd	s0,0(s0)
ffffffffc0200a68:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200a6a:	b67ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a6e:	42051863          	bnez	a0,ffffffffc0200e9e <best_fit_check+0x5fa>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200a72:	4589                	li	a1,2
ffffffffc0200a74:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200a78:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200a7c:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200a80:	00004797          	auipc	a5,0x4
ffffffffc0200a84:	5a07a423          	sw	zero,1448(a5) # ffffffffc0205028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200a88:	b55ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200a8c:	8562                	mv	a0,s8
ffffffffc0200a8e:	4585                	li	a1,1
ffffffffc0200a90:	b4dff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200a94:	4511                	li	a0,4
ffffffffc0200a96:	b3bff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a9a:	3e051263          	bnez	a0,ffffffffc0200e7e <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200a9e:	0309b783          	ld	a5,48(s3)
ffffffffc0200aa2:	8b89                	andi	a5,a5,2
ffffffffc0200aa4:	3a078d63          	beqz	a5,ffffffffc0200e5e <best_fit_check+0x5ba>
ffffffffc0200aa8:	0389a703          	lw	a4,56(s3)
ffffffffc0200aac:	4789                	li	a5,2
ffffffffc0200aae:	3af71863          	bne	a4,a5,ffffffffc0200e5e <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200ab2:	4505                	li	a0,1
ffffffffc0200ab4:	b1dff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200ab8:	8a2a                	mv	s4,a0
ffffffffc0200aba:	38050263          	beqz	a0,ffffffffc0200e3e <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200abe:	4509                	li	a0,2
ffffffffc0200ac0:	b11ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200ac4:	34050d63          	beqz	a0,ffffffffc0200e1e <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc0200ac8:	334c1b63          	bne	s8,s4,ffffffffc0200dfe <best_fit_check+0x55a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200acc:	854e                	mv	a0,s3
ffffffffc0200ace:	4595                	li	a1,5
ffffffffc0200ad0:	b0dff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ad4:	4515                	li	a0,5
ffffffffc0200ad6:	afbff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200ada:	89aa                	mv	s3,a0
ffffffffc0200adc:	30050163          	beqz	a0,ffffffffc0200dde <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc0200ae0:	4505                	li	a0,1
ffffffffc0200ae2:	aefff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200ae6:	2c051c63          	bnez	a0,ffffffffc0200dbe <best_fit_check+0x51a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200aea:	481c                	lw	a5,16(s0)
ffffffffc0200aec:	2a079963          	bnez	a5,ffffffffc0200d9e <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200af0:	4595                	li	a1,5
ffffffffc0200af2:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200af4:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200af8:	01643023          	sd	s6,0(s0)
ffffffffc0200afc:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200b00:	addff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    return listelm->next;
ffffffffc0200b04:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b06:	00878963          	beq	a5,s0,ffffffffc0200b18 <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200b0a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b0e:	679c                	ld	a5,8(a5)
ffffffffc0200b10:	397d                	addiw	s2,s2,-1
ffffffffc0200b12:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b14:	fe879be3          	bne	a5,s0,ffffffffc0200b0a <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc0200b18:	26091363          	bnez	s2,ffffffffc0200d7e <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc0200b1c:	e0ed                	bnez	s1,ffffffffc0200bfe <best_fit_check+0x35a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200b1e:	60a6                	ld	ra,72(sp)
ffffffffc0200b20:	6406                	ld	s0,64(sp)
ffffffffc0200b22:	74e2                	ld	s1,56(sp)
ffffffffc0200b24:	7942                	ld	s2,48(sp)
ffffffffc0200b26:	79a2                	ld	s3,40(sp)
ffffffffc0200b28:	7a02                	ld	s4,32(sp)
ffffffffc0200b2a:	6ae2                	ld	s5,24(sp)
ffffffffc0200b2c:	6b42                	ld	s6,16(sp)
ffffffffc0200b2e:	6ba2                	ld	s7,8(sp)
ffffffffc0200b30:	6c02                	ld	s8,0(sp)
ffffffffc0200b32:	6161                	addi	sp,sp,80
ffffffffc0200b34:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b36:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200b38:	4481                	li	s1,0
ffffffffc0200b3a:	4901                	li	s2,0
ffffffffc0200b3c:	b36d                	j	ffffffffc02008e6 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200b3e:	00001697          	auipc	a3,0x1
ffffffffc0200b42:	f0268693          	addi	a3,a3,-254 # ffffffffc0201a40 <etext+0x3e0>
ffffffffc0200b46:	00001617          	auipc	a2,0x1
ffffffffc0200b4a:	eca60613          	addi	a2,a2,-310 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200b4e:	10900593          	li	a1,265
ffffffffc0200b52:	00001517          	auipc	a0,0x1
ffffffffc0200b56:	ed650513          	addi	a0,a0,-298 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200b5a:	e68ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b5e:	00001697          	auipc	a3,0x1
ffffffffc0200b62:	f7268693          	addi	a3,a3,-142 # ffffffffc0201ad0 <etext+0x470>
ffffffffc0200b66:	00001617          	auipc	a2,0x1
ffffffffc0200b6a:	eaa60613          	addi	a2,a2,-342 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200b6e:	0d500593          	li	a1,213
ffffffffc0200b72:	00001517          	auipc	a0,0x1
ffffffffc0200b76:	eb650513          	addi	a0,a0,-330 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200b7a:	e48ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b7e:	00001697          	auipc	a3,0x1
ffffffffc0200b82:	f7a68693          	addi	a3,a3,-134 # ffffffffc0201af8 <etext+0x498>
ffffffffc0200b86:	00001617          	auipc	a2,0x1
ffffffffc0200b8a:	e8a60613          	addi	a2,a2,-374 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200b8e:	0d600593          	li	a1,214
ffffffffc0200b92:	00001517          	auipc	a0,0x1
ffffffffc0200b96:	e9650513          	addi	a0,a0,-362 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200b9a:	e28ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200b9e:	00001697          	auipc	a3,0x1
ffffffffc0200ba2:	f9a68693          	addi	a3,a3,-102 # ffffffffc0201b38 <etext+0x4d8>
ffffffffc0200ba6:	00001617          	auipc	a2,0x1
ffffffffc0200baa:	e6a60613          	addi	a2,a2,-406 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200bae:	0d800593          	li	a1,216
ffffffffc0200bb2:	00001517          	auipc	a0,0x1
ffffffffc0200bb6:	e7650513          	addi	a0,a0,-394 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200bba:	e08ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200bbe:	00001697          	auipc	a3,0x1
ffffffffc0200bc2:	00268693          	addi	a3,a3,2 # ffffffffc0201bc0 <etext+0x560>
ffffffffc0200bc6:	00001617          	auipc	a2,0x1
ffffffffc0200bca:	e4a60613          	addi	a2,a2,-438 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200bce:	0f100593          	li	a1,241
ffffffffc0200bd2:	00001517          	auipc	a0,0x1
ffffffffc0200bd6:	e5650513          	addi	a0,a0,-426 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200bda:	de8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200bde:	00001697          	auipc	a3,0x1
ffffffffc0200be2:	ed268693          	addi	a3,a3,-302 # ffffffffc0201ab0 <etext+0x450>
ffffffffc0200be6:	00001617          	auipc	a2,0x1
ffffffffc0200bea:	e2a60613          	addi	a2,a2,-470 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200bee:	0d300593          	li	a1,211
ffffffffc0200bf2:	00001517          	auipc	a0,0x1
ffffffffc0200bf6:	e3650513          	addi	a0,a0,-458 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200bfa:	dc8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == 0);
ffffffffc0200bfe:	00001697          	auipc	a3,0x1
ffffffffc0200c02:	0f268693          	addi	a3,a3,242 # ffffffffc0201cf0 <etext+0x690>
ffffffffc0200c06:	00001617          	auipc	a2,0x1
ffffffffc0200c0a:	e0a60613          	addi	a2,a2,-502 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200c0e:	14b00593          	li	a1,331
ffffffffc0200c12:	00001517          	auipc	a0,0x1
ffffffffc0200c16:	e1650513          	addi	a0,a0,-490 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200c1a:	da8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200c1e:	00001697          	auipc	a3,0x1
ffffffffc0200c22:	e3268693          	addi	a3,a3,-462 # ffffffffc0201a50 <etext+0x3f0>
ffffffffc0200c26:	00001617          	auipc	a2,0x1
ffffffffc0200c2a:	dea60613          	addi	a2,a2,-534 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200c2e:	10c00593          	li	a1,268
ffffffffc0200c32:	00001517          	auipc	a0,0x1
ffffffffc0200c36:	df650513          	addi	a0,a0,-522 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200c3a:	d88ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c3e:	00001697          	auipc	a3,0x1
ffffffffc0200c42:	e5268693          	addi	a3,a3,-430 # ffffffffc0201a90 <etext+0x430>
ffffffffc0200c46:	00001617          	auipc	a2,0x1
ffffffffc0200c4a:	dca60613          	addi	a2,a2,-566 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200c4e:	0d200593          	li	a1,210
ffffffffc0200c52:	00001517          	auipc	a0,0x1
ffffffffc0200c56:	dd650513          	addi	a0,a0,-554 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200c5a:	d68ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c5e:	00001697          	auipc	a3,0x1
ffffffffc0200c62:	e1268693          	addi	a3,a3,-494 # ffffffffc0201a70 <etext+0x410>
ffffffffc0200c66:	00001617          	auipc	a2,0x1
ffffffffc0200c6a:	daa60613          	addi	a2,a2,-598 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200c6e:	0d100593          	li	a1,209
ffffffffc0200c72:	00001517          	auipc	a0,0x1
ffffffffc0200c76:	db650513          	addi	a0,a0,-586 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200c7a:	d48ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c7e:	00001697          	auipc	a3,0x1
ffffffffc0200c82:	f1a68693          	addi	a3,a3,-230 # ffffffffc0201b98 <etext+0x538>
ffffffffc0200c86:	00001617          	auipc	a2,0x1
ffffffffc0200c8a:	d8a60613          	addi	a2,a2,-630 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200c8e:	0ee00593          	li	a1,238
ffffffffc0200c92:	00001517          	auipc	a0,0x1
ffffffffc0200c96:	d9650513          	addi	a0,a0,-618 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200c9a:	d28ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c9e:	00001697          	auipc	a3,0x1
ffffffffc0200ca2:	e1268693          	addi	a3,a3,-494 # ffffffffc0201ab0 <etext+0x450>
ffffffffc0200ca6:	00001617          	auipc	a2,0x1
ffffffffc0200caa:	d6a60613          	addi	a2,a2,-662 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200cae:	0ec00593          	li	a1,236
ffffffffc0200cb2:	00001517          	auipc	a0,0x1
ffffffffc0200cb6:	d7650513          	addi	a0,a0,-650 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200cba:	d08ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200cbe:	00001697          	auipc	a3,0x1
ffffffffc0200cc2:	dd268693          	addi	a3,a3,-558 # ffffffffc0201a90 <etext+0x430>
ffffffffc0200cc6:	00001617          	auipc	a2,0x1
ffffffffc0200cca:	d4a60613          	addi	a2,a2,-694 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200cce:	0eb00593          	li	a1,235
ffffffffc0200cd2:	00001517          	auipc	a0,0x1
ffffffffc0200cd6:	d5650513          	addi	a0,a0,-682 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200cda:	ce8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200cde:	00001697          	auipc	a3,0x1
ffffffffc0200ce2:	d9268693          	addi	a3,a3,-622 # ffffffffc0201a70 <etext+0x410>
ffffffffc0200ce6:	00001617          	auipc	a2,0x1
ffffffffc0200cea:	d2a60613          	addi	a2,a2,-726 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200cee:	0ea00593          	li	a1,234
ffffffffc0200cf2:	00001517          	auipc	a0,0x1
ffffffffc0200cf6:	d3650513          	addi	a0,a0,-714 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200cfa:	cc8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 3);
ffffffffc0200cfe:	00001697          	auipc	a3,0x1
ffffffffc0200d02:	eb268693          	addi	a3,a3,-334 # ffffffffc0201bb0 <etext+0x550>
ffffffffc0200d06:	00001617          	auipc	a2,0x1
ffffffffc0200d0a:	d0a60613          	addi	a2,a2,-758 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200d0e:	0e800593          	li	a1,232
ffffffffc0200d12:	00001517          	auipc	a0,0x1
ffffffffc0200d16:	d1650513          	addi	a0,a0,-746 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200d1a:	ca8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d1e:	00001697          	auipc	a3,0x1
ffffffffc0200d22:	e7a68693          	addi	a3,a3,-390 # ffffffffc0201b98 <etext+0x538>
ffffffffc0200d26:	00001617          	auipc	a2,0x1
ffffffffc0200d2a:	cea60613          	addi	a2,a2,-790 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200d2e:	0e300593          	li	a1,227
ffffffffc0200d32:	00001517          	auipc	a0,0x1
ffffffffc0200d36:	cf650513          	addi	a0,a0,-778 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200d3a:	c88ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d3e:	00001697          	auipc	a3,0x1
ffffffffc0200d42:	e3a68693          	addi	a3,a3,-454 # ffffffffc0201b78 <etext+0x518>
ffffffffc0200d46:	00001617          	auipc	a2,0x1
ffffffffc0200d4a:	cca60613          	addi	a2,a2,-822 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200d4e:	0da00593          	li	a1,218
ffffffffc0200d52:	00001517          	auipc	a0,0x1
ffffffffc0200d56:	cd650513          	addi	a0,a0,-810 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200d5a:	c68ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d5e:	00001697          	auipc	a3,0x1
ffffffffc0200d62:	dfa68693          	addi	a3,a3,-518 # ffffffffc0201b58 <etext+0x4f8>
ffffffffc0200d66:	00001617          	auipc	a2,0x1
ffffffffc0200d6a:	caa60613          	addi	a2,a2,-854 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200d6e:	0d900593          	li	a1,217
ffffffffc0200d72:	00001517          	auipc	a0,0x1
ffffffffc0200d76:	cb650513          	addi	a0,a0,-842 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200d7a:	c48ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(count == 0);
ffffffffc0200d7e:	00001697          	auipc	a3,0x1
ffffffffc0200d82:	f6268693          	addi	a3,a3,-158 # ffffffffc0201ce0 <etext+0x680>
ffffffffc0200d86:	00001617          	auipc	a2,0x1
ffffffffc0200d8a:	c8a60613          	addi	a2,a2,-886 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200d8e:	14a00593          	li	a1,330
ffffffffc0200d92:	00001517          	auipc	a0,0x1
ffffffffc0200d96:	c9650513          	addi	a0,a0,-874 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200d9a:	c28ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200d9e:	00001697          	auipc	a3,0x1
ffffffffc0200da2:	e5a68693          	addi	a3,a3,-422 # ffffffffc0201bf8 <etext+0x598>
ffffffffc0200da6:	00001617          	auipc	a2,0x1
ffffffffc0200daa:	c6a60613          	addi	a2,a2,-918 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200dae:	13f00593          	li	a1,319
ffffffffc0200db2:	00001517          	auipc	a0,0x1
ffffffffc0200db6:	c7650513          	addi	a0,a0,-906 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200dba:	c08ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200dbe:	00001697          	auipc	a3,0x1
ffffffffc0200dc2:	dda68693          	addi	a3,a3,-550 # ffffffffc0201b98 <etext+0x538>
ffffffffc0200dc6:	00001617          	auipc	a2,0x1
ffffffffc0200dca:	c4a60613          	addi	a2,a2,-950 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200dce:	13900593          	li	a1,313
ffffffffc0200dd2:	00001517          	auipc	a0,0x1
ffffffffc0200dd6:	c5650513          	addi	a0,a0,-938 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200dda:	be8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200dde:	00001697          	auipc	a3,0x1
ffffffffc0200de2:	ee268693          	addi	a3,a3,-286 # ffffffffc0201cc0 <etext+0x660>
ffffffffc0200de6:	00001617          	auipc	a2,0x1
ffffffffc0200dea:	c2a60613          	addi	a2,a2,-982 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200dee:	13800593          	li	a1,312
ffffffffc0200df2:	00001517          	auipc	a0,0x1
ffffffffc0200df6:	c3650513          	addi	a0,a0,-970 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200dfa:	bc8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200dfe:	00001697          	auipc	a3,0x1
ffffffffc0200e02:	eb268693          	addi	a3,a3,-334 # ffffffffc0201cb0 <etext+0x650>
ffffffffc0200e06:	00001617          	auipc	a2,0x1
ffffffffc0200e0a:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200e0e:	13000593          	li	a1,304
ffffffffc0200e12:	00001517          	auipc	a0,0x1
ffffffffc0200e16:	c1650513          	addi	a0,a0,-1002 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200e1a:	ba8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e1e:	00001697          	auipc	a3,0x1
ffffffffc0200e22:	e7a68693          	addi	a3,a3,-390 # ffffffffc0201c98 <etext+0x638>
ffffffffc0200e26:	00001617          	auipc	a2,0x1
ffffffffc0200e2a:	bea60613          	addi	a2,a2,-1046 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200e2e:	12f00593          	li	a1,303
ffffffffc0200e32:	00001517          	auipc	a0,0x1
ffffffffc0200e36:	bf650513          	addi	a0,a0,-1034 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200e3a:	b88ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e3e:	00001697          	auipc	a3,0x1
ffffffffc0200e42:	e3a68693          	addi	a3,a3,-454 # ffffffffc0201c78 <etext+0x618>
ffffffffc0200e46:	00001617          	auipc	a2,0x1
ffffffffc0200e4a:	bca60613          	addi	a2,a2,-1078 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200e4e:	12e00593          	li	a1,302
ffffffffc0200e52:	00001517          	auipc	a0,0x1
ffffffffc0200e56:	bd650513          	addi	a0,a0,-1066 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200e5a:	b68ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200e5e:	00001697          	auipc	a3,0x1
ffffffffc0200e62:	dea68693          	addi	a3,a3,-534 # ffffffffc0201c48 <etext+0x5e8>
ffffffffc0200e66:	00001617          	auipc	a2,0x1
ffffffffc0200e6a:	baa60613          	addi	a2,a2,-1110 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200e6e:	12c00593          	li	a1,300
ffffffffc0200e72:	00001517          	auipc	a0,0x1
ffffffffc0200e76:	bb650513          	addi	a0,a0,-1098 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200e7a:	b48ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e7e:	00001697          	auipc	a3,0x1
ffffffffc0200e82:	db268693          	addi	a3,a3,-590 # ffffffffc0201c30 <etext+0x5d0>
ffffffffc0200e86:	00001617          	auipc	a2,0x1
ffffffffc0200e8a:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200e8e:	12b00593          	li	a1,299
ffffffffc0200e92:	00001517          	auipc	a0,0x1
ffffffffc0200e96:	b9650513          	addi	a0,a0,-1130 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200e9a:	b28ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e9e:	00001697          	auipc	a3,0x1
ffffffffc0200ea2:	cfa68693          	addi	a3,a3,-774 # ffffffffc0201b98 <etext+0x538>
ffffffffc0200ea6:	00001617          	auipc	a2,0x1
ffffffffc0200eaa:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200eae:	11f00593          	li	a1,287
ffffffffc0200eb2:	00001517          	auipc	a0,0x1
ffffffffc0200eb6:	b7650513          	addi	a0,a0,-1162 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200eba:	b08ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200ebe:	00001697          	auipc	a3,0x1
ffffffffc0200ec2:	d5a68693          	addi	a3,a3,-678 # ffffffffc0201c18 <etext+0x5b8>
ffffffffc0200ec6:	00001617          	auipc	a2,0x1
ffffffffc0200eca:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200ece:	11600593          	li	a1,278
ffffffffc0200ed2:	00001517          	auipc	a0,0x1
ffffffffc0200ed6:	b5650513          	addi	a0,a0,-1194 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200eda:	ae8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200ede:	00001697          	auipc	a3,0x1
ffffffffc0200ee2:	d2a68693          	addi	a3,a3,-726 # ffffffffc0201c08 <etext+0x5a8>
ffffffffc0200ee6:	00001617          	auipc	a2,0x1
ffffffffc0200eea:	b2a60613          	addi	a2,a2,-1238 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200eee:	11500593          	li	a1,277
ffffffffc0200ef2:	00001517          	auipc	a0,0x1
ffffffffc0200ef6:	b3650513          	addi	a0,a0,-1226 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200efa:	ac8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200efe:	00001697          	auipc	a3,0x1
ffffffffc0200f02:	cfa68693          	addi	a3,a3,-774 # ffffffffc0201bf8 <etext+0x598>
ffffffffc0200f06:	00001617          	auipc	a2,0x1
ffffffffc0200f0a:	b0a60613          	addi	a2,a2,-1270 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200f0e:	0f700593          	li	a1,247
ffffffffc0200f12:	00001517          	auipc	a0,0x1
ffffffffc0200f16:	b1650513          	addi	a0,a0,-1258 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200f1a:	aa8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f1e:	00001697          	auipc	a3,0x1
ffffffffc0200f22:	c7a68693          	addi	a3,a3,-902 # ffffffffc0201b98 <etext+0x538>
ffffffffc0200f26:	00001617          	auipc	a2,0x1
ffffffffc0200f2a:	aea60613          	addi	a2,a2,-1302 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200f2e:	0f500593          	li	a1,245
ffffffffc0200f32:	00001517          	auipc	a0,0x1
ffffffffc0200f36:	af650513          	addi	a0,a0,-1290 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200f3a:	a88ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f3e:	00001697          	auipc	a3,0x1
ffffffffc0200f42:	c9a68693          	addi	a3,a3,-870 # ffffffffc0201bd8 <etext+0x578>
ffffffffc0200f46:	00001617          	auipc	a2,0x1
ffffffffc0200f4a:	aca60613          	addi	a2,a2,-1334 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc0200f4e:	0f400593          	li	a1,244
ffffffffc0200f52:	00001517          	auipc	a0,0x1
ffffffffc0200f56:	ad650513          	addi	a0,a0,-1322 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc0200f5a:	a68ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200f5e <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200f5e:	1141                	addi	sp,sp,-16
ffffffffc0200f60:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f62:	14058c63          	beqz	a1,ffffffffc02010ba <best_fit_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc0200f66:	00259693          	slli	a3,a1,0x2
ffffffffc0200f6a:	96ae                	add	a3,a3,a1
ffffffffc0200f6c:	068e                	slli	a3,a3,0x3
ffffffffc0200f6e:	96aa                	add	a3,a3,a0
ffffffffc0200f70:	87aa                	mv	a5,a0
ffffffffc0200f72:	00d50e63          	beq	a0,a3,ffffffffc0200f8e <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200f76:	6798                	ld	a4,8(a5)
ffffffffc0200f78:	8b0d                	andi	a4,a4,3
ffffffffc0200f7a:	12071063          	bnez	a4,ffffffffc020109a <best_fit_free_pages+0x13c>
        p->flags = 0;
ffffffffc0200f7e:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200f82:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f86:	02878793          	addi	a5,a5,40
ffffffffc0200f8a:	fed796e3          	bne	a5,a3,ffffffffc0200f76 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200f8e:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200f92:	00004697          	auipc	a3,0x4
ffffffffc0200f96:	08668693          	addi	a3,a3,134 # ffffffffc0205018 <free_area>
ffffffffc0200f9a:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200f9c:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200f9e:	0028e613          	ori	a2,a7,2
    return list->next == list;
ffffffffc0200fa2:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200fa4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200fa6:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200fa8:	9f2d                	addw	a4,a4,a1
ffffffffc0200faa:	ca98                	sw	a4,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200fac:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200fb0:	0ad78b63          	beq	a5,a3,ffffffffc0201066 <best_fit_free_pages+0x108>
            struct Page* page = le2page(le, page_link);
ffffffffc0200fb4:	fe878713          	addi	a4,a5,-24
ffffffffc0200fb8:	0006b303          	ld	t1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200fbc:	4801                	li	a6,0
            if (base < page) {
ffffffffc0200fbe:	00e56a63          	bltu	a0,a4,ffffffffc0200fd2 <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc0200fc2:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200fc4:	06d70563          	beq	a4,a3,ffffffffc020102e <best_fit_free_pages+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0200fc8:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200fca:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200fce:	fee57ae3          	bgeu	a0,a4,ffffffffc0200fc2 <best_fit_free_pages+0x64>
ffffffffc0200fd2:	00080463          	beqz	a6,ffffffffc0200fda <best_fit_free_pages+0x7c>
ffffffffc0200fd6:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200fda:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200fde:	e390                	sd	a2,0(a5)
ffffffffc0200fe0:	00c83423          	sd	a2,8(a6)
    elm->next = next;
ffffffffc0200fe4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200fe6:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200fea:	02d80463          	beq	a6,a3,ffffffffc0201012 <best_fit_free_pages+0xb4>
        if (p + p->property == base) {
ffffffffc0200fee:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200ff2:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc0200ff6:	020e1613          	slli	a2,t3,0x20
ffffffffc0200ffa:	9201                	srli	a2,a2,0x20
ffffffffc0200ffc:	00261713          	slli	a4,a2,0x2
ffffffffc0201000:	9732                	add	a4,a4,a2
ffffffffc0201002:	070e                	slli	a4,a4,0x3
ffffffffc0201004:	971a                	add	a4,a4,t1
ffffffffc0201006:	02e50e63          	beq	a0,a4,ffffffffc0201042 <best_fit_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc020100a:	00d78f63          	beq	a5,a3,ffffffffc0201028 <best_fit_free_pages+0xca>
ffffffffc020100e:	fe878713          	addi	a4,a5,-24
        if (base + base->property == p) {
ffffffffc0201012:	490c                	lw	a1,16(a0)
ffffffffc0201014:	02059613          	slli	a2,a1,0x20
ffffffffc0201018:	9201                	srli	a2,a2,0x20
ffffffffc020101a:	00261693          	slli	a3,a2,0x2
ffffffffc020101e:	96b2                	add	a3,a3,a2
ffffffffc0201020:	068e                	slli	a3,a3,0x3
ffffffffc0201022:	96aa                	add	a3,a3,a0
ffffffffc0201024:	04d70863          	beq	a4,a3,ffffffffc0201074 <best_fit_free_pages+0x116>
}
ffffffffc0201028:	60a2                	ld	ra,8(sp)
ffffffffc020102a:	0141                	addi	sp,sp,16
ffffffffc020102c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020102e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201030:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201032:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201034:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201036:	02d70463          	beq	a4,a3,ffffffffc020105e <best_fit_free_pages+0x100>
    prev->next = next->prev = elm;
ffffffffc020103a:	8332                	mv	t1,a2
ffffffffc020103c:	4805                	li	a6,1
    for (; p != base + n; p ++) {
ffffffffc020103e:	87ba                	mv	a5,a4
ffffffffc0201040:	b769                	j	ffffffffc0200fca <best_fit_free_pages+0x6c>
            p->property += base->property;
ffffffffc0201042:	01c585bb          	addw	a1,a1,t3
ffffffffc0201046:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc020104a:	ffd8f893          	andi	a7,a7,-3
ffffffffc020104e:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0201052:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0201056:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc020105a:	851a                	mv	a0,t1
ffffffffc020105c:	b77d                	j	ffffffffc020100a <best_fit_free_pages+0xac>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020105e:	883e                	mv	a6,a5
ffffffffc0201060:	e290                	sd	a2,0(a3)
ffffffffc0201062:	87b6                	mv	a5,a3
ffffffffc0201064:	b769                	j	ffffffffc0200fee <best_fit_free_pages+0x90>
}
ffffffffc0201066:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201068:	e390                	sd	a2,0(a5)
ffffffffc020106a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020106c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020106e:	ed1c                	sd	a5,24(a0)
ffffffffc0201070:	0141                	addi	sp,sp,16
ffffffffc0201072:	8082                	ret
            base->property += p->property;
ffffffffc0201074:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0201078:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020107c:	0007b803          	ld	a6,0(a5)
ffffffffc0201080:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0201082:	9db5                	addw	a1,a1,a3
ffffffffc0201084:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0201086:	9b75                	andi	a4,a4,-3
ffffffffc0201088:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc020108c:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020108e:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0201092:	01063023          	sd	a6,0(a2)
ffffffffc0201096:	0141                	addi	sp,sp,16
ffffffffc0201098:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020109a:	00001697          	auipc	a3,0x1
ffffffffc020109e:	c6668693          	addi	a3,a3,-922 # ffffffffc0201d00 <etext+0x6a0>
ffffffffc02010a2:	00001617          	auipc	a2,0x1
ffffffffc02010a6:	96e60613          	addi	a2,a2,-1682 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc02010aa:	09100593          	li	a1,145
ffffffffc02010ae:	00001517          	auipc	a0,0x1
ffffffffc02010b2:	97a50513          	addi	a0,a0,-1670 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc02010b6:	90cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc02010ba:	00001697          	auipc	a3,0x1
ffffffffc02010be:	94e68693          	addi	a3,a3,-1714 # ffffffffc0201a08 <etext+0x3a8>
ffffffffc02010c2:	00001617          	auipc	a2,0x1
ffffffffc02010c6:	94e60613          	addi	a2,a2,-1714 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc02010ca:	08e00593          	li	a1,142
ffffffffc02010ce:	00001517          	auipc	a0,0x1
ffffffffc02010d2:	95a50513          	addi	a0,a0,-1702 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc02010d6:	8ecff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02010da <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02010da:	1141                	addi	sp,sp,-16
ffffffffc02010dc:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02010de:	c5f9                	beqz	a1,ffffffffc02011ac <best_fit_init_memmap+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02010e0:	00259693          	slli	a3,a1,0x2
ffffffffc02010e4:	96ae                	add	a3,a3,a1
ffffffffc02010e6:	068e                	slli	a3,a3,0x3
ffffffffc02010e8:	96aa                	add	a3,a3,a0
ffffffffc02010ea:	87aa                	mv	a5,a0
ffffffffc02010ec:	00d50f63          	beq	a0,a3,ffffffffc020110a <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc02010f0:	6798                	ld	a4,8(a5)
ffffffffc02010f2:	8b05                	andi	a4,a4,1
ffffffffc02010f4:	cf41                	beqz	a4,ffffffffc020118c <best_fit_init_memmap+0xb2>
        p->flags = p->property = 0;
ffffffffc02010f6:	0007a823          	sw	zero,16(a5)
ffffffffc02010fa:	0007b423          	sd	zero,8(a5)
ffffffffc02010fe:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201102:	02878793          	addi	a5,a5,40
ffffffffc0201106:	fed795e3          	bne	a5,a3,ffffffffc02010f0 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc020110a:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc020110c:	00004697          	auipc	a3,0x4
ffffffffc0201110:	f0c68693          	addi	a3,a3,-244 # ffffffffc0205018 <free_area>
ffffffffc0201114:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0201116:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0201118:	00266613          	ori	a2,a2,2
    return list->next == list;
ffffffffc020111c:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc020111e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201120:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0201122:	9db9                	addw	a1,a1,a4
ffffffffc0201124:	ca8c                	sw	a1,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201126:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc020112a:	04d78a63          	beq	a5,a3,ffffffffc020117e <best_fit_init_memmap+0xa4>
            struct Page* page = le2page(le, page_link);
ffffffffc020112e:	fe878713          	addi	a4,a5,-24
ffffffffc0201132:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201136:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201138:	00e56a63          	bltu	a0,a4,ffffffffc020114c <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc020113c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020113e:	02d70263          	beq	a4,a3,ffffffffc0201162 <best_fit_init_memmap+0x88>
    for (; p != base + n; p ++) {
ffffffffc0201142:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201144:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201148:	fee57ae3          	bgeu	a0,a4,ffffffffc020113c <best_fit_init_memmap+0x62>
ffffffffc020114c:	c199                	beqz	a1,ffffffffc0201152 <best_fit_init_memmap+0x78>
ffffffffc020114e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201152:	6398                	ld	a4,0(a5)
}
ffffffffc0201154:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201156:	e390                	sd	a2,0(a5)
ffffffffc0201158:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020115a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020115c:	ed18                	sd	a4,24(a0)
ffffffffc020115e:	0141                	addi	sp,sp,16
ffffffffc0201160:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201162:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201164:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201166:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201168:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020116a:	00d70663          	beq	a4,a3,ffffffffc0201176 <best_fit_init_memmap+0x9c>
    prev->next = next->prev = elm;
ffffffffc020116e:	8832                	mv	a6,a2
ffffffffc0201170:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201172:	87ba                	mv	a5,a4
ffffffffc0201174:	bfc1                	j	ffffffffc0201144 <best_fit_init_memmap+0x6a>
}
ffffffffc0201176:	60a2                	ld	ra,8(sp)
ffffffffc0201178:	e290                	sd	a2,0(a3)
ffffffffc020117a:	0141                	addi	sp,sp,16
ffffffffc020117c:	8082                	ret
ffffffffc020117e:	60a2                	ld	ra,8(sp)
ffffffffc0201180:	e390                	sd	a2,0(a5)
ffffffffc0201182:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201184:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201186:	ed1c                	sd	a5,24(a0)
ffffffffc0201188:	0141                	addi	sp,sp,16
ffffffffc020118a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020118c:	00001697          	auipc	a3,0x1
ffffffffc0201190:	b9c68693          	addi	a3,a3,-1124 # ffffffffc0201d28 <etext+0x6c8>
ffffffffc0201194:	00001617          	auipc	a2,0x1
ffffffffc0201198:	87c60613          	addi	a2,a2,-1924 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc020119c:	04a00593          	li	a1,74
ffffffffc02011a0:	00001517          	auipc	a0,0x1
ffffffffc02011a4:	88850513          	addi	a0,a0,-1912 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc02011a8:	81aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc02011ac:	00001697          	auipc	a3,0x1
ffffffffc02011b0:	85c68693          	addi	a3,a3,-1956 # ffffffffc0201a08 <etext+0x3a8>
ffffffffc02011b4:	00001617          	auipc	a2,0x1
ffffffffc02011b8:	85c60613          	addi	a2,a2,-1956 # ffffffffc0201a10 <etext+0x3b0>
ffffffffc02011bc:	04700593          	li	a1,71
ffffffffc02011c0:	00001517          	auipc	a0,0x1
ffffffffc02011c4:	86850513          	addi	a0,a0,-1944 # ffffffffc0201a28 <etext+0x3c8>
ffffffffc02011c8:	ffbfe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02011cc <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02011cc:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02011d0:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02011d2:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02011d4:	cb81                	beqz	a5,ffffffffc02011e4 <strlen+0x18>
        cnt ++;
ffffffffc02011d6:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02011d8:	00a707b3          	add	a5,a4,a0
ffffffffc02011dc:	0007c783          	lbu	a5,0(a5)
ffffffffc02011e0:	fbfd                	bnez	a5,ffffffffc02011d6 <strlen+0xa>
ffffffffc02011e2:	8082                	ret
    }
    return cnt;
}
ffffffffc02011e4:	8082                	ret

ffffffffc02011e6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02011e6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02011e8:	e589                	bnez	a1,ffffffffc02011f2 <strnlen+0xc>
ffffffffc02011ea:	a811                	j	ffffffffc02011fe <strnlen+0x18>
        cnt ++;
ffffffffc02011ec:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02011ee:	00f58863          	beq	a1,a5,ffffffffc02011fe <strnlen+0x18>
ffffffffc02011f2:	00f50733          	add	a4,a0,a5
ffffffffc02011f6:	00074703          	lbu	a4,0(a4) # fffffffffff80000 <end+0x3fd7af88>
ffffffffc02011fa:	fb6d                	bnez	a4,ffffffffc02011ec <strnlen+0x6>
ffffffffc02011fc:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02011fe:	852e                	mv	a0,a1
ffffffffc0201200:	8082                	ret

ffffffffc0201202 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201202:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201206:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020120a:	cb89                	beqz	a5,ffffffffc020121c <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020120c:	0505                	addi	a0,a0,1
ffffffffc020120e:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201210:	fee789e3          	beq	a5,a4,ffffffffc0201202 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201214:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201218:	9d19                	subw	a0,a0,a4
ffffffffc020121a:	8082                	ret
ffffffffc020121c:	4501                	li	a0,0
ffffffffc020121e:	bfed                	j	ffffffffc0201218 <strcmp+0x16>

ffffffffc0201220 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201220:	c20d                	beqz	a2,ffffffffc0201242 <strncmp+0x22>
ffffffffc0201222:	962e                	add	a2,a2,a1
ffffffffc0201224:	a031                	j	ffffffffc0201230 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201226:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201228:	00e79a63          	bne	a5,a4,ffffffffc020123c <strncmp+0x1c>
ffffffffc020122c:	00b60b63          	beq	a2,a1,ffffffffc0201242 <strncmp+0x22>
ffffffffc0201230:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201234:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201236:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020123a:	f7f5                	bnez	a5,ffffffffc0201226 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020123c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201240:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201242:	4501                	li	a0,0
ffffffffc0201244:	8082                	ret

ffffffffc0201246 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201246:	ca01                	beqz	a2,ffffffffc0201256 <memset+0x10>
ffffffffc0201248:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020124a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020124c:	0785                	addi	a5,a5,1
ffffffffc020124e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201252:	fec79de3          	bne	a5,a2,ffffffffc020124c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201256:	8082                	ret

ffffffffc0201258 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201258:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020125c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020125e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201262:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201264:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201268:	f022                	sd	s0,32(sp)
ffffffffc020126a:	ec26                	sd	s1,24(sp)
ffffffffc020126c:	e84a                	sd	s2,16(sp)
ffffffffc020126e:	f406                	sd	ra,40(sp)
ffffffffc0201270:	e44e                	sd	s3,8(sp)
ffffffffc0201272:	84aa                	mv	s1,a0
ffffffffc0201274:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201276:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020127a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020127c:	03067e63          	bgeu	a2,a6,ffffffffc02012b8 <printnum+0x60>
ffffffffc0201280:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201282:	00805763          	blez	s0,ffffffffc0201290 <printnum+0x38>
ffffffffc0201286:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201288:	85ca                	mv	a1,s2
ffffffffc020128a:	854e                	mv	a0,s3
ffffffffc020128c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020128e:	fc65                	bnez	s0,ffffffffc0201286 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201290:	1a02                	slli	s4,s4,0x20
ffffffffc0201292:	00001797          	auipc	a5,0x1
ffffffffc0201296:	af678793          	addi	a5,a5,-1290 # ffffffffc0201d88 <best_fit_pmm_manager+0x38>
ffffffffc020129a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020129e:	9a3e                	add	s4,s4,a5
}
ffffffffc02012a0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012a2:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02012a6:	70a2                	ld	ra,40(sp)
ffffffffc02012a8:	69a2                	ld	s3,8(sp)
ffffffffc02012aa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012ac:	85ca                	mv	a1,s2
ffffffffc02012ae:	87a6                	mv	a5,s1
}
ffffffffc02012b0:	6942                	ld	s2,16(sp)
ffffffffc02012b2:	64e2                	ld	s1,24(sp)
ffffffffc02012b4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012b6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02012b8:	03065633          	divu	a2,a2,a6
ffffffffc02012bc:	8722                	mv	a4,s0
ffffffffc02012be:	f9bff0ef          	jal	ra,ffffffffc0201258 <printnum>
ffffffffc02012c2:	b7f9                	j	ffffffffc0201290 <printnum+0x38>

ffffffffc02012c4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02012c4:	7119                	addi	sp,sp,-128
ffffffffc02012c6:	f4a6                	sd	s1,104(sp)
ffffffffc02012c8:	f0ca                	sd	s2,96(sp)
ffffffffc02012ca:	ecce                	sd	s3,88(sp)
ffffffffc02012cc:	e8d2                	sd	s4,80(sp)
ffffffffc02012ce:	e4d6                	sd	s5,72(sp)
ffffffffc02012d0:	e0da                	sd	s6,64(sp)
ffffffffc02012d2:	fc5e                	sd	s7,56(sp)
ffffffffc02012d4:	f06a                	sd	s10,32(sp)
ffffffffc02012d6:	fc86                	sd	ra,120(sp)
ffffffffc02012d8:	f8a2                	sd	s0,112(sp)
ffffffffc02012da:	f862                	sd	s8,48(sp)
ffffffffc02012dc:	f466                	sd	s9,40(sp)
ffffffffc02012de:	ec6e                	sd	s11,24(sp)
ffffffffc02012e0:	892a                	mv	s2,a0
ffffffffc02012e2:	84ae                	mv	s1,a1
ffffffffc02012e4:	8d32                	mv	s10,a2
ffffffffc02012e6:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012e8:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02012ec:	5b7d                	li	s6,-1
ffffffffc02012ee:	00001a97          	auipc	s5,0x1
ffffffffc02012f2:	acea8a93          	addi	s5,s5,-1330 # ffffffffc0201dbc <best_fit_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02012f6:	00001b97          	auipc	s7,0x1
ffffffffc02012fa:	ca2b8b93          	addi	s7,s7,-862 # ffffffffc0201f98 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012fe:	000d4503          	lbu	a0,0(s10)
ffffffffc0201302:	001d0413          	addi	s0,s10,1
ffffffffc0201306:	01350a63          	beq	a0,s3,ffffffffc020131a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020130a:	c121                	beqz	a0,ffffffffc020134a <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020130c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020130e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201310:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201312:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201316:	ff351ae3          	bne	a0,s3,ffffffffc020130a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020131a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020131e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201322:	4c81                	li	s9,0
ffffffffc0201324:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201326:	5c7d                	li	s8,-1
ffffffffc0201328:	5dfd                	li	s11,-1
ffffffffc020132a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020132e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201330:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201334:	0ff5f593          	zext.b	a1,a1
ffffffffc0201338:	00140d13          	addi	s10,s0,1
ffffffffc020133c:	04b56263          	bltu	a0,a1,ffffffffc0201380 <vprintfmt+0xbc>
ffffffffc0201340:	058a                	slli	a1,a1,0x2
ffffffffc0201342:	95d6                	add	a1,a1,s5
ffffffffc0201344:	4194                	lw	a3,0(a1)
ffffffffc0201346:	96d6                	add	a3,a3,s5
ffffffffc0201348:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020134a:	70e6                	ld	ra,120(sp)
ffffffffc020134c:	7446                	ld	s0,112(sp)
ffffffffc020134e:	74a6                	ld	s1,104(sp)
ffffffffc0201350:	7906                	ld	s2,96(sp)
ffffffffc0201352:	69e6                	ld	s3,88(sp)
ffffffffc0201354:	6a46                	ld	s4,80(sp)
ffffffffc0201356:	6aa6                	ld	s5,72(sp)
ffffffffc0201358:	6b06                	ld	s6,64(sp)
ffffffffc020135a:	7be2                	ld	s7,56(sp)
ffffffffc020135c:	7c42                	ld	s8,48(sp)
ffffffffc020135e:	7ca2                	ld	s9,40(sp)
ffffffffc0201360:	7d02                	ld	s10,32(sp)
ffffffffc0201362:	6de2                	ld	s11,24(sp)
ffffffffc0201364:	6109                	addi	sp,sp,128
ffffffffc0201366:	8082                	ret
            padc = '0';
ffffffffc0201368:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020136a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020136e:	846a                	mv	s0,s10
ffffffffc0201370:	00140d13          	addi	s10,s0,1
ffffffffc0201374:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201378:	0ff5f593          	zext.b	a1,a1
ffffffffc020137c:	fcb572e3          	bgeu	a0,a1,ffffffffc0201340 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201380:	85a6                	mv	a1,s1
ffffffffc0201382:	02500513          	li	a0,37
ffffffffc0201386:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201388:	fff44783          	lbu	a5,-1(s0)
ffffffffc020138c:	8d22                	mv	s10,s0
ffffffffc020138e:	f73788e3          	beq	a5,s3,ffffffffc02012fe <vprintfmt+0x3a>
ffffffffc0201392:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201396:	1d7d                	addi	s10,s10,-1
ffffffffc0201398:	ff379de3          	bne	a5,s3,ffffffffc0201392 <vprintfmt+0xce>
ffffffffc020139c:	b78d                	j	ffffffffc02012fe <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020139e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02013a2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013a6:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02013a8:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02013ac:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013b0:	02d86463          	bltu	a6,a3,ffffffffc02013d8 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02013b4:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02013b8:	002c169b          	slliw	a3,s8,0x2
ffffffffc02013bc:	0186873b          	addw	a4,a3,s8
ffffffffc02013c0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02013c4:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02013c6:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02013ca:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02013cc:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02013d0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013d4:	fed870e3          	bgeu	a6,a3,ffffffffc02013b4 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02013d8:	f40ddce3          	bgez	s11,ffffffffc0201330 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02013dc:	8de2                	mv	s11,s8
ffffffffc02013de:	5c7d                	li	s8,-1
ffffffffc02013e0:	bf81                	j	ffffffffc0201330 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02013e2:	fffdc693          	not	a3,s11
ffffffffc02013e6:	96fd                	srai	a3,a3,0x3f
ffffffffc02013e8:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013ec:	00144603          	lbu	a2,1(s0)
ffffffffc02013f0:	2d81                	sext.w	s11,s11
ffffffffc02013f2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013f4:	bf35                	j	ffffffffc0201330 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02013f6:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013fa:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02013fe:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201400:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201402:	bfd9                	j	ffffffffc02013d8 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201404:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201406:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020140a:	01174463          	blt	a4,a7,ffffffffc0201412 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020140e:	1a088e63          	beqz	a7,ffffffffc02015ca <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201412:	000a3603          	ld	a2,0(s4)
ffffffffc0201416:	46c1                	li	a3,16
ffffffffc0201418:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020141a:	2781                	sext.w	a5,a5
ffffffffc020141c:	876e                	mv	a4,s11
ffffffffc020141e:	85a6                	mv	a1,s1
ffffffffc0201420:	854a                	mv	a0,s2
ffffffffc0201422:	e37ff0ef          	jal	ra,ffffffffc0201258 <printnum>
            break;
ffffffffc0201426:	bde1                	j	ffffffffc02012fe <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201428:	000a2503          	lw	a0,0(s4)
ffffffffc020142c:	85a6                	mv	a1,s1
ffffffffc020142e:	0a21                	addi	s4,s4,8
ffffffffc0201430:	9902                	jalr	s2
            break;
ffffffffc0201432:	b5f1                	j	ffffffffc02012fe <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201434:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201436:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020143a:	01174463          	blt	a4,a7,ffffffffc0201442 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020143e:	18088163          	beqz	a7,ffffffffc02015c0 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201442:	000a3603          	ld	a2,0(s4)
ffffffffc0201446:	46a9                	li	a3,10
ffffffffc0201448:	8a2e                	mv	s4,a1
ffffffffc020144a:	bfc1                	j	ffffffffc020141a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020144c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201450:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201452:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201454:	bdf1                	j	ffffffffc0201330 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201456:	85a6                	mv	a1,s1
ffffffffc0201458:	02500513          	li	a0,37
ffffffffc020145c:	9902                	jalr	s2
            break;
ffffffffc020145e:	b545                	j	ffffffffc02012fe <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201460:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201464:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201466:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201468:	b5e1                	j	ffffffffc0201330 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020146a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020146c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201470:	01174463          	blt	a4,a7,ffffffffc0201478 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201474:	14088163          	beqz	a7,ffffffffc02015b6 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201478:	000a3603          	ld	a2,0(s4)
ffffffffc020147c:	46a1                	li	a3,8
ffffffffc020147e:	8a2e                	mv	s4,a1
ffffffffc0201480:	bf69                	j	ffffffffc020141a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201482:	03000513          	li	a0,48
ffffffffc0201486:	85a6                	mv	a1,s1
ffffffffc0201488:	e03e                	sd	a5,0(sp)
ffffffffc020148a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020148c:	85a6                	mv	a1,s1
ffffffffc020148e:	07800513          	li	a0,120
ffffffffc0201492:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201494:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201496:	6782                	ld	a5,0(sp)
ffffffffc0201498:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020149a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020149e:	bfb5                	j	ffffffffc020141a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014a0:	000a3403          	ld	s0,0(s4)
ffffffffc02014a4:	008a0713          	addi	a4,s4,8
ffffffffc02014a8:	e03a                	sd	a4,0(sp)
ffffffffc02014aa:	14040263          	beqz	s0,ffffffffc02015ee <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02014ae:	0fb05763          	blez	s11,ffffffffc020159c <vprintfmt+0x2d8>
ffffffffc02014b2:	02d00693          	li	a3,45
ffffffffc02014b6:	0cd79163          	bne	a5,a3,ffffffffc0201578 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014ba:	00044783          	lbu	a5,0(s0)
ffffffffc02014be:	0007851b          	sext.w	a0,a5
ffffffffc02014c2:	cf85                	beqz	a5,ffffffffc02014fa <vprintfmt+0x236>
ffffffffc02014c4:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014c8:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014cc:	000c4563          	bltz	s8,ffffffffc02014d6 <vprintfmt+0x212>
ffffffffc02014d0:	3c7d                	addiw	s8,s8,-1
ffffffffc02014d2:	036c0263          	beq	s8,s6,ffffffffc02014f6 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02014d6:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014d8:	0e0c8e63          	beqz	s9,ffffffffc02015d4 <vprintfmt+0x310>
ffffffffc02014dc:	3781                	addiw	a5,a5,-32
ffffffffc02014de:	0ef47b63          	bgeu	s0,a5,ffffffffc02015d4 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02014e2:	03f00513          	li	a0,63
ffffffffc02014e6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014e8:	000a4783          	lbu	a5,0(s4)
ffffffffc02014ec:	3dfd                	addiw	s11,s11,-1
ffffffffc02014ee:	0a05                	addi	s4,s4,1
ffffffffc02014f0:	0007851b          	sext.w	a0,a5
ffffffffc02014f4:	ffe1                	bnez	a5,ffffffffc02014cc <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02014f6:	01b05963          	blez	s11,ffffffffc0201508 <vprintfmt+0x244>
ffffffffc02014fa:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02014fc:	85a6                	mv	a1,s1
ffffffffc02014fe:	02000513          	li	a0,32
ffffffffc0201502:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201504:	fe0d9be3          	bnez	s11,ffffffffc02014fa <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201508:	6a02                	ld	s4,0(sp)
ffffffffc020150a:	bbd5                	j	ffffffffc02012fe <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020150c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020150e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201512:	01174463          	blt	a4,a7,ffffffffc020151a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201516:	08088d63          	beqz	a7,ffffffffc02015b0 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020151a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020151e:	0a044d63          	bltz	s0,ffffffffc02015d8 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201522:	8622                	mv	a2,s0
ffffffffc0201524:	8a66                	mv	s4,s9
ffffffffc0201526:	46a9                	li	a3,10
ffffffffc0201528:	bdcd                	j	ffffffffc020141a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020152a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020152e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201530:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201532:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201536:	8fb5                	xor	a5,a5,a3
ffffffffc0201538:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020153c:	02d74163          	blt	a4,a3,ffffffffc020155e <vprintfmt+0x29a>
ffffffffc0201540:	00369793          	slli	a5,a3,0x3
ffffffffc0201544:	97de                	add	a5,a5,s7
ffffffffc0201546:	639c                	ld	a5,0(a5)
ffffffffc0201548:	cb99                	beqz	a5,ffffffffc020155e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020154a:	86be                	mv	a3,a5
ffffffffc020154c:	00001617          	auipc	a2,0x1
ffffffffc0201550:	86c60613          	addi	a2,a2,-1940 # ffffffffc0201db8 <best_fit_pmm_manager+0x68>
ffffffffc0201554:	85a6                	mv	a1,s1
ffffffffc0201556:	854a                	mv	a0,s2
ffffffffc0201558:	0ce000ef          	jal	ra,ffffffffc0201626 <printfmt>
ffffffffc020155c:	b34d                	j	ffffffffc02012fe <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020155e:	00001617          	auipc	a2,0x1
ffffffffc0201562:	84a60613          	addi	a2,a2,-1974 # ffffffffc0201da8 <best_fit_pmm_manager+0x58>
ffffffffc0201566:	85a6                	mv	a1,s1
ffffffffc0201568:	854a                	mv	a0,s2
ffffffffc020156a:	0bc000ef          	jal	ra,ffffffffc0201626 <printfmt>
ffffffffc020156e:	bb41                	j	ffffffffc02012fe <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201570:	00001417          	auipc	s0,0x1
ffffffffc0201574:	83040413          	addi	s0,s0,-2000 # ffffffffc0201da0 <best_fit_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201578:	85e2                	mv	a1,s8
ffffffffc020157a:	8522                	mv	a0,s0
ffffffffc020157c:	e43e                	sd	a5,8(sp)
ffffffffc020157e:	c69ff0ef          	jal	ra,ffffffffc02011e6 <strnlen>
ffffffffc0201582:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201586:	01b05b63          	blez	s11,ffffffffc020159c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020158a:	67a2                	ld	a5,8(sp)
ffffffffc020158c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201590:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201592:	85a6                	mv	a1,s1
ffffffffc0201594:	8552                	mv	a0,s4
ffffffffc0201596:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201598:	fe0d9ce3          	bnez	s11,ffffffffc0201590 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020159c:	00044783          	lbu	a5,0(s0)
ffffffffc02015a0:	00140a13          	addi	s4,s0,1
ffffffffc02015a4:	0007851b          	sext.w	a0,a5
ffffffffc02015a8:	d3a5                	beqz	a5,ffffffffc0201508 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02015aa:	05e00413          	li	s0,94
ffffffffc02015ae:	bf39                	j	ffffffffc02014cc <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02015b0:	000a2403          	lw	s0,0(s4)
ffffffffc02015b4:	b7ad                	j	ffffffffc020151e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02015b6:	000a6603          	lwu	a2,0(s4)
ffffffffc02015ba:	46a1                	li	a3,8
ffffffffc02015bc:	8a2e                	mv	s4,a1
ffffffffc02015be:	bdb1                	j	ffffffffc020141a <vprintfmt+0x156>
ffffffffc02015c0:	000a6603          	lwu	a2,0(s4)
ffffffffc02015c4:	46a9                	li	a3,10
ffffffffc02015c6:	8a2e                	mv	s4,a1
ffffffffc02015c8:	bd89                	j	ffffffffc020141a <vprintfmt+0x156>
ffffffffc02015ca:	000a6603          	lwu	a2,0(s4)
ffffffffc02015ce:	46c1                	li	a3,16
ffffffffc02015d0:	8a2e                	mv	s4,a1
ffffffffc02015d2:	b5a1                	j	ffffffffc020141a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02015d4:	9902                	jalr	s2
ffffffffc02015d6:	bf09                	j	ffffffffc02014e8 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02015d8:	85a6                	mv	a1,s1
ffffffffc02015da:	02d00513          	li	a0,45
ffffffffc02015de:	e03e                	sd	a5,0(sp)
ffffffffc02015e0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02015e2:	6782                	ld	a5,0(sp)
ffffffffc02015e4:	8a66                	mv	s4,s9
ffffffffc02015e6:	40800633          	neg	a2,s0
ffffffffc02015ea:	46a9                	li	a3,10
ffffffffc02015ec:	b53d                	j	ffffffffc020141a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02015ee:	03b05163          	blez	s11,ffffffffc0201610 <vprintfmt+0x34c>
ffffffffc02015f2:	02d00693          	li	a3,45
ffffffffc02015f6:	f6d79de3          	bne	a5,a3,ffffffffc0201570 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02015fa:	00000417          	auipc	s0,0x0
ffffffffc02015fe:	7a640413          	addi	s0,s0,1958 # ffffffffc0201da0 <best_fit_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201602:	02800793          	li	a5,40
ffffffffc0201606:	02800513          	li	a0,40
ffffffffc020160a:	00140a13          	addi	s4,s0,1
ffffffffc020160e:	bd6d                	j	ffffffffc02014c8 <vprintfmt+0x204>
ffffffffc0201610:	00000a17          	auipc	s4,0x0
ffffffffc0201614:	791a0a13          	addi	s4,s4,1937 # ffffffffc0201da1 <best_fit_pmm_manager+0x51>
ffffffffc0201618:	02800513          	li	a0,40
ffffffffc020161c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201620:	05e00413          	li	s0,94
ffffffffc0201624:	b565                	j	ffffffffc02014cc <vprintfmt+0x208>

ffffffffc0201626 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201626:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201628:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020162c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020162e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201630:	ec06                	sd	ra,24(sp)
ffffffffc0201632:	f83a                	sd	a4,48(sp)
ffffffffc0201634:	fc3e                	sd	a5,56(sp)
ffffffffc0201636:	e0c2                	sd	a6,64(sp)
ffffffffc0201638:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020163a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020163c:	c89ff0ef          	jal	ra,ffffffffc02012c4 <vprintfmt>
}
ffffffffc0201640:	60e2                	ld	ra,24(sp)
ffffffffc0201642:	6161                	addi	sp,sp,80
ffffffffc0201644:	8082                	ret

ffffffffc0201646 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201646:	4781                	li	a5,0
ffffffffc0201648:	00004717          	auipc	a4,0x4
ffffffffc020164c:	9c873703          	ld	a4,-1592(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201650:	88ba                	mv	a7,a4
ffffffffc0201652:	852a                	mv	a0,a0
ffffffffc0201654:	85be                	mv	a1,a5
ffffffffc0201656:	863e                	mv	a2,a5
ffffffffc0201658:	00000073          	ecall
ffffffffc020165c:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc020165e:	8082                	ret
