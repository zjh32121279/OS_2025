
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
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
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49a60613          	addi	a2,a2,1178 # ffffffffc020d4ec <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	1fb030ef          	jal	ra,ffffffffc0203a5c <memset>
    dtb_init();
ffffffffc0200066:	452000ef          	jal	ra,ffffffffc02004b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	053000ef          	jal	ra,ffffffffc02008bc <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e4258593          	addi	a1,a1,-446 # ffffffffc0203eb0 <etext+0x2>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e5a50513          	addi	a0,a0,-422 # ffffffffc0203ed0 <etext+0x22>
ffffffffc020007e:	062000ef          	jal	ra,ffffffffc02000e0 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1b8000ef          	jal	ra,ffffffffc020023a <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	250010ef          	jal	ra,ffffffffc02012d6 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	0a5000ef          	jal	ra,ffffffffc020092e <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	0af000ef          	jal	ra,ffffffffc020093c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	7b9010ef          	jal	ra,ffffffffc020204a <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	5f4030ef          	jal	ra,ffffffffc020368a <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	7ce000ef          	jal	ra,ffffffffc0200868 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	093000ef          	jal	ra,ffffffffc0200930 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	037030ef          	jal	ra,ffffffffc02038d8 <cpu_idle>

ffffffffc02000a6 <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc02000a6:	1141                	addi	sp,sp,-16
ffffffffc02000a8:	e022                	sd	s0,0(sp)
ffffffffc02000aa:	e406                	sd	ra,8(sp)
ffffffffc02000ac:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000ae:	011000ef          	jal	ra,ffffffffc02008be <cons_putc>
    (*cnt)++;
ffffffffc02000b2:	401c                	lw	a5,0(s0)
}
ffffffffc02000b4:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc02000b6:	2785                	addiw	a5,a5,1
ffffffffc02000b8:	c01c                	sw	a5,0(s0)
}
ffffffffc02000ba:	6402                	ld	s0,0(sp)
ffffffffc02000bc:	0141                	addi	sp,sp,16
ffffffffc02000be:	8082                	ret

ffffffffc02000c0 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc02000c0:	1101                	addi	sp,sp,-32
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fe050513          	addi	a0,a0,-32 # ffffffffc02000a6 <cputch>
ffffffffc02000ce:	006c                	addi	a1,sp,12
{
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d2:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000d4:	243030ef          	jal	ra,ffffffffc0203b16 <vprintfmt>
    return cnt;
}
ffffffffc02000d8:	60e2                	ld	ra,24(sp)
ffffffffc02000da:	4532                	lw	a0,12(sp)
ffffffffc02000dc:	6105                	addi	sp,sp,32
ffffffffc02000de:	8082                	ret

ffffffffc02000e0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc02000e0:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e2:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc02000e6:	8e2a                	mv	t3,a0
ffffffffc02000e8:	f42e                	sd	a1,40(sp)
ffffffffc02000ea:	f832                	sd	a2,48(sp)
ffffffffc02000ec:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000ee:	00000517          	auipc	a0,0x0
ffffffffc02000f2:	fb850513          	addi	a0,a0,-72 # ffffffffc02000a6 <cputch>
ffffffffc02000f6:	004c                	addi	a1,sp,4
ffffffffc02000f8:	869a                	mv	a3,t1
ffffffffc02000fa:	8672                	mv	a2,t3
{
ffffffffc02000fc:	ec06                	sd	ra,24(sp)
ffffffffc02000fe:	e0ba                	sd	a4,64(sp)
ffffffffc0200100:	e4be                	sd	a5,72(sp)
ffffffffc0200102:	e8c2                	sd	a6,80(sp)
ffffffffc0200104:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200106:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200108:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020010a:	20d030ef          	jal	ra,ffffffffc0203b16 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020010e:	60e2                	ld	ra,24(sp)
ffffffffc0200110:	4512                	lw	a0,4(sp)
ffffffffc0200112:	6125                	addi	sp,sp,96
ffffffffc0200114:	8082                	ret

ffffffffc0200116 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc0200116:	7a80006f          	j	ffffffffc02008be <cons_putc>

ffffffffc020011a <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020011a:	1141                	addi	sp,sp,-16
ffffffffc020011c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020011e:	7d4000ef          	jal	ra,ffffffffc02008f2 <cons_getc>
ffffffffc0200122:	dd75                	beqz	a0,ffffffffc020011e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200124:	60a2                	ld	ra,8(sp)
ffffffffc0200126:	0141                	addi	sp,sp,16
ffffffffc0200128:	8082                	ret

ffffffffc020012a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020012a:	715d                	addi	sp,sp,-80
ffffffffc020012c:	e486                	sd	ra,72(sp)
ffffffffc020012e:	e0a6                	sd	s1,64(sp)
ffffffffc0200130:	fc4a                	sd	s2,56(sp)
ffffffffc0200132:	f84e                	sd	s3,48(sp)
ffffffffc0200134:	f452                	sd	s4,40(sp)
ffffffffc0200136:	f056                	sd	s5,32(sp)
ffffffffc0200138:	ec5a                	sd	s6,24(sp)
ffffffffc020013a:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc020013c:	c901                	beqz	a0,ffffffffc020014c <readline+0x22>
ffffffffc020013e:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0200140:	00004517          	auipc	a0,0x4
ffffffffc0200144:	d9850513          	addi	a0,a0,-616 # ffffffffc0203ed8 <etext+0x2a>
ffffffffc0200148:	f99ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
readline(const char *prompt) {
ffffffffc020014c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020014e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0200150:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200152:	4aa9                	li	s5,10
ffffffffc0200154:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200156:	00009b97          	auipc	s7,0x9
ffffffffc020015a:	edab8b93          	addi	s7,s7,-294 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020015e:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0200162:	fb9ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200166:	00054a63          	bltz	a0,ffffffffc020017a <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020016a:	00a95a63          	bge	s2,a0,ffffffffc020017e <readline+0x54>
ffffffffc020016e:	029a5263          	bge	s4,s1,ffffffffc0200192 <readline+0x68>
        c = getchar();
ffffffffc0200172:	fa9ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200176:	fe055ae3          	bgez	a0,ffffffffc020016a <readline+0x40>
            return NULL;
ffffffffc020017a:	4501                	li	a0,0
ffffffffc020017c:	a091                	j	ffffffffc02001c0 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020017e:	03351463          	bne	a0,s3,ffffffffc02001a6 <readline+0x7c>
ffffffffc0200182:	e8a9                	bnez	s1,ffffffffc02001d4 <readline+0xaa>
        c = getchar();
ffffffffc0200184:	f97ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200188:	fe0549e3          	bltz	a0,ffffffffc020017a <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020018c:	fea959e3          	bge	s2,a0,ffffffffc020017e <readline+0x54>
ffffffffc0200190:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200192:	e42a                	sd	a0,8(sp)
ffffffffc0200194:	f83ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i ++] = c;
ffffffffc0200198:	6522                	ld	a0,8(sp)
ffffffffc020019a:	009b87b3          	add	a5,s7,s1
ffffffffc020019e:	2485                	addiw	s1,s1,1
ffffffffc02001a0:	00a78023          	sb	a0,0(a5)
ffffffffc02001a4:	bf7d                	j	ffffffffc0200162 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02001a6:	01550463          	beq	a0,s5,ffffffffc02001ae <readline+0x84>
ffffffffc02001aa:	fb651ce3          	bne	a0,s6,ffffffffc0200162 <readline+0x38>
            cputchar(c);
ffffffffc02001ae:	f69ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i] = '\0';
ffffffffc02001b2:	00009517          	auipc	a0,0x9
ffffffffc02001b6:	e7e50513          	addi	a0,a0,-386 # ffffffffc0209030 <buf>
ffffffffc02001ba:	94aa                	add	s1,s1,a0
ffffffffc02001bc:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001c0:	60a6                	ld	ra,72(sp)
ffffffffc02001c2:	6486                	ld	s1,64(sp)
ffffffffc02001c4:	7962                	ld	s2,56(sp)
ffffffffc02001c6:	79c2                	ld	s3,48(sp)
ffffffffc02001c8:	7a22                	ld	s4,40(sp)
ffffffffc02001ca:	7a82                	ld	s5,32(sp)
ffffffffc02001cc:	6b62                	ld	s6,24(sp)
ffffffffc02001ce:	6bc2                	ld	s7,16(sp)
ffffffffc02001d0:	6161                	addi	sp,sp,80
ffffffffc02001d2:	8082                	ret
            cputchar(c);
ffffffffc02001d4:	4521                	li	a0,8
ffffffffc02001d6:	f41ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            i --;
ffffffffc02001da:	34fd                	addiw	s1,s1,-1
ffffffffc02001dc:	b759                	j	ffffffffc0200162 <readline+0x38>

ffffffffc02001de <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001de:	0000d317          	auipc	t1,0xd
ffffffffc02001e2:	28a30313          	addi	t1,t1,650 # ffffffffc020d468 <is_panic>
ffffffffc02001e6:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ea:	715d                	addi	sp,sp,-80
ffffffffc02001ec:	ec06                	sd	ra,24(sp)
ffffffffc02001ee:	e822                	sd	s0,16(sp)
ffffffffc02001f0:	f436                	sd	a3,40(sp)
ffffffffc02001f2:	f83a                	sd	a4,48(sp)
ffffffffc02001f4:	fc3e                	sd	a5,56(sp)
ffffffffc02001f6:	e0c2                	sd	a6,64(sp)
ffffffffc02001f8:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001fa:	020e1a63          	bnez	t3,ffffffffc020022e <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02001fe:	4785                	li	a5,1
ffffffffc0200200:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200204:	8432                	mv	s0,a2
ffffffffc0200206:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200208:	862e                	mv	a2,a1
ffffffffc020020a:	85aa                	mv	a1,a0
ffffffffc020020c:	00004517          	auipc	a0,0x4
ffffffffc0200210:	cd450513          	addi	a0,a0,-812 # ffffffffc0203ee0 <etext+0x32>
    va_start(ap, fmt);
ffffffffc0200214:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200216:	ecbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020021a:	65a2                	ld	a1,8(sp)
ffffffffc020021c:	8522                	mv	a0,s0
ffffffffc020021e:	ea3ff0ef          	jal	ra,ffffffffc02000c0 <vcprintf>
    cprintf("\n");
ffffffffc0200222:	00005517          	auipc	a0,0x5
ffffffffc0200226:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0204dc0 <commands+0xc88>
ffffffffc020022a:	eb7ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020022e:	708000ef          	jal	ra,ffffffffc0200936 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200232:	4501                	li	a0,0
ffffffffc0200234:	130000ef          	jal	ra,ffffffffc0200364 <kmonitor>
    while (1) {
ffffffffc0200238:	bfed                	j	ffffffffc0200232 <__panic+0x54>

ffffffffc020023a <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020023a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020023c:	00004517          	auipc	a0,0x4
ffffffffc0200240:	cc450513          	addi	a0,a0,-828 # ffffffffc0203f00 <etext+0x52>
{
ffffffffc0200244:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200246:	e9bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020024a:	00000597          	auipc	a1,0x0
ffffffffc020024e:	e0058593          	addi	a1,a1,-512 # ffffffffc020004a <kern_init>
ffffffffc0200252:	00004517          	auipc	a0,0x4
ffffffffc0200256:	cce50513          	addi	a0,a0,-818 # ffffffffc0203f20 <etext+0x72>
ffffffffc020025a:	e87ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020025e:	00004597          	auipc	a1,0x4
ffffffffc0200262:	c5058593          	addi	a1,a1,-944 # ffffffffc0203eae <etext>
ffffffffc0200266:	00004517          	auipc	a0,0x4
ffffffffc020026a:	cda50513          	addi	a0,a0,-806 # ffffffffc0203f40 <etext+0x92>
ffffffffc020026e:	e73ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200272:	00009597          	auipc	a1,0x9
ffffffffc0200276:	dbe58593          	addi	a1,a1,-578 # ffffffffc0209030 <buf>
ffffffffc020027a:	00004517          	auipc	a0,0x4
ffffffffc020027e:	ce650513          	addi	a0,a0,-794 # ffffffffc0203f60 <etext+0xb2>
ffffffffc0200282:	e5fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200286:	0000d597          	auipc	a1,0xd
ffffffffc020028a:	26658593          	addi	a1,a1,614 # ffffffffc020d4ec <end>
ffffffffc020028e:	00004517          	auipc	a0,0x4
ffffffffc0200292:	cf250513          	addi	a0,a0,-782 # ffffffffc0203f80 <etext+0xd2>
ffffffffc0200296:	e4bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020029a:	0000d597          	auipc	a1,0xd
ffffffffc020029e:	65158593          	addi	a1,a1,1617 # ffffffffc020d8eb <end+0x3ff>
ffffffffc02002a2:	00000797          	auipc	a5,0x0
ffffffffc02002a6:	da878793          	addi	a5,a5,-600 # ffffffffc020004a <kern_init>
ffffffffc02002aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02002b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002b8:	95be                	add	a1,a1,a5
ffffffffc02002ba:	85a9                	srai	a1,a1,0xa
ffffffffc02002bc:	00004517          	auipc	a0,0x4
ffffffffc02002c0:	ce450513          	addi	a0,a0,-796 # ffffffffc0203fa0 <etext+0xf2>
}
ffffffffc02002c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002c6:	bd29                	j	ffffffffc02000e0 <cprintf>

ffffffffc02002c8 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002c8:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ca:	00004617          	auipc	a2,0x4
ffffffffc02002ce:	d0660613          	addi	a2,a2,-762 # ffffffffc0203fd0 <etext+0x122>
ffffffffc02002d2:	04900593          	li	a1,73
ffffffffc02002d6:	00004517          	auipc	a0,0x4
ffffffffc02002da:	d1250513          	addi	a0,a0,-750 # ffffffffc0203fe8 <etext+0x13a>
{
ffffffffc02002de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002e0:	effff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02002e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	00004617          	auipc	a2,0x4
ffffffffc02002ea:	d1a60613          	addi	a2,a2,-742 # ffffffffc0204000 <etext+0x152>
ffffffffc02002ee:	00004597          	auipc	a1,0x4
ffffffffc02002f2:	d3258593          	addi	a1,a1,-718 # ffffffffc0204020 <etext+0x172>
ffffffffc02002f6:	00004517          	auipc	a0,0x4
ffffffffc02002fa:	d3250513          	addi	a0,a0,-718 # ffffffffc0204028 <etext+0x17a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200300:	de1ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200304:	00004617          	auipc	a2,0x4
ffffffffc0200308:	d3460613          	addi	a2,a2,-716 # ffffffffc0204038 <etext+0x18a>
ffffffffc020030c:	00004597          	auipc	a1,0x4
ffffffffc0200310:	d5458593          	addi	a1,a1,-684 # ffffffffc0204060 <etext+0x1b2>
ffffffffc0200314:	00004517          	auipc	a0,0x4
ffffffffc0200318:	d1450513          	addi	a0,a0,-748 # ffffffffc0204028 <etext+0x17a>
ffffffffc020031c:	dc5ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200320:	00004617          	auipc	a2,0x4
ffffffffc0200324:	d5060613          	addi	a2,a2,-688 # ffffffffc0204070 <etext+0x1c2>
ffffffffc0200328:	00004597          	auipc	a1,0x4
ffffffffc020032c:	d6858593          	addi	a1,a1,-664 # ffffffffc0204090 <etext+0x1e2>
ffffffffc0200330:	00004517          	auipc	a0,0x4
ffffffffc0200334:	cf850513          	addi	a0,a0,-776 # ffffffffc0204028 <etext+0x17a>
ffffffffc0200338:	da9ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    return 0;
}
ffffffffc020033c:	60a2                	ld	ra,8(sp)
ffffffffc020033e:	4501                	li	a0,0
ffffffffc0200340:	0141                	addi	sp,sp,16
ffffffffc0200342:	8082                	ret

ffffffffc0200344 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200344:	1141                	addi	sp,sp,-16
ffffffffc0200346:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200348:	ef3ff0ef          	jal	ra,ffffffffc020023a <print_kerninfo>
    return 0;
}
ffffffffc020034c:	60a2                	ld	ra,8(sp)
ffffffffc020034e:	4501                	li	a0,0
ffffffffc0200350:	0141                	addi	sp,sp,16
ffffffffc0200352:	8082                	ret

ffffffffc0200354 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200354:	1141                	addi	sp,sp,-16
ffffffffc0200356:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200358:	f71ff0ef          	jal	ra,ffffffffc02002c8 <print_stackframe>
    return 0;
}
ffffffffc020035c:	60a2                	ld	ra,8(sp)
ffffffffc020035e:	4501                	li	a0,0
ffffffffc0200360:	0141                	addi	sp,sp,16
ffffffffc0200362:	8082                	ret

ffffffffc0200364 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200364:	7115                	addi	sp,sp,-224
ffffffffc0200366:	ed5e                	sd	s7,152(sp)
ffffffffc0200368:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	00004517          	auipc	a0,0x4
ffffffffc020036e:	d3650513          	addi	a0,a0,-714 # ffffffffc02040a0 <etext+0x1f2>
kmonitor(struct trapframe *tf) {
ffffffffc0200372:	ed86                	sd	ra,216(sp)
ffffffffc0200374:	e9a2                	sd	s0,208(sp)
ffffffffc0200376:	e5a6                	sd	s1,200(sp)
ffffffffc0200378:	e1ca                	sd	s2,192(sp)
ffffffffc020037a:	fd4e                	sd	s3,184(sp)
ffffffffc020037c:	f952                	sd	s4,176(sp)
ffffffffc020037e:	f556                	sd	s5,168(sp)
ffffffffc0200380:	f15a                	sd	s6,160(sp)
ffffffffc0200382:	e962                	sd	s8,144(sp)
ffffffffc0200384:	e566                	sd	s9,136(sp)
ffffffffc0200386:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200388:	d59ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020038c:	00004517          	auipc	a0,0x4
ffffffffc0200390:	d3c50513          	addi	a0,a0,-708 # ffffffffc02040c8 <etext+0x21a>
ffffffffc0200394:	d4dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    if (tf != NULL) {
ffffffffc0200398:	000b8563          	beqz	s7,ffffffffc02003a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020039c:	855e                	mv	a0,s7
ffffffffc020039e:	786000ef          	jal	ra,ffffffffc0200b24 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02003a2:	4501                	li	a0,0
ffffffffc02003a4:	4581                	li	a1,0
ffffffffc02003a6:	4601                	li	a2,0
ffffffffc02003a8:	48a1                	li	a7,8
ffffffffc02003aa:	00000073          	ecall
ffffffffc02003ae:	00004c17          	auipc	s8,0x4
ffffffffc02003b2:	d8ac0c13          	addi	s8,s8,-630 # ffffffffc0204138 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b6:	00004917          	auipc	s2,0x4
ffffffffc02003ba:	d3a90913          	addi	s2,s2,-710 # ffffffffc02040f0 <etext+0x242>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00004497          	auipc	s1,0x4
ffffffffc02003c2:	d3a48493          	addi	s1,s1,-710 # ffffffffc02040f8 <etext+0x24a>
        if (argc == MAXARGS - 1) {
ffffffffc02003c6:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003c8:	00004b17          	auipc	s6,0x4
ffffffffc02003cc:	d38b0b13          	addi	s6,s6,-712 # ffffffffc0204100 <etext+0x252>
        argv[argc ++] = buf;
ffffffffc02003d0:	00004a17          	auipc	s4,0x4
ffffffffc02003d4:	c50a0a13          	addi	s4,s4,-944 # ffffffffc0204020 <etext+0x172>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d8:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003da:	854a                	mv	a0,s2
ffffffffc02003dc:	d4fff0ef          	jal	ra,ffffffffc020012a <readline>
ffffffffc02003e0:	842a                	mv	s0,a0
ffffffffc02003e2:	dd65                	beqz	a0,ffffffffc02003da <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003e4:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003e8:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ea:	e1bd                	bnez	a1,ffffffffc0200450 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc02003ec:	fe0c87e3          	beqz	s9,ffffffffc02003da <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f0:	6582                	ld	a1,0(sp)
ffffffffc02003f2:	00004d17          	auipc	s10,0x4
ffffffffc02003f6:	d46d0d13          	addi	s10,s10,-698 # ffffffffc0204138 <commands>
        argv[argc ++] = buf;
ffffffffc02003fa:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003fc:	4401                	li	s0,0
ffffffffc02003fe:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200400:	602030ef          	jal	ra,ffffffffc0203a02 <strcmp>
ffffffffc0200404:	c919                	beqz	a0,ffffffffc020041a <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200406:	2405                	addiw	s0,s0,1
ffffffffc0200408:	0b540063          	beq	s0,s5,ffffffffc02004a8 <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020040c:	000d3503          	ld	a0,0(s10)
ffffffffc0200410:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200412:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200414:	5ee030ef          	jal	ra,ffffffffc0203a02 <strcmp>
ffffffffc0200418:	f57d                	bnez	a0,ffffffffc0200406 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97e2                	add	a5,a5,s8
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	865e                	mv	a2,s7
ffffffffc0200428:	002c                	addi	a1,sp,8
ffffffffc020042a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200430:	fa0555e3          	bgez	a0,ffffffffc02003da <kmonitor+0x76>
}
ffffffffc0200434:	60ee                	ld	ra,216(sp)
ffffffffc0200436:	644e                	ld	s0,208(sp)
ffffffffc0200438:	64ae                	ld	s1,200(sp)
ffffffffc020043a:	690e                	ld	s2,192(sp)
ffffffffc020043c:	79ea                	ld	s3,184(sp)
ffffffffc020043e:	7a4a                	ld	s4,176(sp)
ffffffffc0200440:	7aaa                	ld	s5,168(sp)
ffffffffc0200442:	7b0a                	ld	s6,160(sp)
ffffffffc0200444:	6bea                	ld	s7,152(sp)
ffffffffc0200446:	6c4a                	ld	s8,144(sp)
ffffffffc0200448:	6caa                	ld	s9,136(sp)
ffffffffc020044a:	6d0a                	ld	s10,128(sp)
ffffffffc020044c:	612d                	addi	sp,sp,224
ffffffffc020044e:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200450:	8526                	mv	a0,s1
ffffffffc0200452:	5f4030ef          	jal	ra,ffffffffc0203a46 <strchr>
ffffffffc0200456:	c901                	beqz	a0,ffffffffc0200466 <kmonitor+0x102>
ffffffffc0200458:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020045c:	00040023          	sb	zero,0(s0)
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200462:	d5c9                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc0200464:	b7f5                	j	ffffffffc0200450 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200466:	00044783          	lbu	a5,0(s0)
ffffffffc020046a:	d3c9                	beqz	a5,ffffffffc02003ec <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020046c:	033c8963          	beq	s9,s3,ffffffffc020049e <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200470:	003c9793          	slli	a5,s9,0x3
ffffffffc0200474:	0118                	addi	a4,sp,128
ffffffffc0200476:	97ba                	add	a5,a5,a4
ffffffffc0200478:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020047c:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200480:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200482:	e591                	bnez	a1,ffffffffc020048e <kmonitor+0x12a>
ffffffffc0200484:	b7b5                	j	ffffffffc02003f0 <kmonitor+0x8c>
ffffffffc0200486:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020048a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020048c:	d1a5                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc020048e:	8526                	mv	a0,s1
ffffffffc0200490:	5b6030ef          	jal	ra,ffffffffc0203a46 <strchr>
ffffffffc0200494:	d96d                	beqz	a0,ffffffffc0200486 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200496:	00044583          	lbu	a1,0(s0)
ffffffffc020049a:	d9a9                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc020049c:	bf55                	j	ffffffffc0200450 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020049e:	45c1                	li	a1,16
ffffffffc02004a0:	855a                	mv	a0,s6
ffffffffc02004a2:	c3fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02004a6:	b7e9                	j	ffffffffc0200470 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02004a8:	6582                	ld	a1,0(sp)
ffffffffc02004aa:	00004517          	auipc	a0,0x4
ffffffffc02004ae:	c7650513          	addi	a0,a0,-906 # ffffffffc0204120 <etext+0x272>
ffffffffc02004b2:	c2fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
ffffffffc02004b6:	b715                	j	ffffffffc02003da <kmonitor+0x76>

ffffffffc02004b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004b8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004ba:	00004517          	auipc	a0,0x4
ffffffffc02004be:	cc650513          	addi	a0,a0,-826 # ffffffffc0204180 <commands+0x48>
void dtb_init(void) {
ffffffffc02004c2:	fc86                	sd	ra,120(sp)
ffffffffc02004c4:	f8a2                	sd	s0,112(sp)
ffffffffc02004c6:	e8d2                	sd	s4,80(sp)
ffffffffc02004c8:	f4a6                	sd	s1,104(sp)
ffffffffc02004ca:	f0ca                	sd	s2,96(sp)
ffffffffc02004cc:	ecce                	sd	s3,88(sp)
ffffffffc02004ce:	e4d6                	sd	s5,72(sp)
ffffffffc02004d0:	e0da                	sd	s6,64(sp)
ffffffffc02004d2:	fc5e                	sd	s7,56(sp)
ffffffffc02004d4:	f862                	sd	s8,48(sp)
ffffffffc02004d6:	f466                	sd	s9,40(sp)
ffffffffc02004d8:	f06a                	sd	s10,32(sp)
ffffffffc02004da:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004dc:	c05ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004e0:	00009597          	auipc	a1,0x9
ffffffffc02004e4:	b205b583          	ld	a1,-1248(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02004e8:	00004517          	auipc	a0,0x4
ffffffffc02004ec:	ca850513          	addi	a0,a0,-856 # ffffffffc0204190 <commands+0x58>
ffffffffc02004f0:	bf1ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004f4:	00009417          	auipc	s0,0x9
ffffffffc02004f8:	b1440413          	addi	s0,s0,-1260 # ffffffffc0209008 <boot_dtb>
ffffffffc02004fc:	600c                	ld	a1,0(s0)
ffffffffc02004fe:	00004517          	auipc	a0,0x4
ffffffffc0200502:	ca250513          	addi	a0,a0,-862 # ffffffffc02041a0 <commands+0x68>
ffffffffc0200506:	bdbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020050a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020050e:	00004517          	auipc	a0,0x4
ffffffffc0200512:	caa50513          	addi	a0,a0,-854 # ffffffffc02041b8 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc0200516:	120a0463          	beqz	s4,ffffffffc020063e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020051a:	57f5                	li	a5,-3
ffffffffc020051c:	07fa                	slli	a5,a5,0x1e
ffffffffc020051e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200522:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200540:	8ec9                	or	a3,a3,a0
ffffffffc0200542:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200546:	1b7d                	addi	s6,s6,-1
ffffffffc0200548:	0167f7b3          	and	a5,a5,s6
ffffffffc020054c:	8dd5                	or	a1,a1,a3
ffffffffc020054e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200550:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200556:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a01>
ffffffffc020055a:	10f59163          	bne	a1,a5,ffffffffc020065c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020055e:	471c                	lw	a5,8(a4)
ffffffffc0200560:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200562:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200564:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200568:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020056c:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200570:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200574:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200578:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200580:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200584:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200588:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058c:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058e:	01146433          	or	s0,s0,a7
ffffffffc0200592:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200596:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059c:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005a0:	8c49                	or	s0,s0,a0
ffffffffc02005a2:	0166f6b3          	and	a3,a3,s6
ffffffffc02005a6:	00ca6a33          	or	s4,s4,a2
ffffffffc02005aa:	0167f7b3          	and	a5,a5,s6
ffffffffc02005ae:	8c55                	or	s0,s0,a3
ffffffffc02005b0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005b6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005ba:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005be:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005c0:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005c6:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005c8:	00004917          	auipc	s2,0x4
ffffffffc02005cc:	c4090913          	addi	s2,s2,-960 # ffffffffc0204208 <commands+0xd0>
ffffffffc02005d0:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005d2:	4d91                	li	s11,4
ffffffffc02005d4:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005d6:	00004497          	auipc	s1,0x4
ffffffffc02005da:	c2a48493          	addi	s1,s1,-982 # ffffffffc0204200 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005de:	000a2703          	lw	a4,0(s4)
ffffffffc02005e2:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005ea:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f2:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f6:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005fa:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005fc:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200600:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200604:	8fd5                	or	a5,a5,a3
ffffffffc0200606:	00eb7733          	and	a4,s6,a4
ffffffffc020060a:	8fd9                	or	a5,a5,a4
ffffffffc020060c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020060e:	09778c63          	beq	a5,s7,ffffffffc02006a6 <dtb_init+0x1ee>
ffffffffc0200612:	00fbea63          	bltu	s7,a5,ffffffffc0200626 <dtb_init+0x16e>
ffffffffc0200616:	07a78663          	beq	a5,s10,ffffffffc0200682 <dtb_init+0x1ca>
ffffffffc020061a:	4709                	li	a4,2
ffffffffc020061c:	00e79763          	bne	a5,a4,ffffffffc020062a <dtb_init+0x172>
ffffffffc0200620:	4c81                	li	s9,0
ffffffffc0200622:	8a56                	mv	s4,s5
ffffffffc0200624:	bf6d                	j	ffffffffc02005de <dtb_init+0x126>
ffffffffc0200626:	ffb78ee3          	beq	a5,s11,ffffffffc0200622 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020062a:	00004517          	auipc	a0,0x4
ffffffffc020062e:	c5650513          	addi	a0,a0,-938 # ffffffffc0204280 <commands+0x148>
ffffffffc0200632:	aafff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200636:	00004517          	auipc	a0,0x4
ffffffffc020063a:	c8250513          	addi	a0,a0,-894 # ffffffffc02042b8 <commands+0x180>
}
ffffffffc020063e:	7446                	ld	s0,112(sp)
ffffffffc0200640:	70e6                	ld	ra,120(sp)
ffffffffc0200642:	74a6                	ld	s1,104(sp)
ffffffffc0200644:	7906                	ld	s2,96(sp)
ffffffffc0200646:	69e6                	ld	s3,88(sp)
ffffffffc0200648:	6a46                	ld	s4,80(sp)
ffffffffc020064a:	6aa6                	ld	s5,72(sp)
ffffffffc020064c:	6b06                	ld	s6,64(sp)
ffffffffc020064e:	7be2                	ld	s7,56(sp)
ffffffffc0200650:	7c42                	ld	s8,48(sp)
ffffffffc0200652:	7ca2                	ld	s9,40(sp)
ffffffffc0200654:	7d02                	ld	s10,32(sp)
ffffffffc0200656:	6de2                	ld	s11,24(sp)
ffffffffc0200658:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020065a:	b459                	j	ffffffffc02000e0 <cprintf>
}
ffffffffc020065c:	7446                	ld	s0,112(sp)
ffffffffc020065e:	70e6                	ld	ra,120(sp)
ffffffffc0200660:	74a6                	ld	s1,104(sp)
ffffffffc0200662:	7906                	ld	s2,96(sp)
ffffffffc0200664:	69e6                	ld	s3,88(sp)
ffffffffc0200666:	6a46                	ld	s4,80(sp)
ffffffffc0200668:	6aa6                	ld	s5,72(sp)
ffffffffc020066a:	6b06                	ld	s6,64(sp)
ffffffffc020066c:	7be2                	ld	s7,56(sp)
ffffffffc020066e:	7c42                	ld	s8,48(sp)
ffffffffc0200670:	7ca2                	ld	s9,40(sp)
ffffffffc0200672:	7d02                	ld	s10,32(sp)
ffffffffc0200674:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200676:	00004517          	auipc	a0,0x4
ffffffffc020067a:	b6250513          	addi	a0,a0,-1182 # ffffffffc02041d8 <commands+0xa0>
}
ffffffffc020067e:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200680:	b485                	j	ffffffffc02000e0 <cprintf>
                int name_len = strlen(name);
ffffffffc0200682:	8556                	mv	a0,s5
ffffffffc0200684:	336030ef          	jal	ra,ffffffffc02039ba <strlen>
ffffffffc0200688:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020068a:	4619                	li	a2,6
ffffffffc020068c:	85a6                	mv	a1,s1
ffffffffc020068e:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200690:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200692:	38e030ef          	jal	ra,ffffffffc0203a20 <strncmp>
ffffffffc0200696:	e111                	bnez	a0,ffffffffc020069a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200698:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020069a:	0a91                	addi	s5,s5,4
ffffffffc020069c:	9ad2                	add	s5,s5,s4
ffffffffc020069e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006a2:	8a56                	mv	s4,s5
ffffffffc02006a4:	bf2d                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006aa:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ae:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02006b2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006c2:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c6:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ca:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ce:	00eaeab3          	or	s5,s5,a4
ffffffffc02006d2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006d6:	00faeab3          	or	s5,s5,a5
ffffffffc02006da:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006dc:	000c9c63          	bnez	s9,ffffffffc02006f4 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006e0:	1a82                	slli	s5,s5,0x20
ffffffffc02006e2:	00368793          	addi	a5,a3,3
ffffffffc02006e6:	020ada93          	srli	s5,s5,0x20
ffffffffc02006ea:	9abe                	add	s5,s5,a5
ffffffffc02006ec:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006f0:	8a56                	mv	s4,s5
ffffffffc02006f2:	b5f5                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f4:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	85ca                	mv	a1,s2
ffffffffc02006fa:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fc:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200700:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200704:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200708:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200710:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200712:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0087979b          	slliw	a5,a5,0x8
ffffffffc020071a:	8d59                	or	a0,a0,a4
ffffffffc020071c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200720:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200722:	1502                	slli	a0,a0,0x20
ffffffffc0200724:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200726:	9522                	add	a0,a0,s0
ffffffffc0200728:	2da030ef          	jal	ra,ffffffffc0203a02 <strcmp>
ffffffffc020072c:	66a2                	ld	a3,8(sp)
ffffffffc020072e:	f94d                	bnez	a0,ffffffffc02006e0 <dtb_init+0x228>
ffffffffc0200730:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006e0 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200734:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200738:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020073c:	00004517          	auipc	a0,0x4
ffffffffc0200740:	ad450513          	addi	a0,a0,-1324 # ffffffffc0204210 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc0200744:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200748:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020074c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200750:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200754:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200758:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200760:	0187d693          	srli	a3,a5,0x18
ffffffffc0200764:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200768:	0087579b          	srliw	a5,a4,0x8
ffffffffc020076c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200770:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200774:	010f6f33          	or	t5,t5,a6
ffffffffc0200778:	0187529b          	srliw	t0,a4,0x18
ffffffffc020077c:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	0186f6b3          	and	a3,a3,s8
ffffffffc020078c:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200790:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200794:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200798:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079c:	8361                	srli	a4,a4,0x18
ffffffffc020079e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02007a6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02007aa:	00cb7633          	and	a2,s6,a2
ffffffffc02007ae:	0088181b          	slliw	a6,a6,0x8
ffffffffc02007b2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007b6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ba:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007ca:	011b78b3          	and	a7,s6,a7
ffffffffc02007ce:	005eeeb3          	or	t4,t4,t0
ffffffffc02007d2:	00c6e733          	or	a4,a3,a2
ffffffffc02007d6:	006c6c33          	or	s8,s8,t1
ffffffffc02007da:	010b76b3          	and	a3,s6,a6
ffffffffc02007de:	00bb7b33          	and	s6,s6,a1
ffffffffc02007e2:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007e6:	016c6b33          	or	s6,s8,s6
ffffffffc02007ea:	01146433          	or	s0,s0,a7
ffffffffc02007ee:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007f0:	1702                	slli	a4,a4,0x20
ffffffffc02007f2:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f4:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007f6:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f8:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007fa:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007fe:	0167eb33          	or	s6,a5,s6
ffffffffc0200802:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200804:	8ddff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200808:	85a2                	mv	a1,s0
ffffffffc020080a:	00004517          	auipc	a0,0x4
ffffffffc020080e:	a2650513          	addi	a0,a0,-1498 # ffffffffc0204230 <commands+0xf8>
ffffffffc0200812:	8cfff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200816:	014b5613          	srli	a2,s6,0x14
ffffffffc020081a:	85da                	mv	a1,s6
ffffffffc020081c:	00004517          	auipc	a0,0x4
ffffffffc0200820:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0204248 <commands+0x110>
ffffffffc0200824:	8bdff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200828:	008b05b3          	add	a1,s6,s0
ffffffffc020082c:	15fd                	addi	a1,a1,-1
ffffffffc020082e:	00004517          	auipc	a0,0x4
ffffffffc0200832:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0204268 <commands+0x130>
ffffffffc0200836:	8abff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020083a:	00004517          	auipc	a0,0x4
ffffffffc020083e:	a7e50513          	addi	a0,a0,-1410 # ffffffffc02042b8 <commands+0x180>
        memory_base = mem_base;
ffffffffc0200842:	0000d797          	auipc	a5,0xd
ffffffffc0200846:	c287b723          	sd	s0,-978(a5) # ffffffffc020d470 <memory_base>
        memory_size = mem_size;
ffffffffc020084a:	0000d797          	auipc	a5,0xd
ffffffffc020084e:	c367b723          	sd	s6,-978(a5) # ffffffffc020d478 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200852:	b3f5                	j	ffffffffc020063e <dtb_init+0x186>

ffffffffc0200854 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200854:	0000d517          	auipc	a0,0xd
ffffffffc0200858:	c1c53503          	ld	a0,-996(a0) # ffffffffc020d470 <memory_base>
ffffffffc020085c:	8082                	ret

ffffffffc020085e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020085e:	0000d517          	auipc	a0,0xd
ffffffffc0200862:	c1a53503          	ld	a0,-998(a0) # ffffffffc020d478 <memory_size>
ffffffffc0200866:	8082                	ret

ffffffffc0200868 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200868:	67e1                	lui	a5,0x18
ffffffffc020086a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020086e:	0000d717          	auipc	a4,0xd
ffffffffc0200872:	c0f73d23          	sd	a5,-998(a4) # ffffffffc020d488 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200876:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020087a:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020087c:	953e                	add	a0,a0,a5
ffffffffc020087e:	4601                	li	a2,0
ffffffffc0200880:	4881                	li	a7,0
ffffffffc0200882:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200886:	02000793          	li	a5,32
ffffffffc020088a:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020088e:	00004517          	auipc	a0,0x4
ffffffffc0200892:	a4250513          	addi	a0,a0,-1470 # ffffffffc02042d0 <commands+0x198>
    ticks = 0;
ffffffffc0200896:	0000d797          	auipc	a5,0xd
ffffffffc020089a:	be07b523          	sd	zero,-1046(a5) # ffffffffc020d480 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020089e:	843ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc02008a2 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02008a2:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02008a6:	0000d797          	auipc	a5,0xd
ffffffffc02008aa:	be27b783          	ld	a5,-1054(a5) # ffffffffc020d488 <timebase>
ffffffffc02008ae:	953e                	add	a0,a0,a5
ffffffffc02008b0:	4581                	li	a1,0
ffffffffc02008b2:	4601                	li	a2,0
ffffffffc02008b4:	4881                	li	a7,0
ffffffffc02008b6:	00000073          	ecall
ffffffffc02008ba:	8082                	ret

ffffffffc02008bc <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02008bc:	8082                	ret

ffffffffc02008be <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008be:	100027f3          	csrr	a5,sstatus
ffffffffc02008c2:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02008c4:	0ff57513          	zext.b	a0,a0
ffffffffc02008c8:	e799                	bnez	a5,ffffffffc02008d6 <cons_putc+0x18>
ffffffffc02008ca:	4581                	li	a1,0
ffffffffc02008cc:	4601                	li	a2,0
ffffffffc02008ce:	4885                	li	a7,1
ffffffffc02008d0:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02008d4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02008d6:	1101                	addi	sp,sp,-32
ffffffffc02008d8:	ec06                	sd	ra,24(sp)
ffffffffc02008da:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02008dc:	05a000ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02008e0:	6522                	ld	a0,8(sp)
ffffffffc02008e2:	4581                	li	a1,0
ffffffffc02008e4:	4601                	li	a2,0
ffffffffc02008e6:	4885                	li	a7,1
ffffffffc02008e8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02008ec:	60e2                	ld	ra,24(sp)
ffffffffc02008ee:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02008f0:	a081                	j	ffffffffc0200930 <intr_enable>

ffffffffc02008f2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008f2:	100027f3          	csrr	a5,sstatus
ffffffffc02008f6:	8b89                	andi	a5,a5,2
ffffffffc02008f8:	eb89                	bnez	a5,ffffffffc020090a <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02008fa:	4501                	li	a0,0
ffffffffc02008fc:	4581                	li	a1,0
ffffffffc02008fe:	4601                	li	a2,0
ffffffffc0200900:	4889                	li	a7,2
ffffffffc0200902:	00000073          	ecall
ffffffffc0200906:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200908:	8082                	ret
int cons_getc(void) {
ffffffffc020090a:	1101                	addi	sp,sp,-32
ffffffffc020090c:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020090e:	028000ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0200912:	4501                	li	a0,0
ffffffffc0200914:	4581                	li	a1,0
ffffffffc0200916:	4601                	li	a2,0
ffffffffc0200918:	4889                	li	a7,2
ffffffffc020091a:	00000073          	ecall
ffffffffc020091e:	2501                	sext.w	a0,a0
ffffffffc0200920:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200922:	00e000ef          	jal	ra,ffffffffc0200930 <intr_enable>
}
ffffffffc0200926:	60e2                	ld	ra,24(sp)
ffffffffc0200928:	6522                	ld	a0,8(sp)
ffffffffc020092a:	6105                	addi	sp,sp,32
ffffffffc020092c:	8082                	ret

ffffffffc020092e <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200936:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020093a:	8082                	ret

ffffffffc020093c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020093c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200940:	00000797          	auipc	a5,0x0
ffffffffc0200944:	3e078793          	addi	a5,a5,992 # ffffffffc0200d20 <__alltraps>
ffffffffc0200948:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020094c:	000407b7          	lui	a5,0x40
ffffffffc0200950:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200954:	8082                	ret

ffffffffc0200956 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200956:	610c                	ld	a1,0(a0)
{
ffffffffc0200958:	1141                	addi	sp,sp,-16
ffffffffc020095a:	e022                	sd	s0,0(sp)
ffffffffc020095c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020095e:	00004517          	auipc	a0,0x4
ffffffffc0200962:	99250513          	addi	a0,a0,-1646 # ffffffffc02042f0 <commands+0x1b8>
{
ffffffffc0200966:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200968:	f78ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020096c:	640c                	ld	a1,8(s0)
ffffffffc020096e:	00004517          	auipc	a0,0x4
ffffffffc0200972:	99a50513          	addi	a0,a0,-1638 # ffffffffc0204308 <commands+0x1d0>
ffffffffc0200976:	f6aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020097a:	680c                	ld	a1,16(s0)
ffffffffc020097c:	00004517          	auipc	a0,0x4
ffffffffc0200980:	9a450513          	addi	a0,a0,-1628 # ffffffffc0204320 <commands+0x1e8>
ffffffffc0200984:	f5cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200988:	6c0c                	ld	a1,24(s0)
ffffffffc020098a:	00004517          	auipc	a0,0x4
ffffffffc020098e:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0204338 <commands+0x200>
ffffffffc0200992:	f4eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200996:	700c                	ld	a1,32(s0)
ffffffffc0200998:	00004517          	auipc	a0,0x4
ffffffffc020099c:	9b850513          	addi	a0,a0,-1608 # ffffffffc0204350 <commands+0x218>
ffffffffc02009a0:	f40ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009a4:	740c                	ld	a1,40(s0)
ffffffffc02009a6:	00004517          	auipc	a0,0x4
ffffffffc02009aa:	9c250513          	addi	a0,a0,-1598 # ffffffffc0204368 <commands+0x230>
ffffffffc02009ae:	f32ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009b2:	780c                	ld	a1,48(s0)
ffffffffc02009b4:	00004517          	auipc	a0,0x4
ffffffffc02009b8:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0204380 <commands+0x248>
ffffffffc02009bc:	f24ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009c0:	7c0c                	ld	a1,56(s0)
ffffffffc02009c2:	00004517          	auipc	a0,0x4
ffffffffc02009c6:	9d650513          	addi	a0,a0,-1578 # ffffffffc0204398 <commands+0x260>
ffffffffc02009ca:	f16ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009ce:	602c                	ld	a1,64(s0)
ffffffffc02009d0:	00004517          	auipc	a0,0x4
ffffffffc02009d4:	9e050513          	addi	a0,a0,-1568 # ffffffffc02043b0 <commands+0x278>
ffffffffc02009d8:	f08ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009dc:	642c                	ld	a1,72(s0)
ffffffffc02009de:	00004517          	auipc	a0,0x4
ffffffffc02009e2:	9ea50513          	addi	a0,a0,-1558 # ffffffffc02043c8 <commands+0x290>
ffffffffc02009e6:	efaff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ea:	682c                	ld	a1,80(s0)
ffffffffc02009ec:	00004517          	auipc	a0,0x4
ffffffffc02009f0:	9f450513          	addi	a0,a0,-1548 # ffffffffc02043e0 <commands+0x2a8>
ffffffffc02009f4:	eecff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009f8:	6c2c                	ld	a1,88(s0)
ffffffffc02009fa:	00004517          	auipc	a0,0x4
ffffffffc02009fe:	9fe50513          	addi	a0,a0,-1538 # ffffffffc02043f8 <commands+0x2c0>
ffffffffc0200a02:	edeff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a06:	702c                	ld	a1,96(s0)
ffffffffc0200a08:	00004517          	auipc	a0,0x4
ffffffffc0200a0c:	a0850513          	addi	a0,a0,-1528 # ffffffffc0204410 <commands+0x2d8>
ffffffffc0200a10:	ed0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a14:	742c                	ld	a1,104(s0)
ffffffffc0200a16:	00004517          	auipc	a0,0x4
ffffffffc0200a1a:	a1250513          	addi	a0,a0,-1518 # ffffffffc0204428 <commands+0x2f0>
ffffffffc0200a1e:	ec2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a22:	782c                	ld	a1,112(s0)
ffffffffc0200a24:	00004517          	auipc	a0,0x4
ffffffffc0200a28:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0204440 <commands+0x308>
ffffffffc0200a2c:	eb4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a30:	7c2c                	ld	a1,120(s0)
ffffffffc0200a32:	00004517          	auipc	a0,0x4
ffffffffc0200a36:	a2650513          	addi	a0,a0,-1498 # ffffffffc0204458 <commands+0x320>
ffffffffc0200a3a:	ea6ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a3e:	604c                	ld	a1,128(s0)
ffffffffc0200a40:	00004517          	auipc	a0,0x4
ffffffffc0200a44:	a3050513          	addi	a0,a0,-1488 # ffffffffc0204470 <commands+0x338>
ffffffffc0200a48:	e98ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a4c:	644c                	ld	a1,136(s0)
ffffffffc0200a4e:	00004517          	auipc	a0,0x4
ffffffffc0200a52:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0204488 <commands+0x350>
ffffffffc0200a56:	e8aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a5a:	684c                	ld	a1,144(s0)
ffffffffc0200a5c:	00004517          	auipc	a0,0x4
ffffffffc0200a60:	a4450513          	addi	a0,a0,-1468 # ffffffffc02044a0 <commands+0x368>
ffffffffc0200a64:	e7cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a68:	6c4c                	ld	a1,152(s0)
ffffffffc0200a6a:	00004517          	auipc	a0,0x4
ffffffffc0200a6e:	a4e50513          	addi	a0,a0,-1458 # ffffffffc02044b8 <commands+0x380>
ffffffffc0200a72:	e6eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a76:	704c                	ld	a1,160(s0)
ffffffffc0200a78:	00004517          	auipc	a0,0x4
ffffffffc0200a7c:	a5850513          	addi	a0,a0,-1448 # ffffffffc02044d0 <commands+0x398>
ffffffffc0200a80:	e60ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a84:	744c                	ld	a1,168(s0)
ffffffffc0200a86:	00004517          	auipc	a0,0x4
ffffffffc0200a8a:	a6250513          	addi	a0,a0,-1438 # ffffffffc02044e8 <commands+0x3b0>
ffffffffc0200a8e:	e52ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a92:	784c                	ld	a1,176(s0)
ffffffffc0200a94:	00004517          	auipc	a0,0x4
ffffffffc0200a98:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0204500 <commands+0x3c8>
ffffffffc0200a9c:	e44ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200aa0:	7c4c                	ld	a1,184(s0)
ffffffffc0200aa2:	00004517          	auipc	a0,0x4
ffffffffc0200aa6:	a7650513          	addi	a0,a0,-1418 # ffffffffc0204518 <commands+0x3e0>
ffffffffc0200aaa:	e36ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aae:	606c                	ld	a1,192(s0)
ffffffffc0200ab0:	00004517          	auipc	a0,0x4
ffffffffc0200ab4:	a8050513          	addi	a0,a0,-1408 # ffffffffc0204530 <commands+0x3f8>
ffffffffc0200ab8:	e28ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200abc:	646c                	ld	a1,200(s0)
ffffffffc0200abe:	00004517          	auipc	a0,0x4
ffffffffc0200ac2:	a8a50513          	addi	a0,a0,-1398 # ffffffffc0204548 <commands+0x410>
ffffffffc0200ac6:	e1aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200aca:	686c                	ld	a1,208(s0)
ffffffffc0200acc:	00004517          	auipc	a0,0x4
ffffffffc0200ad0:	a9450513          	addi	a0,a0,-1388 # ffffffffc0204560 <commands+0x428>
ffffffffc0200ad4:	e0cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ad8:	6c6c                	ld	a1,216(s0)
ffffffffc0200ada:	00004517          	auipc	a0,0x4
ffffffffc0200ade:	a9e50513          	addi	a0,a0,-1378 # ffffffffc0204578 <commands+0x440>
ffffffffc0200ae2:	dfeff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ae6:	706c                	ld	a1,224(s0)
ffffffffc0200ae8:	00004517          	auipc	a0,0x4
ffffffffc0200aec:	aa850513          	addi	a0,a0,-1368 # ffffffffc0204590 <commands+0x458>
ffffffffc0200af0:	df0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200af4:	746c                	ld	a1,232(s0)
ffffffffc0200af6:	00004517          	auipc	a0,0x4
ffffffffc0200afa:	ab250513          	addi	a0,a0,-1358 # ffffffffc02045a8 <commands+0x470>
ffffffffc0200afe:	de2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b02:	786c                	ld	a1,240(s0)
ffffffffc0200b04:	00004517          	auipc	a0,0x4
ffffffffc0200b08:	abc50513          	addi	a0,a0,-1348 # ffffffffc02045c0 <commands+0x488>
ffffffffc0200b0c:	dd4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b10:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b12:	6402                	ld	s0,0(sp)
ffffffffc0200b14:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b16:	00004517          	auipc	a0,0x4
ffffffffc0200b1a:	ac250513          	addi	a0,a0,-1342 # ffffffffc02045d8 <commands+0x4a0>
}
ffffffffc0200b1e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b20:	dc0ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200b24 <print_trapframe>:
{
ffffffffc0200b24:	1141                	addi	sp,sp,-16
ffffffffc0200b26:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b28:	85aa                	mv	a1,a0
{
ffffffffc0200b2a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b2c:	00004517          	auipc	a0,0x4
ffffffffc0200b30:	ac450513          	addi	a0,a0,-1340 # ffffffffc02045f0 <commands+0x4b8>
{
ffffffffc0200b34:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b36:	daaff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b3a:	8522                	mv	a0,s0
ffffffffc0200b3c:	e1bff0ef          	jal	ra,ffffffffc0200956 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b40:	10043583          	ld	a1,256(s0)
ffffffffc0200b44:	00004517          	auipc	a0,0x4
ffffffffc0200b48:	ac450513          	addi	a0,a0,-1340 # ffffffffc0204608 <commands+0x4d0>
ffffffffc0200b4c:	d94ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b50:	10843583          	ld	a1,264(s0)
ffffffffc0200b54:	00004517          	auipc	a0,0x4
ffffffffc0200b58:	acc50513          	addi	a0,a0,-1332 # ffffffffc0204620 <commands+0x4e8>
ffffffffc0200b5c:	d84ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b60:	11043583          	ld	a1,272(s0)
ffffffffc0200b64:	00004517          	auipc	a0,0x4
ffffffffc0200b68:	ad450513          	addi	a0,a0,-1324 # ffffffffc0204638 <commands+0x500>
ffffffffc0200b6c:	d74ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b70:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b74:	6402                	ld	s0,0(sp)
ffffffffc0200b76:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b78:	00004517          	auipc	a0,0x4
ffffffffc0200b7c:	ad850513          	addi	a0,a0,-1320 # ffffffffc0204650 <commands+0x518>
}
ffffffffc0200b80:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b82:	d5eff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200b86 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b86:	11853783          	ld	a5,280(a0)
ffffffffc0200b8a:	472d                	li	a4,11
ffffffffc0200b8c:	0786                	slli	a5,a5,0x1
ffffffffc0200b8e:	8385                	srli	a5,a5,0x1
ffffffffc0200b90:	06f76d63          	bltu	a4,a5,ffffffffc0200c0a <interrupt_handler+0x84>
ffffffffc0200b94:	00004717          	auipc	a4,0x4
ffffffffc0200b98:	b8470713          	addi	a4,a4,-1148 # ffffffffc0204718 <commands+0x5e0>
ffffffffc0200b9c:	078a                	slli	a5,a5,0x2
ffffffffc0200b9e:	97ba                	add	a5,a5,a4
ffffffffc0200ba0:	439c                	lw	a5,0(a5)
ffffffffc0200ba2:	97ba                	add	a5,a5,a4
ffffffffc0200ba4:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ba6:	00004517          	auipc	a0,0x4
ffffffffc0200baa:	b2250513          	addi	a0,a0,-1246 # ffffffffc02046c8 <commands+0x590>
ffffffffc0200bae:	d32ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200bb2:	00004517          	auipc	a0,0x4
ffffffffc0200bb6:	af650513          	addi	a0,a0,-1290 # ffffffffc02046a8 <commands+0x570>
ffffffffc0200bba:	d26ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bbe:	00004517          	auipc	a0,0x4
ffffffffc0200bc2:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0204668 <commands+0x530>
ffffffffc0200bc6:	d1aff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bca:	00004517          	auipc	a0,0x4
ffffffffc0200bce:	abe50513          	addi	a0,a0,-1346 # ffffffffc0204688 <commands+0x550>
ffffffffc0200bd2:	d0eff06f          	j	ffffffffc02000e0 <cprintf>
{
ffffffffc0200bd6:	1141                	addi	sp,sp,-16
ffffffffc0200bd8:	e406                	sd	ra,8(sp)
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        // 设置下次时钟中断
         clock_set_next_event();
ffffffffc0200bda:	cc9ff0ef          	jal	ra,ffffffffc02008a2 <clock_set_next_event>
            
        // 计数器加一
        ticks++;
ffffffffc0200bde:	0000d797          	auipc	a5,0xd
ffffffffc0200be2:	8a278793          	addi	a5,a5,-1886 # ffffffffc020d480 <ticks>
ffffffffc0200be6:	6398                	ld	a4,0(a5)
ffffffffc0200be8:	0705                	addi	a4,a4,1
ffffffffc0200bea:	e398                	sd	a4,0(a5)
            
        // 定义一个静态变量来记录打印次数
        static int print_count = 0;
        
        // 当计数器加到100的时候，输出信息并重置计数器
        if (ticks % TICK_NUM == 0) {
ffffffffc0200bec:	639c                	ld	a5,0(a5)
ffffffffc0200bee:	06400713          	li	a4,100
ffffffffc0200bf2:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200bf6:	cb99                	beqz	a5,ffffffffc0200c0c <interrupt_handler+0x86>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bf8:	60a2                	ld	ra,8(sp)
ffffffffc0200bfa:	0141                	addi	sp,sp,16
ffffffffc0200bfc:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bfe:	00004517          	auipc	a0,0x4
ffffffffc0200c02:	afa50513          	addi	a0,a0,-1286 # ffffffffc02046f8 <commands+0x5c0>
ffffffffc0200c06:	cdaff06f          	j	ffffffffc02000e0 <cprintf>
        print_trapframe(tf);
ffffffffc0200c0a:	bf29                	j	ffffffffc0200b24 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c0c:	06400593          	li	a1,100
ffffffffc0200c10:	00004517          	auipc	a0,0x4
ffffffffc0200c14:	ad850513          	addi	a0,a0,-1320 # ffffffffc02046e8 <commands+0x5b0>
ffffffffc0200c18:	cc8ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
            print_count++;
ffffffffc0200c1c:	0000d717          	auipc	a4,0xd
ffffffffc0200c20:	87470713          	addi	a4,a4,-1932 # ffffffffc020d490 <print_count.0>
ffffffffc0200c24:	431c                	lw	a5,0(a4)
            if (print_count == 10) {
ffffffffc0200c26:	46a9                	li	a3,10
            print_count++;
ffffffffc0200c28:	0017861b          	addiw	a2,a5,1
ffffffffc0200c2c:	c310                	sw	a2,0(a4)
            if (print_count == 10) {
ffffffffc0200c2e:	fcd615e3          	bne	a2,a3,ffffffffc0200bf8 <interrupt_handler+0x72>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c32:	4501                	li	a0,0
ffffffffc0200c34:	4581                	li	a1,0
ffffffffc0200c36:	4601                	li	a2,0
ffffffffc0200c38:	48a1                	li	a7,8
ffffffffc0200c3a:	00000073          	ecall
}
ffffffffc0200c3e:	bf6d                	j	ffffffffc0200bf8 <interrupt_handler+0x72>

ffffffffc0200c40 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c40:	11853783          	ld	a5,280(a0)
ffffffffc0200c44:	473d                	li	a4,15
ffffffffc0200c46:	0cf76563          	bltu	a4,a5,ffffffffc0200d10 <exception_handler+0xd0>
ffffffffc0200c4a:	00004717          	auipc	a4,0x4
ffffffffc0200c4e:	c9670713          	addi	a4,a4,-874 # ffffffffc02048e0 <commands+0x7a8>
ffffffffc0200c52:	078a                	slli	a5,a5,0x2
ffffffffc0200c54:	97ba                	add	a5,a5,a4
ffffffffc0200c56:	439c                	lw	a5,0(a5)
ffffffffc0200c58:	97ba                	add	a5,a5,a4
ffffffffc0200c5a:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200c5c:	00004517          	auipc	a0,0x4
ffffffffc0200c60:	c6c50513          	addi	a0,a0,-916 # ffffffffc02048c8 <commands+0x790>
ffffffffc0200c64:	c7cff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200c68:	00004517          	auipc	a0,0x4
ffffffffc0200c6c:	ae050513          	addi	a0,a0,-1312 # ffffffffc0204748 <commands+0x610>
ffffffffc0200c70:	c70ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200c74:	00004517          	auipc	a0,0x4
ffffffffc0200c78:	af450513          	addi	a0,a0,-1292 # ffffffffc0204768 <commands+0x630>
ffffffffc0200c7c:	c64ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c80:	00004517          	auipc	a0,0x4
ffffffffc0200c84:	b0850513          	addi	a0,a0,-1272 # ffffffffc0204788 <commands+0x650>
ffffffffc0200c88:	c58ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c8c:	00004517          	auipc	a0,0x4
ffffffffc0200c90:	b1450513          	addi	a0,a0,-1260 # ffffffffc02047a0 <commands+0x668>
ffffffffc0200c94:	c4cff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200c98:	00004517          	auipc	a0,0x4
ffffffffc0200c9c:	b1850513          	addi	a0,a0,-1256 # ffffffffc02047b0 <commands+0x678>
ffffffffc0200ca0:	c40ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200ca4:	00004517          	auipc	a0,0x4
ffffffffc0200ca8:	b2c50513          	addi	a0,a0,-1236 # ffffffffc02047d0 <commands+0x698>
ffffffffc0200cac:	c34ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200cb0:	00004517          	auipc	a0,0x4
ffffffffc0200cb4:	b3850513          	addi	a0,a0,-1224 # ffffffffc02047e8 <commands+0x6b0>
ffffffffc0200cb8:	c28ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200cbc:	00004517          	auipc	a0,0x4
ffffffffc0200cc0:	b4450513          	addi	a0,a0,-1212 # ffffffffc0204800 <commands+0x6c8>
ffffffffc0200cc4:	c1cff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200cc8:	00004517          	auipc	a0,0x4
ffffffffc0200ccc:	b5050513          	addi	a0,a0,-1200 # ffffffffc0204818 <commands+0x6e0>
ffffffffc0200cd0:	c10ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200cd4:	00004517          	auipc	a0,0x4
ffffffffc0200cd8:	b6450513          	addi	a0,a0,-1180 # ffffffffc0204838 <commands+0x700>
ffffffffc0200cdc:	c04ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200ce0:	00004517          	auipc	a0,0x4
ffffffffc0200ce4:	b7850513          	addi	a0,a0,-1160 # ffffffffc0204858 <commands+0x720>
ffffffffc0200ce8:	bf8ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cec:	00004517          	auipc	a0,0x4
ffffffffc0200cf0:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0204878 <commands+0x740>
ffffffffc0200cf4:	becff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200cf8:	00004517          	auipc	a0,0x4
ffffffffc0200cfc:	ba050513          	addi	a0,a0,-1120 # ffffffffc0204898 <commands+0x760>
ffffffffc0200d00:	be0ff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200d04:	00004517          	auipc	a0,0x4
ffffffffc0200d08:	bac50513          	addi	a0,a0,-1108 # ffffffffc02048b0 <commands+0x778>
ffffffffc0200d0c:	bd4ff06f          	j	ffffffffc02000e0 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200d10:	bd11                	j	ffffffffc0200b24 <print_trapframe>

ffffffffc0200d12 <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d12:	11853783          	ld	a5,280(a0)
ffffffffc0200d16:	0007c363          	bltz	a5,ffffffffc0200d1c <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200d1a:	b71d                	j	ffffffffc0200c40 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200d1c:	b5ad                	j	ffffffffc0200b86 <interrupt_handler>
	...

ffffffffc0200d20 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200d20:	14011073          	csrw	sscratch,sp
ffffffffc0200d24:	712d                	addi	sp,sp,-288
ffffffffc0200d26:	e406                	sd	ra,8(sp)
ffffffffc0200d28:	ec0e                	sd	gp,24(sp)
ffffffffc0200d2a:	f012                	sd	tp,32(sp)
ffffffffc0200d2c:	f416                	sd	t0,40(sp)
ffffffffc0200d2e:	f81a                	sd	t1,48(sp)
ffffffffc0200d30:	fc1e                	sd	t2,56(sp)
ffffffffc0200d32:	e0a2                	sd	s0,64(sp)
ffffffffc0200d34:	e4a6                	sd	s1,72(sp)
ffffffffc0200d36:	e8aa                	sd	a0,80(sp)
ffffffffc0200d38:	ecae                	sd	a1,88(sp)
ffffffffc0200d3a:	f0b2                	sd	a2,96(sp)
ffffffffc0200d3c:	f4b6                	sd	a3,104(sp)
ffffffffc0200d3e:	f8ba                	sd	a4,112(sp)
ffffffffc0200d40:	fcbe                	sd	a5,120(sp)
ffffffffc0200d42:	e142                	sd	a6,128(sp)
ffffffffc0200d44:	e546                	sd	a7,136(sp)
ffffffffc0200d46:	e94a                	sd	s2,144(sp)
ffffffffc0200d48:	ed4e                	sd	s3,152(sp)
ffffffffc0200d4a:	f152                	sd	s4,160(sp)
ffffffffc0200d4c:	f556                	sd	s5,168(sp)
ffffffffc0200d4e:	f95a                	sd	s6,176(sp)
ffffffffc0200d50:	fd5e                	sd	s7,184(sp)
ffffffffc0200d52:	e1e2                	sd	s8,192(sp)
ffffffffc0200d54:	e5e6                	sd	s9,200(sp)
ffffffffc0200d56:	e9ea                	sd	s10,208(sp)
ffffffffc0200d58:	edee                	sd	s11,216(sp)
ffffffffc0200d5a:	f1f2                	sd	t3,224(sp)
ffffffffc0200d5c:	f5f6                	sd	t4,232(sp)
ffffffffc0200d5e:	f9fa                	sd	t5,240(sp)
ffffffffc0200d60:	fdfe                	sd	t6,248(sp)
ffffffffc0200d62:	14002473          	csrr	s0,sscratch
ffffffffc0200d66:	100024f3          	csrr	s1,sstatus
ffffffffc0200d6a:	14102973          	csrr	s2,sepc
ffffffffc0200d6e:	143029f3          	csrr	s3,stval
ffffffffc0200d72:	14202a73          	csrr	s4,scause
ffffffffc0200d76:	e822                	sd	s0,16(sp)
ffffffffc0200d78:	e226                	sd	s1,256(sp)
ffffffffc0200d7a:	e64a                	sd	s2,264(sp)
ffffffffc0200d7c:	ea4e                	sd	s3,272(sp)
ffffffffc0200d7e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d80:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d82:	f91ff0ef          	jal	ra,ffffffffc0200d12 <trap>

ffffffffc0200d86 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d86:	6492                	ld	s1,256(sp)
ffffffffc0200d88:	6932                	ld	s2,264(sp)
ffffffffc0200d8a:	10049073          	csrw	sstatus,s1
ffffffffc0200d8e:	14191073          	csrw	sepc,s2
ffffffffc0200d92:	60a2                	ld	ra,8(sp)
ffffffffc0200d94:	61e2                	ld	gp,24(sp)
ffffffffc0200d96:	7202                	ld	tp,32(sp)
ffffffffc0200d98:	72a2                	ld	t0,40(sp)
ffffffffc0200d9a:	7342                	ld	t1,48(sp)
ffffffffc0200d9c:	73e2                	ld	t2,56(sp)
ffffffffc0200d9e:	6406                	ld	s0,64(sp)
ffffffffc0200da0:	64a6                	ld	s1,72(sp)
ffffffffc0200da2:	6546                	ld	a0,80(sp)
ffffffffc0200da4:	65e6                	ld	a1,88(sp)
ffffffffc0200da6:	7606                	ld	a2,96(sp)
ffffffffc0200da8:	76a6                	ld	a3,104(sp)
ffffffffc0200daa:	7746                	ld	a4,112(sp)
ffffffffc0200dac:	77e6                	ld	a5,120(sp)
ffffffffc0200dae:	680a                	ld	a6,128(sp)
ffffffffc0200db0:	68aa                	ld	a7,136(sp)
ffffffffc0200db2:	694a                	ld	s2,144(sp)
ffffffffc0200db4:	69ea                	ld	s3,152(sp)
ffffffffc0200db6:	7a0a                	ld	s4,160(sp)
ffffffffc0200db8:	7aaa                	ld	s5,168(sp)
ffffffffc0200dba:	7b4a                	ld	s6,176(sp)
ffffffffc0200dbc:	7bea                	ld	s7,184(sp)
ffffffffc0200dbe:	6c0e                	ld	s8,192(sp)
ffffffffc0200dc0:	6cae                	ld	s9,200(sp)
ffffffffc0200dc2:	6d4e                	ld	s10,208(sp)
ffffffffc0200dc4:	6dee                	ld	s11,216(sp)
ffffffffc0200dc6:	7e0e                	ld	t3,224(sp)
ffffffffc0200dc8:	7eae                	ld	t4,232(sp)
ffffffffc0200dca:	7f4e                	ld	t5,240(sp)
ffffffffc0200dcc:	7fee                	ld	t6,248(sp)
ffffffffc0200dce:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200dd0:	10200073          	sret

ffffffffc0200dd4 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200dd4:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dd6:	bf45                	j	ffffffffc0200d86 <__trapret>
	...

ffffffffc0200dda <pa2page.part.0>:
{
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa)
ffffffffc0200dda:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc0200ddc:	00004617          	auipc	a2,0x4
ffffffffc0200de0:	b4460613          	addi	a2,a2,-1212 # ffffffffc0204920 <commands+0x7e8>
ffffffffc0200de4:	06900593          	li	a1,105
ffffffffc0200de8:	00004517          	auipc	a0,0x4
ffffffffc0200dec:	b5850513          	addi	a0,a0,-1192 # ffffffffc0204940 <commands+0x808>
pa2page(uintptr_t pa)
ffffffffc0200df0:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200df2:	becff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0200df6 <pte2page.part.0>:
{
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte)
ffffffffc0200df6:	1141                	addi	sp,sp,-16
{
    if (!(pte & PTE_V))
    {
        panic("pte2page called with invalid pte");
ffffffffc0200df8:	00004617          	auipc	a2,0x4
ffffffffc0200dfc:	b5860613          	addi	a2,a2,-1192 # ffffffffc0204950 <commands+0x818>
ffffffffc0200e00:	07f00593          	li	a1,127
ffffffffc0200e04:	00004517          	auipc	a0,0x4
ffffffffc0200e08:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0204940 <commands+0x808>
pte2page(pte_t pte)
ffffffffc0200e0c:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0200e0e:	bd0ff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0200e12 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e12:	100027f3          	csrr	a5,sstatus
ffffffffc0200e16:	8b89                	andi	a5,a5,2
ffffffffc0200e18:	e799                	bnez	a5,ffffffffc0200e26 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200e1a:	0000c797          	auipc	a5,0xc
ffffffffc0200e1e:	69e7b783          	ld	a5,1694(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0200e22:	6f9c                	ld	a5,24(a5)
ffffffffc0200e24:	8782                	jr	a5
{
ffffffffc0200e26:	1141                	addi	sp,sp,-16
ffffffffc0200e28:	e406                	sd	ra,8(sp)
ffffffffc0200e2a:	e022                	sd	s0,0(sp)
ffffffffc0200e2c:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200e2e:	b09ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200e32:	0000c797          	auipc	a5,0xc
ffffffffc0200e36:	6867b783          	ld	a5,1670(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0200e3a:	6f9c                	ld	a5,24(a5)
ffffffffc0200e3c:	8522                	mv	a0,s0
ffffffffc0200e3e:	9782                	jalr	a5
ffffffffc0200e40:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200e42:	aefff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200e46:	60a2                	ld	ra,8(sp)
ffffffffc0200e48:	8522                	mv	a0,s0
ffffffffc0200e4a:	6402                	ld	s0,0(sp)
ffffffffc0200e4c:	0141                	addi	sp,sp,16
ffffffffc0200e4e:	8082                	ret

ffffffffc0200e50 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e50:	100027f3          	csrr	a5,sstatus
ffffffffc0200e54:	8b89                	andi	a5,a5,2
ffffffffc0200e56:	e799                	bnez	a5,ffffffffc0200e64 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200e58:	0000c797          	auipc	a5,0xc
ffffffffc0200e5c:	6607b783          	ld	a5,1632(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0200e60:	739c                	ld	a5,32(a5)
ffffffffc0200e62:	8782                	jr	a5
{
ffffffffc0200e64:	1101                	addi	sp,sp,-32
ffffffffc0200e66:	ec06                	sd	ra,24(sp)
ffffffffc0200e68:	e822                	sd	s0,16(sp)
ffffffffc0200e6a:	e426                	sd	s1,8(sp)
ffffffffc0200e6c:	842a                	mv	s0,a0
ffffffffc0200e6e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200e70:	ac7ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200e74:	0000c797          	auipc	a5,0xc
ffffffffc0200e78:	6447b783          	ld	a5,1604(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0200e7c:	739c                	ld	a5,32(a5)
ffffffffc0200e7e:	85a6                	mv	a1,s1
ffffffffc0200e80:	8522                	mv	a0,s0
ffffffffc0200e82:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200e84:	6442                	ld	s0,16(sp)
ffffffffc0200e86:	60e2                	ld	ra,24(sp)
ffffffffc0200e88:	64a2                	ld	s1,8(sp)
ffffffffc0200e8a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200e8c:	b455                	j	ffffffffc0200930 <intr_enable>

ffffffffc0200e8e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e8e:	100027f3          	csrr	a5,sstatus
ffffffffc0200e92:	8b89                	andi	a5,a5,2
ffffffffc0200e94:	e799                	bnez	a5,ffffffffc0200ea2 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200e96:	0000c797          	auipc	a5,0xc
ffffffffc0200e9a:	6227b783          	ld	a5,1570(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0200e9e:	779c                	ld	a5,40(a5)
ffffffffc0200ea0:	8782                	jr	a5
{
ffffffffc0200ea2:	1141                	addi	sp,sp,-16
ffffffffc0200ea4:	e406                	sd	ra,8(sp)
ffffffffc0200ea6:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200ea8:	a8fff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200eac:	0000c797          	auipc	a5,0xc
ffffffffc0200eb0:	60c7b783          	ld	a5,1548(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0200eb4:	779c                	ld	a5,40(a5)
ffffffffc0200eb6:	9782                	jalr	a5
ffffffffc0200eb8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200eba:	a77ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200ebe:	60a2                	ld	ra,8(sp)
ffffffffc0200ec0:	8522                	mv	a0,s0
ffffffffc0200ec2:	6402                	ld	s0,0(sp)
ffffffffc0200ec4:	0141                	addi	sp,sp,16
ffffffffc0200ec6:	8082                	ret

ffffffffc0200ec8 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200ec8:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0200ecc:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0200ed0:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200ed2:	078e                	slli	a5,a5,0x3
{
ffffffffc0200ed4:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200ed6:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0200eda:	6094                	ld	a3,0(s1)
{
ffffffffc0200edc:	f04a                	sd	s2,32(sp)
ffffffffc0200ede:	ec4e                	sd	s3,24(sp)
ffffffffc0200ee0:	e852                	sd	s4,16(sp)
ffffffffc0200ee2:	fc06                	sd	ra,56(sp)
ffffffffc0200ee4:	f822                	sd	s0,48(sp)
ffffffffc0200ee6:	e456                	sd	s5,8(sp)
ffffffffc0200ee8:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0200eea:	0016f793          	andi	a5,a3,1
{
ffffffffc0200eee:	892e                	mv	s2,a1
ffffffffc0200ef0:	8a32                	mv	s4,a2
ffffffffc0200ef2:	0000c997          	auipc	s3,0xc
ffffffffc0200ef6:	5b698993          	addi	s3,s3,1462 # ffffffffc020d4a8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0200efa:	efbd                	bnez	a5,ffffffffc0200f78 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200efc:	14060c63          	beqz	a2,ffffffffc0201054 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f00:	100027f3          	csrr	a5,sstatus
ffffffffc0200f04:	8b89                	andi	a5,a5,2
ffffffffc0200f06:	14079963          	bnez	a5,ffffffffc0201058 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f0a:	0000c797          	auipc	a5,0xc
ffffffffc0200f0e:	5ae7b783          	ld	a5,1454(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0200f12:	6f9c                	ld	a5,24(a5)
ffffffffc0200f14:	4505                	li	a0,1
ffffffffc0200f16:	9782                	jalr	a5
ffffffffc0200f18:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200f1a:	12040d63          	beqz	s0,ffffffffc0201054 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0200f1e:	0000cb17          	auipc	s6,0xc
ffffffffc0200f22:	592b0b13          	addi	s6,s6,1426 # ffffffffc020d4b0 <pages>
ffffffffc0200f26:	000b3503          	ld	a0,0(s6)
ffffffffc0200f2a:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200f2e:	0000c997          	auipc	s3,0xc
ffffffffc0200f32:	57a98993          	addi	s3,s3,1402 # ffffffffc020d4a8 <npage>
ffffffffc0200f36:	40a40533          	sub	a0,s0,a0
ffffffffc0200f3a:	8519                	srai	a0,a0,0x6
ffffffffc0200f3c:	9556                	add	a0,a0,s5
ffffffffc0200f3e:	0009b703          	ld	a4,0(s3)
ffffffffc0200f42:	00c51793          	slli	a5,a0,0xc
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0200f46:	4685                	li	a3,1
ffffffffc0200f48:	c014                	sw	a3,0(s0)
ffffffffc0200f4a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f4c:	0532                	slli	a0,a0,0xc
ffffffffc0200f4e:	16e7f763          	bgeu	a5,a4,ffffffffc02010bc <get_pte+0x1f4>
ffffffffc0200f52:	0000c797          	auipc	a5,0xc
ffffffffc0200f56:	56e7b783          	ld	a5,1390(a5) # ffffffffc020d4c0 <va_pa_offset>
ffffffffc0200f5a:	6605                	lui	a2,0x1
ffffffffc0200f5c:	4581                	li	a1,0
ffffffffc0200f5e:	953e                	add	a0,a0,a5
ffffffffc0200f60:	2fd020ef          	jal	ra,ffffffffc0203a5c <memset>
    return page - pages + nbase;
ffffffffc0200f64:	000b3683          	ld	a3,0(s6)
ffffffffc0200f68:	40d406b3          	sub	a3,s0,a3
ffffffffc0200f6c:	8699                	srai	a3,a3,0x6
ffffffffc0200f6e:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200f70:	06aa                	slli	a3,a3,0xa
ffffffffc0200f72:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200f76:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200f78:	77fd                	lui	a5,0xfffff
ffffffffc0200f7a:	068a                	slli	a3,a3,0x2
ffffffffc0200f7c:	0009b703          	ld	a4,0(s3)
ffffffffc0200f80:	8efd                	and	a3,a3,a5
ffffffffc0200f82:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200f86:	10e7ff63          	bgeu	a5,a4,ffffffffc02010a4 <get_pte+0x1dc>
ffffffffc0200f8a:	0000ca97          	auipc	s5,0xc
ffffffffc0200f8e:	536a8a93          	addi	s5,s5,1334 # ffffffffc020d4c0 <va_pa_offset>
ffffffffc0200f92:	000ab403          	ld	s0,0(s5)
ffffffffc0200f96:	01595793          	srli	a5,s2,0x15
ffffffffc0200f9a:	1ff7f793          	andi	a5,a5,511
ffffffffc0200f9e:	96a2                	add	a3,a3,s0
ffffffffc0200fa0:	00379413          	slli	s0,a5,0x3
ffffffffc0200fa4:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0200fa6:	6014                	ld	a3,0(s0)
ffffffffc0200fa8:	0016f793          	andi	a5,a3,1
ffffffffc0200fac:	ebad                	bnez	a5,ffffffffc020101e <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200fae:	0a0a0363          	beqz	s4,ffffffffc0201054 <get_pte+0x18c>
ffffffffc0200fb2:	100027f3          	csrr	a5,sstatus
ffffffffc0200fb6:	8b89                	andi	a5,a5,2
ffffffffc0200fb8:	efcd                	bnez	a5,ffffffffc0201072 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200fba:	0000c797          	auipc	a5,0xc
ffffffffc0200fbe:	4fe7b783          	ld	a5,1278(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0200fc2:	6f9c                	ld	a5,24(a5)
ffffffffc0200fc4:	4505                	li	a0,1
ffffffffc0200fc6:	9782                	jalr	a5
ffffffffc0200fc8:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200fca:	c4c9                	beqz	s1,ffffffffc0201054 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0200fcc:	0000cb17          	auipc	s6,0xc
ffffffffc0200fd0:	4e4b0b13          	addi	s6,s6,1252 # ffffffffc020d4b0 <pages>
ffffffffc0200fd4:	000b3503          	ld	a0,0(s6)
ffffffffc0200fd8:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200fdc:	0009b703          	ld	a4,0(s3)
ffffffffc0200fe0:	40a48533          	sub	a0,s1,a0
ffffffffc0200fe4:	8519                	srai	a0,a0,0x6
ffffffffc0200fe6:	9552                	add	a0,a0,s4
ffffffffc0200fe8:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0200fec:	4685                	li	a3,1
ffffffffc0200fee:	c094                	sw	a3,0(s1)
ffffffffc0200ff0:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ff2:	0532                	slli	a0,a0,0xc
ffffffffc0200ff4:	0ee7f163          	bgeu	a5,a4,ffffffffc02010d6 <get_pte+0x20e>
ffffffffc0200ff8:	000ab783          	ld	a5,0(s5)
ffffffffc0200ffc:	6605                	lui	a2,0x1
ffffffffc0200ffe:	4581                	li	a1,0
ffffffffc0201000:	953e                	add	a0,a0,a5
ffffffffc0201002:	25b020ef          	jal	ra,ffffffffc0203a5c <memset>
    return page - pages + nbase;
ffffffffc0201006:	000b3683          	ld	a3,0(s6)
ffffffffc020100a:	40d486b3          	sub	a3,s1,a3
ffffffffc020100e:	8699                	srai	a3,a3,0x6
ffffffffc0201010:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201012:	06aa                	slli	a3,a3,0xa
ffffffffc0201014:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201018:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020101a:	0009b703          	ld	a4,0(s3)
ffffffffc020101e:	068a                	slli	a3,a3,0x2
ffffffffc0201020:	757d                	lui	a0,0xfffff
ffffffffc0201022:	8ee9                	and	a3,a3,a0
ffffffffc0201024:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201028:	06e7f263          	bgeu	a5,a4,ffffffffc020108c <get_pte+0x1c4>
ffffffffc020102c:	000ab503          	ld	a0,0(s5)
ffffffffc0201030:	00c95913          	srli	s2,s2,0xc
ffffffffc0201034:	1ff97913          	andi	s2,s2,511
ffffffffc0201038:	96aa                	add	a3,a3,a0
ffffffffc020103a:	00391513          	slli	a0,s2,0x3
ffffffffc020103e:	9536                	add	a0,a0,a3
}
ffffffffc0201040:	70e2                	ld	ra,56(sp)
ffffffffc0201042:	7442                	ld	s0,48(sp)
ffffffffc0201044:	74a2                	ld	s1,40(sp)
ffffffffc0201046:	7902                	ld	s2,32(sp)
ffffffffc0201048:	69e2                	ld	s3,24(sp)
ffffffffc020104a:	6a42                	ld	s4,16(sp)
ffffffffc020104c:	6aa2                	ld	s5,8(sp)
ffffffffc020104e:	6b02                	ld	s6,0(sp)
ffffffffc0201050:	6121                	addi	sp,sp,64
ffffffffc0201052:	8082                	ret
            return NULL;
ffffffffc0201054:	4501                	li	a0,0
ffffffffc0201056:	b7ed                	j	ffffffffc0201040 <get_pte+0x178>
        intr_disable();
ffffffffc0201058:	8dfff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020105c:	0000c797          	auipc	a5,0xc
ffffffffc0201060:	45c7b783          	ld	a5,1116(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201064:	6f9c                	ld	a5,24(a5)
ffffffffc0201066:	4505                	li	a0,1
ffffffffc0201068:	9782                	jalr	a5
ffffffffc020106a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020106c:	8c5ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201070:	b56d                	j	ffffffffc0200f1a <get_pte+0x52>
        intr_disable();
ffffffffc0201072:	8c5ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0201076:	0000c797          	auipc	a5,0xc
ffffffffc020107a:	4427b783          	ld	a5,1090(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc020107e:	6f9c                	ld	a5,24(a5)
ffffffffc0201080:	4505                	li	a0,1
ffffffffc0201082:	9782                	jalr	a5
ffffffffc0201084:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201086:	8abff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020108a:	b781                	j	ffffffffc0200fca <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020108c:	00004617          	auipc	a2,0x4
ffffffffc0201090:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0204978 <commands+0x840>
ffffffffc0201094:	0fb00593          	li	a1,251
ffffffffc0201098:	00004517          	auipc	a0,0x4
ffffffffc020109c:	90850513          	addi	a0,a0,-1784 # ffffffffc02049a0 <commands+0x868>
ffffffffc02010a0:	93eff0ef          	jal	ra,ffffffffc02001de <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02010a4:	00004617          	auipc	a2,0x4
ffffffffc02010a8:	8d460613          	addi	a2,a2,-1836 # ffffffffc0204978 <commands+0x840>
ffffffffc02010ac:	0ee00593          	li	a1,238
ffffffffc02010b0:	00004517          	auipc	a0,0x4
ffffffffc02010b4:	8f050513          	addi	a0,a0,-1808 # ffffffffc02049a0 <commands+0x868>
ffffffffc02010b8:	926ff0ef          	jal	ra,ffffffffc02001de <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02010bc:	86aa                	mv	a3,a0
ffffffffc02010be:	00004617          	auipc	a2,0x4
ffffffffc02010c2:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0204978 <commands+0x840>
ffffffffc02010c6:	0eb00593          	li	a1,235
ffffffffc02010ca:	00004517          	auipc	a0,0x4
ffffffffc02010ce:	8d650513          	addi	a0,a0,-1834 # ffffffffc02049a0 <commands+0x868>
ffffffffc02010d2:	90cff0ef          	jal	ra,ffffffffc02001de <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02010d6:	86aa                	mv	a3,a0
ffffffffc02010d8:	00004617          	auipc	a2,0x4
ffffffffc02010dc:	8a060613          	addi	a2,a2,-1888 # ffffffffc0204978 <commands+0x840>
ffffffffc02010e0:	0f800593          	li	a1,248
ffffffffc02010e4:	00004517          	auipc	a0,0x4
ffffffffc02010e8:	8bc50513          	addi	a0,a0,-1860 # ffffffffc02049a0 <commands+0x868>
ffffffffc02010ec:	8f2ff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02010f0 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02010f0:	1141                	addi	sp,sp,-16
ffffffffc02010f2:	e022                	sd	s0,0(sp)
ffffffffc02010f4:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02010f6:	4601                	li	a2,0
{
ffffffffc02010f8:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02010fa:	dcfff0ef          	jal	ra,ffffffffc0200ec8 <get_pte>
    if (ptep_store != NULL)
ffffffffc02010fe:	c011                	beqz	s0,ffffffffc0201102 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201100:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201102:	c511                	beqz	a0,ffffffffc020110e <get_page+0x1e>
ffffffffc0201104:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201106:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201108:	0017f713          	andi	a4,a5,1
ffffffffc020110c:	e709                	bnez	a4,ffffffffc0201116 <get_page+0x26>
}
ffffffffc020110e:	60a2                	ld	ra,8(sp)
ffffffffc0201110:	6402                	ld	s0,0(sp)
ffffffffc0201112:	0141                	addi	sp,sp,16
ffffffffc0201114:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201116:	078a                	slli	a5,a5,0x2
ffffffffc0201118:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020111a:	0000c717          	auipc	a4,0xc
ffffffffc020111e:	38e73703          	ld	a4,910(a4) # ffffffffc020d4a8 <npage>
ffffffffc0201122:	00e7ff63          	bgeu	a5,a4,ffffffffc0201140 <get_page+0x50>
ffffffffc0201126:	60a2                	ld	ra,8(sp)
ffffffffc0201128:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc020112a:	fff80537          	lui	a0,0xfff80
ffffffffc020112e:	97aa                	add	a5,a5,a0
ffffffffc0201130:	079a                	slli	a5,a5,0x6
ffffffffc0201132:	0000c517          	auipc	a0,0xc
ffffffffc0201136:	37e53503          	ld	a0,894(a0) # ffffffffc020d4b0 <pages>
ffffffffc020113a:	953e                	add	a0,a0,a5
ffffffffc020113c:	0141                	addi	sp,sp,16
ffffffffc020113e:	8082                	ret
ffffffffc0201140:	c9bff0ef          	jal	ra,ffffffffc0200dda <pa2page.part.0>

ffffffffc0201144 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201144:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201146:	4601                	li	a2,0
{
ffffffffc0201148:	ec26                	sd	s1,24(sp)
ffffffffc020114a:	f406                	sd	ra,40(sp)
ffffffffc020114c:	f022                	sd	s0,32(sp)
ffffffffc020114e:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201150:	d79ff0ef          	jal	ra,ffffffffc0200ec8 <get_pte>
    if (ptep != NULL)
ffffffffc0201154:	c511                	beqz	a0,ffffffffc0201160 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201156:	611c                	ld	a5,0(a0)
ffffffffc0201158:	842a                	mv	s0,a0
ffffffffc020115a:	0017f713          	andi	a4,a5,1
ffffffffc020115e:	e711                	bnez	a4,ffffffffc020116a <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201160:	70a2                	ld	ra,40(sp)
ffffffffc0201162:	7402                	ld	s0,32(sp)
ffffffffc0201164:	64e2                	ld	s1,24(sp)
ffffffffc0201166:	6145                	addi	sp,sp,48
ffffffffc0201168:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020116a:	078a                	slli	a5,a5,0x2
ffffffffc020116c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020116e:	0000c717          	auipc	a4,0xc
ffffffffc0201172:	33a73703          	ld	a4,826(a4) # ffffffffc020d4a8 <npage>
ffffffffc0201176:	06e7f363          	bgeu	a5,a4,ffffffffc02011dc <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020117a:	fff80537          	lui	a0,0xfff80
ffffffffc020117e:	97aa                	add	a5,a5,a0
ffffffffc0201180:	079a                	slli	a5,a5,0x6
ffffffffc0201182:	0000c517          	auipc	a0,0xc
ffffffffc0201186:	32e53503          	ld	a0,814(a0) # ffffffffc020d4b0 <pages>
ffffffffc020118a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020118c:	411c                	lw	a5,0(a0)
ffffffffc020118e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201192:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201194:	cb11                	beqz	a4,ffffffffc02011a8 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201196:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020119a:	12048073          	sfence.vma	s1
}
ffffffffc020119e:	70a2                	ld	ra,40(sp)
ffffffffc02011a0:	7402                	ld	s0,32(sp)
ffffffffc02011a2:	64e2                	ld	s1,24(sp)
ffffffffc02011a4:	6145                	addi	sp,sp,48
ffffffffc02011a6:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02011a8:	100027f3          	csrr	a5,sstatus
ffffffffc02011ac:	8b89                	andi	a5,a5,2
ffffffffc02011ae:	eb89                	bnez	a5,ffffffffc02011c0 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02011b0:	0000c797          	auipc	a5,0xc
ffffffffc02011b4:	3087b783          	ld	a5,776(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc02011b8:	739c                	ld	a5,32(a5)
ffffffffc02011ba:	4585                	li	a1,1
ffffffffc02011bc:	9782                	jalr	a5
    if (flag) {
ffffffffc02011be:	bfe1                	j	ffffffffc0201196 <page_remove+0x52>
        intr_disable();
ffffffffc02011c0:	e42a                	sd	a0,8(sp)
ffffffffc02011c2:	f74ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02011c6:	0000c797          	auipc	a5,0xc
ffffffffc02011ca:	2f27b783          	ld	a5,754(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc02011ce:	739c                	ld	a5,32(a5)
ffffffffc02011d0:	6522                	ld	a0,8(sp)
ffffffffc02011d2:	4585                	li	a1,1
ffffffffc02011d4:	9782                	jalr	a5
        intr_enable();
ffffffffc02011d6:	f5aff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02011da:	bf75                	j	ffffffffc0201196 <page_remove+0x52>
ffffffffc02011dc:	bffff0ef          	jal	ra,ffffffffc0200dda <pa2page.part.0>

ffffffffc02011e0 <page_insert>:
{
ffffffffc02011e0:	7139                	addi	sp,sp,-64
ffffffffc02011e2:	e852                	sd	s4,16(sp)
ffffffffc02011e4:	8a32                	mv	s4,a2
ffffffffc02011e6:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02011e8:	4605                	li	a2,1
{
ffffffffc02011ea:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02011ec:	85d2                	mv	a1,s4
{
ffffffffc02011ee:	f426                	sd	s1,40(sp)
ffffffffc02011f0:	fc06                	sd	ra,56(sp)
ffffffffc02011f2:	f04a                	sd	s2,32(sp)
ffffffffc02011f4:	ec4e                	sd	s3,24(sp)
ffffffffc02011f6:	e456                	sd	s5,8(sp)
ffffffffc02011f8:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02011fa:	ccfff0ef          	jal	ra,ffffffffc0200ec8 <get_pte>
    if (ptep == NULL)
ffffffffc02011fe:	c961                	beqz	a0,ffffffffc02012ce <page_insert+0xee>
    page->ref += 1;
ffffffffc0201200:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0201202:	611c                	ld	a5,0(a0)
ffffffffc0201204:	89aa                	mv	s3,a0
ffffffffc0201206:	0016871b          	addiw	a4,a3,1
ffffffffc020120a:	c018                	sw	a4,0(s0)
ffffffffc020120c:	0017f713          	andi	a4,a5,1
ffffffffc0201210:	ef05                	bnez	a4,ffffffffc0201248 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0201212:	0000c717          	auipc	a4,0xc
ffffffffc0201216:	29e73703          	ld	a4,670(a4) # ffffffffc020d4b0 <pages>
ffffffffc020121a:	8c19                	sub	s0,s0,a4
ffffffffc020121c:	000807b7          	lui	a5,0x80
ffffffffc0201220:	8419                	srai	s0,s0,0x6
ffffffffc0201222:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201224:	042a                	slli	s0,s0,0xa
ffffffffc0201226:	8cc1                	or	s1,s1,s0
ffffffffc0201228:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020122c:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201230:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0201234:	4501                	li	a0,0
}
ffffffffc0201236:	70e2                	ld	ra,56(sp)
ffffffffc0201238:	7442                	ld	s0,48(sp)
ffffffffc020123a:	74a2                	ld	s1,40(sp)
ffffffffc020123c:	7902                	ld	s2,32(sp)
ffffffffc020123e:	69e2                	ld	s3,24(sp)
ffffffffc0201240:	6a42                	ld	s4,16(sp)
ffffffffc0201242:	6aa2                	ld	s5,8(sp)
ffffffffc0201244:	6121                	addi	sp,sp,64
ffffffffc0201246:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201248:	078a                	slli	a5,a5,0x2
ffffffffc020124a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020124c:	0000c717          	auipc	a4,0xc
ffffffffc0201250:	25c73703          	ld	a4,604(a4) # ffffffffc020d4a8 <npage>
ffffffffc0201254:	06e7ff63          	bgeu	a5,a4,ffffffffc02012d2 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0201258:	0000ca97          	auipc	s5,0xc
ffffffffc020125c:	258a8a93          	addi	s5,s5,600 # ffffffffc020d4b0 <pages>
ffffffffc0201260:	000ab703          	ld	a4,0(s5)
ffffffffc0201264:	fff80937          	lui	s2,0xfff80
ffffffffc0201268:	993e                	add	s2,s2,a5
ffffffffc020126a:	091a                	slli	s2,s2,0x6
ffffffffc020126c:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc020126e:	01240c63          	beq	s0,s2,ffffffffc0201286 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0201272:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b14>
ffffffffc0201276:	fff7869b          	addiw	a3,a5,-1
ffffffffc020127a:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc020127e:	c691                	beqz	a3,ffffffffc020128a <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201280:	120a0073          	sfence.vma	s4
}
ffffffffc0201284:	bf59                	j	ffffffffc020121a <page_insert+0x3a>
ffffffffc0201286:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201288:	bf49                	j	ffffffffc020121a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020128a:	100027f3          	csrr	a5,sstatus
ffffffffc020128e:	8b89                	andi	a5,a5,2
ffffffffc0201290:	ef91                	bnez	a5,ffffffffc02012ac <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0201292:	0000c797          	auipc	a5,0xc
ffffffffc0201296:	2267b783          	ld	a5,550(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc020129a:	739c                	ld	a5,32(a5)
ffffffffc020129c:	4585                	li	a1,1
ffffffffc020129e:	854a                	mv	a0,s2
ffffffffc02012a0:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02012a2:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02012a6:	120a0073          	sfence.vma	s4
ffffffffc02012aa:	bf85                	j	ffffffffc020121a <page_insert+0x3a>
        intr_disable();
ffffffffc02012ac:	e8aff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02012b0:	0000c797          	auipc	a5,0xc
ffffffffc02012b4:	2087b783          	ld	a5,520(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc02012b8:	739c                	ld	a5,32(a5)
ffffffffc02012ba:	4585                	li	a1,1
ffffffffc02012bc:	854a                	mv	a0,s2
ffffffffc02012be:	9782                	jalr	a5
        intr_enable();
ffffffffc02012c0:	e70ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02012c4:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02012c8:	120a0073          	sfence.vma	s4
ffffffffc02012cc:	b7b9                	j	ffffffffc020121a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02012ce:	5571                	li	a0,-4
ffffffffc02012d0:	b79d                	j	ffffffffc0201236 <page_insert+0x56>
ffffffffc02012d2:	b09ff0ef          	jal	ra,ffffffffc0200dda <pa2page.part.0>

ffffffffc02012d6 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02012d6:	00004797          	auipc	a5,0x4
ffffffffc02012da:	2f278793          	addi	a5,a5,754 # ffffffffc02055c8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012de:	638c                	ld	a1,0(a5)
{
ffffffffc02012e0:	7159                	addi	sp,sp,-112
ffffffffc02012e2:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012e4:	00003517          	auipc	a0,0x3
ffffffffc02012e8:	6cc50513          	addi	a0,a0,1740 # ffffffffc02049b0 <commands+0x878>
    pmm_manager = &default_pmm_manager;
ffffffffc02012ec:	0000cb17          	auipc	s6,0xc
ffffffffc02012f0:	1ccb0b13          	addi	s6,s6,460 # ffffffffc020d4b8 <pmm_manager>
{
ffffffffc02012f4:	f486                	sd	ra,104(sp)
ffffffffc02012f6:	e8ca                	sd	s2,80(sp)
ffffffffc02012f8:	e4ce                	sd	s3,72(sp)
ffffffffc02012fa:	f0a2                	sd	s0,96(sp)
ffffffffc02012fc:	eca6                	sd	s1,88(sp)
ffffffffc02012fe:	e0d2                	sd	s4,64(sp)
ffffffffc0201300:	fc56                	sd	s5,56(sp)
ffffffffc0201302:	f45e                	sd	s7,40(sp)
ffffffffc0201304:	f062                	sd	s8,32(sp)
ffffffffc0201306:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201308:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020130c:	dd5fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    pmm_manager->init();
ffffffffc0201310:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201314:	0000c997          	auipc	s3,0xc
ffffffffc0201318:	1ac98993          	addi	s3,s3,428 # ffffffffc020d4c0 <va_pa_offset>
    pmm_manager->init();
ffffffffc020131c:	679c                	ld	a5,8(a5)
ffffffffc020131e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201320:	57f5                	li	a5,-3
ffffffffc0201322:	07fa                	slli	a5,a5,0x1e
ffffffffc0201324:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201328:	d2cff0ef          	jal	ra,ffffffffc0200854 <get_memory_base>
ffffffffc020132c:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020132e:	d30ff0ef          	jal	ra,ffffffffc020085e <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201332:	200505e3          	beqz	a0,ffffffffc0201d3c <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201336:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0201338:	00003517          	auipc	a0,0x3
ffffffffc020133c:	6b050513          	addi	a0,a0,1712 # ffffffffc02049e8 <commands+0x8b0>
ffffffffc0201340:	da1fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201344:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201348:	fff40693          	addi	a3,s0,-1
ffffffffc020134c:	864a                	mv	a2,s2
ffffffffc020134e:	85a6                	mv	a1,s1
ffffffffc0201350:	00003517          	auipc	a0,0x3
ffffffffc0201354:	6b050513          	addi	a0,a0,1712 # ffffffffc0204a00 <commands+0x8c8>
ffffffffc0201358:	d89fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020135c:	c8000737          	lui	a4,0xc8000
ffffffffc0201360:	87a2                	mv	a5,s0
ffffffffc0201362:	54876163          	bltu	a4,s0,ffffffffc02018a4 <pmm_init+0x5ce>
ffffffffc0201366:	757d                	lui	a0,0xfffff
ffffffffc0201368:	0000d617          	auipc	a2,0xd
ffffffffc020136c:	18360613          	addi	a2,a2,387 # ffffffffc020e4eb <end+0xfff>
ffffffffc0201370:	8e69                	and	a2,a2,a0
ffffffffc0201372:	0000c497          	auipc	s1,0xc
ffffffffc0201376:	13648493          	addi	s1,s1,310 # ffffffffc020d4a8 <npage>
ffffffffc020137a:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020137e:	0000cb97          	auipc	s7,0xc
ffffffffc0201382:	132b8b93          	addi	s7,s7,306 # ffffffffc020d4b0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201386:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201388:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020138c:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201390:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201392:	02f50863          	beq	a0,a5,ffffffffc02013c2 <pmm_init+0xec>
ffffffffc0201396:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201398:	4585                	li	a1,1
ffffffffc020139a:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020139e:	00679513          	slli	a0,a5,0x6
ffffffffc02013a2:	9532                	add	a0,a0,a2
ffffffffc02013a4:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b1c>
ffffffffc02013a8:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02013ac:	6088                	ld	a0,0(s1)
ffffffffc02013ae:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02013b0:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02013b4:	00d50733          	add	a4,a0,a3
ffffffffc02013b8:	fee7e3e3          	bltu	a5,a4,ffffffffc020139e <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02013bc:	071a                	slli	a4,a4,0x6
ffffffffc02013be:	00e606b3          	add	a3,a2,a4
ffffffffc02013c2:	c02007b7          	lui	a5,0xc0200
ffffffffc02013c6:	2ef6ece3          	bltu	a3,a5,ffffffffc0201ebe <pmm_init+0xbe8>
ffffffffc02013ca:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02013ce:	77fd                	lui	a5,0xfffff
ffffffffc02013d0:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02013d2:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02013d4:	5086eb63          	bltu	a3,s0,ffffffffc02018ea <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02013d8:	00003517          	auipc	a0,0x3
ffffffffc02013dc:	67850513          	addi	a0,a0,1656 # ffffffffc0204a50 <commands+0x918>
ffffffffc02013e0:	d01fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02013e4:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02013e8:	0000c917          	auipc	s2,0xc
ffffffffc02013ec:	0b890913          	addi	s2,s2,184 # ffffffffc020d4a0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02013f0:	7b9c                	ld	a5,48(a5)
ffffffffc02013f2:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02013f4:	00003517          	auipc	a0,0x3
ffffffffc02013f8:	67450513          	addi	a0,a0,1652 # ffffffffc0204a68 <commands+0x930>
ffffffffc02013fc:	ce5fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0201400:	00007697          	auipc	a3,0x7
ffffffffc0201404:	c0068693          	addi	a3,a3,-1024 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0201408:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020140c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201410:	28f6ebe3          	bltu	a3,a5,ffffffffc0201ea6 <pmm_init+0xbd0>
ffffffffc0201414:	0009b783          	ld	a5,0(s3)
ffffffffc0201418:	8e9d                	sub	a3,a3,a5
ffffffffc020141a:	0000c797          	auipc	a5,0xc
ffffffffc020141e:	06d7bf23          	sd	a3,126(a5) # ffffffffc020d498 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201422:	100027f3          	csrr	a5,sstatus
ffffffffc0201426:	8b89                	andi	a5,a5,2
ffffffffc0201428:	4a079763          	bnez	a5,ffffffffc02018d6 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc020142c:	000b3783          	ld	a5,0(s6)
ffffffffc0201430:	779c                	ld	a5,40(a5)
ffffffffc0201432:	9782                	jalr	a5
ffffffffc0201434:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201436:	6098                	ld	a4,0(s1)
ffffffffc0201438:	c80007b7          	lui	a5,0xc8000
ffffffffc020143c:	83b1                	srli	a5,a5,0xc
ffffffffc020143e:	66e7e363          	bltu	a5,a4,ffffffffc0201aa4 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0201442:	00093503          	ld	a0,0(s2)
ffffffffc0201446:	62050f63          	beqz	a0,ffffffffc0201a84 <pmm_init+0x7ae>
ffffffffc020144a:	03451793          	slli	a5,a0,0x34
ffffffffc020144e:	62079b63          	bnez	a5,ffffffffc0201a84 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0201452:	4601                	li	a2,0
ffffffffc0201454:	4581                	li	a1,0
ffffffffc0201456:	c9bff0ef          	jal	ra,ffffffffc02010f0 <get_page>
ffffffffc020145a:	60051563          	bnez	a0,ffffffffc0201a64 <pmm_init+0x78e>
ffffffffc020145e:	100027f3          	csrr	a5,sstatus
ffffffffc0201462:	8b89                	andi	a5,a5,2
ffffffffc0201464:	44079e63          	bnez	a5,ffffffffc02018c0 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201468:	000b3783          	ld	a5,0(s6)
ffffffffc020146c:	4505                	li	a0,1
ffffffffc020146e:	6f9c                	ld	a5,24(a5)
ffffffffc0201470:	9782                	jalr	a5
ffffffffc0201472:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0201474:	00093503          	ld	a0,0(s2)
ffffffffc0201478:	4681                	li	a3,0
ffffffffc020147a:	4601                	li	a2,0
ffffffffc020147c:	85d2                	mv	a1,s4
ffffffffc020147e:	d63ff0ef          	jal	ra,ffffffffc02011e0 <page_insert>
ffffffffc0201482:	26051ae3          	bnez	a0,ffffffffc0201ef6 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0201486:	00093503          	ld	a0,0(s2)
ffffffffc020148a:	4601                	li	a2,0
ffffffffc020148c:	4581                	li	a1,0
ffffffffc020148e:	a3bff0ef          	jal	ra,ffffffffc0200ec8 <get_pte>
ffffffffc0201492:	240502e3          	beqz	a0,ffffffffc0201ed6 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0201496:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0201498:	0017f713          	andi	a4,a5,1
ffffffffc020149c:	5a070263          	beqz	a4,ffffffffc0201a40 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02014a0:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02014a2:	078a                	slli	a5,a5,0x2
ffffffffc02014a4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02014a6:	58e7fb63          	bgeu	a5,a4,ffffffffc0201a3c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02014aa:	000bb683          	ld	a3,0(s7)
ffffffffc02014ae:	fff80637          	lui	a2,0xfff80
ffffffffc02014b2:	97b2                	add	a5,a5,a2
ffffffffc02014b4:	079a                	slli	a5,a5,0x6
ffffffffc02014b6:	97b6                	add	a5,a5,a3
ffffffffc02014b8:	14fa17e3          	bne	s4,a5,ffffffffc0201e06 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02014bc:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc02014c0:	4785                	li	a5,1
ffffffffc02014c2:	12f692e3          	bne	a3,a5,ffffffffc0201de6 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02014c6:	00093503          	ld	a0,0(s2)
ffffffffc02014ca:	77fd                	lui	a5,0xfffff
ffffffffc02014cc:	6114                	ld	a3,0(a0)
ffffffffc02014ce:	068a                	slli	a3,a3,0x2
ffffffffc02014d0:	8efd                	and	a3,a3,a5
ffffffffc02014d2:	00c6d613          	srli	a2,a3,0xc
ffffffffc02014d6:	0ee67ce3          	bgeu	a2,a4,ffffffffc0201dce <pmm_init+0xaf8>
ffffffffc02014da:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02014de:	96e2                	add	a3,a3,s8
ffffffffc02014e0:	0006ba83          	ld	s5,0(a3)
ffffffffc02014e4:	0a8a                	slli	s5,s5,0x2
ffffffffc02014e6:	00fafab3          	and	s5,s5,a5
ffffffffc02014ea:	00cad793          	srli	a5,s5,0xc
ffffffffc02014ee:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0201db4 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02014f2:	4601                	li	a2,0
ffffffffc02014f4:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02014f6:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02014f8:	9d1ff0ef          	jal	ra,ffffffffc0200ec8 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02014fc:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02014fe:	55551363          	bne	a0,s5,ffffffffc0201a44 <pmm_init+0x76e>
ffffffffc0201502:	100027f3          	csrr	a5,sstatus
ffffffffc0201506:	8b89                	andi	a5,a5,2
ffffffffc0201508:	3a079163          	bnez	a5,ffffffffc02018aa <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020150c:	000b3783          	ld	a5,0(s6)
ffffffffc0201510:	4505                	li	a0,1
ffffffffc0201512:	6f9c                	ld	a5,24(a5)
ffffffffc0201514:	9782                	jalr	a5
ffffffffc0201516:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201518:	00093503          	ld	a0,0(s2)
ffffffffc020151c:	46d1                	li	a3,20
ffffffffc020151e:	6605                	lui	a2,0x1
ffffffffc0201520:	85e2                	mv	a1,s8
ffffffffc0201522:	cbfff0ef          	jal	ra,ffffffffc02011e0 <page_insert>
ffffffffc0201526:	060517e3          	bnez	a0,ffffffffc0201d94 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020152a:	00093503          	ld	a0,0(s2)
ffffffffc020152e:	4601                	li	a2,0
ffffffffc0201530:	6585                	lui	a1,0x1
ffffffffc0201532:	997ff0ef          	jal	ra,ffffffffc0200ec8 <get_pte>
ffffffffc0201536:	02050fe3          	beqz	a0,ffffffffc0201d74 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020153a:	611c                	ld	a5,0(a0)
ffffffffc020153c:	0107f713          	andi	a4,a5,16
ffffffffc0201540:	7c070e63          	beqz	a4,ffffffffc0201d1c <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0201544:	8b91                	andi	a5,a5,4
ffffffffc0201546:	7a078b63          	beqz	a5,ffffffffc0201cfc <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020154a:	00093503          	ld	a0,0(s2)
ffffffffc020154e:	611c                	ld	a5,0(a0)
ffffffffc0201550:	8bc1                	andi	a5,a5,16
ffffffffc0201552:	78078563          	beqz	a5,ffffffffc0201cdc <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0201556:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc020155a:	4785                	li	a5,1
ffffffffc020155c:	76f71063          	bne	a4,a5,ffffffffc0201cbc <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0201560:	4681                	li	a3,0
ffffffffc0201562:	6605                	lui	a2,0x1
ffffffffc0201564:	85d2                	mv	a1,s4
ffffffffc0201566:	c7bff0ef          	jal	ra,ffffffffc02011e0 <page_insert>
ffffffffc020156a:	72051963          	bnez	a0,ffffffffc0201c9c <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc020156e:	000a2703          	lw	a4,0(s4)
ffffffffc0201572:	4789                	li	a5,2
ffffffffc0201574:	70f71463          	bne	a4,a5,ffffffffc0201c7c <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0201578:	000c2783          	lw	a5,0(s8)
ffffffffc020157c:	6e079063          	bnez	a5,ffffffffc0201c5c <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201580:	00093503          	ld	a0,0(s2)
ffffffffc0201584:	4601                	li	a2,0
ffffffffc0201586:	6585                	lui	a1,0x1
ffffffffc0201588:	941ff0ef          	jal	ra,ffffffffc0200ec8 <get_pte>
ffffffffc020158c:	6a050863          	beqz	a0,ffffffffc0201c3c <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0201590:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0201592:	00177793          	andi	a5,a4,1
ffffffffc0201596:	4a078563          	beqz	a5,ffffffffc0201a40 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020159a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020159c:	00271793          	slli	a5,a4,0x2
ffffffffc02015a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02015a2:	48d7fd63          	bgeu	a5,a3,ffffffffc0201a3c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02015a6:	000bb683          	ld	a3,0(s7)
ffffffffc02015aa:	fff80ab7          	lui	s5,0xfff80
ffffffffc02015ae:	97d6                	add	a5,a5,s5
ffffffffc02015b0:	079a                	slli	a5,a5,0x6
ffffffffc02015b2:	97b6                	add	a5,a5,a3
ffffffffc02015b4:	66fa1463          	bne	s4,a5,ffffffffc0201c1c <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc02015b8:	8b41                	andi	a4,a4,16
ffffffffc02015ba:	64071163          	bnez	a4,ffffffffc0201bfc <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02015be:	00093503          	ld	a0,0(s2)
ffffffffc02015c2:	4581                	li	a1,0
ffffffffc02015c4:	b81ff0ef          	jal	ra,ffffffffc0201144 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02015c8:	000a2c83          	lw	s9,0(s4)
ffffffffc02015cc:	4785                	li	a5,1
ffffffffc02015ce:	60fc9763          	bne	s9,a5,ffffffffc0201bdc <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc02015d2:	000c2783          	lw	a5,0(s8)
ffffffffc02015d6:	5e079363          	bnez	a5,ffffffffc0201bbc <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02015da:	00093503          	ld	a0,0(s2)
ffffffffc02015de:	6585                	lui	a1,0x1
ffffffffc02015e0:	b65ff0ef          	jal	ra,ffffffffc0201144 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02015e4:	000a2783          	lw	a5,0(s4)
ffffffffc02015e8:	52079a63          	bnez	a5,ffffffffc0201b1c <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc02015ec:	000c2783          	lw	a5,0(s8)
ffffffffc02015f0:	50079663          	bnez	a5,ffffffffc0201afc <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02015f4:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02015f8:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02015fa:	000a3683          	ld	a3,0(s4)
ffffffffc02015fe:	068a                	slli	a3,a3,0x2
ffffffffc0201600:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0201602:	42b6fd63          	bgeu	a3,a1,ffffffffc0201a3c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201606:	000bb503          	ld	a0,0(s7)
ffffffffc020160a:	96d6                	add	a3,a3,s5
ffffffffc020160c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020160e:	00d507b3          	add	a5,a0,a3
ffffffffc0201612:	439c                	lw	a5,0(a5)
ffffffffc0201614:	4d979463          	bne	a5,s9,ffffffffc0201adc <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0201618:	8699                	srai	a3,a3,0x6
ffffffffc020161a:	00080637          	lui	a2,0x80
ffffffffc020161e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0201620:	00c69713          	slli	a4,a3,0xc
ffffffffc0201624:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201626:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201628:	48b77e63          	bgeu	a4,a1,ffffffffc0201ac4 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020162c:	0009b703          	ld	a4,0(s3)
ffffffffc0201630:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0201632:	629c                	ld	a5,0(a3)
ffffffffc0201634:	078a                	slli	a5,a5,0x2
ffffffffc0201636:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201638:	40b7f263          	bgeu	a5,a1,ffffffffc0201a3c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020163c:	8f91                	sub	a5,a5,a2
ffffffffc020163e:	079a                	slli	a5,a5,0x6
ffffffffc0201640:	953e                	add	a0,a0,a5
ffffffffc0201642:	100027f3          	csrr	a5,sstatus
ffffffffc0201646:	8b89                	andi	a5,a5,2
ffffffffc0201648:	30079963          	bnez	a5,ffffffffc020195a <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc020164c:	000b3783          	ld	a5,0(s6)
ffffffffc0201650:	4585                	li	a1,1
ffffffffc0201652:	739c                	ld	a5,32(a5)
ffffffffc0201654:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201656:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc020165a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020165c:	078a                	slli	a5,a5,0x2
ffffffffc020165e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201660:	3ce7fe63          	bgeu	a5,a4,ffffffffc0201a3c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201664:	000bb503          	ld	a0,0(s7)
ffffffffc0201668:	fff80737          	lui	a4,0xfff80
ffffffffc020166c:	97ba                	add	a5,a5,a4
ffffffffc020166e:	079a                	slli	a5,a5,0x6
ffffffffc0201670:	953e                	add	a0,a0,a5
ffffffffc0201672:	100027f3          	csrr	a5,sstatus
ffffffffc0201676:	8b89                	andi	a5,a5,2
ffffffffc0201678:	2c079563          	bnez	a5,ffffffffc0201942 <pmm_init+0x66c>
ffffffffc020167c:	000b3783          	ld	a5,0(s6)
ffffffffc0201680:	4585                	li	a1,1
ffffffffc0201682:	739c                	ld	a5,32(a5)
ffffffffc0201684:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0201686:	00093783          	ld	a5,0(s2)
ffffffffc020168a:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b14>
    asm volatile("sfence.vma");
ffffffffc020168e:	12000073          	sfence.vma
ffffffffc0201692:	100027f3          	csrr	a5,sstatus
ffffffffc0201696:	8b89                	andi	a5,a5,2
ffffffffc0201698:	28079b63          	bnez	a5,ffffffffc020192e <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc020169c:	000b3783          	ld	a5,0(s6)
ffffffffc02016a0:	779c                	ld	a5,40(a5)
ffffffffc02016a2:	9782                	jalr	a5
ffffffffc02016a4:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02016a6:	4b441b63          	bne	s0,s4,ffffffffc0201b5c <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02016aa:	00003517          	auipc	a0,0x3
ffffffffc02016ae:	6fe50513          	addi	a0,a0,1790 # ffffffffc0204da8 <commands+0xc70>
ffffffffc02016b2:	a2ffe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02016b6:	100027f3          	csrr	a5,sstatus
ffffffffc02016ba:	8b89                	andi	a5,a5,2
ffffffffc02016bc:	24079f63          	bnez	a5,ffffffffc020191a <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc02016c0:	000b3783          	ld	a5,0(s6)
ffffffffc02016c4:	779c                	ld	a5,40(a5)
ffffffffc02016c6:	9782                	jalr	a5
ffffffffc02016c8:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02016ca:	6098                	ld	a4,0(s1)
ffffffffc02016cc:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02016d0:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02016d2:	00c71793          	slli	a5,a4,0xc
ffffffffc02016d6:	6a05                	lui	s4,0x1
ffffffffc02016d8:	02f47c63          	bgeu	s0,a5,ffffffffc0201710 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02016dc:	00c45793          	srli	a5,s0,0xc
ffffffffc02016e0:	00093503          	ld	a0,0(s2)
ffffffffc02016e4:	2ee7ff63          	bgeu	a5,a4,ffffffffc02019e2 <pmm_init+0x70c>
ffffffffc02016e8:	0009b583          	ld	a1,0(s3)
ffffffffc02016ec:	4601                	li	a2,0
ffffffffc02016ee:	95a2                	add	a1,a1,s0
ffffffffc02016f0:	fd8ff0ef          	jal	ra,ffffffffc0200ec8 <get_pte>
ffffffffc02016f4:	32050463          	beqz	a0,ffffffffc0201a1c <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02016f8:	611c                	ld	a5,0(a0)
ffffffffc02016fa:	078a                	slli	a5,a5,0x2
ffffffffc02016fc:	0157f7b3          	and	a5,a5,s5
ffffffffc0201700:	2e879e63          	bne	a5,s0,ffffffffc02019fc <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201704:	6098                	ld	a4,0(s1)
ffffffffc0201706:	9452                	add	s0,s0,s4
ffffffffc0201708:	00c71793          	slli	a5,a4,0xc
ffffffffc020170c:	fcf468e3          	bltu	s0,a5,ffffffffc02016dc <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0201710:	00093783          	ld	a5,0(s2)
ffffffffc0201714:	639c                	ld	a5,0(a5)
ffffffffc0201716:	42079363          	bnez	a5,ffffffffc0201b3c <pmm_init+0x866>
ffffffffc020171a:	100027f3          	csrr	a5,sstatus
ffffffffc020171e:	8b89                	andi	a5,a5,2
ffffffffc0201720:	24079963          	bnez	a5,ffffffffc0201972 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201724:	000b3783          	ld	a5,0(s6)
ffffffffc0201728:	4505                	li	a0,1
ffffffffc020172a:	6f9c                	ld	a5,24(a5)
ffffffffc020172c:	9782                	jalr	a5
ffffffffc020172e:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201730:	00093503          	ld	a0,0(s2)
ffffffffc0201734:	4699                	li	a3,6
ffffffffc0201736:	10000613          	li	a2,256
ffffffffc020173a:	85d2                	mv	a1,s4
ffffffffc020173c:	aa5ff0ef          	jal	ra,ffffffffc02011e0 <page_insert>
ffffffffc0201740:	44051e63          	bnez	a0,ffffffffc0201b9c <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0201744:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201748:	4785                	li	a5,1
ffffffffc020174a:	42f71963          	bne	a4,a5,ffffffffc0201b7c <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020174e:	00093503          	ld	a0,0(s2)
ffffffffc0201752:	6405                	lui	s0,0x1
ffffffffc0201754:	4699                	li	a3,6
ffffffffc0201756:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc020175a:	85d2                	mv	a1,s4
ffffffffc020175c:	a85ff0ef          	jal	ra,ffffffffc02011e0 <page_insert>
ffffffffc0201760:	72051363          	bnez	a0,ffffffffc0201e86 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0201764:	000a2703          	lw	a4,0(s4)
ffffffffc0201768:	4789                	li	a5,2
ffffffffc020176a:	6ef71e63          	bne	a4,a5,ffffffffc0201e66 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020176e:	00003597          	auipc	a1,0x3
ffffffffc0201772:	78258593          	addi	a1,a1,1922 # ffffffffc0204ef0 <commands+0xdb8>
ffffffffc0201776:	10000513          	li	a0,256
ffffffffc020177a:	276020ef          	jal	ra,ffffffffc02039f0 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020177e:	10040593          	addi	a1,s0,256
ffffffffc0201782:	10000513          	li	a0,256
ffffffffc0201786:	27c020ef          	jal	ra,ffffffffc0203a02 <strcmp>
ffffffffc020178a:	6a051e63          	bnez	a0,ffffffffc0201e46 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc020178e:	000bb683          	ld	a3,0(s7)
ffffffffc0201792:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0201796:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0201798:	40da06b3          	sub	a3,s4,a3
ffffffffc020179c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020179e:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc02017a0:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02017a2:	8031                	srli	s0,s0,0xc
ffffffffc02017a4:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02017a8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02017aa:	30f77d63          	bgeu	a4,a5,ffffffffc0201ac4 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02017ae:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02017b2:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02017b6:	96be                	add	a3,a3,a5
ffffffffc02017b8:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02017bc:	1fe020ef          	jal	ra,ffffffffc02039ba <strlen>
ffffffffc02017c0:	66051363          	bnez	a0,ffffffffc0201e26 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc02017c4:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02017c8:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02017ca:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b14>
ffffffffc02017ce:	068a                	slli	a3,a3,0x2
ffffffffc02017d0:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02017d2:	26f6f563          	bgeu	a3,a5,ffffffffc0201a3c <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc02017d6:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02017d8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02017da:	2ef47563          	bgeu	s0,a5,ffffffffc0201ac4 <pmm_init+0x7ee>
ffffffffc02017de:	0009b403          	ld	s0,0(s3)
ffffffffc02017e2:	9436                	add	s0,s0,a3
ffffffffc02017e4:	100027f3          	csrr	a5,sstatus
ffffffffc02017e8:	8b89                	andi	a5,a5,2
ffffffffc02017ea:	1e079163          	bnez	a5,ffffffffc02019cc <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc02017ee:	000b3783          	ld	a5,0(s6)
ffffffffc02017f2:	4585                	li	a1,1
ffffffffc02017f4:	8552                	mv	a0,s4
ffffffffc02017f6:	739c                	ld	a5,32(a5)
ffffffffc02017f8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02017fa:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc02017fc:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02017fe:	078a                	slli	a5,a5,0x2
ffffffffc0201800:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201802:	22e7fd63          	bgeu	a5,a4,ffffffffc0201a3c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201806:	000bb503          	ld	a0,0(s7)
ffffffffc020180a:	fff80737          	lui	a4,0xfff80
ffffffffc020180e:	97ba                	add	a5,a5,a4
ffffffffc0201810:	079a                	slli	a5,a5,0x6
ffffffffc0201812:	953e                	add	a0,a0,a5
ffffffffc0201814:	100027f3          	csrr	a5,sstatus
ffffffffc0201818:	8b89                	andi	a5,a5,2
ffffffffc020181a:	18079d63          	bnez	a5,ffffffffc02019b4 <pmm_init+0x6de>
ffffffffc020181e:	000b3783          	ld	a5,0(s6)
ffffffffc0201822:	4585                	li	a1,1
ffffffffc0201824:	739c                	ld	a5,32(a5)
ffffffffc0201826:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201828:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc020182c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020182e:	078a                	slli	a5,a5,0x2
ffffffffc0201830:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201832:	20e7f563          	bgeu	a5,a4,ffffffffc0201a3c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201836:	000bb503          	ld	a0,0(s7)
ffffffffc020183a:	fff80737          	lui	a4,0xfff80
ffffffffc020183e:	97ba                	add	a5,a5,a4
ffffffffc0201840:	079a                	slli	a5,a5,0x6
ffffffffc0201842:	953e                	add	a0,a0,a5
ffffffffc0201844:	100027f3          	csrr	a5,sstatus
ffffffffc0201848:	8b89                	andi	a5,a5,2
ffffffffc020184a:	14079963          	bnez	a5,ffffffffc020199c <pmm_init+0x6c6>
ffffffffc020184e:	000b3783          	ld	a5,0(s6)
ffffffffc0201852:	4585                	li	a1,1
ffffffffc0201854:	739c                	ld	a5,32(a5)
ffffffffc0201856:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0201858:	00093783          	ld	a5,0(s2)
ffffffffc020185c:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0201860:	12000073          	sfence.vma
ffffffffc0201864:	100027f3          	csrr	a5,sstatus
ffffffffc0201868:	8b89                	andi	a5,a5,2
ffffffffc020186a:	10079f63          	bnez	a5,ffffffffc0201988 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc020186e:	000b3783          	ld	a5,0(s6)
ffffffffc0201872:	779c                	ld	a5,40(a5)
ffffffffc0201874:	9782                	jalr	a5
ffffffffc0201876:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0201878:	4c8c1e63          	bne	s8,s0,ffffffffc0201d54 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020187c:	00003517          	auipc	a0,0x3
ffffffffc0201880:	6ec50513          	addi	a0,a0,1772 # ffffffffc0204f68 <commands+0xe30>
ffffffffc0201884:	85dfe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc0201888:	7406                	ld	s0,96(sp)
ffffffffc020188a:	70a6                	ld	ra,104(sp)
ffffffffc020188c:	64e6                	ld	s1,88(sp)
ffffffffc020188e:	6946                	ld	s2,80(sp)
ffffffffc0201890:	69a6                	ld	s3,72(sp)
ffffffffc0201892:	6a06                	ld	s4,64(sp)
ffffffffc0201894:	7ae2                	ld	s5,56(sp)
ffffffffc0201896:	7b42                	ld	s6,48(sp)
ffffffffc0201898:	7ba2                	ld	s7,40(sp)
ffffffffc020189a:	7c02                	ld	s8,32(sp)
ffffffffc020189c:	6ce2                	ld	s9,24(sp)
ffffffffc020189e:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc02018a0:	4ef0006f          	j	ffffffffc020258e <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc02018a4:	c80007b7          	lui	a5,0xc8000
ffffffffc02018a8:	bc7d                	j	ffffffffc0201366 <pmm_init+0x90>
        intr_disable();
ffffffffc02018aa:	88cff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02018ae:	000b3783          	ld	a5,0(s6)
ffffffffc02018b2:	4505                	li	a0,1
ffffffffc02018b4:	6f9c                	ld	a5,24(a5)
ffffffffc02018b6:	9782                	jalr	a5
ffffffffc02018b8:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02018ba:	876ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02018be:	b9a9                	j	ffffffffc0201518 <pmm_init+0x242>
        intr_disable();
ffffffffc02018c0:	876ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02018c4:	000b3783          	ld	a5,0(s6)
ffffffffc02018c8:	4505                	li	a0,1
ffffffffc02018ca:	6f9c                	ld	a5,24(a5)
ffffffffc02018cc:	9782                	jalr	a5
ffffffffc02018ce:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02018d0:	860ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02018d4:	b645                	j	ffffffffc0201474 <pmm_init+0x19e>
        intr_disable();
ffffffffc02018d6:	860ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02018da:	000b3783          	ld	a5,0(s6)
ffffffffc02018de:	779c                	ld	a5,40(a5)
ffffffffc02018e0:	9782                	jalr	a5
ffffffffc02018e2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02018e4:	84cff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02018e8:	b6b9                	j	ffffffffc0201436 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018ea:	6705                	lui	a4,0x1
ffffffffc02018ec:	177d                	addi	a4,a4,-1
ffffffffc02018ee:	96ba                	add	a3,a3,a4
ffffffffc02018f0:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc02018f2:	00c7d713          	srli	a4,a5,0xc
ffffffffc02018f6:	14a77363          	bgeu	a4,a0,ffffffffc0201a3c <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc02018fa:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc02018fe:	fff80537          	lui	a0,0xfff80
ffffffffc0201902:	972a                	add	a4,a4,a0
ffffffffc0201904:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201906:	8c1d                	sub	s0,s0,a5
ffffffffc0201908:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020190c:	00c45593          	srli	a1,s0,0xc
ffffffffc0201910:	9532                	add	a0,a0,a2
ffffffffc0201912:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0201914:	0009b583          	ld	a1,0(s3)
}
ffffffffc0201918:	b4c1                	j	ffffffffc02013d8 <pmm_init+0x102>
        intr_disable();
ffffffffc020191a:	81cff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020191e:	000b3783          	ld	a5,0(s6)
ffffffffc0201922:	779c                	ld	a5,40(a5)
ffffffffc0201924:	9782                	jalr	a5
ffffffffc0201926:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0201928:	808ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020192c:	bb79                	j	ffffffffc02016ca <pmm_init+0x3f4>
        intr_disable();
ffffffffc020192e:	808ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0201932:	000b3783          	ld	a5,0(s6)
ffffffffc0201936:	779c                	ld	a5,40(a5)
ffffffffc0201938:	9782                	jalr	a5
ffffffffc020193a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020193c:	ff5fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201940:	b39d                	j	ffffffffc02016a6 <pmm_init+0x3d0>
ffffffffc0201942:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201944:	ff3fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201948:	000b3783          	ld	a5,0(s6)
ffffffffc020194c:	6522                	ld	a0,8(sp)
ffffffffc020194e:	4585                	li	a1,1
ffffffffc0201950:	739c                	ld	a5,32(a5)
ffffffffc0201952:	9782                	jalr	a5
        intr_enable();
ffffffffc0201954:	fddfe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201958:	b33d                	j	ffffffffc0201686 <pmm_init+0x3b0>
ffffffffc020195a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020195c:	fdbfe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0201960:	000b3783          	ld	a5,0(s6)
ffffffffc0201964:	6522                	ld	a0,8(sp)
ffffffffc0201966:	4585                	li	a1,1
ffffffffc0201968:	739c                	ld	a5,32(a5)
ffffffffc020196a:	9782                	jalr	a5
        intr_enable();
ffffffffc020196c:	fc5fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201970:	b1dd                	j	ffffffffc0201656 <pmm_init+0x380>
        intr_disable();
ffffffffc0201972:	fc5fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201976:	000b3783          	ld	a5,0(s6)
ffffffffc020197a:	4505                	li	a0,1
ffffffffc020197c:	6f9c                	ld	a5,24(a5)
ffffffffc020197e:	9782                	jalr	a5
ffffffffc0201980:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0201982:	faffe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201986:	b36d                	j	ffffffffc0201730 <pmm_init+0x45a>
        intr_disable();
ffffffffc0201988:	faffe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020198c:	000b3783          	ld	a5,0(s6)
ffffffffc0201990:	779c                	ld	a5,40(a5)
ffffffffc0201992:	9782                	jalr	a5
ffffffffc0201994:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201996:	f9bfe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020199a:	bdf9                	j	ffffffffc0201878 <pmm_init+0x5a2>
ffffffffc020199c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020199e:	f99fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02019a2:	000b3783          	ld	a5,0(s6)
ffffffffc02019a6:	6522                	ld	a0,8(sp)
ffffffffc02019a8:	4585                	li	a1,1
ffffffffc02019aa:	739c                	ld	a5,32(a5)
ffffffffc02019ac:	9782                	jalr	a5
        intr_enable();
ffffffffc02019ae:	f83fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02019b2:	b55d                	j	ffffffffc0201858 <pmm_init+0x582>
ffffffffc02019b4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02019b6:	f81fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02019ba:	000b3783          	ld	a5,0(s6)
ffffffffc02019be:	6522                	ld	a0,8(sp)
ffffffffc02019c0:	4585                	li	a1,1
ffffffffc02019c2:	739c                	ld	a5,32(a5)
ffffffffc02019c4:	9782                	jalr	a5
        intr_enable();
ffffffffc02019c6:	f6bfe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02019ca:	bdb9                	j	ffffffffc0201828 <pmm_init+0x552>
        intr_disable();
ffffffffc02019cc:	f6bfe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02019d0:	000b3783          	ld	a5,0(s6)
ffffffffc02019d4:	4585                	li	a1,1
ffffffffc02019d6:	8552                	mv	a0,s4
ffffffffc02019d8:	739c                	ld	a5,32(a5)
ffffffffc02019da:	9782                	jalr	a5
        intr_enable();
ffffffffc02019dc:	f55fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02019e0:	bd29                	j	ffffffffc02017fa <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02019e2:	86a2                	mv	a3,s0
ffffffffc02019e4:	00003617          	auipc	a2,0x3
ffffffffc02019e8:	f9460613          	addi	a2,a2,-108 # ffffffffc0204978 <commands+0x840>
ffffffffc02019ec:	1a400593          	li	a1,420
ffffffffc02019f0:	00003517          	auipc	a0,0x3
ffffffffc02019f4:	fb050513          	addi	a0,a0,-80 # ffffffffc02049a0 <commands+0x868>
ffffffffc02019f8:	fe6fe0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02019fc:	00003697          	auipc	a3,0x3
ffffffffc0201a00:	40c68693          	addi	a3,a3,1036 # ffffffffc0204e08 <commands+0xcd0>
ffffffffc0201a04:	00003617          	auipc	a2,0x3
ffffffffc0201a08:	0a460613          	addi	a2,a2,164 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201a0c:	1a500593          	li	a1,421
ffffffffc0201a10:	00003517          	auipc	a0,0x3
ffffffffc0201a14:	f9050513          	addi	a0,a0,-112 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201a18:	fc6fe0ef          	jal	ra,ffffffffc02001de <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201a1c:	00003697          	auipc	a3,0x3
ffffffffc0201a20:	3ac68693          	addi	a3,a3,940 # ffffffffc0204dc8 <commands+0xc90>
ffffffffc0201a24:	00003617          	auipc	a2,0x3
ffffffffc0201a28:	08460613          	addi	a2,a2,132 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201a2c:	1a400593          	li	a1,420
ffffffffc0201a30:	00003517          	auipc	a0,0x3
ffffffffc0201a34:	f7050513          	addi	a0,a0,-144 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201a38:	fa6fe0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc0201a3c:	b9eff0ef          	jal	ra,ffffffffc0200dda <pa2page.part.0>
ffffffffc0201a40:	bb6ff0ef          	jal	ra,ffffffffc0200df6 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201a44:	00003697          	auipc	a3,0x3
ffffffffc0201a48:	17c68693          	addi	a3,a3,380 # ffffffffc0204bc0 <commands+0xa88>
ffffffffc0201a4c:	00003617          	auipc	a2,0x3
ffffffffc0201a50:	05c60613          	addi	a2,a2,92 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201a54:	17400593          	li	a1,372
ffffffffc0201a58:	00003517          	auipc	a0,0x3
ffffffffc0201a5c:	f4850513          	addi	a0,a0,-184 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201a60:	f7efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0201a64:	00003697          	auipc	a3,0x3
ffffffffc0201a68:	09c68693          	addi	a3,a3,156 # ffffffffc0204b00 <commands+0x9c8>
ffffffffc0201a6c:	00003617          	auipc	a2,0x3
ffffffffc0201a70:	03c60613          	addi	a2,a2,60 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201a74:	16700593          	li	a1,359
ffffffffc0201a78:	00003517          	auipc	a0,0x3
ffffffffc0201a7c:	f2850513          	addi	a0,a0,-216 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201a80:	f5efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0201a84:	00003697          	auipc	a3,0x3
ffffffffc0201a88:	03c68693          	addi	a3,a3,60 # ffffffffc0204ac0 <commands+0x988>
ffffffffc0201a8c:	00003617          	auipc	a2,0x3
ffffffffc0201a90:	01c60613          	addi	a2,a2,28 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201a94:	16600593          	li	a1,358
ffffffffc0201a98:	00003517          	auipc	a0,0x3
ffffffffc0201a9c:	f0850513          	addi	a0,a0,-248 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201aa0:	f3efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201aa4:	00003697          	auipc	a3,0x3
ffffffffc0201aa8:	fe468693          	addi	a3,a3,-28 # ffffffffc0204a88 <commands+0x950>
ffffffffc0201aac:	00003617          	auipc	a2,0x3
ffffffffc0201ab0:	ffc60613          	addi	a2,a2,-4 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201ab4:	16500593          	li	a1,357
ffffffffc0201ab8:	00003517          	auipc	a0,0x3
ffffffffc0201abc:	ee850513          	addi	a0,a0,-280 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201ac0:	f1efe0ef          	jal	ra,ffffffffc02001de <__panic>
    return KADDR(page2pa(page));
ffffffffc0201ac4:	00003617          	auipc	a2,0x3
ffffffffc0201ac8:	eb460613          	addi	a2,a2,-332 # ffffffffc0204978 <commands+0x840>
ffffffffc0201acc:	07100593          	li	a1,113
ffffffffc0201ad0:	00003517          	auipc	a0,0x3
ffffffffc0201ad4:	e7050513          	addi	a0,a0,-400 # ffffffffc0204940 <commands+0x808>
ffffffffc0201ad8:	f06fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0201adc:	00003697          	auipc	a3,0x3
ffffffffc0201ae0:	27468693          	addi	a3,a3,628 # ffffffffc0204d50 <commands+0xc18>
ffffffffc0201ae4:	00003617          	auipc	a2,0x3
ffffffffc0201ae8:	fc460613          	addi	a2,a2,-60 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201aec:	18d00593          	li	a1,397
ffffffffc0201af0:	00003517          	auipc	a0,0x3
ffffffffc0201af4:	eb050513          	addi	a0,a0,-336 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201af8:	ee6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201afc:	00003697          	auipc	a3,0x3
ffffffffc0201b00:	20c68693          	addi	a3,a3,524 # ffffffffc0204d08 <commands+0xbd0>
ffffffffc0201b04:	00003617          	auipc	a2,0x3
ffffffffc0201b08:	fa460613          	addi	a2,a2,-92 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201b0c:	18b00593          	li	a1,395
ffffffffc0201b10:	00003517          	auipc	a0,0x3
ffffffffc0201b14:	e9050513          	addi	a0,a0,-368 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201b18:	ec6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0201b1c:	00003697          	auipc	a3,0x3
ffffffffc0201b20:	21c68693          	addi	a3,a3,540 # ffffffffc0204d38 <commands+0xc00>
ffffffffc0201b24:	00003617          	auipc	a2,0x3
ffffffffc0201b28:	f8460613          	addi	a2,a2,-124 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201b2c:	18a00593          	li	a1,394
ffffffffc0201b30:	00003517          	auipc	a0,0x3
ffffffffc0201b34:	e7050513          	addi	a0,a0,-400 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201b38:	ea6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0201b3c:	00003697          	auipc	a3,0x3
ffffffffc0201b40:	2e468693          	addi	a3,a3,740 # ffffffffc0204e20 <commands+0xce8>
ffffffffc0201b44:	00003617          	auipc	a2,0x3
ffffffffc0201b48:	f6460613          	addi	a2,a2,-156 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201b4c:	1a800593          	li	a1,424
ffffffffc0201b50:	00003517          	auipc	a0,0x3
ffffffffc0201b54:	e5050513          	addi	a0,a0,-432 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201b58:	e86fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0201b5c:	00003697          	auipc	a3,0x3
ffffffffc0201b60:	22468693          	addi	a3,a3,548 # ffffffffc0204d80 <commands+0xc48>
ffffffffc0201b64:	00003617          	auipc	a2,0x3
ffffffffc0201b68:	f4460613          	addi	a2,a2,-188 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201b6c:	19500593          	li	a1,405
ffffffffc0201b70:	00003517          	auipc	a0,0x3
ffffffffc0201b74:	e3050513          	addi	a0,a0,-464 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201b78:	e66fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p) == 1);
ffffffffc0201b7c:	00003697          	auipc	a3,0x3
ffffffffc0201b80:	2fc68693          	addi	a3,a3,764 # ffffffffc0204e78 <commands+0xd40>
ffffffffc0201b84:	00003617          	auipc	a2,0x3
ffffffffc0201b88:	f2460613          	addi	a2,a2,-220 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201b8c:	1ad00593          	li	a1,429
ffffffffc0201b90:	00003517          	auipc	a0,0x3
ffffffffc0201b94:	e1050513          	addi	a0,a0,-496 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201b98:	e46fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201b9c:	00003697          	auipc	a3,0x3
ffffffffc0201ba0:	29c68693          	addi	a3,a3,668 # ffffffffc0204e38 <commands+0xd00>
ffffffffc0201ba4:	00003617          	auipc	a2,0x3
ffffffffc0201ba8:	f0460613          	addi	a2,a2,-252 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201bac:	1ac00593          	li	a1,428
ffffffffc0201bb0:	00003517          	auipc	a0,0x3
ffffffffc0201bb4:	df050513          	addi	a0,a0,-528 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201bb8:	e26fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201bbc:	00003697          	auipc	a3,0x3
ffffffffc0201bc0:	14c68693          	addi	a3,a3,332 # ffffffffc0204d08 <commands+0xbd0>
ffffffffc0201bc4:	00003617          	auipc	a2,0x3
ffffffffc0201bc8:	ee460613          	addi	a2,a2,-284 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201bcc:	18700593          	li	a1,391
ffffffffc0201bd0:	00003517          	auipc	a0,0x3
ffffffffc0201bd4:	dd050513          	addi	a0,a0,-560 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201bd8:	e06fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201bdc:	00003697          	auipc	a3,0x3
ffffffffc0201be0:	fcc68693          	addi	a3,a3,-52 # ffffffffc0204ba8 <commands+0xa70>
ffffffffc0201be4:	00003617          	auipc	a2,0x3
ffffffffc0201be8:	ec460613          	addi	a2,a2,-316 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201bec:	18600593          	li	a1,390
ffffffffc0201bf0:	00003517          	auipc	a0,0x3
ffffffffc0201bf4:	db050513          	addi	a0,a0,-592 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201bf8:	de6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201bfc:	00003697          	auipc	a3,0x3
ffffffffc0201c00:	12468693          	addi	a3,a3,292 # ffffffffc0204d20 <commands+0xbe8>
ffffffffc0201c04:	00003617          	auipc	a2,0x3
ffffffffc0201c08:	ea460613          	addi	a2,a2,-348 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201c0c:	18300593          	li	a1,387
ffffffffc0201c10:	00003517          	auipc	a0,0x3
ffffffffc0201c14:	d9050513          	addi	a0,a0,-624 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201c18:	dc6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201c1c:	00003697          	auipc	a3,0x3
ffffffffc0201c20:	f7468693          	addi	a3,a3,-140 # ffffffffc0204b90 <commands+0xa58>
ffffffffc0201c24:	00003617          	auipc	a2,0x3
ffffffffc0201c28:	e8460613          	addi	a2,a2,-380 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201c2c:	18200593          	li	a1,386
ffffffffc0201c30:	00003517          	auipc	a0,0x3
ffffffffc0201c34:	d7050513          	addi	a0,a0,-656 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201c38:	da6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201c3c:	00003697          	auipc	a3,0x3
ffffffffc0201c40:	ff468693          	addi	a3,a3,-12 # ffffffffc0204c30 <commands+0xaf8>
ffffffffc0201c44:	00003617          	auipc	a2,0x3
ffffffffc0201c48:	e6460613          	addi	a2,a2,-412 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201c4c:	18100593          	li	a1,385
ffffffffc0201c50:	00003517          	auipc	a0,0x3
ffffffffc0201c54:	d5050513          	addi	a0,a0,-688 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201c58:	d86fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201c5c:	00003697          	auipc	a3,0x3
ffffffffc0201c60:	0ac68693          	addi	a3,a3,172 # ffffffffc0204d08 <commands+0xbd0>
ffffffffc0201c64:	00003617          	auipc	a2,0x3
ffffffffc0201c68:	e4460613          	addi	a2,a2,-444 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201c6c:	18000593          	li	a1,384
ffffffffc0201c70:	00003517          	auipc	a0,0x3
ffffffffc0201c74:	d3050513          	addi	a0,a0,-720 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201c78:	d66fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0201c7c:	00003697          	auipc	a3,0x3
ffffffffc0201c80:	07468693          	addi	a3,a3,116 # ffffffffc0204cf0 <commands+0xbb8>
ffffffffc0201c84:	00003617          	auipc	a2,0x3
ffffffffc0201c88:	e2460613          	addi	a2,a2,-476 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201c8c:	17f00593          	li	a1,383
ffffffffc0201c90:	00003517          	auipc	a0,0x3
ffffffffc0201c94:	d1050513          	addi	a0,a0,-752 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201c98:	d46fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0201c9c:	00003697          	auipc	a3,0x3
ffffffffc0201ca0:	02468693          	addi	a3,a3,36 # ffffffffc0204cc0 <commands+0xb88>
ffffffffc0201ca4:	00003617          	auipc	a2,0x3
ffffffffc0201ca8:	e0460613          	addi	a2,a2,-508 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201cac:	17e00593          	li	a1,382
ffffffffc0201cb0:	00003517          	auipc	a0,0x3
ffffffffc0201cb4:	cf050513          	addi	a0,a0,-784 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201cb8:	d26fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0201cbc:	00003697          	auipc	a3,0x3
ffffffffc0201cc0:	fec68693          	addi	a3,a3,-20 # ffffffffc0204ca8 <commands+0xb70>
ffffffffc0201cc4:	00003617          	auipc	a2,0x3
ffffffffc0201cc8:	de460613          	addi	a2,a2,-540 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201ccc:	17c00593          	li	a1,380
ffffffffc0201cd0:	00003517          	auipc	a0,0x3
ffffffffc0201cd4:	cd050513          	addi	a0,a0,-816 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201cd8:	d06fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0201cdc:	00003697          	auipc	a3,0x3
ffffffffc0201ce0:	fac68693          	addi	a3,a3,-84 # ffffffffc0204c88 <commands+0xb50>
ffffffffc0201ce4:	00003617          	auipc	a2,0x3
ffffffffc0201ce8:	dc460613          	addi	a2,a2,-572 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201cec:	17b00593          	li	a1,379
ffffffffc0201cf0:	00003517          	auipc	a0,0x3
ffffffffc0201cf4:	cb050513          	addi	a0,a0,-848 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201cf8:	ce6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201cfc:	00003697          	auipc	a3,0x3
ffffffffc0201d00:	f7c68693          	addi	a3,a3,-132 # ffffffffc0204c78 <commands+0xb40>
ffffffffc0201d04:	00003617          	auipc	a2,0x3
ffffffffc0201d08:	da460613          	addi	a2,a2,-604 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201d0c:	17a00593          	li	a1,378
ffffffffc0201d10:	00003517          	auipc	a0,0x3
ffffffffc0201d14:	c9050513          	addi	a0,a0,-880 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201d18:	cc6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201d1c:	00003697          	auipc	a3,0x3
ffffffffc0201d20:	f4c68693          	addi	a3,a3,-180 # ffffffffc0204c68 <commands+0xb30>
ffffffffc0201d24:	00003617          	auipc	a2,0x3
ffffffffc0201d28:	d8460613          	addi	a2,a2,-636 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201d2c:	17900593          	li	a1,377
ffffffffc0201d30:	00003517          	auipc	a0,0x3
ffffffffc0201d34:	c7050513          	addi	a0,a0,-912 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201d38:	ca6fe0ef          	jal	ra,ffffffffc02001de <__panic>
        panic("DTB memory info not available");
ffffffffc0201d3c:	00003617          	auipc	a2,0x3
ffffffffc0201d40:	c8c60613          	addi	a2,a2,-884 # ffffffffc02049c8 <commands+0x890>
ffffffffc0201d44:	06400593          	li	a1,100
ffffffffc0201d48:	00003517          	auipc	a0,0x3
ffffffffc0201d4c:	c5850513          	addi	a0,a0,-936 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201d50:	c8efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0201d54:	00003697          	auipc	a3,0x3
ffffffffc0201d58:	02c68693          	addi	a3,a3,44 # ffffffffc0204d80 <commands+0xc48>
ffffffffc0201d5c:	00003617          	auipc	a2,0x3
ffffffffc0201d60:	d4c60613          	addi	a2,a2,-692 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201d64:	1bf00593          	li	a1,447
ffffffffc0201d68:	00003517          	auipc	a0,0x3
ffffffffc0201d6c:	c3850513          	addi	a0,a0,-968 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201d70:	c6efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201d74:	00003697          	auipc	a3,0x3
ffffffffc0201d78:	ebc68693          	addi	a3,a3,-324 # ffffffffc0204c30 <commands+0xaf8>
ffffffffc0201d7c:	00003617          	auipc	a2,0x3
ffffffffc0201d80:	d2c60613          	addi	a2,a2,-724 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201d84:	17800593          	li	a1,376
ffffffffc0201d88:	00003517          	auipc	a0,0x3
ffffffffc0201d8c:	c1850513          	addi	a0,a0,-1000 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201d90:	c4efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201d94:	00003697          	auipc	a3,0x3
ffffffffc0201d98:	e5c68693          	addi	a3,a3,-420 # ffffffffc0204bf0 <commands+0xab8>
ffffffffc0201d9c:	00003617          	auipc	a2,0x3
ffffffffc0201da0:	d0c60613          	addi	a2,a2,-756 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201da4:	17700593          	li	a1,375
ffffffffc0201da8:	00003517          	auipc	a0,0x3
ffffffffc0201dac:	bf850513          	addi	a0,a0,-1032 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201db0:	c2efe0ef          	jal	ra,ffffffffc02001de <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201db4:	86d6                	mv	a3,s5
ffffffffc0201db6:	00003617          	auipc	a2,0x3
ffffffffc0201dba:	bc260613          	addi	a2,a2,-1086 # ffffffffc0204978 <commands+0x840>
ffffffffc0201dbe:	17300593          	li	a1,371
ffffffffc0201dc2:	00003517          	auipc	a0,0x3
ffffffffc0201dc6:	bde50513          	addi	a0,a0,-1058 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201dca:	c14fe0ef          	jal	ra,ffffffffc02001de <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0201dce:	00003617          	auipc	a2,0x3
ffffffffc0201dd2:	baa60613          	addi	a2,a2,-1110 # ffffffffc0204978 <commands+0x840>
ffffffffc0201dd6:	17200593          	li	a1,370
ffffffffc0201dda:	00003517          	auipc	a0,0x3
ffffffffc0201dde:	bc650513          	addi	a0,a0,-1082 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201de2:	bfcfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201de6:	00003697          	auipc	a3,0x3
ffffffffc0201dea:	dc268693          	addi	a3,a3,-574 # ffffffffc0204ba8 <commands+0xa70>
ffffffffc0201dee:	00003617          	auipc	a2,0x3
ffffffffc0201df2:	cba60613          	addi	a2,a2,-838 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201df6:	17000593          	li	a1,368
ffffffffc0201dfa:	00003517          	auipc	a0,0x3
ffffffffc0201dfe:	ba650513          	addi	a0,a0,-1114 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201e02:	bdcfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201e06:	00003697          	auipc	a3,0x3
ffffffffc0201e0a:	d8a68693          	addi	a3,a3,-630 # ffffffffc0204b90 <commands+0xa58>
ffffffffc0201e0e:	00003617          	auipc	a2,0x3
ffffffffc0201e12:	c9a60613          	addi	a2,a2,-870 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201e16:	16f00593          	li	a1,367
ffffffffc0201e1a:	00003517          	auipc	a0,0x3
ffffffffc0201e1e:	b8650513          	addi	a0,a0,-1146 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201e22:	bbcfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201e26:	00003697          	auipc	a3,0x3
ffffffffc0201e2a:	11a68693          	addi	a3,a3,282 # ffffffffc0204f40 <commands+0xe08>
ffffffffc0201e2e:	00003617          	auipc	a2,0x3
ffffffffc0201e32:	c7a60613          	addi	a2,a2,-902 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201e36:	1b600593          	li	a1,438
ffffffffc0201e3a:	00003517          	auipc	a0,0x3
ffffffffc0201e3e:	b6650513          	addi	a0,a0,-1178 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201e42:	b9cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201e46:	00003697          	auipc	a3,0x3
ffffffffc0201e4a:	0c268693          	addi	a3,a3,194 # ffffffffc0204f08 <commands+0xdd0>
ffffffffc0201e4e:	00003617          	auipc	a2,0x3
ffffffffc0201e52:	c5a60613          	addi	a2,a2,-934 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201e56:	1b300593          	li	a1,435
ffffffffc0201e5a:	00003517          	auipc	a0,0x3
ffffffffc0201e5e:	b4650513          	addi	a0,a0,-1210 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201e62:	b7cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p) == 2);
ffffffffc0201e66:	00003697          	auipc	a3,0x3
ffffffffc0201e6a:	07268693          	addi	a3,a3,114 # ffffffffc0204ed8 <commands+0xda0>
ffffffffc0201e6e:	00003617          	auipc	a2,0x3
ffffffffc0201e72:	c3a60613          	addi	a2,a2,-966 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201e76:	1af00593          	li	a1,431
ffffffffc0201e7a:	00003517          	auipc	a0,0x3
ffffffffc0201e7e:	b2650513          	addi	a0,a0,-1242 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201e82:	b5cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201e86:	00003697          	auipc	a3,0x3
ffffffffc0201e8a:	00a68693          	addi	a3,a3,10 # ffffffffc0204e90 <commands+0xd58>
ffffffffc0201e8e:	00003617          	auipc	a2,0x3
ffffffffc0201e92:	c1a60613          	addi	a2,a2,-998 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201e96:	1ae00593          	li	a1,430
ffffffffc0201e9a:	00003517          	auipc	a0,0x3
ffffffffc0201e9e:	b0650513          	addi	a0,a0,-1274 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201ea2:	b3cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0201ea6:	00003617          	auipc	a2,0x3
ffffffffc0201eaa:	b8260613          	addi	a2,a2,-1150 # ffffffffc0204a28 <commands+0x8f0>
ffffffffc0201eae:	0cb00593          	li	a1,203
ffffffffc0201eb2:	00003517          	auipc	a0,0x3
ffffffffc0201eb6:	aee50513          	addi	a0,a0,-1298 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201eba:	b24fe0ef          	jal	ra,ffffffffc02001de <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201ebe:	00003617          	auipc	a2,0x3
ffffffffc0201ec2:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0204a28 <commands+0x8f0>
ffffffffc0201ec6:	08000593          	li	a1,128
ffffffffc0201eca:	00003517          	auipc	a0,0x3
ffffffffc0201ece:	ad650513          	addi	a0,a0,-1322 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201ed2:	b0cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0201ed6:	00003697          	auipc	a3,0x3
ffffffffc0201eda:	c8a68693          	addi	a3,a3,-886 # ffffffffc0204b60 <commands+0xa28>
ffffffffc0201ede:	00003617          	auipc	a2,0x3
ffffffffc0201ee2:	bca60613          	addi	a2,a2,-1078 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201ee6:	16e00593          	li	a1,366
ffffffffc0201eea:	00003517          	auipc	a0,0x3
ffffffffc0201eee:	ab650513          	addi	a0,a0,-1354 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201ef2:	aecfe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0201ef6:	00003697          	auipc	a3,0x3
ffffffffc0201efa:	c3a68693          	addi	a3,a3,-966 # ffffffffc0204b30 <commands+0x9f8>
ffffffffc0201efe:	00003617          	auipc	a2,0x3
ffffffffc0201f02:	baa60613          	addi	a2,a2,-1110 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201f06:	16b00593          	li	a1,363
ffffffffc0201f0a:	00003517          	auipc	a0,0x3
ffffffffc0201f0e:	a9650513          	addi	a0,a0,-1386 # ffffffffc02049a0 <commands+0x868>
ffffffffc0201f12:	accfe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201f16 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201f16:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0201f18:	00003697          	auipc	a3,0x3
ffffffffc0201f1c:	07068693          	addi	a3,a3,112 # ffffffffc0204f88 <commands+0xe50>
ffffffffc0201f20:	00003617          	auipc	a2,0x3
ffffffffc0201f24:	b8860613          	addi	a2,a2,-1144 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201f28:	08800593          	li	a1,136
ffffffffc0201f2c:	00003517          	auipc	a0,0x3
ffffffffc0201f30:	07c50513          	addi	a0,a0,124 # ffffffffc0204fa8 <commands+0xe70>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201f34:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0201f36:	aa8fe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201f3a <find_vma>:
{
ffffffffc0201f3a:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0201f3c:	c505                	beqz	a0,ffffffffc0201f64 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0201f3e:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201f40:	c501                	beqz	a0,ffffffffc0201f48 <find_vma+0xe>
ffffffffc0201f42:	651c                	ld	a5,8(a0)
ffffffffc0201f44:	02f5f263          	bgeu	a1,a5,ffffffffc0201f68 <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201f48:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0201f4a:	00f68d63          	beq	a3,a5,ffffffffc0201f64 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0201f4e:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2afc>
ffffffffc0201f52:	00e5e663          	bltu	a1,a4,ffffffffc0201f5e <find_vma+0x24>
ffffffffc0201f56:	ff07b703          	ld	a4,-16(a5)
ffffffffc0201f5a:	00e5ec63          	bltu	a1,a4,ffffffffc0201f72 <find_vma+0x38>
ffffffffc0201f5e:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0201f60:	fef697e3          	bne	a3,a5,ffffffffc0201f4e <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0201f64:	4501                	li	a0,0
}
ffffffffc0201f66:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201f68:	691c                	ld	a5,16(a0)
ffffffffc0201f6a:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0201f48 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0201f6e:	ea88                	sd	a0,16(a3)
ffffffffc0201f70:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0201f72:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0201f76:	ea88                	sd	a0,16(a3)
ffffffffc0201f78:	8082                	ret

ffffffffc0201f7a <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f7a:	6590                	ld	a2,8(a1)
ffffffffc0201f7c:	0105b803          	ld	a6,16(a1)
{
ffffffffc0201f80:	1141                	addi	sp,sp,-16
ffffffffc0201f82:	e406                	sd	ra,8(sp)
ffffffffc0201f84:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f86:	01066763          	bltu	a2,a6,ffffffffc0201f94 <insert_vma_struct+0x1a>
ffffffffc0201f8a:	a085                	j	ffffffffc0201fea <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0201f8c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201f90:	04e66863          	bltu	a2,a4,ffffffffc0201fe0 <insert_vma_struct+0x66>
ffffffffc0201f94:	86be                	mv	a3,a5
ffffffffc0201f96:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0201f98:	fef51ae3          	bne	a0,a5,ffffffffc0201f8c <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0201f9c:	02a68463          	beq	a3,a0,ffffffffc0201fc4 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0201fa0:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201fa4:	fe86b883          	ld	a7,-24(a3)
ffffffffc0201fa8:	08e8f163          	bgeu	a7,a4,ffffffffc020202a <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201fac:	04e66f63          	bltu	a2,a4,ffffffffc020200a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0201fb0:	00f50a63          	beq	a0,a5,ffffffffc0201fc4 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0201fb4:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201fb8:	05076963          	bltu	a4,a6,ffffffffc020200a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0201fbc:	ff07b603          	ld	a2,-16(a5)
ffffffffc0201fc0:	02c77363          	bgeu	a4,a2,ffffffffc0201fe6 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0201fc4:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0201fc6:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0201fc8:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201fcc:	e390                	sd	a2,0(a5)
ffffffffc0201fce:	e690                	sd	a2,8(a3)
}
ffffffffc0201fd0:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0201fd2:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0201fd4:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0201fd6:	0017079b          	addiw	a5,a4,1
ffffffffc0201fda:	d11c                	sw	a5,32(a0)
}
ffffffffc0201fdc:	0141                	addi	sp,sp,16
ffffffffc0201fde:	8082                	ret
    if (le_prev != list)
ffffffffc0201fe0:	fca690e3          	bne	a3,a0,ffffffffc0201fa0 <insert_vma_struct+0x26>
ffffffffc0201fe4:	bfd1                	j	ffffffffc0201fb8 <insert_vma_struct+0x3e>
ffffffffc0201fe6:	f31ff0ef          	jal	ra,ffffffffc0201f16 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201fea:	00003697          	auipc	a3,0x3
ffffffffc0201fee:	fce68693          	addi	a3,a3,-50 # ffffffffc0204fb8 <commands+0xe80>
ffffffffc0201ff2:	00003617          	auipc	a2,0x3
ffffffffc0201ff6:	ab660613          	addi	a2,a2,-1354 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0201ffa:	08e00593          	li	a1,142
ffffffffc0201ffe:	00003517          	auipc	a0,0x3
ffffffffc0202002:	faa50513          	addi	a0,a0,-86 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc0202006:	9d8fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020200a:	00003697          	auipc	a3,0x3
ffffffffc020200e:	fee68693          	addi	a3,a3,-18 # ffffffffc0204ff8 <commands+0xec0>
ffffffffc0202012:	00003617          	auipc	a2,0x3
ffffffffc0202016:	a9660613          	addi	a2,a2,-1386 # ffffffffc0204aa8 <commands+0x970>
ffffffffc020201a:	08700593          	li	a1,135
ffffffffc020201e:	00003517          	auipc	a0,0x3
ffffffffc0202022:	f8a50513          	addi	a0,a0,-118 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc0202026:	9b8fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020202a:	00003697          	auipc	a3,0x3
ffffffffc020202e:	fae68693          	addi	a3,a3,-82 # ffffffffc0204fd8 <commands+0xea0>
ffffffffc0202032:	00003617          	auipc	a2,0x3
ffffffffc0202036:	a7660613          	addi	a2,a2,-1418 # ffffffffc0204aa8 <commands+0x970>
ffffffffc020203a:	08600593          	li	a1,134
ffffffffc020203e:	00003517          	auipc	a0,0x3
ffffffffc0202042:	f6a50513          	addi	a0,a0,-150 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc0202046:	998fe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020204a <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc020204a:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020204c:	03000513          	li	a0,48
{
ffffffffc0202050:	fc06                	sd	ra,56(sp)
ffffffffc0202052:	f822                	sd	s0,48(sp)
ffffffffc0202054:	f426                	sd	s1,40(sp)
ffffffffc0202056:	f04a                	sd	s2,32(sp)
ffffffffc0202058:	ec4e                	sd	s3,24(sp)
ffffffffc020205a:	e852                	sd	s4,16(sp)
ffffffffc020205c:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020205e:	550000ef          	jal	ra,ffffffffc02025ae <kmalloc>
    if (mm != NULL)
ffffffffc0202062:	2e050f63          	beqz	a0,ffffffffc0202360 <vmm_init+0x316>
ffffffffc0202066:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202068:	e508                	sd	a0,8(a0)
ffffffffc020206a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020206c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202070:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202074:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202078:	02053423          	sd	zero,40(a0)
ffffffffc020207c:	03200413          	li	s0,50
ffffffffc0202080:	a811                	j	ffffffffc0202094 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202082:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202084:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202086:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc020208a:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020208c:	8526                	mv	a0,s1
ffffffffc020208e:	eedff0ef          	jal	ra,ffffffffc0201f7a <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202092:	c80d                	beqz	s0,ffffffffc02020c4 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202094:	03000513          	li	a0,48
ffffffffc0202098:	516000ef          	jal	ra,ffffffffc02025ae <kmalloc>
ffffffffc020209c:	85aa                	mv	a1,a0
ffffffffc020209e:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02020a2:	f165                	bnez	a0,ffffffffc0202082 <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc02020a4:	00003697          	auipc	a3,0x3
ffffffffc02020a8:	0ec68693          	addi	a3,a3,236 # ffffffffc0205190 <commands+0x1058>
ffffffffc02020ac:	00003617          	auipc	a2,0x3
ffffffffc02020b0:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02020b4:	0da00593          	li	a1,218
ffffffffc02020b8:	00003517          	auipc	a0,0x3
ffffffffc02020bc:	ef050513          	addi	a0,a0,-272 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc02020c0:	91efe0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc02020c4:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02020c8:	1f900913          	li	s2,505
ffffffffc02020cc:	a819                	j	ffffffffc02020e2 <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc02020ce:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02020d0:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02020d2:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02020d6:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02020d8:	8526                	mv	a0,s1
ffffffffc02020da:	ea1ff0ef          	jal	ra,ffffffffc0201f7a <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02020de:	03240a63          	beq	s0,s2,ffffffffc0202112 <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02020e2:	03000513          	li	a0,48
ffffffffc02020e6:	4c8000ef          	jal	ra,ffffffffc02025ae <kmalloc>
ffffffffc02020ea:	85aa                	mv	a1,a0
ffffffffc02020ec:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02020f0:	fd79                	bnez	a0,ffffffffc02020ce <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc02020f2:	00003697          	auipc	a3,0x3
ffffffffc02020f6:	09e68693          	addi	a3,a3,158 # ffffffffc0205190 <commands+0x1058>
ffffffffc02020fa:	00003617          	auipc	a2,0x3
ffffffffc02020fe:	9ae60613          	addi	a2,a2,-1618 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202102:	0e100593          	li	a1,225
ffffffffc0202106:	00003517          	auipc	a0,0x3
ffffffffc020210a:	ea250513          	addi	a0,a0,-350 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc020210e:	8d0fe0ef          	jal	ra,ffffffffc02001de <__panic>
    return listelm->next;
ffffffffc0202112:	649c                	ld	a5,8(s1)
ffffffffc0202114:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202116:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc020211a:	18f48363          	beq	s1,a5,ffffffffc02022a0 <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020211e:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202122:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202126:	10d61d63          	bne	a2,a3,ffffffffc0202240 <vmm_init+0x1f6>
ffffffffc020212a:	ff07b683          	ld	a3,-16(a5)
ffffffffc020212e:	10e69963          	bne	a3,a4,ffffffffc0202240 <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202132:	0715                	addi	a4,a4,5
ffffffffc0202134:	679c                	ld	a5,8(a5)
ffffffffc0202136:	feb712e3          	bne	a4,a1,ffffffffc020211a <vmm_init+0xd0>
ffffffffc020213a:	4a1d                	li	s4,7
ffffffffc020213c:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc020213e:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202142:	85a2                	mv	a1,s0
ffffffffc0202144:	8526                	mv	a0,s1
ffffffffc0202146:	df5ff0ef          	jal	ra,ffffffffc0201f3a <find_vma>
ffffffffc020214a:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc020214c:	18050a63          	beqz	a0,ffffffffc02022e0 <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202150:	00140593          	addi	a1,s0,1
ffffffffc0202154:	8526                	mv	a0,s1
ffffffffc0202156:	de5ff0ef          	jal	ra,ffffffffc0201f3a <find_vma>
ffffffffc020215a:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc020215c:	16050263          	beqz	a0,ffffffffc02022c0 <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202160:	85d2                	mv	a1,s4
ffffffffc0202162:	8526                	mv	a0,s1
ffffffffc0202164:	dd7ff0ef          	jal	ra,ffffffffc0201f3a <find_vma>
        assert(vma3 == NULL);
ffffffffc0202168:	18051c63          	bnez	a0,ffffffffc0202300 <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc020216c:	00340593          	addi	a1,s0,3
ffffffffc0202170:	8526                	mv	a0,s1
ffffffffc0202172:	dc9ff0ef          	jal	ra,ffffffffc0201f3a <find_vma>
        assert(vma4 == NULL);
ffffffffc0202176:	1c051563          	bnez	a0,ffffffffc0202340 <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc020217a:	00440593          	addi	a1,s0,4
ffffffffc020217e:	8526                	mv	a0,s1
ffffffffc0202180:	dbbff0ef          	jal	ra,ffffffffc0201f3a <find_vma>
        assert(vma5 == NULL);
ffffffffc0202184:	18051e63          	bnez	a0,ffffffffc0202320 <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202188:	00893783          	ld	a5,8(s2)
ffffffffc020218c:	0c879a63          	bne	a5,s0,ffffffffc0202260 <vmm_init+0x216>
ffffffffc0202190:	01093783          	ld	a5,16(s2)
ffffffffc0202194:	0d479663          	bne	a5,s4,ffffffffc0202260 <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202198:	0089b783          	ld	a5,8(s3)
ffffffffc020219c:	0e879263          	bne	a5,s0,ffffffffc0202280 <vmm_init+0x236>
ffffffffc02021a0:	0109b783          	ld	a5,16(s3)
ffffffffc02021a4:	0d479e63          	bne	a5,s4,ffffffffc0202280 <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc02021a8:	0415                	addi	s0,s0,5
ffffffffc02021aa:	0a15                	addi	s4,s4,5
ffffffffc02021ac:	f9541be3          	bne	s0,s5,ffffffffc0202142 <vmm_init+0xf8>
ffffffffc02021b0:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc02021b2:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc02021b4:	85a2                	mv	a1,s0
ffffffffc02021b6:	8526                	mv	a0,s1
ffffffffc02021b8:	d83ff0ef          	jal	ra,ffffffffc0201f3a <find_vma>
ffffffffc02021bc:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc02021c0:	c90d                	beqz	a0,ffffffffc02021f2 <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02021c2:	6914                	ld	a3,16(a0)
ffffffffc02021c4:	6510                	ld	a2,8(a0)
ffffffffc02021c6:	00003517          	auipc	a0,0x3
ffffffffc02021ca:	f5250513          	addi	a0,a0,-174 # ffffffffc0205118 <commands+0xfe0>
ffffffffc02021ce:	f13fd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02021d2:	00003697          	auipc	a3,0x3
ffffffffc02021d6:	f6e68693          	addi	a3,a3,-146 # ffffffffc0205140 <commands+0x1008>
ffffffffc02021da:	00003617          	auipc	a2,0x3
ffffffffc02021de:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02021e2:	10700593          	li	a1,263
ffffffffc02021e6:	00003517          	auipc	a0,0x3
ffffffffc02021ea:	dc250513          	addi	a0,a0,-574 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc02021ee:	ff1fd0ef          	jal	ra,ffffffffc02001de <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc02021f2:	147d                	addi	s0,s0,-1
ffffffffc02021f4:	fd2410e3          	bne	s0,s2,ffffffffc02021b4 <vmm_init+0x16a>
ffffffffc02021f8:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc02021fa:	00a48c63          	beq	s1,a0,ffffffffc0202212 <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc02021fe:	6118                	ld	a4,0(a0)
ffffffffc0202200:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0202202:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0202204:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202206:	e398                	sd	a4,0(a5)
ffffffffc0202208:	456000ef          	jal	ra,ffffffffc020265e <kfree>
    return listelm->next;
ffffffffc020220c:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020220e:	fea498e3          	bne	s1,a0,ffffffffc02021fe <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc0202212:	8526                	mv	a0,s1
ffffffffc0202214:	44a000ef          	jal	ra,ffffffffc020265e <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202218:	00003517          	auipc	a0,0x3
ffffffffc020221c:	f4050513          	addi	a0,a0,-192 # ffffffffc0205158 <commands+0x1020>
ffffffffc0202220:	ec1fd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc0202224:	7442                	ld	s0,48(sp)
ffffffffc0202226:	70e2                	ld	ra,56(sp)
ffffffffc0202228:	74a2                	ld	s1,40(sp)
ffffffffc020222a:	7902                	ld	s2,32(sp)
ffffffffc020222c:	69e2                	ld	s3,24(sp)
ffffffffc020222e:	6a42                	ld	s4,16(sp)
ffffffffc0202230:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202232:	00003517          	auipc	a0,0x3
ffffffffc0202236:	f4650513          	addi	a0,a0,-186 # ffffffffc0205178 <commands+0x1040>
}
ffffffffc020223a:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc020223c:	ea5fd06f          	j	ffffffffc02000e0 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202240:	00003697          	auipc	a3,0x3
ffffffffc0202244:	df068693          	addi	a3,a3,-528 # ffffffffc0205030 <commands+0xef8>
ffffffffc0202248:	00003617          	auipc	a2,0x3
ffffffffc020224c:	86060613          	addi	a2,a2,-1952 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202250:	0eb00593          	li	a1,235
ffffffffc0202254:	00003517          	auipc	a0,0x3
ffffffffc0202258:	d5450513          	addi	a0,a0,-684 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc020225c:	f83fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202260:	00003697          	auipc	a3,0x3
ffffffffc0202264:	e5868693          	addi	a3,a3,-424 # ffffffffc02050b8 <commands+0xf80>
ffffffffc0202268:	00003617          	auipc	a2,0x3
ffffffffc020226c:	84060613          	addi	a2,a2,-1984 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202270:	0fc00593          	li	a1,252
ffffffffc0202274:	00003517          	auipc	a0,0x3
ffffffffc0202278:	d3450513          	addi	a0,a0,-716 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc020227c:	f63fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202280:	00003697          	auipc	a3,0x3
ffffffffc0202284:	e6868693          	addi	a3,a3,-408 # ffffffffc02050e8 <commands+0xfb0>
ffffffffc0202288:	00003617          	auipc	a2,0x3
ffffffffc020228c:	82060613          	addi	a2,a2,-2016 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202290:	0fd00593          	li	a1,253
ffffffffc0202294:	00003517          	auipc	a0,0x3
ffffffffc0202298:	d1450513          	addi	a0,a0,-748 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc020229c:	f43fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02022a0:	00003697          	auipc	a3,0x3
ffffffffc02022a4:	d7868693          	addi	a3,a3,-648 # ffffffffc0205018 <commands+0xee0>
ffffffffc02022a8:	00003617          	auipc	a2,0x3
ffffffffc02022ac:	80060613          	addi	a2,a2,-2048 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02022b0:	0e900593          	li	a1,233
ffffffffc02022b4:	00003517          	auipc	a0,0x3
ffffffffc02022b8:	cf450513          	addi	a0,a0,-780 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc02022bc:	f23fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma2 != NULL);
ffffffffc02022c0:	00003697          	auipc	a3,0x3
ffffffffc02022c4:	db868693          	addi	a3,a3,-584 # ffffffffc0205078 <commands+0xf40>
ffffffffc02022c8:	00002617          	auipc	a2,0x2
ffffffffc02022cc:	7e060613          	addi	a2,a2,2016 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02022d0:	0f400593          	li	a1,244
ffffffffc02022d4:	00003517          	auipc	a0,0x3
ffffffffc02022d8:	cd450513          	addi	a0,a0,-812 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc02022dc:	f03fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma1 != NULL);
ffffffffc02022e0:	00003697          	auipc	a3,0x3
ffffffffc02022e4:	d8868693          	addi	a3,a3,-632 # ffffffffc0205068 <commands+0xf30>
ffffffffc02022e8:	00002617          	auipc	a2,0x2
ffffffffc02022ec:	7c060613          	addi	a2,a2,1984 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02022f0:	0f200593          	li	a1,242
ffffffffc02022f4:	00003517          	auipc	a0,0x3
ffffffffc02022f8:	cb450513          	addi	a0,a0,-844 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc02022fc:	ee3fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma3 == NULL);
ffffffffc0202300:	00003697          	auipc	a3,0x3
ffffffffc0202304:	d8868693          	addi	a3,a3,-632 # ffffffffc0205088 <commands+0xf50>
ffffffffc0202308:	00002617          	auipc	a2,0x2
ffffffffc020230c:	7a060613          	addi	a2,a2,1952 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202310:	0f600593          	li	a1,246
ffffffffc0202314:	00003517          	auipc	a0,0x3
ffffffffc0202318:	c9450513          	addi	a0,a0,-876 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc020231c:	ec3fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma5 == NULL);
ffffffffc0202320:	00003697          	auipc	a3,0x3
ffffffffc0202324:	d8868693          	addi	a3,a3,-632 # ffffffffc02050a8 <commands+0xf70>
ffffffffc0202328:	00002617          	auipc	a2,0x2
ffffffffc020232c:	78060613          	addi	a2,a2,1920 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202330:	0fa00593          	li	a1,250
ffffffffc0202334:	00003517          	auipc	a0,0x3
ffffffffc0202338:	c7450513          	addi	a0,a0,-908 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc020233c:	ea3fd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma4 == NULL);
ffffffffc0202340:	00003697          	auipc	a3,0x3
ffffffffc0202344:	d5868693          	addi	a3,a3,-680 # ffffffffc0205098 <commands+0xf60>
ffffffffc0202348:	00002617          	auipc	a2,0x2
ffffffffc020234c:	76060613          	addi	a2,a2,1888 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202350:	0f800593          	li	a1,248
ffffffffc0202354:	00003517          	auipc	a0,0x3
ffffffffc0202358:	c5450513          	addi	a0,a0,-940 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc020235c:	e83fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(mm != NULL);
ffffffffc0202360:	00003697          	auipc	a3,0x3
ffffffffc0202364:	e4068693          	addi	a3,a3,-448 # ffffffffc02051a0 <commands+0x1068>
ffffffffc0202368:	00002617          	auipc	a2,0x2
ffffffffc020236c:	74060613          	addi	a2,a2,1856 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202370:	0d200593          	li	a1,210
ffffffffc0202374:	00003517          	auipc	a0,0x3
ffffffffc0202378:	c3450513          	addi	a0,a0,-972 # ffffffffc0204fa8 <commands+0xe70>
ffffffffc020237c:	e63fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202380 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0202380:	c94d                	beqz	a0,ffffffffc0202432 <slob_free+0xb2>
{
ffffffffc0202382:	1141                	addi	sp,sp,-16
ffffffffc0202384:	e022                	sd	s0,0(sp)
ffffffffc0202386:	e406                	sd	ra,8(sp)
ffffffffc0202388:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020238a:	e9c1                	bnez	a1,ffffffffc020241a <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020238c:	100027f3          	csrr	a5,sstatus
ffffffffc0202390:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0202392:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202394:	ebd9                	bnez	a5,ffffffffc020242a <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0202396:	00007617          	auipc	a2,0x7
ffffffffc020239a:	c8a60613          	addi	a2,a2,-886 # ffffffffc0209020 <slobfree>
ffffffffc020239e:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02023a0:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02023a2:	679c                	ld	a5,8(a5)
ffffffffc02023a4:	02877a63          	bgeu	a4,s0,ffffffffc02023d8 <slob_free+0x58>
ffffffffc02023a8:	00f46463          	bltu	s0,a5,ffffffffc02023b0 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02023ac:	fef76ae3          	bltu	a4,a5,ffffffffc02023a0 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02023b0:	400c                	lw	a1,0(s0)
ffffffffc02023b2:	00459693          	slli	a3,a1,0x4
ffffffffc02023b6:	96a2                	add	a3,a3,s0
ffffffffc02023b8:	02d78a63          	beq	a5,a3,ffffffffc02023ec <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02023bc:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02023be:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02023c0:	00469793          	slli	a5,a3,0x4
ffffffffc02023c4:	97ba                	add	a5,a5,a4
ffffffffc02023c6:	02f40e63          	beq	s0,a5,ffffffffc0202402 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02023ca:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02023cc:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02023ce:	e129                	bnez	a0,ffffffffc0202410 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02023d0:	60a2                	ld	ra,8(sp)
ffffffffc02023d2:	6402                	ld	s0,0(sp)
ffffffffc02023d4:	0141                	addi	sp,sp,16
ffffffffc02023d6:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02023d8:	fcf764e3          	bltu	a4,a5,ffffffffc02023a0 <slob_free+0x20>
ffffffffc02023dc:	fcf472e3          	bgeu	s0,a5,ffffffffc02023a0 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02023e0:	400c                	lw	a1,0(s0)
ffffffffc02023e2:	00459693          	slli	a3,a1,0x4
ffffffffc02023e6:	96a2                	add	a3,a3,s0
ffffffffc02023e8:	fcd79ae3          	bne	a5,a3,ffffffffc02023bc <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02023ec:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02023ee:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02023f0:	9db5                	addw	a1,a1,a3
ffffffffc02023f2:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02023f4:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02023f6:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02023f8:	00469793          	slli	a5,a3,0x4
ffffffffc02023fc:	97ba                	add	a5,a5,a4
ffffffffc02023fe:	fcf416e3          	bne	s0,a5,ffffffffc02023ca <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0202402:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0202404:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0202406:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0202408:	9ebd                	addw	a3,a3,a5
ffffffffc020240a:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc020240c:	e70c                	sd	a1,8(a4)
ffffffffc020240e:	d169                	beqz	a0,ffffffffc02023d0 <slob_free+0x50>
}
ffffffffc0202410:	6402                	ld	s0,0(sp)
ffffffffc0202412:	60a2                	ld	ra,8(sp)
ffffffffc0202414:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0202416:	d1afe06f          	j	ffffffffc0200930 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc020241a:	25bd                	addiw	a1,a1,15
ffffffffc020241c:	8191                	srli	a1,a1,0x4
ffffffffc020241e:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202420:	100027f3          	csrr	a5,sstatus
ffffffffc0202424:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0202426:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202428:	d7bd                	beqz	a5,ffffffffc0202396 <slob_free+0x16>
        intr_disable();
ffffffffc020242a:	d0cfe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc020242e:	4505                	li	a0,1
ffffffffc0202430:	b79d                	j	ffffffffc0202396 <slob_free+0x16>
ffffffffc0202432:	8082                	ret

ffffffffc0202434 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0202434:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0202436:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0202438:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020243c:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc020243e:	9d5fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
	if (!page)
ffffffffc0202442:	c91d                	beqz	a0,ffffffffc0202478 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0202444:	0000b697          	auipc	a3,0xb
ffffffffc0202448:	06c6b683          	ld	a3,108(a3) # ffffffffc020d4b0 <pages>
ffffffffc020244c:	8d15                	sub	a0,a0,a3
ffffffffc020244e:	8519                	srai	a0,a0,0x6
ffffffffc0202450:	00003697          	auipc	a3,0x3
ffffffffc0202454:	5a86b683          	ld	a3,1448(a3) # ffffffffc02059f8 <nbase>
ffffffffc0202458:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc020245a:	00c51793          	slli	a5,a0,0xc
ffffffffc020245e:	83b1                	srli	a5,a5,0xc
ffffffffc0202460:	0000b717          	auipc	a4,0xb
ffffffffc0202464:	04873703          	ld	a4,72(a4) # ffffffffc020d4a8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202468:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc020246a:	00e7fa63          	bgeu	a5,a4,ffffffffc020247e <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc020246e:	0000b697          	auipc	a3,0xb
ffffffffc0202472:	0526b683          	ld	a3,82(a3) # ffffffffc020d4c0 <va_pa_offset>
ffffffffc0202476:	9536                	add	a0,a0,a3
}
ffffffffc0202478:	60a2                	ld	ra,8(sp)
ffffffffc020247a:	0141                	addi	sp,sp,16
ffffffffc020247c:	8082                	ret
ffffffffc020247e:	86aa                	mv	a3,a0
ffffffffc0202480:	00002617          	auipc	a2,0x2
ffffffffc0202484:	4f860613          	addi	a2,a2,1272 # ffffffffc0204978 <commands+0x840>
ffffffffc0202488:	07100593          	li	a1,113
ffffffffc020248c:	00002517          	auipc	a0,0x2
ffffffffc0202490:	4b450513          	addi	a0,a0,1204 # ffffffffc0204940 <commands+0x808>
ffffffffc0202494:	d4bfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202498 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0202498:	1101                	addi	sp,sp,-32
ffffffffc020249a:	ec06                	sd	ra,24(sp)
ffffffffc020249c:	e822                	sd	s0,16(sp)
ffffffffc020249e:	e426                	sd	s1,8(sp)
ffffffffc02024a0:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02024a2:	01050713          	addi	a4,a0,16
ffffffffc02024a6:	6785                	lui	a5,0x1
ffffffffc02024a8:	0cf77363          	bgeu	a4,a5,ffffffffc020256e <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02024ac:	00f50493          	addi	s1,a0,15
ffffffffc02024b0:	8091                	srli	s1,s1,0x4
ffffffffc02024b2:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02024b4:	10002673          	csrr	a2,sstatus
ffffffffc02024b8:	8a09                	andi	a2,a2,2
ffffffffc02024ba:	e25d                	bnez	a2,ffffffffc0202560 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02024bc:	00007917          	auipc	s2,0x7
ffffffffc02024c0:	b6490913          	addi	s2,s2,-1180 # ffffffffc0209020 <slobfree>
ffffffffc02024c4:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02024c8:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc02024ca:	4398                	lw	a4,0(a5)
ffffffffc02024cc:	08975e63          	bge	a4,s1,ffffffffc0202568 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc02024d0:	00d78b63          	beq	a5,a3,ffffffffc02024e6 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02024d4:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02024d6:	4018                	lw	a4,0(s0)
ffffffffc02024d8:	02975a63          	bge	a4,s1,ffffffffc020250c <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc02024dc:	00093683          	ld	a3,0(s2)
ffffffffc02024e0:	87a2                	mv	a5,s0
ffffffffc02024e2:	fed799e3          	bne	a5,a3,ffffffffc02024d4 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc02024e6:	ee31                	bnez	a2,ffffffffc0202542 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02024e8:	4501                	li	a0,0
ffffffffc02024ea:	f4bff0ef          	jal	ra,ffffffffc0202434 <__slob_get_free_pages.constprop.0>
ffffffffc02024ee:	842a                	mv	s0,a0
			if (!cur)
ffffffffc02024f0:	cd05                	beqz	a0,ffffffffc0202528 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc02024f2:	6585                	lui	a1,0x1
ffffffffc02024f4:	e8dff0ef          	jal	ra,ffffffffc0202380 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02024f8:	10002673          	csrr	a2,sstatus
ffffffffc02024fc:	8a09                	andi	a2,a2,2
ffffffffc02024fe:	ee05                	bnez	a2,ffffffffc0202536 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0202500:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0202504:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0202506:	4018                	lw	a4,0(s0)
ffffffffc0202508:	fc974ae3          	blt	a4,s1,ffffffffc02024dc <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc020250c:	04e48763          	beq	s1,a4,ffffffffc020255a <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0202510:	00449693          	slli	a3,s1,0x4
ffffffffc0202514:	96a2                	add	a3,a3,s0
ffffffffc0202516:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0202518:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc020251a:	9f05                	subw	a4,a4,s1
ffffffffc020251c:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc020251e:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0202520:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0202522:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0202526:	e20d                	bnez	a2,ffffffffc0202548 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0202528:	60e2                	ld	ra,24(sp)
ffffffffc020252a:	8522                	mv	a0,s0
ffffffffc020252c:	6442                	ld	s0,16(sp)
ffffffffc020252e:	64a2                	ld	s1,8(sp)
ffffffffc0202530:	6902                	ld	s2,0(sp)
ffffffffc0202532:	6105                	addi	sp,sp,32
ffffffffc0202534:	8082                	ret
        intr_disable();
ffffffffc0202536:	c00fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
			cur = slobfree;
ffffffffc020253a:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc020253e:	4605                	li	a2,1
ffffffffc0202540:	b7d1                	j	ffffffffc0202504 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0202542:	beefe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0202546:	b74d                	j	ffffffffc02024e8 <slob_alloc.constprop.0+0x50>
ffffffffc0202548:	be8fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
}
ffffffffc020254c:	60e2                	ld	ra,24(sp)
ffffffffc020254e:	8522                	mv	a0,s0
ffffffffc0202550:	6442                	ld	s0,16(sp)
ffffffffc0202552:	64a2                	ld	s1,8(sp)
ffffffffc0202554:	6902                	ld	s2,0(sp)
ffffffffc0202556:	6105                	addi	sp,sp,32
ffffffffc0202558:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc020255a:	6418                	ld	a4,8(s0)
ffffffffc020255c:	e798                	sd	a4,8(a5)
ffffffffc020255e:	b7d1                	j	ffffffffc0202522 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0202560:	bd6fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc0202564:	4605                	li	a2,1
ffffffffc0202566:	bf99                	j	ffffffffc02024bc <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0202568:	843e                	mv	s0,a5
ffffffffc020256a:	87b6                	mv	a5,a3
ffffffffc020256c:	b745                	j	ffffffffc020250c <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc020256e:	00003697          	auipc	a3,0x3
ffffffffc0202572:	c4268693          	addi	a3,a3,-958 # ffffffffc02051b0 <commands+0x1078>
ffffffffc0202576:	00002617          	auipc	a2,0x2
ffffffffc020257a:	53260613          	addi	a2,a2,1330 # ffffffffc0204aa8 <commands+0x970>
ffffffffc020257e:	06300593          	li	a1,99
ffffffffc0202582:	00003517          	auipc	a0,0x3
ffffffffc0202586:	c4e50513          	addi	a0,a0,-946 # ffffffffc02051d0 <commands+0x1098>
ffffffffc020258a:	c55fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020258e <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc020258e:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0202590:	00003517          	auipc	a0,0x3
ffffffffc0202594:	c5850513          	addi	a0,a0,-936 # ffffffffc02051e8 <commands+0x10b0>
{
ffffffffc0202598:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc020259a:	b47fd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc020259e:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc02025a0:	00003517          	auipc	a0,0x3
ffffffffc02025a4:	c6050513          	addi	a0,a0,-928 # ffffffffc0205200 <commands+0x10c8>
}
ffffffffc02025a8:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc02025aa:	b37fd06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc02025ae <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc02025ae:	1101                	addi	sp,sp,-32
ffffffffc02025b0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc02025b2:	6905                	lui	s2,0x1
{
ffffffffc02025b4:	e822                	sd	s0,16(sp)
ffffffffc02025b6:	ec06                	sd	ra,24(sp)
ffffffffc02025b8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc02025ba:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc02025be:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc02025c0:	04a7f963          	bgeu	a5,a0,ffffffffc0202612 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc02025c4:	4561                	li	a0,24
ffffffffc02025c6:	ed3ff0ef          	jal	ra,ffffffffc0202498 <slob_alloc.constprop.0>
ffffffffc02025ca:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc02025cc:	c929                	beqz	a0,ffffffffc020261e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc02025ce:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc02025d2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc02025d4:	00f95763          	bge	s2,a5,ffffffffc02025e2 <kmalloc+0x34>
ffffffffc02025d8:	6705                	lui	a4,0x1
ffffffffc02025da:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc02025dc:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc02025de:	fef74ee3          	blt	a4,a5,ffffffffc02025da <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc02025e2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc02025e4:	e51ff0ef          	jal	ra,ffffffffc0202434 <__slob_get_free_pages.constprop.0>
ffffffffc02025e8:	e488                	sd	a0,8(s1)
ffffffffc02025ea:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc02025ec:	c525                	beqz	a0,ffffffffc0202654 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02025ee:	100027f3          	csrr	a5,sstatus
ffffffffc02025f2:	8b89                	andi	a5,a5,2
ffffffffc02025f4:	ef8d                	bnez	a5,ffffffffc020262e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc02025f6:	0000b797          	auipc	a5,0xb
ffffffffc02025fa:	ed278793          	addi	a5,a5,-302 # ffffffffc020d4c8 <bigblocks>
ffffffffc02025fe:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0202600:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0202602:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0202604:	60e2                	ld	ra,24(sp)
ffffffffc0202606:	8522                	mv	a0,s0
ffffffffc0202608:	6442                	ld	s0,16(sp)
ffffffffc020260a:	64a2                	ld	s1,8(sp)
ffffffffc020260c:	6902                	ld	s2,0(sp)
ffffffffc020260e:	6105                	addi	sp,sp,32
ffffffffc0202610:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0202612:	0541                	addi	a0,a0,16
ffffffffc0202614:	e85ff0ef          	jal	ra,ffffffffc0202498 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0202618:	01050413          	addi	s0,a0,16
ffffffffc020261c:	f565                	bnez	a0,ffffffffc0202604 <kmalloc+0x56>
ffffffffc020261e:	4401                	li	s0,0
}
ffffffffc0202620:	60e2                	ld	ra,24(sp)
ffffffffc0202622:	8522                	mv	a0,s0
ffffffffc0202624:	6442                	ld	s0,16(sp)
ffffffffc0202626:	64a2                	ld	s1,8(sp)
ffffffffc0202628:	6902                	ld	s2,0(sp)
ffffffffc020262a:	6105                	addi	sp,sp,32
ffffffffc020262c:	8082                	ret
        intr_disable();
ffffffffc020262e:	b08fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
		bb->next = bigblocks;
ffffffffc0202632:	0000b797          	auipc	a5,0xb
ffffffffc0202636:	e9678793          	addi	a5,a5,-362 # ffffffffc020d4c8 <bigblocks>
ffffffffc020263a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc020263c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc020263e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0202640:	af0fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
		return bb->pages;
ffffffffc0202644:	6480                	ld	s0,8(s1)
}
ffffffffc0202646:	60e2                	ld	ra,24(sp)
ffffffffc0202648:	64a2                	ld	s1,8(sp)
ffffffffc020264a:	8522                	mv	a0,s0
ffffffffc020264c:	6442                	ld	s0,16(sp)
ffffffffc020264e:	6902                	ld	s2,0(sp)
ffffffffc0202650:	6105                	addi	sp,sp,32
ffffffffc0202652:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0202654:	45e1                	li	a1,24
ffffffffc0202656:	8526                	mv	a0,s1
ffffffffc0202658:	d29ff0ef          	jal	ra,ffffffffc0202380 <slob_free>
	return __kmalloc(size, 0);
ffffffffc020265c:	b765                	j	ffffffffc0202604 <kmalloc+0x56>

ffffffffc020265e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc020265e:	c179                	beqz	a0,ffffffffc0202724 <kfree+0xc6>
{
ffffffffc0202660:	1101                	addi	sp,sp,-32
ffffffffc0202662:	e822                	sd	s0,16(sp)
ffffffffc0202664:	ec06                	sd	ra,24(sp)
ffffffffc0202666:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0202668:	03451793          	slli	a5,a0,0x34
ffffffffc020266c:	842a                	mv	s0,a0
ffffffffc020266e:	e7c1                	bnez	a5,ffffffffc02026f6 <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202670:	100027f3          	csrr	a5,sstatus
ffffffffc0202674:	8b89                	andi	a5,a5,2
ffffffffc0202676:	ebc9                	bnez	a5,ffffffffc0202708 <kfree+0xaa>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202678:	0000b797          	auipc	a5,0xb
ffffffffc020267c:	e507b783          	ld	a5,-432(a5) # ffffffffc020d4c8 <bigblocks>
    return 0;
ffffffffc0202680:	4601                	li	a2,0
ffffffffc0202682:	cbb5                	beqz	a5,ffffffffc02026f6 <kfree+0x98>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0202684:	0000b697          	auipc	a3,0xb
ffffffffc0202688:	e4468693          	addi	a3,a3,-444 # ffffffffc020d4c8 <bigblocks>
ffffffffc020268c:	a021                	j	ffffffffc0202694 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc020268e:	01048693          	addi	a3,s1,16
ffffffffc0202692:	c3ad                	beqz	a5,ffffffffc02026f4 <kfree+0x96>
		{
			if (bb->pages == block)
ffffffffc0202694:	6798                	ld	a4,8(a5)
ffffffffc0202696:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0202698:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc020269a:	fe871ae3          	bne	a4,s0,ffffffffc020268e <kfree+0x30>
				*last = bb->next;
ffffffffc020269e:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc02026a0:	ee3d                	bnez	a2,ffffffffc020271e <kfree+0xc0>
    return pa2page(PADDR(kva));
ffffffffc02026a2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc02026a6:	4098                	lw	a4,0(s1)
ffffffffc02026a8:	08f46b63          	bltu	s0,a5,ffffffffc020273e <kfree+0xe0>
ffffffffc02026ac:	0000b697          	auipc	a3,0xb
ffffffffc02026b0:	e146b683          	ld	a3,-492(a3) # ffffffffc020d4c0 <va_pa_offset>
ffffffffc02026b4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc02026b6:	8031                	srli	s0,s0,0xc
ffffffffc02026b8:	0000b797          	auipc	a5,0xb
ffffffffc02026bc:	df07b783          	ld	a5,-528(a5) # ffffffffc020d4a8 <npage>
ffffffffc02026c0:	06f47363          	bgeu	s0,a5,ffffffffc0202726 <kfree+0xc8>
    return &pages[PPN(pa) - nbase];
ffffffffc02026c4:	00003517          	auipc	a0,0x3
ffffffffc02026c8:	33453503          	ld	a0,820(a0) # ffffffffc02059f8 <nbase>
ffffffffc02026cc:	8c09                	sub	s0,s0,a0
ffffffffc02026ce:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc02026d0:	0000b517          	auipc	a0,0xb
ffffffffc02026d4:	de053503          	ld	a0,-544(a0) # ffffffffc020d4b0 <pages>
ffffffffc02026d8:	4585                	li	a1,1
ffffffffc02026da:	9522                	add	a0,a0,s0
ffffffffc02026dc:	00e595bb          	sllw	a1,a1,a4
ffffffffc02026e0:	f70fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc02026e4:	6442                	ld	s0,16(sp)
ffffffffc02026e6:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc02026e8:	8526                	mv	a0,s1
}
ffffffffc02026ea:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc02026ec:	45e1                	li	a1,24
}
ffffffffc02026ee:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc02026f0:	c91ff06f          	j	ffffffffc0202380 <slob_free>
ffffffffc02026f4:	e215                	bnez	a2,ffffffffc0202718 <kfree+0xba>
ffffffffc02026f6:	ff040513          	addi	a0,s0,-16
}
ffffffffc02026fa:	6442                	ld	s0,16(sp)
ffffffffc02026fc:	60e2                	ld	ra,24(sp)
ffffffffc02026fe:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202700:	4581                	li	a1,0
}
ffffffffc0202702:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202704:	c7dff06f          	j	ffffffffc0202380 <slob_free>
        intr_disable();
ffffffffc0202708:	a2efe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc020270c:	0000b797          	auipc	a5,0xb
ffffffffc0202710:	dbc7b783          	ld	a5,-580(a5) # ffffffffc020d4c8 <bigblocks>
        return 1;
ffffffffc0202714:	4605                	li	a2,1
ffffffffc0202716:	f7bd                	bnez	a5,ffffffffc0202684 <kfree+0x26>
        intr_enable();
ffffffffc0202718:	a18fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020271c:	bfe9                	j	ffffffffc02026f6 <kfree+0x98>
ffffffffc020271e:	a12fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0202722:	b741                	j	ffffffffc02026a2 <kfree+0x44>
ffffffffc0202724:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0202726:	00002617          	auipc	a2,0x2
ffffffffc020272a:	1fa60613          	addi	a2,a2,506 # ffffffffc0204920 <commands+0x7e8>
ffffffffc020272e:	06900593          	li	a1,105
ffffffffc0202732:	00002517          	auipc	a0,0x2
ffffffffc0202736:	20e50513          	addi	a0,a0,526 # ffffffffc0204940 <commands+0x808>
ffffffffc020273a:	aa5fd0ef          	jal	ra,ffffffffc02001de <__panic>
    return pa2page(PADDR(kva));
ffffffffc020273e:	86a2                	mv	a3,s0
ffffffffc0202740:	00002617          	auipc	a2,0x2
ffffffffc0202744:	2e860613          	addi	a2,a2,744 # ffffffffc0204a28 <commands+0x8f0>
ffffffffc0202748:	07700593          	li	a1,119
ffffffffc020274c:	00002517          	auipc	a0,0x2
ffffffffc0202750:	1f450513          	addi	a0,a0,500 # ffffffffc0204940 <commands+0x808>
ffffffffc0202754:	a8bfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202758 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0202758:	00007797          	auipc	a5,0x7
ffffffffc020275c:	cd878793          	addi	a5,a5,-808 # ffffffffc0209430 <free_area>
ffffffffc0202760:	e79c                	sd	a5,8(a5)
ffffffffc0202762:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0202764:	0007a823          	sw	zero,16(a5)
}
ffffffffc0202768:	8082                	ret

ffffffffc020276a <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc020276a:	00007517          	auipc	a0,0x7
ffffffffc020276e:	cd656503          	lwu	a0,-810(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0202772:	8082                	ret

ffffffffc0202774 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0202774:	715d                	addi	sp,sp,-80
ffffffffc0202776:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0202778:	00007417          	auipc	s0,0x7
ffffffffc020277c:	cb840413          	addi	s0,s0,-840 # ffffffffc0209430 <free_area>
ffffffffc0202780:	641c                	ld	a5,8(s0)
ffffffffc0202782:	e486                	sd	ra,72(sp)
ffffffffc0202784:	fc26                	sd	s1,56(sp)
ffffffffc0202786:	f84a                	sd	s2,48(sp)
ffffffffc0202788:	f44e                	sd	s3,40(sp)
ffffffffc020278a:	f052                	sd	s4,32(sp)
ffffffffc020278c:	ec56                	sd	s5,24(sp)
ffffffffc020278e:	e85a                	sd	s6,16(sp)
ffffffffc0202790:	e45e                	sd	s7,8(sp)
ffffffffc0202792:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202794:	2a878d63          	beq	a5,s0,ffffffffc0202a4e <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0202798:	4481                	li	s1,0
ffffffffc020279a:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020279c:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02027a0:	8b09                	andi	a4,a4,2
ffffffffc02027a2:	2a070a63          	beqz	a4,ffffffffc0202a56 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc02027a6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02027aa:	679c                	ld	a5,8(a5)
ffffffffc02027ac:	2905                	addiw	s2,s2,1
ffffffffc02027ae:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02027b0:	fe8796e3          	bne	a5,s0,ffffffffc020279c <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02027b4:	89a6                	mv	s3,s1
ffffffffc02027b6:	ed8fe0ef          	jal	ra,ffffffffc0200e8e <nr_free_pages>
ffffffffc02027ba:	6f351e63          	bne	a0,s3,ffffffffc0202eb6 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02027be:	4505                	li	a0,1
ffffffffc02027c0:	e52fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02027c4:	8aaa                	mv	s5,a0
ffffffffc02027c6:	42050863          	beqz	a0,ffffffffc0202bf6 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02027ca:	4505                	li	a0,1
ffffffffc02027cc:	e46fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02027d0:	89aa                	mv	s3,a0
ffffffffc02027d2:	70050263          	beqz	a0,ffffffffc0202ed6 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02027d6:	4505                	li	a0,1
ffffffffc02027d8:	e3afe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02027dc:	8a2a                	mv	s4,a0
ffffffffc02027de:	48050c63          	beqz	a0,ffffffffc0202c76 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02027e2:	293a8a63          	beq	s5,s3,ffffffffc0202a76 <default_check+0x302>
ffffffffc02027e6:	28aa8863          	beq	s5,a0,ffffffffc0202a76 <default_check+0x302>
ffffffffc02027ea:	28a98663          	beq	s3,a0,ffffffffc0202a76 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02027ee:	000aa783          	lw	a5,0(s5)
ffffffffc02027f2:	2a079263          	bnez	a5,ffffffffc0202a96 <default_check+0x322>
ffffffffc02027f6:	0009a783          	lw	a5,0(s3)
ffffffffc02027fa:	28079e63          	bnez	a5,ffffffffc0202a96 <default_check+0x322>
ffffffffc02027fe:	411c                	lw	a5,0(a0)
ffffffffc0202800:	28079b63          	bnez	a5,ffffffffc0202a96 <default_check+0x322>
    return page - pages + nbase;
ffffffffc0202804:	0000b797          	auipc	a5,0xb
ffffffffc0202808:	cac7b783          	ld	a5,-852(a5) # ffffffffc020d4b0 <pages>
ffffffffc020280c:	40fa8733          	sub	a4,s5,a5
ffffffffc0202810:	00003617          	auipc	a2,0x3
ffffffffc0202814:	1e863603          	ld	a2,488(a2) # ffffffffc02059f8 <nbase>
ffffffffc0202818:	8719                	srai	a4,a4,0x6
ffffffffc020281a:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020281c:	0000b697          	auipc	a3,0xb
ffffffffc0202820:	c8c6b683          	ld	a3,-884(a3) # ffffffffc020d4a8 <npage>
ffffffffc0202824:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202826:	0732                	slli	a4,a4,0xc
ffffffffc0202828:	28d77763          	bgeu	a4,a3,ffffffffc0202ab6 <default_check+0x342>
    return page - pages + nbase;
ffffffffc020282c:	40f98733          	sub	a4,s3,a5
ffffffffc0202830:	8719                	srai	a4,a4,0x6
ffffffffc0202832:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202834:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202836:	4cd77063          	bgeu	a4,a3,ffffffffc0202cf6 <default_check+0x582>
    return page - pages + nbase;
ffffffffc020283a:	40f507b3          	sub	a5,a0,a5
ffffffffc020283e:	8799                	srai	a5,a5,0x6
ffffffffc0202840:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202842:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0202844:	30d7f963          	bgeu	a5,a3,ffffffffc0202b56 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0202848:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020284a:	00043c03          	ld	s8,0(s0)
ffffffffc020284e:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0202852:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0202856:	e400                	sd	s0,8(s0)
ffffffffc0202858:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020285a:	00007797          	auipc	a5,0x7
ffffffffc020285e:	be07a323          	sw	zero,-1050(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0202862:	db0fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc0202866:	2c051863          	bnez	a0,ffffffffc0202b36 <default_check+0x3c2>
    free_page(p0);
ffffffffc020286a:	4585                	li	a1,1
ffffffffc020286c:	8556                	mv	a0,s5
ffffffffc020286e:	de2fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    free_page(p1);
ffffffffc0202872:	4585                	li	a1,1
ffffffffc0202874:	854e                	mv	a0,s3
ffffffffc0202876:	ddafe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    free_page(p2);
ffffffffc020287a:	4585                	li	a1,1
ffffffffc020287c:	8552                	mv	a0,s4
ffffffffc020287e:	dd2fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    assert(nr_free == 3);
ffffffffc0202882:	4818                	lw	a4,16(s0)
ffffffffc0202884:	478d                	li	a5,3
ffffffffc0202886:	28f71863          	bne	a4,a5,ffffffffc0202b16 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020288a:	4505                	li	a0,1
ffffffffc020288c:	d86fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc0202890:	89aa                	mv	s3,a0
ffffffffc0202892:	26050263          	beqz	a0,ffffffffc0202af6 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202896:	4505                	li	a0,1
ffffffffc0202898:	d7afe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc020289c:	8aaa                	mv	s5,a0
ffffffffc020289e:	3a050c63          	beqz	a0,ffffffffc0202c56 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02028a2:	4505                	li	a0,1
ffffffffc02028a4:	d6efe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02028a8:	8a2a                	mv	s4,a0
ffffffffc02028aa:	38050663          	beqz	a0,ffffffffc0202c36 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02028ae:	4505                	li	a0,1
ffffffffc02028b0:	d62fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02028b4:	36051163          	bnez	a0,ffffffffc0202c16 <default_check+0x4a2>
    free_page(p0);
ffffffffc02028b8:	4585                	li	a1,1
ffffffffc02028ba:	854e                	mv	a0,s3
ffffffffc02028bc:	d94fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02028c0:	641c                	ld	a5,8(s0)
ffffffffc02028c2:	20878a63          	beq	a5,s0,ffffffffc0202ad6 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02028c6:	4505                	li	a0,1
ffffffffc02028c8:	d4afe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02028cc:	30a99563          	bne	s3,a0,ffffffffc0202bd6 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02028d0:	4505                	li	a0,1
ffffffffc02028d2:	d40fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02028d6:	2e051063          	bnez	a0,ffffffffc0202bb6 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02028da:	481c                	lw	a5,16(s0)
ffffffffc02028dc:	2a079d63          	bnez	a5,ffffffffc0202b96 <default_check+0x422>
    free_page(p);
ffffffffc02028e0:	854e                	mv	a0,s3
ffffffffc02028e2:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02028e4:	01843023          	sd	s8,0(s0)
ffffffffc02028e8:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02028ec:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02028f0:	d60fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    free_page(p1);
ffffffffc02028f4:	4585                	li	a1,1
ffffffffc02028f6:	8556                	mv	a0,s5
ffffffffc02028f8:	d58fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    free_page(p2);
ffffffffc02028fc:	4585                	li	a1,1
ffffffffc02028fe:	8552                	mv	a0,s4
ffffffffc0202900:	d50fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0202904:	4515                	li	a0,5
ffffffffc0202906:	d0cfe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc020290a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020290c:	26050563          	beqz	a0,ffffffffc0202b76 <default_check+0x402>
ffffffffc0202910:	651c                	ld	a5,8(a0)
ffffffffc0202912:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0202914:	8b85                	andi	a5,a5,1
ffffffffc0202916:	54079063          	bnez	a5,ffffffffc0202e56 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020291a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020291c:	00043b03          	ld	s6,0(s0)
ffffffffc0202920:	00843a83          	ld	s5,8(s0)
ffffffffc0202924:	e000                	sd	s0,0(s0)
ffffffffc0202926:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0202928:	ceafe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc020292c:	50051563          	bnez	a0,ffffffffc0202e36 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0202930:	08098a13          	addi	s4,s3,128
ffffffffc0202934:	8552                	mv	a0,s4
ffffffffc0202936:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0202938:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020293c:	00007797          	auipc	a5,0x7
ffffffffc0202940:	b007a223          	sw	zero,-1276(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0202944:	d0cfe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0202948:	4511                	li	a0,4
ffffffffc020294a:	cc8fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc020294e:	4c051463          	bnez	a0,ffffffffc0202e16 <default_check+0x6a2>
ffffffffc0202952:	0889b783          	ld	a5,136(s3)
ffffffffc0202956:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202958:	8b85                	andi	a5,a5,1
ffffffffc020295a:	48078e63          	beqz	a5,ffffffffc0202df6 <default_check+0x682>
ffffffffc020295e:	0909a703          	lw	a4,144(s3)
ffffffffc0202962:	478d                	li	a5,3
ffffffffc0202964:	48f71963          	bne	a4,a5,ffffffffc0202df6 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202968:	450d                	li	a0,3
ffffffffc020296a:	ca8fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc020296e:	8c2a                	mv	s8,a0
ffffffffc0202970:	46050363          	beqz	a0,ffffffffc0202dd6 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0202974:	4505                	li	a0,1
ffffffffc0202976:	c9cfe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc020297a:	42051e63          	bnez	a0,ffffffffc0202db6 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc020297e:	418a1c63          	bne	s4,s8,ffffffffc0202d96 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0202982:	4585                	li	a1,1
ffffffffc0202984:	854e                	mv	a0,s3
ffffffffc0202986:	ccafe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    free_pages(p1, 3);
ffffffffc020298a:	458d                	li	a1,3
ffffffffc020298c:	8552                	mv	a0,s4
ffffffffc020298e:	cc2fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
ffffffffc0202992:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0202996:	04098c13          	addi	s8,s3,64
ffffffffc020299a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020299c:	8b85                	andi	a5,a5,1
ffffffffc020299e:	3c078c63          	beqz	a5,ffffffffc0202d76 <default_check+0x602>
ffffffffc02029a2:	0109a703          	lw	a4,16(s3)
ffffffffc02029a6:	4785                	li	a5,1
ffffffffc02029a8:	3cf71763          	bne	a4,a5,ffffffffc0202d76 <default_check+0x602>
ffffffffc02029ac:	008a3783          	ld	a5,8(s4)
ffffffffc02029b0:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02029b2:	8b85                	andi	a5,a5,1
ffffffffc02029b4:	3a078163          	beqz	a5,ffffffffc0202d56 <default_check+0x5e2>
ffffffffc02029b8:	010a2703          	lw	a4,16(s4)
ffffffffc02029bc:	478d                	li	a5,3
ffffffffc02029be:	38f71c63          	bne	a4,a5,ffffffffc0202d56 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02029c2:	4505                	li	a0,1
ffffffffc02029c4:	c4efe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02029c8:	36a99763          	bne	s3,a0,ffffffffc0202d36 <default_check+0x5c2>
    free_page(p0);
ffffffffc02029cc:	4585                	li	a1,1
ffffffffc02029ce:	c82fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02029d2:	4509                	li	a0,2
ffffffffc02029d4:	c3efe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02029d8:	32aa1f63          	bne	s4,a0,ffffffffc0202d16 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02029dc:	4589                	li	a1,2
ffffffffc02029de:	c72fe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    free_page(p2);
ffffffffc02029e2:	4585                	li	a1,1
ffffffffc02029e4:	8562                	mv	a0,s8
ffffffffc02029e6:	c6afe0ef          	jal	ra,ffffffffc0200e50 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02029ea:	4515                	li	a0,5
ffffffffc02029ec:	c26fe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02029f0:	89aa                	mv	s3,a0
ffffffffc02029f2:	48050263          	beqz	a0,ffffffffc0202e76 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02029f6:	4505                	li	a0,1
ffffffffc02029f8:	c1afe0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
ffffffffc02029fc:	2c051d63          	bnez	a0,ffffffffc0202cd6 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0202a00:	481c                	lw	a5,16(s0)
ffffffffc0202a02:	2a079a63          	bnez	a5,ffffffffc0202cb6 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0202a06:	4595                	li	a1,5
ffffffffc0202a08:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0202a0a:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0202a0e:	01643023          	sd	s6,0(s0)
ffffffffc0202a12:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0202a16:	c3afe0ef          	jal	ra,ffffffffc0200e50 <free_pages>
    return listelm->next;
ffffffffc0202a1a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202a1c:	00878963          	beq	a5,s0,ffffffffc0202a2e <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0202a20:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202a24:	679c                	ld	a5,8(a5)
ffffffffc0202a26:	397d                	addiw	s2,s2,-1
ffffffffc0202a28:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202a2a:	fe879be3          	bne	a5,s0,ffffffffc0202a20 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0202a2e:	26091463          	bnez	s2,ffffffffc0202c96 <default_check+0x522>
    assert(total == 0);
ffffffffc0202a32:	46049263          	bnez	s1,ffffffffc0202e96 <default_check+0x722>
}
ffffffffc0202a36:	60a6                	ld	ra,72(sp)
ffffffffc0202a38:	6406                	ld	s0,64(sp)
ffffffffc0202a3a:	74e2                	ld	s1,56(sp)
ffffffffc0202a3c:	7942                	ld	s2,48(sp)
ffffffffc0202a3e:	79a2                	ld	s3,40(sp)
ffffffffc0202a40:	7a02                	ld	s4,32(sp)
ffffffffc0202a42:	6ae2                	ld	s5,24(sp)
ffffffffc0202a44:	6b42                	ld	s6,16(sp)
ffffffffc0202a46:	6ba2                	ld	s7,8(sp)
ffffffffc0202a48:	6c02                	ld	s8,0(sp)
ffffffffc0202a4a:	6161                	addi	sp,sp,80
ffffffffc0202a4c:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202a4e:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0202a50:	4481                	li	s1,0
ffffffffc0202a52:	4901                	li	s2,0
ffffffffc0202a54:	b38d                	j	ffffffffc02027b6 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0202a56:	00002697          	auipc	a3,0x2
ffffffffc0202a5a:	7ca68693          	addi	a3,a3,1994 # ffffffffc0205220 <commands+0x10e8>
ffffffffc0202a5e:	00002617          	auipc	a2,0x2
ffffffffc0202a62:	04a60613          	addi	a2,a2,74 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202a66:	0f000593          	li	a1,240
ffffffffc0202a6a:	00002517          	auipc	a0,0x2
ffffffffc0202a6e:	7c650513          	addi	a0,a0,1990 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202a72:	f6cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0202a76:	00003697          	auipc	a3,0x3
ffffffffc0202a7a:	85268693          	addi	a3,a3,-1966 # ffffffffc02052c8 <commands+0x1190>
ffffffffc0202a7e:	00002617          	auipc	a2,0x2
ffffffffc0202a82:	02a60613          	addi	a2,a2,42 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202a86:	0bd00593          	li	a1,189
ffffffffc0202a8a:	00002517          	auipc	a0,0x2
ffffffffc0202a8e:	7a650513          	addi	a0,a0,1958 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202a92:	f4cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202a96:	00003697          	auipc	a3,0x3
ffffffffc0202a9a:	85a68693          	addi	a3,a3,-1958 # ffffffffc02052f0 <commands+0x11b8>
ffffffffc0202a9e:	00002617          	auipc	a2,0x2
ffffffffc0202aa2:	00a60613          	addi	a2,a2,10 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202aa6:	0be00593          	li	a1,190
ffffffffc0202aaa:	00002517          	auipc	a0,0x2
ffffffffc0202aae:	78650513          	addi	a0,a0,1926 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202ab2:	f2cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0202ab6:	00003697          	auipc	a3,0x3
ffffffffc0202aba:	87a68693          	addi	a3,a3,-1926 # ffffffffc0205330 <commands+0x11f8>
ffffffffc0202abe:	00002617          	auipc	a2,0x2
ffffffffc0202ac2:	fea60613          	addi	a2,a2,-22 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202ac6:	0c000593          	li	a1,192
ffffffffc0202aca:	00002517          	auipc	a0,0x2
ffffffffc0202ace:	76650513          	addi	a0,a0,1894 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202ad2:	f0cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(!list_empty(&free_list));
ffffffffc0202ad6:	00003697          	auipc	a3,0x3
ffffffffc0202ada:	8e268693          	addi	a3,a3,-1822 # ffffffffc02053b8 <commands+0x1280>
ffffffffc0202ade:	00002617          	auipc	a2,0x2
ffffffffc0202ae2:	fca60613          	addi	a2,a2,-54 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202ae6:	0d900593          	li	a1,217
ffffffffc0202aea:	00002517          	auipc	a0,0x2
ffffffffc0202aee:	74650513          	addi	a0,a0,1862 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202af2:	eecfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202af6:	00002697          	auipc	a3,0x2
ffffffffc0202afa:	77268693          	addi	a3,a3,1906 # ffffffffc0205268 <commands+0x1130>
ffffffffc0202afe:	00002617          	auipc	a2,0x2
ffffffffc0202b02:	faa60613          	addi	a2,a2,-86 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202b06:	0d200593          	li	a1,210
ffffffffc0202b0a:	00002517          	auipc	a0,0x2
ffffffffc0202b0e:	72650513          	addi	a0,a0,1830 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202b12:	eccfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 3);
ffffffffc0202b16:	00003697          	auipc	a3,0x3
ffffffffc0202b1a:	89268693          	addi	a3,a3,-1902 # ffffffffc02053a8 <commands+0x1270>
ffffffffc0202b1e:	00002617          	auipc	a2,0x2
ffffffffc0202b22:	f8a60613          	addi	a2,a2,-118 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202b26:	0d000593          	li	a1,208
ffffffffc0202b2a:	00002517          	auipc	a0,0x2
ffffffffc0202b2e:	70650513          	addi	a0,a0,1798 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202b32:	eacfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202b36:	00003697          	auipc	a3,0x3
ffffffffc0202b3a:	85a68693          	addi	a3,a3,-1958 # ffffffffc0205390 <commands+0x1258>
ffffffffc0202b3e:	00002617          	auipc	a2,0x2
ffffffffc0202b42:	f6a60613          	addi	a2,a2,-150 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202b46:	0cb00593          	li	a1,203
ffffffffc0202b4a:	00002517          	auipc	a0,0x2
ffffffffc0202b4e:	6e650513          	addi	a0,a0,1766 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202b52:	e8cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0202b56:	00003697          	auipc	a3,0x3
ffffffffc0202b5a:	81a68693          	addi	a3,a3,-2022 # ffffffffc0205370 <commands+0x1238>
ffffffffc0202b5e:	00002617          	auipc	a2,0x2
ffffffffc0202b62:	f4a60613          	addi	a2,a2,-182 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202b66:	0c200593          	li	a1,194
ffffffffc0202b6a:	00002517          	auipc	a0,0x2
ffffffffc0202b6e:	6c650513          	addi	a0,a0,1734 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202b72:	e6cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 != NULL);
ffffffffc0202b76:	00003697          	auipc	a3,0x3
ffffffffc0202b7a:	88a68693          	addi	a3,a3,-1910 # ffffffffc0205400 <commands+0x12c8>
ffffffffc0202b7e:	00002617          	auipc	a2,0x2
ffffffffc0202b82:	f2a60613          	addi	a2,a2,-214 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202b86:	0f800593          	li	a1,248
ffffffffc0202b8a:	00002517          	auipc	a0,0x2
ffffffffc0202b8e:	6a650513          	addi	a0,a0,1702 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202b92:	e4cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 0);
ffffffffc0202b96:	00003697          	auipc	a3,0x3
ffffffffc0202b9a:	85a68693          	addi	a3,a3,-1958 # ffffffffc02053f0 <commands+0x12b8>
ffffffffc0202b9e:	00002617          	auipc	a2,0x2
ffffffffc0202ba2:	f0a60613          	addi	a2,a2,-246 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202ba6:	0df00593          	li	a1,223
ffffffffc0202baa:	00002517          	auipc	a0,0x2
ffffffffc0202bae:	68650513          	addi	a0,a0,1670 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202bb2:	e2cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202bb6:	00002697          	auipc	a3,0x2
ffffffffc0202bba:	7da68693          	addi	a3,a3,2010 # ffffffffc0205390 <commands+0x1258>
ffffffffc0202bbe:	00002617          	auipc	a2,0x2
ffffffffc0202bc2:	eea60613          	addi	a2,a2,-278 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202bc6:	0dd00593          	li	a1,221
ffffffffc0202bca:	00002517          	auipc	a0,0x2
ffffffffc0202bce:	66650513          	addi	a0,a0,1638 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202bd2:	e0cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0202bd6:	00002697          	auipc	a3,0x2
ffffffffc0202bda:	7fa68693          	addi	a3,a3,2042 # ffffffffc02053d0 <commands+0x1298>
ffffffffc0202bde:	00002617          	auipc	a2,0x2
ffffffffc0202be2:	eca60613          	addi	a2,a2,-310 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202be6:	0dc00593          	li	a1,220
ffffffffc0202bea:	00002517          	auipc	a0,0x2
ffffffffc0202bee:	64650513          	addi	a0,a0,1606 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202bf2:	decfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202bf6:	00002697          	auipc	a3,0x2
ffffffffc0202bfa:	67268693          	addi	a3,a3,1650 # ffffffffc0205268 <commands+0x1130>
ffffffffc0202bfe:	00002617          	auipc	a2,0x2
ffffffffc0202c02:	eaa60613          	addi	a2,a2,-342 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202c06:	0b900593          	li	a1,185
ffffffffc0202c0a:	00002517          	auipc	a0,0x2
ffffffffc0202c0e:	62650513          	addi	a0,a0,1574 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202c12:	dccfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202c16:	00002697          	auipc	a3,0x2
ffffffffc0202c1a:	77a68693          	addi	a3,a3,1914 # ffffffffc0205390 <commands+0x1258>
ffffffffc0202c1e:	00002617          	auipc	a2,0x2
ffffffffc0202c22:	e8a60613          	addi	a2,a2,-374 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202c26:	0d600593          	li	a1,214
ffffffffc0202c2a:	00002517          	auipc	a0,0x2
ffffffffc0202c2e:	60650513          	addi	a0,a0,1542 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202c32:	dacfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202c36:	00002697          	auipc	a3,0x2
ffffffffc0202c3a:	67268693          	addi	a3,a3,1650 # ffffffffc02052a8 <commands+0x1170>
ffffffffc0202c3e:	00002617          	auipc	a2,0x2
ffffffffc0202c42:	e6a60613          	addi	a2,a2,-406 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202c46:	0d400593          	li	a1,212
ffffffffc0202c4a:	00002517          	auipc	a0,0x2
ffffffffc0202c4e:	5e650513          	addi	a0,a0,1510 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202c52:	d8cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202c56:	00002697          	auipc	a3,0x2
ffffffffc0202c5a:	63268693          	addi	a3,a3,1586 # ffffffffc0205288 <commands+0x1150>
ffffffffc0202c5e:	00002617          	auipc	a2,0x2
ffffffffc0202c62:	e4a60613          	addi	a2,a2,-438 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202c66:	0d300593          	li	a1,211
ffffffffc0202c6a:	00002517          	auipc	a0,0x2
ffffffffc0202c6e:	5c650513          	addi	a0,a0,1478 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202c72:	d6cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202c76:	00002697          	auipc	a3,0x2
ffffffffc0202c7a:	63268693          	addi	a3,a3,1586 # ffffffffc02052a8 <commands+0x1170>
ffffffffc0202c7e:	00002617          	auipc	a2,0x2
ffffffffc0202c82:	e2a60613          	addi	a2,a2,-470 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202c86:	0bb00593          	li	a1,187
ffffffffc0202c8a:	00002517          	auipc	a0,0x2
ffffffffc0202c8e:	5a650513          	addi	a0,a0,1446 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202c92:	d4cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(count == 0);
ffffffffc0202c96:	00003697          	auipc	a3,0x3
ffffffffc0202c9a:	8ba68693          	addi	a3,a3,-1862 # ffffffffc0205550 <commands+0x1418>
ffffffffc0202c9e:	00002617          	auipc	a2,0x2
ffffffffc0202ca2:	e0a60613          	addi	a2,a2,-502 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202ca6:	12500593          	li	a1,293
ffffffffc0202caa:	00002517          	auipc	a0,0x2
ffffffffc0202cae:	58650513          	addi	a0,a0,1414 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202cb2:	d2cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 0);
ffffffffc0202cb6:	00002697          	auipc	a3,0x2
ffffffffc0202cba:	73a68693          	addi	a3,a3,1850 # ffffffffc02053f0 <commands+0x12b8>
ffffffffc0202cbe:	00002617          	auipc	a2,0x2
ffffffffc0202cc2:	dea60613          	addi	a2,a2,-534 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202cc6:	11a00593          	li	a1,282
ffffffffc0202cca:	00002517          	auipc	a0,0x2
ffffffffc0202cce:	56650513          	addi	a0,a0,1382 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202cd2:	d0cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202cd6:	00002697          	auipc	a3,0x2
ffffffffc0202cda:	6ba68693          	addi	a3,a3,1722 # ffffffffc0205390 <commands+0x1258>
ffffffffc0202cde:	00002617          	auipc	a2,0x2
ffffffffc0202ce2:	dca60613          	addi	a2,a2,-566 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202ce6:	11800593          	li	a1,280
ffffffffc0202cea:	00002517          	auipc	a0,0x2
ffffffffc0202cee:	54650513          	addi	a0,a0,1350 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202cf2:	cecfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202cf6:	00002697          	auipc	a3,0x2
ffffffffc0202cfa:	65a68693          	addi	a3,a3,1626 # ffffffffc0205350 <commands+0x1218>
ffffffffc0202cfe:	00002617          	auipc	a2,0x2
ffffffffc0202d02:	daa60613          	addi	a2,a2,-598 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202d06:	0c100593          	li	a1,193
ffffffffc0202d0a:	00002517          	auipc	a0,0x2
ffffffffc0202d0e:	52650513          	addi	a0,a0,1318 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202d12:	cccfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202d16:	00002697          	auipc	a3,0x2
ffffffffc0202d1a:	7fa68693          	addi	a3,a3,2042 # ffffffffc0205510 <commands+0x13d8>
ffffffffc0202d1e:	00002617          	auipc	a2,0x2
ffffffffc0202d22:	d8a60613          	addi	a2,a2,-630 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202d26:	11200593          	li	a1,274
ffffffffc0202d2a:	00002517          	auipc	a0,0x2
ffffffffc0202d2e:	50650513          	addi	a0,a0,1286 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202d32:	cacfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202d36:	00002697          	auipc	a3,0x2
ffffffffc0202d3a:	7ba68693          	addi	a3,a3,1978 # ffffffffc02054f0 <commands+0x13b8>
ffffffffc0202d3e:	00002617          	auipc	a2,0x2
ffffffffc0202d42:	d6a60613          	addi	a2,a2,-662 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202d46:	11000593          	li	a1,272
ffffffffc0202d4a:	00002517          	auipc	a0,0x2
ffffffffc0202d4e:	4e650513          	addi	a0,a0,1254 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202d52:	c8cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202d56:	00002697          	auipc	a3,0x2
ffffffffc0202d5a:	77268693          	addi	a3,a3,1906 # ffffffffc02054c8 <commands+0x1390>
ffffffffc0202d5e:	00002617          	auipc	a2,0x2
ffffffffc0202d62:	d4a60613          	addi	a2,a2,-694 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202d66:	10e00593          	li	a1,270
ffffffffc0202d6a:	00002517          	auipc	a0,0x2
ffffffffc0202d6e:	4c650513          	addi	a0,a0,1222 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202d72:	c6cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202d76:	00002697          	auipc	a3,0x2
ffffffffc0202d7a:	72a68693          	addi	a3,a3,1834 # ffffffffc02054a0 <commands+0x1368>
ffffffffc0202d7e:	00002617          	auipc	a2,0x2
ffffffffc0202d82:	d2a60613          	addi	a2,a2,-726 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202d86:	10d00593          	li	a1,269
ffffffffc0202d8a:	00002517          	auipc	a0,0x2
ffffffffc0202d8e:	4a650513          	addi	a0,a0,1190 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202d92:	c4cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 + 2 == p1);
ffffffffc0202d96:	00002697          	auipc	a3,0x2
ffffffffc0202d9a:	6fa68693          	addi	a3,a3,1786 # ffffffffc0205490 <commands+0x1358>
ffffffffc0202d9e:	00002617          	auipc	a2,0x2
ffffffffc0202da2:	d0a60613          	addi	a2,a2,-758 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202da6:	10800593          	li	a1,264
ffffffffc0202daa:	00002517          	auipc	a0,0x2
ffffffffc0202dae:	48650513          	addi	a0,a0,1158 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202db2:	c2cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202db6:	00002697          	auipc	a3,0x2
ffffffffc0202dba:	5da68693          	addi	a3,a3,1498 # ffffffffc0205390 <commands+0x1258>
ffffffffc0202dbe:	00002617          	auipc	a2,0x2
ffffffffc0202dc2:	cea60613          	addi	a2,a2,-790 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202dc6:	10700593          	li	a1,263
ffffffffc0202dca:	00002517          	auipc	a0,0x2
ffffffffc0202dce:	46650513          	addi	a0,a0,1126 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202dd2:	c0cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202dd6:	00002697          	auipc	a3,0x2
ffffffffc0202dda:	69a68693          	addi	a3,a3,1690 # ffffffffc0205470 <commands+0x1338>
ffffffffc0202dde:	00002617          	auipc	a2,0x2
ffffffffc0202de2:	cca60613          	addi	a2,a2,-822 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202de6:	10600593          	li	a1,262
ffffffffc0202dea:	00002517          	auipc	a0,0x2
ffffffffc0202dee:	44650513          	addi	a0,a0,1094 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202df2:	becfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202df6:	00002697          	auipc	a3,0x2
ffffffffc0202dfa:	64a68693          	addi	a3,a3,1610 # ffffffffc0205440 <commands+0x1308>
ffffffffc0202dfe:	00002617          	auipc	a2,0x2
ffffffffc0202e02:	caa60613          	addi	a2,a2,-854 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202e06:	10500593          	li	a1,261
ffffffffc0202e0a:	00002517          	auipc	a0,0x2
ffffffffc0202e0e:	42650513          	addi	a0,a0,1062 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202e12:	bccfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0202e16:	00002697          	auipc	a3,0x2
ffffffffc0202e1a:	61268693          	addi	a3,a3,1554 # ffffffffc0205428 <commands+0x12f0>
ffffffffc0202e1e:	00002617          	auipc	a2,0x2
ffffffffc0202e22:	c8a60613          	addi	a2,a2,-886 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202e26:	10400593          	li	a1,260
ffffffffc0202e2a:	00002517          	auipc	a0,0x2
ffffffffc0202e2e:	40650513          	addi	a0,a0,1030 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202e32:	bacfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202e36:	00002697          	auipc	a3,0x2
ffffffffc0202e3a:	55a68693          	addi	a3,a3,1370 # ffffffffc0205390 <commands+0x1258>
ffffffffc0202e3e:	00002617          	auipc	a2,0x2
ffffffffc0202e42:	c6a60613          	addi	a2,a2,-918 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202e46:	0fe00593          	li	a1,254
ffffffffc0202e4a:	00002517          	auipc	a0,0x2
ffffffffc0202e4e:	3e650513          	addi	a0,a0,998 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202e52:	b8cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(!PageProperty(p0));
ffffffffc0202e56:	00002697          	auipc	a3,0x2
ffffffffc0202e5a:	5ba68693          	addi	a3,a3,1466 # ffffffffc0205410 <commands+0x12d8>
ffffffffc0202e5e:	00002617          	auipc	a2,0x2
ffffffffc0202e62:	c4a60613          	addi	a2,a2,-950 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202e66:	0f900593          	li	a1,249
ffffffffc0202e6a:	00002517          	auipc	a0,0x2
ffffffffc0202e6e:	3c650513          	addi	a0,a0,966 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202e72:	b6cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202e76:	00002697          	auipc	a3,0x2
ffffffffc0202e7a:	6ba68693          	addi	a3,a3,1722 # ffffffffc0205530 <commands+0x13f8>
ffffffffc0202e7e:	00002617          	auipc	a2,0x2
ffffffffc0202e82:	c2a60613          	addi	a2,a2,-982 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202e86:	11700593          	li	a1,279
ffffffffc0202e8a:	00002517          	auipc	a0,0x2
ffffffffc0202e8e:	3a650513          	addi	a0,a0,934 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202e92:	b4cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(total == 0);
ffffffffc0202e96:	00002697          	auipc	a3,0x2
ffffffffc0202e9a:	6ca68693          	addi	a3,a3,1738 # ffffffffc0205560 <commands+0x1428>
ffffffffc0202e9e:	00002617          	auipc	a2,0x2
ffffffffc0202ea2:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202ea6:	12600593          	li	a1,294
ffffffffc0202eaa:	00002517          	auipc	a0,0x2
ffffffffc0202eae:	38650513          	addi	a0,a0,902 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202eb2:	b2cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(total == nr_free_pages());
ffffffffc0202eb6:	00002697          	auipc	a3,0x2
ffffffffc0202eba:	39268693          	addi	a3,a3,914 # ffffffffc0205248 <commands+0x1110>
ffffffffc0202ebe:	00002617          	auipc	a2,0x2
ffffffffc0202ec2:	bea60613          	addi	a2,a2,-1046 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202ec6:	0f300593          	li	a1,243
ffffffffc0202eca:	00002517          	auipc	a0,0x2
ffffffffc0202ece:	36650513          	addi	a0,a0,870 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202ed2:	b0cfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202ed6:	00002697          	auipc	a3,0x2
ffffffffc0202eda:	3b268693          	addi	a3,a3,946 # ffffffffc0205288 <commands+0x1150>
ffffffffc0202ede:	00002617          	auipc	a2,0x2
ffffffffc0202ee2:	bca60613          	addi	a2,a2,-1078 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0202ee6:	0ba00593          	li	a1,186
ffffffffc0202eea:	00002517          	auipc	a0,0x2
ffffffffc0202eee:	34650513          	addi	a0,a0,838 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0202ef2:	aecfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202ef6 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0202ef6:	1141                	addi	sp,sp,-16
ffffffffc0202ef8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202efa:	14058463          	beqz	a1,ffffffffc0203042 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0202efe:	00659693          	slli	a3,a1,0x6
ffffffffc0202f02:	96aa                	add	a3,a3,a0
ffffffffc0202f04:	87aa                	mv	a5,a0
ffffffffc0202f06:	02d50263          	beq	a0,a3,ffffffffc0202f2a <default_free_pages+0x34>
ffffffffc0202f0a:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202f0c:	8b05                	andi	a4,a4,1
ffffffffc0202f0e:	10071a63          	bnez	a4,ffffffffc0203022 <default_free_pages+0x12c>
ffffffffc0202f12:	6798                	ld	a4,8(a5)
ffffffffc0202f14:	8b09                	andi	a4,a4,2
ffffffffc0202f16:	10071663          	bnez	a4,ffffffffc0203022 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0202f1a:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0202f1e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202f22:	04078793          	addi	a5,a5,64
ffffffffc0202f26:	fed792e3          	bne	a5,a3,ffffffffc0202f0a <default_free_pages+0x14>
    base->property = n;
ffffffffc0202f2a:	2581                	sext.w	a1,a1
ffffffffc0202f2c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0202f2e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202f32:	4789                	li	a5,2
ffffffffc0202f34:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0202f38:	00006697          	auipc	a3,0x6
ffffffffc0202f3c:	4f868693          	addi	a3,a3,1272 # ffffffffc0209430 <free_area>
ffffffffc0202f40:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202f42:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0202f44:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0202f48:	9db9                	addw	a1,a1,a4
ffffffffc0202f4a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0202f4c:	0ad78463          	beq	a5,a3,ffffffffc0202ff4 <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc0202f50:	fe878713          	addi	a4,a5,-24
ffffffffc0202f54:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202f58:	4581                	li	a1,0
            if (base < page) {
ffffffffc0202f5a:	00e56a63          	bltu	a0,a4,ffffffffc0202f6e <default_free_pages+0x78>
    return listelm->next;
ffffffffc0202f5e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202f60:	04d70c63          	beq	a4,a3,ffffffffc0202fb8 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc0202f64:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202f66:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0202f6a:	fee57ae3          	bgeu	a0,a4,ffffffffc0202f5e <default_free_pages+0x68>
ffffffffc0202f6e:	c199                	beqz	a1,ffffffffc0202f74 <default_free_pages+0x7e>
ffffffffc0202f70:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202f74:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0202f76:	e390                	sd	a2,0(a5)
ffffffffc0202f78:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202f7a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202f7c:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0202f7e:	00d70d63          	beq	a4,a3,ffffffffc0202f98 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0202f82:	ff872583          	lw	a1,-8(a4) # ff8 <kern_entry-0xffffffffc01ff008>
        p = le2page(le, page_link);
ffffffffc0202f86:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0202f8a:	02059813          	slli	a6,a1,0x20
ffffffffc0202f8e:	01a85793          	srli	a5,a6,0x1a
ffffffffc0202f92:	97b2                	add	a5,a5,a2
ffffffffc0202f94:	02f50c63          	beq	a0,a5,ffffffffc0202fcc <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0202f98:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0202f9a:	00d78c63          	beq	a5,a3,ffffffffc0202fb2 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0202f9e:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0202fa0:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0202fa4:	02061593          	slli	a1,a2,0x20
ffffffffc0202fa8:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0202fac:	972a                	add	a4,a4,a0
ffffffffc0202fae:	04e68a63          	beq	a3,a4,ffffffffc0203002 <default_free_pages+0x10c>
}
ffffffffc0202fb2:	60a2                	ld	ra,8(sp)
ffffffffc0202fb4:	0141                	addi	sp,sp,16
ffffffffc0202fb6:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202fb8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202fba:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0202fbc:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0202fbe:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202fc0:	02d70763          	beq	a4,a3,ffffffffc0202fee <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0202fc4:	8832                	mv	a6,a2
ffffffffc0202fc6:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202fc8:	87ba                	mv	a5,a4
ffffffffc0202fca:	bf71                	j	ffffffffc0202f66 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0202fcc:	491c                	lw	a5,16(a0)
ffffffffc0202fce:	9dbd                	addw	a1,a1,a5
ffffffffc0202fd0:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202fd4:	57f5                	li	a5,-3
ffffffffc0202fd6:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202fda:	01853803          	ld	a6,24(a0)
ffffffffc0202fde:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0202fe0:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0202fe2:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0202fe6:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0202fe8:	0105b023          	sd	a6,0(a1) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0202fec:	b77d                	j	ffffffffc0202f9a <default_free_pages+0xa4>
ffffffffc0202fee:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202ff0:	873e                	mv	a4,a5
ffffffffc0202ff2:	bf41                	j	ffffffffc0202f82 <default_free_pages+0x8c>
}
ffffffffc0202ff4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0202ff6:	e390                	sd	a2,0(a5)
ffffffffc0202ff8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202ffa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202ffc:	ed1c                	sd	a5,24(a0)
ffffffffc0202ffe:	0141                	addi	sp,sp,16
ffffffffc0203000:	8082                	ret
            base->property += p->property;
ffffffffc0203002:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203006:	ff078693          	addi	a3,a5,-16
ffffffffc020300a:	9e39                	addw	a2,a2,a4
ffffffffc020300c:	c910                	sw	a2,16(a0)
ffffffffc020300e:	5775                	li	a4,-3
ffffffffc0203010:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203014:	6398                	ld	a4,0(a5)
ffffffffc0203016:	679c                	ld	a5,8(a5)
}
ffffffffc0203018:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020301a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020301c:	e398                	sd	a4,0(a5)
ffffffffc020301e:	0141                	addi	sp,sp,16
ffffffffc0203020:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203022:	00002697          	auipc	a3,0x2
ffffffffc0203026:	55668693          	addi	a3,a3,1366 # ffffffffc0205578 <commands+0x1440>
ffffffffc020302a:	00002617          	auipc	a2,0x2
ffffffffc020302e:	a7e60613          	addi	a2,a2,-1410 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0203032:	08300593          	li	a1,131
ffffffffc0203036:	00002517          	auipc	a0,0x2
ffffffffc020303a:	1fa50513          	addi	a0,a0,506 # ffffffffc0205230 <commands+0x10f8>
ffffffffc020303e:	9a0fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(n > 0);
ffffffffc0203042:	00002697          	auipc	a3,0x2
ffffffffc0203046:	52e68693          	addi	a3,a3,1326 # ffffffffc0205570 <commands+0x1438>
ffffffffc020304a:	00002617          	auipc	a2,0x2
ffffffffc020304e:	a5e60613          	addi	a2,a2,-1442 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0203052:	08000593          	li	a1,128
ffffffffc0203056:	00002517          	auipc	a0,0x2
ffffffffc020305a:	1da50513          	addi	a0,a0,474 # ffffffffc0205230 <commands+0x10f8>
ffffffffc020305e:	980fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203062 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0203062:	c941                	beqz	a0,ffffffffc02030f2 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc0203064:	00006597          	auipc	a1,0x6
ffffffffc0203068:	3cc58593          	addi	a1,a1,972 # ffffffffc0209430 <free_area>
ffffffffc020306c:	0105a803          	lw	a6,16(a1)
ffffffffc0203070:	872a                	mv	a4,a0
ffffffffc0203072:	02081793          	slli	a5,a6,0x20
ffffffffc0203076:	9381                	srli	a5,a5,0x20
ffffffffc0203078:	00a7ee63          	bltu	a5,a0,ffffffffc0203094 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020307c:	87ae                	mv	a5,a1
ffffffffc020307e:	a801                	j	ffffffffc020308e <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0203080:	ff87a683          	lw	a3,-8(a5)
ffffffffc0203084:	02069613          	slli	a2,a3,0x20
ffffffffc0203088:	9201                	srli	a2,a2,0x20
ffffffffc020308a:	00e67763          	bgeu	a2,a4,ffffffffc0203098 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020308e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0203090:	feb798e3          	bne	a5,a1,ffffffffc0203080 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0203094:	4501                	li	a0,0
}
ffffffffc0203096:	8082                	ret
    return listelm->prev;
ffffffffc0203098:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020309c:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02030a0:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02030a4:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02030a8:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02030ac:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02030b0:	02c77863          	bgeu	a4,a2,ffffffffc02030e0 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02030b4:	071a                	slli	a4,a4,0x6
ffffffffc02030b6:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02030b8:	41c686bb          	subw	a3,a3,t3
ffffffffc02030bc:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02030be:	00870613          	addi	a2,a4,8
ffffffffc02030c2:	4689                	li	a3,2
ffffffffc02030c4:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02030c8:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02030cc:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02030d0:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02030d4:	e290                	sd	a2,0(a3)
ffffffffc02030d6:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02030da:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02030dc:	01173c23          	sd	a7,24(a4)
ffffffffc02030e0:	41c8083b          	subw	a6,a6,t3
ffffffffc02030e4:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02030e8:	5775                	li	a4,-3
ffffffffc02030ea:	17c1                	addi	a5,a5,-16
ffffffffc02030ec:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02030f0:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02030f2:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02030f4:	00002697          	auipc	a3,0x2
ffffffffc02030f8:	47c68693          	addi	a3,a3,1148 # ffffffffc0205570 <commands+0x1438>
ffffffffc02030fc:	00002617          	auipc	a2,0x2
ffffffffc0203100:	9ac60613          	addi	a2,a2,-1620 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0203104:	06200593          	li	a1,98
ffffffffc0203108:	00002517          	auipc	a0,0x2
ffffffffc020310c:	12850513          	addi	a0,a0,296 # ffffffffc0205230 <commands+0x10f8>
default_alloc_pages(size_t n) {
ffffffffc0203110:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203112:	8ccfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203116 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0203116:	1141                	addi	sp,sp,-16
ffffffffc0203118:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020311a:	c5f1                	beqz	a1,ffffffffc02031e6 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc020311c:	00659693          	slli	a3,a1,0x6
ffffffffc0203120:	96aa                	add	a3,a3,a0
ffffffffc0203122:	87aa                	mv	a5,a0
ffffffffc0203124:	00d50f63          	beq	a0,a3,ffffffffc0203142 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203128:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020312a:	8b05                	andi	a4,a4,1
ffffffffc020312c:	cf49                	beqz	a4,ffffffffc02031c6 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc020312e:	0007a823          	sw	zero,16(a5)
ffffffffc0203132:	0007b423          	sd	zero,8(a5)
ffffffffc0203136:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020313a:	04078793          	addi	a5,a5,64
ffffffffc020313e:	fed795e3          	bne	a5,a3,ffffffffc0203128 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0203142:	2581                	sext.w	a1,a1
ffffffffc0203144:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203146:	4789                	li	a5,2
ffffffffc0203148:	00850713          	addi	a4,a0,8
ffffffffc020314c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0203150:	00006697          	auipc	a3,0x6
ffffffffc0203154:	2e068693          	addi	a3,a3,736 # ffffffffc0209430 <free_area>
ffffffffc0203158:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020315a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020315c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0203160:	9db9                	addw	a1,a1,a4
ffffffffc0203162:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0203164:	04d78a63          	beq	a5,a3,ffffffffc02031b8 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0203168:	fe878713          	addi	a4,a5,-24
ffffffffc020316c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0203170:	4581                	li	a1,0
            if (base < page) {
ffffffffc0203172:	00e56a63          	bltu	a0,a4,ffffffffc0203186 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0203176:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0203178:	02d70263          	beq	a4,a3,ffffffffc020319c <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc020317c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020317e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0203182:	fee57ae3          	bgeu	a0,a4,ffffffffc0203176 <default_init_memmap+0x60>
ffffffffc0203186:	c199                	beqz	a1,ffffffffc020318c <default_init_memmap+0x76>
ffffffffc0203188:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020318c:	6398                	ld	a4,0(a5)
}
ffffffffc020318e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0203190:	e390                	sd	a2,0(a5)
ffffffffc0203192:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203194:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0203196:	ed18                	sd	a4,24(a0)
ffffffffc0203198:	0141                	addi	sp,sp,16
ffffffffc020319a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020319c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020319e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02031a0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02031a2:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02031a4:	00d70663          	beq	a4,a3,ffffffffc02031b0 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02031a8:	8832                	mv	a6,a2
ffffffffc02031aa:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02031ac:	87ba                	mv	a5,a4
ffffffffc02031ae:	bfc1                	j	ffffffffc020317e <default_init_memmap+0x68>
}
ffffffffc02031b0:	60a2                	ld	ra,8(sp)
ffffffffc02031b2:	e290                	sd	a2,0(a3)
ffffffffc02031b4:	0141                	addi	sp,sp,16
ffffffffc02031b6:	8082                	ret
ffffffffc02031b8:	60a2                	ld	ra,8(sp)
ffffffffc02031ba:	e390                	sd	a2,0(a5)
ffffffffc02031bc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02031be:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02031c0:	ed1c                	sd	a5,24(a0)
ffffffffc02031c2:	0141                	addi	sp,sp,16
ffffffffc02031c4:	8082                	ret
        assert(PageReserved(p));
ffffffffc02031c6:	00002697          	auipc	a3,0x2
ffffffffc02031ca:	3da68693          	addi	a3,a3,986 # ffffffffc02055a0 <commands+0x1468>
ffffffffc02031ce:	00002617          	auipc	a2,0x2
ffffffffc02031d2:	8da60613          	addi	a2,a2,-1830 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02031d6:	04900593          	li	a1,73
ffffffffc02031da:	00002517          	auipc	a0,0x2
ffffffffc02031de:	05650513          	addi	a0,a0,86 # ffffffffc0205230 <commands+0x10f8>
ffffffffc02031e2:	ffdfc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(n > 0);
ffffffffc02031e6:	00002697          	auipc	a3,0x2
ffffffffc02031ea:	38a68693          	addi	a3,a3,906 # ffffffffc0205570 <commands+0x1438>
ffffffffc02031ee:	00002617          	auipc	a2,0x2
ffffffffc02031f2:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02031f6:	04600593          	li	a1,70
ffffffffc02031fa:	00002517          	auipc	a0,0x2
ffffffffc02031fe:	03650513          	addi	a0,a0,54 # ffffffffc0205230 <commands+0x10f8>
ffffffffc0203202:	fddfc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203206 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203206:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203208:	9402                	jalr	s0

	jal do_exit
ffffffffc020320a:	464000ef          	jal	ra,ffffffffc020366e <do_exit>

ffffffffc020320e <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020320e:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0203212:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0203216:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0203218:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020321a:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020321e:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0203222:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203226:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020322a:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020322e:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0203232:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203236:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020323a:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020323e:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0203242:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0203246:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020324a:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020324c:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020324e:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0203252:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203256:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020325a:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020325e:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0203262:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203266:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020326a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020326e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0203272:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203276:	8082                	ret

ffffffffc0203278 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203278:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020327a:	0e800513          	li	a0,232
{
ffffffffc020327e:	e022                	sd	s0,0(sp)
ffffffffc0203280:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203282:	b2cff0ef          	jal	ra,ffffffffc02025ae <kmalloc>
ffffffffc0203286:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203288:	cd21                	beqz	a0,ffffffffc02032e0 <alloc_proc+0x68>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc020328a:	57fd                	li	a5,-1
ffffffffc020328c:	1782                	slli	a5,a5,0x20
ffffffffc020328e:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&proc->context, 0, sizeof(struct context));
ffffffffc0203290:	07000613          	li	a2,112
ffffffffc0203294:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0203296:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc020329a:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc020329e:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;
ffffffffc02032a2:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc02032a6:	02053423          	sd	zero,40(a0)
        memset(&proc->context, 0, sizeof(struct context));
ffffffffc02032aa:	03050513          	addi	a0,a0,48
ffffffffc02032ae:	7ae000ef          	jal	ra,ffffffffc0203a5c <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc02032b2:	0000a797          	auipc	a5,0xa
ffffffffc02032b6:	1e67b783          	ld	a5,486(a5) # ffffffffc020d498 <boot_pgdir_pa>
ffffffffc02032ba:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc02032bc:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;
ffffffffc02032c0:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc02032c4:	4641                	li	a2,16
ffffffffc02032c6:	4581                	li	a1,0
ffffffffc02032c8:	0b440513          	addi	a0,s0,180
ffffffffc02032cc:	790000ef          	jal	ra,ffffffffc0203a5c <memset>
        list_init(&proc->list_link);
ffffffffc02032d0:	0c840713          	addi	a4,s0,200
        list_init(&proc->hash_link);
ffffffffc02032d4:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc02032d8:	e878                	sd	a4,208(s0)
ffffffffc02032da:	e478                	sd	a4,200(s0)
ffffffffc02032dc:	f07c                	sd	a5,224(s0)
ffffffffc02032de:	ec7c                	sd	a5,216(s0)
    }
    return proc;
}
ffffffffc02032e0:	60a2                	ld	ra,8(sp)
ffffffffc02032e2:	8522                	mv	a0,s0
ffffffffc02032e4:	6402                	ld	s0,0(sp)
ffffffffc02032e6:	0141                	addi	sp,sp,16
ffffffffc02032e8:	8082                	ret

ffffffffc02032ea <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc02032ea:	0000a797          	auipc	a5,0xa
ffffffffc02032ee:	1e67b783          	ld	a5,486(a5) # ffffffffc020d4d0 <current>
ffffffffc02032f2:	73c8                	ld	a0,160(a5)
ffffffffc02032f4:	ae1fd06f          	j	ffffffffc0200dd4 <forkrets>

ffffffffc02032f8 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02032f8:	7179                	addi	sp,sp,-48
ffffffffc02032fa:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc02032fc:	0000a497          	auipc	s1,0xa
ffffffffc0203300:	14c48493          	addi	s1,s1,332 # ffffffffc020d448 <name.2>
{
ffffffffc0203304:	f022                	sd	s0,32(sp)
ffffffffc0203306:	e84a                	sd	s2,16(sp)
ffffffffc0203308:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020330a:	0000a917          	auipc	s2,0xa
ffffffffc020330e:	1c693903          	ld	s2,454(s2) # ffffffffc020d4d0 <current>
    memset(name, 0, sizeof(name));
ffffffffc0203312:	4641                	li	a2,16
ffffffffc0203314:	4581                	li	a1,0
ffffffffc0203316:	8526                	mv	a0,s1
{
ffffffffc0203318:	f406                	sd	ra,40(sp)
ffffffffc020331a:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020331c:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc0203320:	73c000ef          	jal	ra,ffffffffc0203a5c <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0203324:	0b490593          	addi	a1,s2,180
ffffffffc0203328:	463d                	li	a2,15
ffffffffc020332a:	8526                	mv	a0,s1
ffffffffc020332c:	742000ef          	jal	ra,ffffffffc0203a6e <memcpy>
ffffffffc0203330:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203332:	85ce                	mv	a1,s3
ffffffffc0203334:	00002517          	auipc	a0,0x2
ffffffffc0203338:	2cc50513          	addi	a0,a0,716 # ffffffffc0205600 <default_pmm_manager+0x38>
ffffffffc020333c:	da5fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc0203340:	85a2                	mv	a1,s0
ffffffffc0203342:	00002517          	auipc	a0,0x2
ffffffffc0203346:	2e650513          	addi	a0,a0,742 # ffffffffc0205628 <default_pmm_manager+0x60>
ffffffffc020334a:	d97fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc020334e:	00002517          	auipc	a0,0x2
ffffffffc0203352:	2ea50513          	addi	a0,a0,746 # ffffffffc0205638 <default_pmm_manager+0x70>
ffffffffc0203356:	d8bfc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
}
ffffffffc020335a:	70a2                	ld	ra,40(sp)
ffffffffc020335c:	7402                	ld	s0,32(sp)
ffffffffc020335e:	64e2                	ld	s1,24(sp)
ffffffffc0203360:	6942                	ld	s2,16(sp)
ffffffffc0203362:	69a2                	ld	s3,8(sp)
ffffffffc0203364:	4501                	li	a0,0
ffffffffc0203366:	6145                	addi	sp,sp,48
ffffffffc0203368:	8082                	ret

ffffffffc020336a <proc_run>:
{
ffffffffc020336a:	7179                	addi	sp,sp,-48
ffffffffc020336c:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc020336e:	0000a497          	auipc	s1,0xa
ffffffffc0203372:	16248493          	addi	s1,s1,354 # ffffffffc020d4d0 <current>
ffffffffc0203376:	6098                	ld	a4,0(s1)
{
ffffffffc0203378:	f406                	sd	ra,40(sp)
ffffffffc020337a:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc020337c:	02a70863          	beq	a4,a0,ffffffffc02033ac <proc_run+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203380:	100027f3          	csrr	a5,sstatus
ffffffffc0203384:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203386:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203388:	ef8d                	bnez	a5,ffffffffc02033c2 <proc_run+0x58>
        lsatp(proc->pgdir);
ffffffffc020338a:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc020338c:	800006b7          	lui	a3,0x80000
        current = proc;
ffffffffc0203390:	e088                	sd	a0,0(s1)
ffffffffc0203392:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0203396:	8fd5                	or	a5,a5,a3
ffffffffc0203398:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(proc->context));
ffffffffc020339c:	03050593          	addi	a1,a0,48
ffffffffc02033a0:	03070513          	addi	a0,a4,48
ffffffffc02033a4:	e6bff0ef          	jal	ra,ffffffffc020320e <switch_to>
    if (flag) {
ffffffffc02033a8:	00091763          	bnez	s2,ffffffffc02033b6 <proc_run+0x4c>
}
ffffffffc02033ac:	70a2                	ld	ra,40(sp)
ffffffffc02033ae:	7482                	ld	s1,32(sp)
ffffffffc02033b0:	6962                	ld	s2,24(sp)
ffffffffc02033b2:	6145                	addi	sp,sp,48
ffffffffc02033b4:	8082                	ret
ffffffffc02033b6:	70a2                	ld	ra,40(sp)
ffffffffc02033b8:	7482                	ld	s1,32(sp)
ffffffffc02033ba:	6962                	ld	s2,24(sp)
ffffffffc02033bc:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02033be:	d72fd06f          	j	ffffffffc0200930 <intr_enable>
ffffffffc02033c2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02033c4:	d72fd0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        struct proc_struct *prev = current;
ffffffffc02033c8:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc02033ca:	6522                	ld	a0,8(sp)
ffffffffc02033cc:	4905                	li	s2,1
ffffffffc02033ce:	bf75                	j	ffffffffc020338a <proc_run+0x20>

ffffffffc02033d0 <do_fork>:
{
ffffffffc02033d0:	7179                	addi	sp,sp,-48
ffffffffc02033d2:	e84a                	sd	s2,16(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02033d4:	0000a917          	auipc	s2,0xa
ffffffffc02033d8:	11490913          	addi	s2,s2,276 # ffffffffc020d4e8 <nr_process>
ffffffffc02033dc:	00092703          	lw	a4,0(s2)
{
ffffffffc02033e0:	f406                	sd	ra,40(sp)
ffffffffc02033e2:	f022                	sd	s0,32(sp)
ffffffffc02033e4:	ec26                	sd	s1,24(sp)
ffffffffc02033e6:	e44e                	sd	s3,8(sp)
ffffffffc02033e8:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02033ea:	6785                	lui	a5,0x1
ffffffffc02033ec:	1ef75663          	bge	a4,a5,ffffffffc02035d8 <do_fork+0x208>
ffffffffc02033f0:	84aa                	mv	s1,a0
ffffffffc02033f2:	89ae                	mv	s3,a1
ffffffffc02033f4:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc02033f6:	e83ff0ef          	jal	ra,ffffffffc0203278 <alloc_proc>
ffffffffc02033fa:	8a2a                	mv	s4,a0
ffffffffc02033fc:	1e050363          	beqz	a0,ffffffffc02035e2 <do_fork+0x212>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203400:	4509                	li	a0,2
ffffffffc0203402:	a11fd0ef          	jal	ra,ffffffffc0200e12 <alloc_pages>
    if (page != NULL)
ffffffffc0203406:	1c050463          	beqz	a0,ffffffffc02035ce <do_fork+0x1fe>
    return page - pages + nbase;
ffffffffc020340a:	0000a697          	auipc	a3,0xa
ffffffffc020340e:	0a66b683          	ld	a3,166(a3) # ffffffffc020d4b0 <pages>
ffffffffc0203412:	40d506b3          	sub	a3,a0,a3
ffffffffc0203416:	00002797          	auipc	a5,0x2
ffffffffc020341a:	5e27b783          	ld	a5,1506(a5) # ffffffffc02059f8 <nbase>
ffffffffc020341e:	8699                	srai	a3,a3,0x6
ffffffffc0203420:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203422:	00c69793          	slli	a5,a3,0xc
ffffffffc0203426:	83b1                	srli	a5,a5,0xc
ffffffffc0203428:	0000a717          	auipc	a4,0xa
ffffffffc020342c:	08073703          	ld	a4,128(a4) # ffffffffc020d4a8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0203430:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203432:	1ce7fa63          	bgeu	a5,a4,ffffffffc0203606 <do_fork+0x236>
    assert(current->mm == NULL);
ffffffffc0203436:	0000a317          	auipc	t1,0xa
ffffffffc020343a:	09a33303          	ld	t1,154(t1) # ffffffffc020d4d0 <current>
ffffffffc020343e:	02833783          	ld	a5,40(t1)
ffffffffc0203442:	0000a717          	auipc	a4,0xa
ffffffffc0203446:	07e73703          	ld	a4,126(a4) # ffffffffc020d4c0 <va_pa_offset>
ffffffffc020344a:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020344c:	00da3823          	sd	a3,16(s4)
    assert(current->mm == NULL);
ffffffffc0203450:	18079b63          	bnez	a5,ffffffffc02035e6 <do_fork+0x216>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0203454:	6789                	lui	a5,0x2
ffffffffc0203456:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc020345a:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020345c:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc020345e:	0ada3023          	sd	a3,160(s4)
    *(proc->tf) = *tf;
ffffffffc0203462:	87b6                	mv	a5,a3
ffffffffc0203464:	12040893          	addi	a7,s0,288
ffffffffc0203468:	00063803          	ld	a6,0(a2)
ffffffffc020346c:	6608                	ld	a0,8(a2)
ffffffffc020346e:	6a0c                	ld	a1,16(a2)
ffffffffc0203470:	6e18                	ld	a4,24(a2)
ffffffffc0203472:	0107b023          	sd	a6,0(a5)
ffffffffc0203476:	e788                	sd	a0,8(a5)
ffffffffc0203478:	eb8c                	sd	a1,16(a5)
ffffffffc020347a:	ef98                	sd	a4,24(a5)
ffffffffc020347c:	02060613          	addi	a2,a2,32
ffffffffc0203480:	02078793          	addi	a5,a5,32
ffffffffc0203484:	ff1612e3          	bne	a2,a7,ffffffffc0203468 <do_fork+0x98>
    proc->tf->gpr.a0 = 0;
ffffffffc0203488:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020348c:	12098563          	beqz	s3,ffffffffc02035b6 <do_fork+0x1e6>
    if (++last_pid >= MAX_PID)
ffffffffc0203490:	00006817          	auipc	a6,0x6
ffffffffc0203494:	b9880813          	addi	a6,a6,-1128 # ffffffffc0209028 <last_pid.1>
ffffffffc0203498:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020349c:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02034a0:	00000717          	auipc	a4,0x0
ffffffffc02034a4:	e4a70713          	addi	a4,a4,-438 # ffffffffc02032ea <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc02034a8:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02034ac:	02ea3823          	sd	a4,48(s4)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02034b0:	02da3c23          	sd	a3,56(s4)
    if (++last_pid >= MAX_PID)
ffffffffc02034b4:	00a82023          	sw	a0,0(a6)
ffffffffc02034b8:	6789                	lui	a5,0x2
ffffffffc02034ba:	08f55763          	bge	a0,a5,ffffffffc0203548 <do_fork+0x178>
    if (last_pid >= next_safe)
ffffffffc02034be:	00006e17          	auipc	t3,0x6
ffffffffc02034c2:	b6ee0e13          	addi	t3,t3,-1170 # ffffffffc020902c <next_safe.0>
ffffffffc02034c6:	000e2783          	lw	a5,0(t3)
ffffffffc02034ca:	0000a417          	auipc	s0,0xa
ffffffffc02034ce:	f8e40413          	addi	s0,s0,-114 # ffffffffc020d458 <proc_list>
ffffffffc02034d2:	08f55363          	bge	a0,a5,ffffffffc0203558 <do_fork+0x188>
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02034d6:	45a9                	li	a1,10
    proc->pid = get_pid();
ffffffffc02034d8:	00aa2223          	sw	a0,4(s4)
    proc->parent = current;
ffffffffc02034dc:	026a3023          	sd	t1,32(s4)
    proc->runs = 0;
ffffffffc02034e0:	000a2423          	sw	zero,8(s4)
    proc->flags = clone_flags;
ffffffffc02034e4:	0a9a2823          	sw	s1,176(s4)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02034e8:	2501                	sext.w	a0,a0
ffffffffc02034ea:	1af000ef          	jal	ra,ffffffffc0203e98 <hash32>
ffffffffc02034ee:	02051793          	slli	a5,a0,0x20
ffffffffc02034f2:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02034f6:	00006797          	auipc	a5,0x6
ffffffffc02034fa:	f5278793          	addi	a5,a5,-174 # ffffffffc0209448 <hash_list>
ffffffffc02034fe:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0203500:	6518                	ld	a4,8(a0)
ffffffffc0203502:	0d8a0793          	addi	a5,s4,216
ffffffffc0203506:	6414                	ld	a3,8(s0)
    prev->next = next->prev = elm;
ffffffffc0203508:	e31c                	sd	a5,0(a4)
ffffffffc020350a:	e51c                	sd	a5,8(a0)
    nr_process++;
ffffffffc020350c:	00092783          	lw	a5,0(s2)
    elm->next = next;
ffffffffc0203510:	0eea3023          	sd	a4,224(s4)
    elm->prev = prev;
ffffffffc0203514:	0caa3c23          	sd	a0,216(s4)
    list_add(&proc_list, &proc->list_link);
ffffffffc0203518:	0c8a0713          	addi	a4,s4,200
    prev->next = next->prev = elm;
ffffffffc020351c:	e298                	sd	a4,0(a3)
    nr_process++;
ffffffffc020351e:	2785                	addiw	a5,a5,1
    wakeup_proc(proc);
ffffffffc0203520:	8552                	mv	a0,s4
    elm->next = next;
ffffffffc0203522:	0cda3823          	sd	a3,208(s4)
    elm->prev = prev;
ffffffffc0203526:	0c8a3423          	sd	s0,200(s4)
    prev->next = next->prev = elm;
ffffffffc020352a:	e418                	sd	a4,8(s0)
    nr_process++;
ffffffffc020352c:	00f92023          	sw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc0203530:	3c4000ef          	jal	ra,ffffffffc02038f4 <wakeup_proc>
    ret = proc->pid;
ffffffffc0203534:	004a2503          	lw	a0,4(s4)
}
ffffffffc0203538:	70a2                	ld	ra,40(sp)
ffffffffc020353a:	7402                	ld	s0,32(sp)
ffffffffc020353c:	64e2                	ld	s1,24(sp)
ffffffffc020353e:	6942                	ld	s2,16(sp)
ffffffffc0203540:	69a2                	ld	s3,8(sp)
ffffffffc0203542:	6a02                	ld	s4,0(sp)
ffffffffc0203544:	6145                	addi	sp,sp,48
ffffffffc0203546:	8082                	ret
        last_pid = 1;
ffffffffc0203548:	4785                	li	a5,1
ffffffffc020354a:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020354e:	4505                	li	a0,1
ffffffffc0203550:	00006e17          	auipc	t3,0x6
ffffffffc0203554:	adce0e13          	addi	t3,t3,-1316 # ffffffffc020902c <next_safe.0>
    return listelm->next;
ffffffffc0203558:	0000a417          	auipc	s0,0xa
ffffffffc020355c:	f0040413          	addi	s0,s0,-256 # ffffffffc020d458 <proc_list>
ffffffffc0203560:	00843e83          	ld	t4,8(s0)
        next_safe = MAX_PID;
ffffffffc0203564:	6789                	lui	a5,0x2
ffffffffc0203566:	00fe2023          	sw	a5,0(t3)
ffffffffc020356a:	86aa                	mv	a3,a0
ffffffffc020356c:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020356e:	6f09                	lui	t5,0x2
ffffffffc0203570:	048e8a63          	beq	t4,s0,ffffffffc02035c4 <do_fork+0x1f4>
ffffffffc0203574:	88ae                	mv	a7,a1
ffffffffc0203576:	87f6                	mv	a5,t4
ffffffffc0203578:	6609                	lui	a2,0x2
ffffffffc020357a:	a811                	j	ffffffffc020358e <do_fork+0x1be>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020357c:	00e6d663          	bge	a3,a4,ffffffffc0203588 <do_fork+0x1b8>
ffffffffc0203580:	00c75463          	bge	a4,a2,ffffffffc0203588 <do_fork+0x1b8>
ffffffffc0203584:	863a                	mv	a2,a4
ffffffffc0203586:	4885                	li	a7,1
ffffffffc0203588:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020358a:	00878d63          	beq	a5,s0,ffffffffc02035a4 <do_fork+0x1d4>
            if (proc->pid == last_pid)
ffffffffc020358e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0203592:	fed715e3          	bne	a4,a3,ffffffffc020357c <do_fork+0x1ac>
                if (++last_pid >= next_safe)
ffffffffc0203596:	2685                	addiw	a3,a3,1
ffffffffc0203598:	02c6d163          	bge	a3,a2,ffffffffc02035ba <do_fork+0x1ea>
ffffffffc020359c:	679c                	ld	a5,8(a5)
ffffffffc020359e:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02035a0:	fe8797e3          	bne	a5,s0,ffffffffc020358e <do_fork+0x1be>
ffffffffc02035a4:	c581                	beqz	a1,ffffffffc02035ac <do_fork+0x1dc>
ffffffffc02035a6:	00d82023          	sw	a3,0(a6)
ffffffffc02035aa:	8536                	mv	a0,a3
ffffffffc02035ac:	f20885e3          	beqz	a7,ffffffffc02034d6 <do_fork+0x106>
ffffffffc02035b0:	00ce2023          	sw	a2,0(t3)
ffffffffc02035b4:	b70d                	j	ffffffffc02034d6 <do_fork+0x106>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02035b6:	89b6                	mv	s3,a3
ffffffffc02035b8:	bde1                	j	ffffffffc0203490 <do_fork+0xc0>
                    if (last_pid >= MAX_PID)
ffffffffc02035ba:	01e6c363          	blt	a3,t5,ffffffffc02035c0 <do_fork+0x1f0>
                        last_pid = 1;
ffffffffc02035be:	4685                	li	a3,1
                    goto repeat;
ffffffffc02035c0:	4585                	li	a1,1
ffffffffc02035c2:	b77d                	j	ffffffffc0203570 <do_fork+0x1a0>
ffffffffc02035c4:	cd81                	beqz	a1,ffffffffc02035dc <do_fork+0x20c>
ffffffffc02035c6:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02035ca:	8536                	mv	a0,a3
ffffffffc02035cc:	b729                	j	ffffffffc02034d6 <do_fork+0x106>
    kfree(proc);
ffffffffc02035ce:	8552                	mv	a0,s4
ffffffffc02035d0:	88eff0ef          	jal	ra,ffffffffc020265e <kfree>
    ret = -E_NO_MEM;
ffffffffc02035d4:	5571                	li	a0,-4
    goto fork_out;
ffffffffc02035d6:	b78d                	j	ffffffffc0203538 <do_fork+0x168>
    int ret = -E_NO_FREE_PROC;
ffffffffc02035d8:	556d                	li	a0,-5
ffffffffc02035da:	bfb9                	j	ffffffffc0203538 <do_fork+0x168>
    return last_pid;
ffffffffc02035dc:	00082503          	lw	a0,0(a6)
ffffffffc02035e0:	bddd                	j	ffffffffc02034d6 <do_fork+0x106>
    ret = -E_NO_MEM;
ffffffffc02035e2:	5571                	li	a0,-4
    return ret;
ffffffffc02035e4:	bf91                	j	ffffffffc0203538 <do_fork+0x168>
    assert(current->mm == NULL);
ffffffffc02035e6:	00002697          	auipc	a3,0x2
ffffffffc02035ea:	07268693          	addi	a3,a3,114 # ffffffffc0205658 <default_pmm_manager+0x90>
ffffffffc02035ee:	00001617          	auipc	a2,0x1
ffffffffc02035f2:	4ba60613          	addi	a2,a2,1210 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02035f6:	12600593          	li	a1,294
ffffffffc02035fa:	00002517          	auipc	a0,0x2
ffffffffc02035fe:	07650513          	addi	a0,a0,118 # ffffffffc0205670 <default_pmm_manager+0xa8>
ffffffffc0203602:	bddfc0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc0203606:	00001617          	auipc	a2,0x1
ffffffffc020360a:	37260613          	addi	a2,a2,882 # ffffffffc0204978 <commands+0x840>
ffffffffc020360e:	07100593          	li	a1,113
ffffffffc0203612:	00001517          	auipc	a0,0x1
ffffffffc0203616:	32e50513          	addi	a0,a0,814 # ffffffffc0204940 <commands+0x808>
ffffffffc020361a:	bc5fc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020361e <kernel_thread>:
{
ffffffffc020361e:	7129                	addi	sp,sp,-320
ffffffffc0203620:	fa22                	sd	s0,304(sp)
ffffffffc0203622:	f626                	sd	s1,296(sp)
ffffffffc0203624:	f24a                	sd	s2,288(sp)
ffffffffc0203626:	84ae                	mv	s1,a1
ffffffffc0203628:	892a                	mv	s2,a0
ffffffffc020362a:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020362c:	4581                	li	a1,0
ffffffffc020362e:	12000613          	li	a2,288
ffffffffc0203632:	850a                	mv	a0,sp
{
ffffffffc0203634:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203636:	426000ef          	jal	ra,ffffffffc0203a5c <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020363a:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020363c:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020363e:	100027f3          	csrr	a5,sstatus
ffffffffc0203642:	edd7f793          	andi	a5,a5,-291
ffffffffc0203646:	1207e793          	ori	a5,a5,288
ffffffffc020364a:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020364c:	860a                	mv	a2,sp
ffffffffc020364e:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203652:	00000797          	auipc	a5,0x0
ffffffffc0203656:	bb478793          	addi	a5,a5,-1100 # ffffffffc0203206 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020365a:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020365c:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020365e:	d73ff0ef          	jal	ra,ffffffffc02033d0 <do_fork>
}
ffffffffc0203662:	70f2                	ld	ra,312(sp)
ffffffffc0203664:	7452                	ld	s0,304(sp)
ffffffffc0203666:	74b2                	ld	s1,296(sp)
ffffffffc0203668:	7912                	ld	s2,288(sp)
ffffffffc020366a:	6131                	addi	sp,sp,320
ffffffffc020366c:	8082                	ret

ffffffffc020366e <do_exit>:
{
ffffffffc020366e:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0203670:	00002617          	auipc	a2,0x2
ffffffffc0203674:	01860613          	addi	a2,a2,24 # ffffffffc0205688 <default_pmm_manager+0xc0>
ffffffffc0203678:	19400593          	li	a1,404
ffffffffc020367c:	00002517          	auipc	a0,0x2
ffffffffc0203680:	ff450513          	addi	a0,a0,-12 # ffffffffc0205670 <default_pmm_manager+0xa8>
{
ffffffffc0203684:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc0203686:	b59fc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020368a <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc020368a:	7179                	addi	sp,sp,-48
ffffffffc020368c:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc020368e:	0000a797          	auipc	a5,0xa
ffffffffc0203692:	dca78793          	addi	a5,a5,-566 # ffffffffc020d458 <proc_list>
ffffffffc0203696:	f406                	sd	ra,40(sp)
ffffffffc0203698:	f022                	sd	s0,32(sp)
ffffffffc020369a:	e84a                	sd	s2,16(sp)
ffffffffc020369c:	e44e                	sd	s3,8(sp)
ffffffffc020369e:	00006497          	auipc	s1,0x6
ffffffffc02036a2:	daa48493          	addi	s1,s1,-598 # ffffffffc0209448 <hash_list>
ffffffffc02036a6:	e79c                	sd	a5,8(a5)
ffffffffc02036a8:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02036aa:	0000a717          	auipc	a4,0xa
ffffffffc02036ae:	d9e70713          	addi	a4,a4,-610 # ffffffffc020d448 <name.2>
ffffffffc02036b2:	87a6                	mv	a5,s1
ffffffffc02036b4:	e79c                	sd	a5,8(a5)
ffffffffc02036b6:	e39c                	sd	a5,0(a5)
ffffffffc02036b8:	07c1                	addi	a5,a5,16
ffffffffc02036ba:	fef71de3          	bne	a4,a5,ffffffffc02036b4 <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02036be:	bbbff0ef          	jal	ra,ffffffffc0203278 <alloc_proc>
ffffffffc02036c2:	0000a917          	auipc	s2,0xa
ffffffffc02036c6:	e1690913          	addi	s2,s2,-490 # ffffffffc020d4d8 <idleproc>
ffffffffc02036ca:	00a93023          	sd	a0,0(s2)
ffffffffc02036ce:	18050d63          	beqz	a0,ffffffffc0203868 <proc_init+0x1de>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036d2:	07000513          	li	a0,112
ffffffffc02036d6:	ed9fe0ef          	jal	ra,ffffffffc02025ae <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036da:	07000613          	li	a2,112
ffffffffc02036de:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036e0:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036e2:	37a000ef          	jal	ra,ffffffffc0203a5c <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc02036e6:	00093503          	ld	a0,0(s2)
ffffffffc02036ea:	85a2                	mv	a1,s0
ffffffffc02036ec:	07000613          	li	a2,112
ffffffffc02036f0:	03050513          	addi	a0,a0,48
ffffffffc02036f4:	392000ef          	jal	ra,ffffffffc0203a86 <memcmp>
ffffffffc02036f8:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036fa:	453d                	li	a0,15
ffffffffc02036fc:	eb3fe0ef          	jal	ra,ffffffffc02025ae <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203700:	463d                	li	a2,15
ffffffffc0203702:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203704:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203706:	356000ef          	jal	ra,ffffffffc0203a5c <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc020370a:	00093503          	ld	a0,0(s2)
ffffffffc020370e:	463d                	li	a2,15
ffffffffc0203710:	85a2                	mv	a1,s0
ffffffffc0203712:	0b450513          	addi	a0,a0,180
ffffffffc0203716:	370000ef          	jal	ra,ffffffffc0203a86 <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc020371a:	00093783          	ld	a5,0(s2)
ffffffffc020371e:	0000a717          	auipc	a4,0xa
ffffffffc0203722:	d7a73703          	ld	a4,-646(a4) # ffffffffc020d498 <boot_pgdir_pa>
ffffffffc0203726:	77d4                	ld	a3,168(a5)
ffffffffc0203728:	0ee68463          	beq	a3,a4,ffffffffc0203810 <proc_init+0x186>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc020372c:	4709                	li	a4,2
ffffffffc020372e:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203730:	00003717          	auipc	a4,0x3
ffffffffc0203734:	8d070713          	addi	a4,a4,-1840 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203738:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020373c:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc020373e:	4705                	li	a4,1
ffffffffc0203740:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203742:	4641                	li	a2,16
ffffffffc0203744:	4581                	li	a1,0
ffffffffc0203746:	8522                	mv	a0,s0
ffffffffc0203748:	314000ef          	jal	ra,ffffffffc0203a5c <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020374c:	463d                	li	a2,15
ffffffffc020374e:	00002597          	auipc	a1,0x2
ffffffffc0203752:	f8258593          	addi	a1,a1,-126 # ffffffffc02056d0 <default_pmm_manager+0x108>
ffffffffc0203756:	8522                	mv	a0,s0
ffffffffc0203758:	316000ef          	jal	ra,ffffffffc0203a6e <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc020375c:	0000a717          	auipc	a4,0xa
ffffffffc0203760:	d8c70713          	addi	a4,a4,-628 # ffffffffc020d4e8 <nr_process>
ffffffffc0203764:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0203766:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020376a:	4601                	li	a2,0
    nr_process++;
ffffffffc020376c:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020376e:	00002597          	auipc	a1,0x2
ffffffffc0203772:	f6a58593          	addi	a1,a1,-150 # ffffffffc02056d8 <default_pmm_manager+0x110>
ffffffffc0203776:	00000517          	auipc	a0,0x0
ffffffffc020377a:	b8250513          	addi	a0,a0,-1150 # ffffffffc02032f8 <init_main>
    nr_process++;
ffffffffc020377e:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0203780:	0000a797          	auipc	a5,0xa
ffffffffc0203784:	d4d7b823          	sd	a3,-688(a5) # ffffffffc020d4d0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203788:	e97ff0ef          	jal	ra,ffffffffc020361e <kernel_thread>
ffffffffc020378c:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc020378e:	0ea05963          	blez	a0,ffffffffc0203880 <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID)
ffffffffc0203792:	6789                	lui	a5,0x2
ffffffffc0203794:	fff5071b          	addiw	a4,a0,-1
ffffffffc0203798:	17f9                	addi	a5,a5,-2
ffffffffc020379a:	2501                	sext.w	a0,a0
ffffffffc020379c:	02e7e363          	bltu	a5,a4,ffffffffc02037c2 <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02037a0:	45a9                	li	a1,10
ffffffffc02037a2:	6f6000ef          	jal	ra,ffffffffc0203e98 <hash32>
ffffffffc02037a6:	02051793          	slli	a5,a0,0x20
ffffffffc02037aa:	01c7d693          	srli	a3,a5,0x1c
ffffffffc02037ae:	96a6                	add	a3,a3,s1
ffffffffc02037b0:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02037b2:	a029                	j	ffffffffc02037bc <proc_init+0x132>
            if (proc->pid == pid)
ffffffffc02037b4:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc02037b8:	0a870563          	beq	a4,s0,ffffffffc0203862 <proc_init+0x1d8>
    return listelm->next;
ffffffffc02037bc:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02037be:	fef69be3          	bne	a3,a5,ffffffffc02037b4 <proc_init+0x12a>
    return NULL;
ffffffffc02037c2:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037c4:	0b478493          	addi	s1,a5,180
ffffffffc02037c8:	4641                	li	a2,16
ffffffffc02037ca:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02037cc:	0000a417          	auipc	s0,0xa
ffffffffc02037d0:	d1440413          	addi	s0,s0,-748 # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037d4:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc02037d6:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037d8:	284000ef          	jal	ra,ffffffffc0203a5c <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02037dc:	463d                	li	a2,15
ffffffffc02037de:	00002597          	auipc	a1,0x2
ffffffffc02037e2:	f2a58593          	addi	a1,a1,-214 # ffffffffc0205708 <default_pmm_manager+0x140>
ffffffffc02037e6:	8526                	mv	a0,s1
ffffffffc02037e8:	286000ef          	jal	ra,ffffffffc0203a6e <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02037ec:	00093783          	ld	a5,0(s2)
ffffffffc02037f0:	c7e1                	beqz	a5,ffffffffc02038b8 <proc_init+0x22e>
ffffffffc02037f2:	43dc                	lw	a5,4(a5)
ffffffffc02037f4:	e3f1                	bnez	a5,ffffffffc02038b8 <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02037f6:	601c                	ld	a5,0(s0)
ffffffffc02037f8:	c3c5                	beqz	a5,ffffffffc0203898 <proc_init+0x20e>
ffffffffc02037fa:	43d8                	lw	a4,4(a5)
ffffffffc02037fc:	4785                	li	a5,1
ffffffffc02037fe:	08f71d63          	bne	a4,a5,ffffffffc0203898 <proc_init+0x20e>
}
ffffffffc0203802:	70a2                	ld	ra,40(sp)
ffffffffc0203804:	7402                	ld	s0,32(sp)
ffffffffc0203806:	64e2                	ld	s1,24(sp)
ffffffffc0203808:	6942                	ld	s2,16(sp)
ffffffffc020380a:	69a2                	ld	s3,8(sp)
ffffffffc020380c:	6145                	addi	sp,sp,48
ffffffffc020380e:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203810:	73d8                	ld	a4,160(a5)
ffffffffc0203812:	ff09                	bnez	a4,ffffffffc020372c <proc_init+0xa2>
ffffffffc0203814:	f0099ce3          	bnez	s3,ffffffffc020372c <proc_init+0xa2>
ffffffffc0203818:	6394                	ld	a3,0(a5)
ffffffffc020381a:	577d                	li	a4,-1
ffffffffc020381c:	1702                	slli	a4,a4,0x20
ffffffffc020381e:	f0e697e3          	bne	a3,a4,ffffffffc020372c <proc_init+0xa2>
ffffffffc0203822:	4798                	lw	a4,8(a5)
ffffffffc0203824:	f00714e3          	bnez	a4,ffffffffc020372c <proc_init+0xa2>
ffffffffc0203828:	6b98                	ld	a4,16(a5)
ffffffffc020382a:	f00711e3          	bnez	a4,ffffffffc020372c <proc_init+0xa2>
ffffffffc020382e:	4f98                	lw	a4,24(a5)
ffffffffc0203830:	2701                	sext.w	a4,a4
ffffffffc0203832:	ee071de3          	bnez	a4,ffffffffc020372c <proc_init+0xa2>
ffffffffc0203836:	7398                	ld	a4,32(a5)
ffffffffc0203838:	ee071ae3          	bnez	a4,ffffffffc020372c <proc_init+0xa2>
ffffffffc020383c:	7798                	ld	a4,40(a5)
ffffffffc020383e:	ee0717e3          	bnez	a4,ffffffffc020372c <proc_init+0xa2>
ffffffffc0203842:	0b07a703          	lw	a4,176(a5)
ffffffffc0203846:	8d59                	or	a0,a0,a4
ffffffffc0203848:	0005071b          	sext.w	a4,a0
ffffffffc020384c:	ee0710e3          	bnez	a4,ffffffffc020372c <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0203850:	00002517          	auipc	a0,0x2
ffffffffc0203854:	e6850513          	addi	a0,a0,-408 # ffffffffc02056b8 <default_pmm_manager+0xf0>
ffffffffc0203858:	889fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    idleproc->pid = 0;
ffffffffc020385c:	00093783          	ld	a5,0(s2)
ffffffffc0203860:	b5f1                	j	ffffffffc020372c <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0203862:	f2878793          	addi	a5,a5,-216
ffffffffc0203866:	bfb9                	j	ffffffffc02037c4 <proc_init+0x13a>
        panic("cannot alloc idleproc.\n");
ffffffffc0203868:	00002617          	auipc	a2,0x2
ffffffffc020386c:	e3860613          	addi	a2,a2,-456 # ffffffffc02056a0 <default_pmm_manager+0xd8>
ffffffffc0203870:	1af00593          	li	a1,431
ffffffffc0203874:	00002517          	auipc	a0,0x2
ffffffffc0203878:	dfc50513          	addi	a0,a0,-516 # ffffffffc0205670 <default_pmm_manager+0xa8>
ffffffffc020387c:	963fc0ef          	jal	ra,ffffffffc02001de <__panic>
        panic("create init_main failed.\n");
ffffffffc0203880:	00002617          	auipc	a2,0x2
ffffffffc0203884:	e6860613          	addi	a2,a2,-408 # ffffffffc02056e8 <default_pmm_manager+0x120>
ffffffffc0203888:	1cc00593          	li	a1,460
ffffffffc020388c:	00002517          	auipc	a0,0x2
ffffffffc0203890:	de450513          	addi	a0,a0,-540 # ffffffffc0205670 <default_pmm_manager+0xa8>
ffffffffc0203894:	94bfc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203898:	00002697          	auipc	a3,0x2
ffffffffc020389c:	ea068693          	addi	a3,a3,-352 # ffffffffc0205738 <default_pmm_manager+0x170>
ffffffffc02038a0:	00001617          	auipc	a2,0x1
ffffffffc02038a4:	20860613          	addi	a2,a2,520 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02038a8:	1d300593          	li	a1,467
ffffffffc02038ac:	00002517          	auipc	a0,0x2
ffffffffc02038b0:	dc450513          	addi	a0,a0,-572 # ffffffffc0205670 <default_pmm_manager+0xa8>
ffffffffc02038b4:	92bfc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02038b8:	00002697          	auipc	a3,0x2
ffffffffc02038bc:	e5868693          	addi	a3,a3,-424 # ffffffffc0205710 <default_pmm_manager+0x148>
ffffffffc02038c0:	00001617          	auipc	a2,0x1
ffffffffc02038c4:	1e860613          	addi	a2,a2,488 # ffffffffc0204aa8 <commands+0x970>
ffffffffc02038c8:	1d200593          	li	a1,466
ffffffffc02038cc:	00002517          	auipc	a0,0x2
ffffffffc02038d0:	da450513          	addi	a0,a0,-604 # ffffffffc0205670 <default_pmm_manager+0xa8>
ffffffffc02038d4:	90bfc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02038d8 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02038d8:	1141                	addi	sp,sp,-16
ffffffffc02038da:	e022                	sd	s0,0(sp)
ffffffffc02038dc:	e406                	sd	ra,8(sp)
ffffffffc02038de:	0000a417          	auipc	s0,0xa
ffffffffc02038e2:	bf240413          	addi	s0,s0,-1038 # ffffffffc020d4d0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02038e6:	6018                	ld	a4,0(s0)
ffffffffc02038e8:	4f1c                	lw	a5,24(a4)
ffffffffc02038ea:	2781                	sext.w	a5,a5
ffffffffc02038ec:	dff5                	beqz	a5,ffffffffc02038e8 <cpu_idle+0x10>
        {
            schedule();
ffffffffc02038ee:	038000ef          	jal	ra,ffffffffc0203926 <schedule>
ffffffffc02038f2:	bfd5                	j	ffffffffc02038e6 <cpu_idle+0xe>

ffffffffc02038f4 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038f4:	411c                	lw	a5,0(a0)
ffffffffc02038f6:	4705                	li	a4,1
ffffffffc02038f8:	37f9                	addiw	a5,a5,-2
ffffffffc02038fa:	00f77563          	bgeu	a4,a5,ffffffffc0203904 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc02038fe:	4789                	li	a5,2
ffffffffc0203900:	c11c                	sw	a5,0(a0)
ffffffffc0203902:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203904:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203906:	00002697          	auipc	a3,0x2
ffffffffc020390a:	e5a68693          	addi	a3,a3,-422 # ffffffffc0205760 <default_pmm_manager+0x198>
ffffffffc020390e:	00001617          	auipc	a2,0x1
ffffffffc0203912:	19a60613          	addi	a2,a2,410 # ffffffffc0204aa8 <commands+0x970>
ffffffffc0203916:	45a5                	li	a1,9
ffffffffc0203918:	00002517          	auipc	a0,0x2
ffffffffc020391c:	e8850513          	addi	a0,a0,-376 # ffffffffc02057a0 <default_pmm_manager+0x1d8>
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203920:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203922:	8bdfc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203926 <schedule>:
}

void
schedule(void) {
ffffffffc0203926:	1141                	addi	sp,sp,-16
ffffffffc0203928:	e406                	sd	ra,8(sp)
ffffffffc020392a:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020392c:	100027f3          	csrr	a5,sstatus
ffffffffc0203930:	8b89                	andi	a5,a5,2
ffffffffc0203932:	4401                	li	s0,0
ffffffffc0203934:	efbd                	bnez	a5,ffffffffc02039b2 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0203936:	0000a897          	auipc	a7,0xa
ffffffffc020393a:	b9a8b883          	ld	a7,-1126(a7) # ffffffffc020d4d0 <current>
ffffffffc020393e:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203942:	0000a517          	auipc	a0,0xa
ffffffffc0203946:	b9653503          	ld	a0,-1130(a0) # ffffffffc020d4d8 <idleproc>
ffffffffc020394a:	04a88e63          	beq	a7,a0,ffffffffc02039a6 <schedule+0x80>
ffffffffc020394e:	0c888693          	addi	a3,a7,200
ffffffffc0203952:	0000a617          	auipc	a2,0xa
ffffffffc0203956:	b0660613          	addi	a2,a2,-1274 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc020395a:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020395c:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc020395e:	4809                	li	a6,2
ffffffffc0203960:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203962:	00c78863          	beq	a5,a2,ffffffffc0203972 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203966:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020396a:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc020396e:	03070163          	beq	a4,a6,ffffffffc0203990 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203972:	fef697e3          	bne	a3,a5,ffffffffc0203960 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203976:	ed89                	bnez	a1,ffffffffc0203990 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0203978:	451c                	lw	a5,8(a0)
ffffffffc020397a:	2785                	addiw	a5,a5,1
ffffffffc020397c:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc020397e:	00a88463          	beq	a7,a0,ffffffffc0203986 <schedule+0x60>
            proc_run(next);
ffffffffc0203982:	9e9ff0ef          	jal	ra,ffffffffc020336a <proc_run>
    if (flag) {
ffffffffc0203986:	e819                	bnez	s0,ffffffffc020399c <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0203988:	60a2                	ld	ra,8(sp)
ffffffffc020398a:	6402                	ld	s0,0(sp)
ffffffffc020398c:	0141                	addi	sp,sp,16
ffffffffc020398e:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203990:	4198                	lw	a4,0(a1)
ffffffffc0203992:	4789                	li	a5,2
ffffffffc0203994:	fef712e3          	bne	a4,a5,ffffffffc0203978 <schedule+0x52>
ffffffffc0203998:	852e                	mv	a0,a1
ffffffffc020399a:	bff9                	j	ffffffffc0203978 <schedule+0x52>
}
ffffffffc020399c:	6402                	ld	s0,0(sp)
ffffffffc020399e:	60a2                	ld	ra,8(sp)
ffffffffc02039a0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02039a2:	f8ffc06f          	j	ffffffffc0200930 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02039a6:	0000a617          	auipc	a2,0xa
ffffffffc02039aa:	ab260613          	addi	a2,a2,-1358 # ffffffffc020d458 <proc_list>
ffffffffc02039ae:	86b2                	mv	a3,a2
ffffffffc02039b0:	b76d                	j	ffffffffc020395a <schedule+0x34>
        intr_disable();
ffffffffc02039b2:	f85fc0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc02039b6:	4405                	li	s0,1
ffffffffc02039b8:	bfbd                	j	ffffffffc0203936 <schedule+0x10>

ffffffffc02039ba <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02039ba:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02039be:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02039c0:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02039c2:	cb81                	beqz	a5,ffffffffc02039d2 <strlen+0x18>
        cnt ++;
ffffffffc02039c4:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02039c6:	00a707b3          	add	a5,a4,a0
ffffffffc02039ca:	0007c783          	lbu	a5,0(a5)
ffffffffc02039ce:	fbfd                	bnez	a5,ffffffffc02039c4 <strlen+0xa>
ffffffffc02039d0:	8082                	ret
    }
    return cnt;
}
ffffffffc02039d2:	8082                	ret

ffffffffc02039d4 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02039d4:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02039d6:	e589                	bnez	a1,ffffffffc02039e0 <strnlen+0xc>
ffffffffc02039d8:	a811                	j	ffffffffc02039ec <strnlen+0x18>
        cnt ++;
ffffffffc02039da:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02039dc:	00f58863          	beq	a1,a5,ffffffffc02039ec <strnlen+0x18>
ffffffffc02039e0:	00f50733          	add	a4,a0,a5
ffffffffc02039e4:	00074703          	lbu	a4,0(a4)
ffffffffc02039e8:	fb6d                	bnez	a4,ffffffffc02039da <strnlen+0x6>
ffffffffc02039ea:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02039ec:	852e                	mv	a0,a1
ffffffffc02039ee:	8082                	ret

ffffffffc02039f0 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02039f0:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02039f2:	0005c703          	lbu	a4,0(a1)
ffffffffc02039f6:	0785                	addi	a5,a5,1
ffffffffc02039f8:	0585                	addi	a1,a1,1
ffffffffc02039fa:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02039fe:	fb75                	bnez	a4,ffffffffc02039f2 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203a00:	8082                	ret

ffffffffc0203a02 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203a02:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203a06:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203a0a:	cb89                	beqz	a5,ffffffffc0203a1c <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203a0c:	0505                	addi	a0,a0,1
ffffffffc0203a0e:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203a10:	fee789e3          	beq	a5,a4,ffffffffc0203a02 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203a14:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203a18:	9d19                	subw	a0,a0,a4
ffffffffc0203a1a:	8082                	ret
ffffffffc0203a1c:	4501                	li	a0,0
ffffffffc0203a1e:	bfed                	j	ffffffffc0203a18 <strcmp+0x16>

ffffffffc0203a20 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203a20:	c20d                	beqz	a2,ffffffffc0203a42 <strncmp+0x22>
ffffffffc0203a22:	962e                	add	a2,a2,a1
ffffffffc0203a24:	a031                	j	ffffffffc0203a30 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203a26:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203a28:	00e79a63          	bne	a5,a4,ffffffffc0203a3c <strncmp+0x1c>
ffffffffc0203a2c:	00b60b63          	beq	a2,a1,ffffffffc0203a42 <strncmp+0x22>
ffffffffc0203a30:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203a34:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203a36:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203a3a:	f7f5                	bnez	a5,ffffffffc0203a26 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203a3c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203a40:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203a42:	4501                	li	a0,0
ffffffffc0203a44:	8082                	ret

ffffffffc0203a46 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203a46:	00054783          	lbu	a5,0(a0)
ffffffffc0203a4a:	c799                	beqz	a5,ffffffffc0203a58 <strchr+0x12>
        if (*s == c) {
ffffffffc0203a4c:	00f58763          	beq	a1,a5,ffffffffc0203a5a <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203a50:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203a54:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203a56:	fbfd                	bnez	a5,ffffffffc0203a4c <strchr+0x6>
    }
    return NULL;
ffffffffc0203a58:	4501                	li	a0,0
}
ffffffffc0203a5a:	8082                	ret

ffffffffc0203a5c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203a5c:	ca01                	beqz	a2,ffffffffc0203a6c <memset+0x10>
ffffffffc0203a5e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203a60:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203a62:	0785                	addi	a5,a5,1
ffffffffc0203a64:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203a68:	fec79de3          	bne	a5,a2,ffffffffc0203a62 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203a6c:	8082                	ret

ffffffffc0203a6e <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203a6e:	ca19                	beqz	a2,ffffffffc0203a84 <memcpy+0x16>
ffffffffc0203a70:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203a72:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203a74:	0005c703          	lbu	a4,0(a1)
ffffffffc0203a78:	0585                	addi	a1,a1,1
ffffffffc0203a7a:	0785                	addi	a5,a5,1
ffffffffc0203a7c:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203a80:	fec59ae3          	bne	a1,a2,ffffffffc0203a74 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203a84:	8082                	ret

ffffffffc0203a86 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203a86:	c205                	beqz	a2,ffffffffc0203aa6 <memcmp+0x20>
ffffffffc0203a88:	962e                	add	a2,a2,a1
ffffffffc0203a8a:	a019                	j	ffffffffc0203a90 <memcmp+0xa>
ffffffffc0203a8c:	00c58d63          	beq	a1,a2,ffffffffc0203aa6 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203a90:	00054783          	lbu	a5,0(a0)
ffffffffc0203a94:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203a98:	0505                	addi	a0,a0,1
ffffffffc0203a9a:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203a9c:	fee788e3          	beq	a5,a4,ffffffffc0203a8c <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203aa0:	40e7853b          	subw	a0,a5,a4
ffffffffc0203aa4:	8082                	ret
    }
    return 0;
ffffffffc0203aa6:	4501                	li	a0,0
}
ffffffffc0203aa8:	8082                	ret

ffffffffc0203aaa <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203aaa:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203aae:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203ab0:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203ab4:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203ab6:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203aba:	f022                	sd	s0,32(sp)
ffffffffc0203abc:	ec26                	sd	s1,24(sp)
ffffffffc0203abe:	e84a                	sd	s2,16(sp)
ffffffffc0203ac0:	f406                	sd	ra,40(sp)
ffffffffc0203ac2:	e44e                	sd	s3,8(sp)
ffffffffc0203ac4:	84aa                	mv	s1,a0
ffffffffc0203ac6:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203ac8:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203acc:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203ace:	03067e63          	bgeu	a2,a6,ffffffffc0203b0a <printnum+0x60>
ffffffffc0203ad2:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203ad4:	00805763          	blez	s0,ffffffffc0203ae2 <printnum+0x38>
ffffffffc0203ad8:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203ada:	85ca                	mv	a1,s2
ffffffffc0203adc:	854e                	mv	a0,s3
ffffffffc0203ade:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203ae0:	fc65                	bnez	s0,ffffffffc0203ad8 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203ae2:	1a02                	slli	s4,s4,0x20
ffffffffc0203ae4:	00002797          	auipc	a5,0x2
ffffffffc0203ae8:	cd478793          	addi	a5,a5,-812 # ffffffffc02057b8 <default_pmm_manager+0x1f0>
ffffffffc0203aec:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203af0:	9a3e                	add	s4,s4,a5
}
ffffffffc0203af2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203af4:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203af8:	70a2                	ld	ra,40(sp)
ffffffffc0203afa:	69a2                	ld	s3,8(sp)
ffffffffc0203afc:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203afe:	85ca                	mv	a1,s2
ffffffffc0203b00:	87a6                	mv	a5,s1
}
ffffffffc0203b02:	6942                	ld	s2,16(sp)
ffffffffc0203b04:	64e2                	ld	s1,24(sp)
ffffffffc0203b06:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203b08:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203b0a:	03065633          	divu	a2,a2,a6
ffffffffc0203b0e:	8722                	mv	a4,s0
ffffffffc0203b10:	f9bff0ef          	jal	ra,ffffffffc0203aaa <printnum>
ffffffffc0203b14:	b7f9                	j	ffffffffc0203ae2 <printnum+0x38>

ffffffffc0203b16 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203b16:	7119                	addi	sp,sp,-128
ffffffffc0203b18:	f4a6                	sd	s1,104(sp)
ffffffffc0203b1a:	f0ca                	sd	s2,96(sp)
ffffffffc0203b1c:	ecce                	sd	s3,88(sp)
ffffffffc0203b1e:	e8d2                	sd	s4,80(sp)
ffffffffc0203b20:	e4d6                	sd	s5,72(sp)
ffffffffc0203b22:	e0da                	sd	s6,64(sp)
ffffffffc0203b24:	fc5e                	sd	s7,56(sp)
ffffffffc0203b26:	f06a                	sd	s10,32(sp)
ffffffffc0203b28:	fc86                	sd	ra,120(sp)
ffffffffc0203b2a:	f8a2                	sd	s0,112(sp)
ffffffffc0203b2c:	f862                	sd	s8,48(sp)
ffffffffc0203b2e:	f466                	sd	s9,40(sp)
ffffffffc0203b30:	ec6e                	sd	s11,24(sp)
ffffffffc0203b32:	892a                	mv	s2,a0
ffffffffc0203b34:	84ae                	mv	s1,a1
ffffffffc0203b36:	8d32                	mv	s10,a2
ffffffffc0203b38:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203b3a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203b3e:	5b7d                	li	s6,-1
ffffffffc0203b40:	00002a97          	auipc	s5,0x2
ffffffffc0203b44:	ca4a8a93          	addi	s5,s5,-860 # ffffffffc02057e4 <default_pmm_manager+0x21c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203b48:	00002b97          	auipc	s7,0x2
ffffffffc0203b4c:	e78b8b93          	addi	s7,s7,-392 # ffffffffc02059c0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203b50:	000d4503          	lbu	a0,0(s10)
ffffffffc0203b54:	001d0413          	addi	s0,s10,1
ffffffffc0203b58:	01350a63          	beq	a0,s3,ffffffffc0203b6c <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203b5c:	c121                	beqz	a0,ffffffffc0203b9c <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203b5e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203b60:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203b62:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203b64:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203b68:	ff351ae3          	bne	a0,s3,ffffffffc0203b5c <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b6c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203b70:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203b74:	4c81                	li	s9,0
ffffffffc0203b76:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203b78:	5c7d                	li	s8,-1
ffffffffc0203b7a:	5dfd                	li	s11,-1
ffffffffc0203b7c:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203b80:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b82:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203b86:	0ff5f593          	zext.b	a1,a1
ffffffffc0203b8a:	00140d13          	addi	s10,s0,1
ffffffffc0203b8e:	04b56263          	bltu	a0,a1,ffffffffc0203bd2 <vprintfmt+0xbc>
ffffffffc0203b92:	058a                	slli	a1,a1,0x2
ffffffffc0203b94:	95d6                	add	a1,a1,s5
ffffffffc0203b96:	4194                	lw	a3,0(a1)
ffffffffc0203b98:	96d6                	add	a3,a3,s5
ffffffffc0203b9a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203b9c:	70e6                	ld	ra,120(sp)
ffffffffc0203b9e:	7446                	ld	s0,112(sp)
ffffffffc0203ba0:	74a6                	ld	s1,104(sp)
ffffffffc0203ba2:	7906                	ld	s2,96(sp)
ffffffffc0203ba4:	69e6                	ld	s3,88(sp)
ffffffffc0203ba6:	6a46                	ld	s4,80(sp)
ffffffffc0203ba8:	6aa6                	ld	s5,72(sp)
ffffffffc0203baa:	6b06                	ld	s6,64(sp)
ffffffffc0203bac:	7be2                	ld	s7,56(sp)
ffffffffc0203bae:	7c42                	ld	s8,48(sp)
ffffffffc0203bb0:	7ca2                	ld	s9,40(sp)
ffffffffc0203bb2:	7d02                	ld	s10,32(sp)
ffffffffc0203bb4:	6de2                	ld	s11,24(sp)
ffffffffc0203bb6:	6109                	addi	sp,sp,128
ffffffffc0203bb8:	8082                	ret
            padc = '0';
ffffffffc0203bba:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203bbc:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bc0:	846a                	mv	s0,s10
ffffffffc0203bc2:	00140d13          	addi	s10,s0,1
ffffffffc0203bc6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203bca:	0ff5f593          	zext.b	a1,a1
ffffffffc0203bce:	fcb572e3          	bgeu	a0,a1,ffffffffc0203b92 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203bd2:	85a6                	mv	a1,s1
ffffffffc0203bd4:	02500513          	li	a0,37
ffffffffc0203bd8:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203bda:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203bde:	8d22                	mv	s10,s0
ffffffffc0203be0:	f73788e3          	beq	a5,s3,ffffffffc0203b50 <vprintfmt+0x3a>
ffffffffc0203be4:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203be8:	1d7d                	addi	s10,s10,-1
ffffffffc0203bea:	ff379de3          	bne	a5,s3,ffffffffc0203be4 <vprintfmt+0xce>
ffffffffc0203bee:	b78d                	j	ffffffffc0203b50 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203bf0:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203bf4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bf8:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203bfa:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203bfe:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203c02:	02d86463          	bltu	a6,a3,ffffffffc0203c2a <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203c06:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203c0a:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203c0e:	0186873b          	addw	a4,a3,s8
ffffffffc0203c12:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203c16:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203c18:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203c1c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203c1e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203c22:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203c26:	fed870e3          	bgeu	a6,a3,ffffffffc0203c06 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203c2a:	f40ddce3          	bgez	s11,ffffffffc0203b82 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203c2e:	8de2                	mv	s11,s8
ffffffffc0203c30:	5c7d                	li	s8,-1
ffffffffc0203c32:	bf81                	j	ffffffffc0203b82 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203c34:	fffdc693          	not	a3,s11
ffffffffc0203c38:	96fd                	srai	a3,a3,0x3f
ffffffffc0203c3a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c3e:	00144603          	lbu	a2,1(s0)
ffffffffc0203c42:	2d81                	sext.w	s11,s11
ffffffffc0203c44:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203c46:	bf35                	j	ffffffffc0203b82 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203c48:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c4c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203c50:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c52:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203c54:	bfd9                	j	ffffffffc0203c2a <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203c56:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c58:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c5c:	01174463          	blt	a4,a7,ffffffffc0203c64 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203c60:	1a088e63          	beqz	a7,ffffffffc0203e1c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203c64:	000a3603          	ld	a2,0(s4)
ffffffffc0203c68:	46c1                	li	a3,16
ffffffffc0203c6a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203c6c:	2781                	sext.w	a5,a5
ffffffffc0203c6e:	876e                	mv	a4,s11
ffffffffc0203c70:	85a6                	mv	a1,s1
ffffffffc0203c72:	854a                	mv	a0,s2
ffffffffc0203c74:	e37ff0ef          	jal	ra,ffffffffc0203aaa <printnum>
            break;
ffffffffc0203c78:	bde1                	j	ffffffffc0203b50 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203c7a:	000a2503          	lw	a0,0(s4)
ffffffffc0203c7e:	85a6                	mv	a1,s1
ffffffffc0203c80:	0a21                	addi	s4,s4,8
ffffffffc0203c82:	9902                	jalr	s2
            break;
ffffffffc0203c84:	b5f1                	j	ffffffffc0203b50 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203c86:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c88:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c8c:	01174463          	blt	a4,a7,ffffffffc0203c94 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203c90:	18088163          	beqz	a7,ffffffffc0203e12 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203c94:	000a3603          	ld	a2,0(s4)
ffffffffc0203c98:	46a9                	li	a3,10
ffffffffc0203c9a:	8a2e                	mv	s4,a1
ffffffffc0203c9c:	bfc1                	j	ffffffffc0203c6c <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c9e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203ca2:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ca4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203ca6:	bdf1                	j	ffffffffc0203b82 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203ca8:	85a6                	mv	a1,s1
ffffffffc0203caa:	02500513          	li	a0,37
ffffffffc0203cae:	9902                	jalr	s2
            break;
ffffffffc0203cb0:	b545                	j	ffffffffc0203b50 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203cb2:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203cb6:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203cb8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203cba:	b5e1                	j	ffffffffc0203b82 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203cbc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203cbe:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203cc2:	01174463          	blt	a4,a7,ffffffffc0203cca <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203cc6:	14088163          	beqz	a7,ffffffffc0203e08 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203cca:	000a3603          	ld	a2,0(s4)
ffffffffc0203cce:	46a1                	li	a3,8
ffffffffc0203cd0:	8a2e                	mv	s4,a1
ffffffffc0203cd2:	bf69                	j	ffffffffc0203c6c <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203cd4:	03000513          	li	a0,48
ffffffffc0203cd8:	85a6                	mv	a1,s1
ffffffffc0203cda:	e03e                	sd	a5,0(sp)
ffffffffc0203cdc:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203cde:	85a6                	mv	a1,s1
ffffffffc0203ce0:	07800513          	li	a0,120
ffffffffc0203ce4:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203ce6:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203ce8:	6782                	ld	a5,0(sp)
ffffffffc0203cea:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203cec:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203cf0:	bfb5                	j	ffffffffc0203c6c <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203cf2:	000a3403          	ld	s0,0(s4)
ffffffffc0203cf6:	008a0713          	addi	a4,s4,8
ffffffffc0203cfa:	e03a                	sd	a4,0(sp)
ffffffffc0203cfc:	14040263          	beqz	s0,ffffffffc0203e40 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203d00:	0fb05763          	blez	s11,ffffffffc0203dee <vprintfmt+0x2d8>
ffffffffc0203d04:	02d00693          	li	a3,45
ffffffffc0203d08:	0cd79163          	bne	a5,a3,ffffffffc0203dca <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d0c:	00044783          	lbu	a5,0(s0)
ffffffffc0203d10:	0007851b          	sext.w	a0,a5
ffffffffc0203d14:	cf85                	beqz	a5,ffffffffc0203d4c <vprintfmt+0x236>
ffffffffc0203d16:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d1a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d1e:	000c4563          	bltz	s8,ffffffffc0203d28 <vprintfmt+0x212>
ffffffffc0203d22:	3c7d                	addiw	s8,s8,-1
ffffffffc0203d24:	036c0263          	beq	s8,s6,ffffffffc0203d48 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203d28:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d2a:	0e0c8e63          	beqz	s9,ffffffffc0203e26 <vprintfmt+0x310>
ffffffffc0203d2e:	3781                	addiw	a5,a5,-32
ffffffffc0203d30:	0ef47b63          	bgeu	s0,a5,ffffffffc0203e26 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203d34:	03f00513          	li	a0,63
ffffffffc0203d38:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d3a:	000a4783          	lbu	a5,0(s4)
ffffffffc0203d3e:	3dfd                	addiw	s11,s11,-1
ffffffffc0203d40:	0a05                	addi	s4,s4,1
ffffffffc0203d42:	0007851b          	sext.w	a0,a5
ffffffffc0203d46:	ffe1                	bnez	a5,ffffffffc0203d1e <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203d48:	01b05963          	blez	s11,ffffffffc0203d5a <vprintfmt+0x244>
ffffffffc0203d4c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203d4e:	85a6                	mv	a1,s1
ffffffffc0203d50:	02000513          	li	a0,32
ffffffffc0203d54:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203d56:	fe0d9be3          	bnez	s11,ffffffffc0203d4c <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203d5a:	6a02                	ld	s4,0(sp)
ffffffffc0203d5c:	bbd5                	j	ffffffffc0203b50 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203d5e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203d60:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203d64:	01174463          	blt	a4,a7,ffffffffc0203d6c <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203d68:	08088d63          	beqz	a7,ffffffffc0203e02 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203d6c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203d70:	0a044d63          	bltz	s0,ffffffffc0203e2a <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203d74:	8622                	mv	a2,s0
ffffffffc0203d76:	8a66                	mv	s4,s9
ffffffffc0203d78:	46a9                	li	a3,10
ffffffffc0203d7a:	bdcd                	j	ffffffffc0203c6c <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203d7c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203d80:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203d82:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203d84:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203d88:	8fb5                	xor	a5,a5,a3
ffffffffc0203d8a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203d8e:	02d74163          	blt	a4,a3,ffffffffc0203db0 <vprintfmt+0x29a>
ffffffffc0203d92:	00369793          	slli	a5,a3,0x3
ffffffffc0203d96:	97de                	add	a5,a5,s7
ffffffffc0203d98:	639c                	ld	a5,0(a5)
ffffffffc0203d9a:	cb99                	beqz	a5,ffffffffc0203db0 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203d9c:	86be                	mv	a3,a5
ffffffffc0203d9e:	00000617          	auipc	a2,0x0
ffffffffc0203da2:	13a60613          	addi	a2,a2,314 # ffffffffc0203ed8 <etext+0x2a>
ffffffffc0203da6:	85a6                	mv	a1,s1
ffffffffc0203da8:	854a                	mv	a0,s2
ffffffffc0203daa:	0ce000ef          	jal	ra,ffffffffc0203e78 <printfmt>
ffffffffc0203dae:	b34d                	j	ffffffffc0203b50 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203db0:	00002617          	auipc	a2,0x2
ffffffffc0203db4:	a2860613          	addi	a2,a2,-1496 # ffffffffc02057d8 <default_pmm_manager+0x210>
ffffffffc0203db8:	85a6                	mv	a1,s1
ffffffffc0203dba:	854a                	mv	a0,s2
ffffffffc0203dbc:	0bc000ef          	jal	ra,ffffffffc0203e78 <printfmt>
ffffffffc0203dc0:	bb41                	j	ffffffffc0203b50 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203dc2:	00002417          	auipc	s0,0x2
ffffffffc0203dc6:	a0e40413          	addi	s0,s0,-1522 # ffffffffc02057d0 <default_pmm_manager+0x208>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203dca:	85e2                	mv	a1,s8
ffffffffc0203dcc:	8522                	mv	a0,s0
ffffffffc0203dce:	e43e                	sd	a5,8(sp)
ffffffffc0203dd0:	c05ff0ef          	jal	ra,ffffffffc02039d4 <strnlen>
ffffffffc0203dd4:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203dd8:	01b05b63          	blez	s11,ffffffffc0203dee <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203ddc:	67a2                	ld	a5,8(sp)
ffffffffc0203dde:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203de2:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203de4:	85a6                	mv	a1,s1
ffffffffc0203de6:	8552                	mv	a0,s4
ffffffffc0203de8:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203dea:	fe0d9ce3          	bnez	s11,ffffffffc0203de2 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203dee:	00044783          	lbu	a5,0(s0)
ffffffffc0203df2:	00140a13          	addi	s4,s0,1
ffffffffc0203df6:	0007851b          	sext.w	a0,a5
ffffffffc0203dfa:	d3a5                	beqz	a5,ffffffffc0203d5a <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203dfc:	05e00413          	li	s0,94
ffffffffc0203e00:	bf39                	j	ffffffffc0203d1e <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203e02:	000a2403          	lw	s0,0(s4)
ffffffffc0203e06:	b7ad                	j	ffffffffc0203d70 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203e08:	000a6603          	lwu	a2,0(s4)
ffffffffc0203e0c:	46a1                	li	a3,8
ffffffffc0203e0e:	8a2e                	mv	s4,a1
ffffffffc0203e10:	bdb1                	j	ffffffffc0203c6c <vprintfmt+0x156>
ffffffffc0203e12:	000a6603          	lwu	a2,0(s4)
ffffffffc0203e16:	46a9                	li	a3,10
ffffffffc0203e18:	8a2e                	mv	s4,a1
ffffffffc0203e1a:	bd89                	j	ffffffffc0203c6c <vprintfmt+0x156>
ffffffffc0203e1c:	000a6603          	lwu	a2,0(s4)
ffffffffc0203e20:	46c1                	li	a3,16
ffffffffc0203e22:	8a2e                	mv	s4,a1
ffffffffc0203e24:	b5a1                	j	ffffffffc0203c6c <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203e26:	9902                	jalr	s2
ffffffffc0203e28:	bf09                	j	ffffffffc0203d3a <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203e2a:	85a6                	mv	a1,s1
ffffffffc0203e2c:	02d00513          	li	a0,45
ffffffffc0203e30:	e03e                	sd	a5,0(sp)
ffffffffc0203e32:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203e34:	6782                	ld	a5,0(sp)
ffffffffc0203e36:	8a66                	mv	s4,s9
ffffffffc0203e38:	40800633          	neg	a2,s0
ffffffffc0203e3c:	46a9                	li	a3,10
ffffffffc0203e3e:	b53d                	j	ffffffffc0203c6c <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203e40:	03b05163          	blez	s11,ffffffffc0203e62 <vprintfmt+0x34c>
ffffffffc0203e44:	02d00693          	li	a3,45
ffffffffc0203e48:	f6d79de3          	bne	a5,a3,ffffffffc0203dc2 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203e4c:	00002417          	auipc	s0,0x2
ffffffffc0203e50:	98440413          	addi	s0,s0,-1660 # ffffffffc02057d0 <default_pmm_manager+0x208>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203e54:	02800793          	li	a5,40
ffffffffc0203e58:	02800513          	li	a0,40
ffffffffc0203e5c:	00140a13          	addi	s4,s0,1
ffffffffc0203e60:	bd6d                	j	ffffffffc0203d1a <vprintfmt+0x204>
ffffffffc0203e62:	00002a17          	auipc	s4,0x2
ffffffffc0203e66:	96fa0a13          	addi	s4,s4,-1681 # ffffffffc02057d1 <default_pmm_manager+0x209>
ffffffffc0203e6a:	02800513          	li	a0,40
ffffffffc0203e6e:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203e72:	05e00413          	li	s0,94
ffffffffc0203e76:	b565                	j	ffffffffc0203d1e <vprintfmt+0x208>

ffffffffc0203e78 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203e78:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203e7a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203e7e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203e80:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203e82:	ec06                	sd	ra,24(sp)
ffffffffc0203e84:	f83a                	sd	a4,48(sp)
ffffffffc0203e86:	fc3e                	sd	a5,56(sp)
ffffffffc0203e88:	e0c2                	sd	a6,64(sp)
ffffffffc0203e8a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203e8c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203e8e:	c89ff0ef          	jal	ra,ffffffffc0203b16 <vprintfmt>
}
ffffffffc0203e92:	60e2                	ld	ra,24(sp)
ffffffffc0203e94:	6161                	addi	sp,sp,80
ffffffffc0203e96:	8082                	ret

ffffffffc0203e98 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203e98:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203e9c:	2785                	addiw	a5,a5,1
ffffffffc0203e9e:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0203ea2:	02000793          	li	a5,32
ffffffffc0203ea6:	9f8d                	subw	a5,a5,a1
}
ffffffffc0203ea8:	00f5553b          	srlw	a0,a0,a5
ffffffffc0203eac:	8082                	ret
