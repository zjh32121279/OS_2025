
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	151010ef          	jal	ra,ffffffffc02019bc <memset>
    dtb_init();
ffffffffc0200070:	3be000ef          	jal	ra,ffffffffc020042e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	7ae000ef          	jal	ra,ffffffffc0200822 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	e6850513          	addi	a0,a0,-408 # ffffffffc0201ee0 <etext+0x6>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	138000ef          	jal	ra,ffffffffc02001bc <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7b4000ef          	jal	ra,ffffffffc020083c <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	4b5000ef          	jal	ra,ffffffffc0200d40 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7ac000ef          	jal	ra,ffffffffc020083c <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	74a000ef          	jal	ra,ffffffffc02007de <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	798000ef          	jal	ra,ffffffffc0200830 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	77e000ef          	jal	ra,ffffffffc0200824 <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	16f010ef          	jal	ra,ffffffffc0201a3a <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200100:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200102:	139010ef          	jal	ra,ffffffffc0201a3a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010e:	af19                	j	ffffffffc0200824 <cons_putc>

ffffffffc0200110 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200126:	6fe000ef          	jal	ra,ffffffffc0200824 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	6e8000ef          	jal	ra,ffffffffc0200824 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200154:	6d8000ef          	jal	ra,ffffffffc020082c <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015a:	60a2                	ld	ra,8(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200160:	00006317          	auipc	t1,0x6
ffffffffc0200164:	2e030313          	addi	t1,t1,736 # ffffffffc0206440 <is_panic>
ffffffffc0200168:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020016c:	715d                	addi	sp,sp,-80
ffffffffc020016e:	ec06                	sd	ra,24(sp)
ffffffffc0200170:	e822                	sd	s0,16(sp)
ffffffffc0200172:	f436                	sd	a3,40(sp)
ffffffffc0200174:	f83a                	sd	a4,48(sp)
ffffffffc0200176:	fc3e                	sd	a5,56(sp)
ffffffffc0200178:	e0c2                	sd	a6,64(sp)
ffffffffc020017a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020017c:	020e1a63          	bnez	t3,ffffffffc02001b0 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200180:	4785                	li	a5,1
ffffffffc0200182:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200186:	8432                	mv	s0,a2
ffffffffc0200188:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020018a:	862e                	mv	a2,a1
ffffffffc020018c:	85aa                	mv	a1,a0
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	d7250513          	addi	a0,a0,-654 # ffffffffc0201f00 <etext+0x26>
    va_start(ap, fmt);
ffffffffc0200196:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200198:	f41ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020019c:	65a2                	ld	a1,8(sp)
ffffffffc020019e:	8522                	mv	a0,s0
ffffffffc02001a0:	f19ff0ef          	jal	ra,ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc02001a4:	00002517          	auipc	a0,0x2
ffffffffc02001a8:	e4450513          	addi	a0,a0,-444 # ffffffffc0201fe8 <etext+0x10e>
ffffffffc02001ac:	f2dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02001b0:	686000ef          	jal	ra,ffffffffc0200836 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02001b4:	4501                	li	a0,0
ffffffffc02001b6:	130000ef          	jal	ra,ffffffffc02002e6 <kmonitor>
    while (1) {
ffffffffc02001ba:	bfed                	j	ffffffffc02001b4 <__panic+0x54>

ffffffffc02001bc <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001bc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001be:	00002517          	auipc	a0,0x2
ffffffffc02001c2:	d6250513          	addi	a0,a0,-670 # ffffffffc0201f20 <etext+0x46>
void print_kerninfo(void) {
ffffffffc02001c6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001c8:	f11ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001cc:	00000597          	auipc	a1,0x0
ffffffffc02001d0:	e8858593          	addi	a1,a1,-376 # ffffffffc0200054 <kern_init>
ffffffffc02001d4:	00002517          	auipc	a0,0x2
ffffffffc02001d8:	d6c50513          	addi	a0,a0,-660 # ffffffffc0201f40 <etext+0x66>
ffffffffc02001dc:	efdff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001e0:	00002597          	auipc	a1,0x2
ffffffffc02001e4:	cfa58593          	addi	a1,a1,-774 # ffffffffc0201eda <etext>
ffffffffc02001e8:	00002517          	auipc	a0,0x2
ffffffffc02001ec:	d7850513          	addi	a0,a0,-648 # ffffffffc0201f60 <etext+0x86>
ffffffffc02001f0:	ee9ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001f4:	00006597          	auipc	a1,0x6
ffffffffc02001f8:	e3458593          	addi	a1,a1,-460 # ffffffffc0206028 <free_area>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	d8450513          	addi	a0,a0,-636 # ffffffffc0201f80 <etext+0xa6>
ffffffffc0200204:	ed5ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200208:	00006597          	auipc	a1,0x6
ffffffffc020020c:	29858593          	addi	a1,a1,664 # ffffffffc02064a0 <end>
ffffffffc0200210:	00002517          	auipc	a0,0x2
ffffffffc0200214:	d9050513          	addi	a0,a0,-624 # ffffffffc0201fa0 <etext+0xc6>
ffffffffc0200218:	ec1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020021c:	00006597          	auipc	a1,0x6
ffffffffc0200220:	68358593          	addi	a1,a1,1667 # ffffffffc020689f <end+0x3ff>
ffffffffc0200224:	00000797          	auipc	a5,0x0
ffffffffc0200228:	e3078793          	addi	a5,a5,-464 # ffffffffc0200054 <kern_init>
ffffffffc020022c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200230:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200234:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200236:	3ff5f593          	andi	a1,a1,1023
ffffffffc020023a:	95be                	add	a1,a1,a5
ffffffffc020023c:	85a9                	srai	a1,a1,0xa
ffffffffc020023e:	00002517          	auipc	a0,0x2
ffffffffc0200242:	d8250513          	addi	a0,a0,-638 # ffffffffc0201fc0 <etext+0xe6>
}
ffffffffc0200246:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200248:	bd41                	j	ffffffffc02000d8 <cprintf>

ffffffffc020024a <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020024c:	00002617          	auipc	a2,0x2
ffffffffc0200250:	da460613          	addi	a2,a2,-604 # ffffffffc0201ff0 <etext+0x116>
ffffffffc0200254:	04d00593          	li	a1,77
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	db050513          	addi	a0,a0,-592 # ffffffffc0202008 <etext+0x12e>
void print_stackframe(void) {
ffffffffc0200260:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200262:	effff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0200266 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200266:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200268:	00002617          	auipc	a2,0x2
ffffffffc020026c:	db860613          	addi	a2,a2,-584 # ffffffffc0202020 <etext+0x146>
ffffffffc0200270:	00002597          	auipc	a1,0x2
ffffffffc0200274:	dd058593          	addi	a1,a1,-560 # ffffffffc0202040 <etext+0x166>
ffffffffc0200278:	00002517          	auipc	a0,0x2
ffffffffc020027c:	dd050513          	addi	a0,a0,-560 # ffffffffc0202048 <etext+0x16e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200280:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200282:	e57ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200286:	00002617          	auipc	a2,0x2
ffffffffc020028a:	dd260613          	addi	a2,a2,-558 # ffffffffc0202058 <etext+0x17e>
ffffffffc020028e:	00002597          	auipc	a1,0x2
ffffffffc0200292:	df258593          	addi	a1,a1,-526 # ffffffffc0202080 <etext+0x1a6>
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	db250513          	addi	a0,a0,-590 # ffffffffc0202048 <etext+0x16e>
ffffffffc020029e:	e3bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02002a2:	00002617          	auipc	a2,0x2
ffffffffc02002a6:	dee60613          	addi	a2,a2,-530 # ffffffffc0202090 <etext+0x1b6>
ffffffffc02002aa:	00002597          	auipc	a1,0x2
ffffffffc02002ae:	e0658593          	addi	a1,a1,-506 # ffffffffc02020b0 <etext+0x1d6>
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	d9650513          	addi	a0,a0,-618 # ffffffffc0202048 <etext+0x16e>
ffffffffc02002ba:	e1fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc02002be:	60a2                	ld	ra,8(sp)
ffffffffc02002c0:	4501                	li	a0,0
ffffffffc02002c2:	0141                	addi	sp,sp,16
ffffffffc02002c4:	8082                	ret

ffffffffc02002c6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002c6:	1141                	addi	sp,sp,-16
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ca:	ef3ff0ef          	jal	ra,ffffffffc02001bc <print_kerninfo>
    return 0;
}
ffffffffc02002ce:	60a2                	ld	ra,8(sp)
ffffffffc02002d0:	4501                	li	a0,0
ffffffffc02002d2:	0141                	addi	sp,sp,16
ffffffffc02002d4:	8082                	ret

ffffffffc02002d6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002d6:	1141                	addi	sp,sp,-16
ffffffffc02002d8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002da:	f71ff0ef          	jal	ra,ffffffffc020024a <print_stackframe>
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002e6:	7115                	addi	sp,sp,-224
ffffffffc02002e8:	ed5e                	sd	s7,152(sp)
ffffffffc02002ea:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ec:	00002517          	auipc	a0,0x2
ffffffffc02002f0:	dd450513          	addi	a0,a0,-556 # ffffffffc02020c0 <etext+0x1e6>
kmonitor(struct trapframe *tf) {
ffffffffc02002f4:	ed86                	sd	ra,216(sp)
ffffffffc02002f6:	e9a2                	sd	s0,208(sp)
ffffffffc02002f8:	e5a6                	sd	s1,200(sp)
ffffffffc02002fa:	e1ca                	sd	s2,192(sp)
ffffffffc02002fc:	fd4e                	sd	s3,184(sp)
ffffffffc02002fe:	f952                	sd	s4,176(sp)
ffffffffc0200300:	f556                	sd	s5,168(sp)
ffffffffc0200302:	f15a                	sd	s6,160(sp)
ffffffffc0200304:	e962                	sd	s8,144(sp)
ffffffffc0200306:	e566                	sd	s9,136(sp)
ffffffffc0200308:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030a:	dcfff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020030e:	00002517          	auipc	a0,0x2
ffffffffc0200312:	dda50513          	addi	a0,a0,-550 # ffffffffc02020e8 <etext+0x20e>
ffffffffc0200316:	dc3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc020031a:	000b8563          	beqz	s7,ffffffffc0200324 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020031e:	855e                	mv	a0,s7
ffffffffc0200320:	6fc000ef          	jal	ra,ffffffffc0200a1c <print_trapframe>
ffffffffc0200324:	00002c17          	auipc	s8,0x2
ffffffffc0200328:	e34c0c13          	addi	s8,s8,-460 # ffffffffc0202158 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032c:	00002917          	auipc	s2,0x2
ffffffffc0200330:	de490913          	addi	s2,s2,-540 # ffffffffc0202110 <etext+0x236>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200334:	00002497          	auipc	s1,0x2
ffffffffc0200338:	de448493          	addi	s1,s1,-540 # ffffffffc0202118 <etext+0x23e>
        if (argc == MAXARGS - 1) {
ffffffffc020033c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020033e:	00002b17          	auipc	s6,0x2
ffffffffc0200342:	de2b0b13          	addi	s6,s6,-542 # ffffffffc0202120 <etext+0x246>
        argv[argc ++] = buf;
ffffffffc0200346:	00002a17          	auipc	s4,0x2
ffffffffc020034a:	cfaa0a13          	addi	s4,s4,-774 # ffffffffc0202040 <etext+0x166>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034e:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200350:	854a                	mv	a0,s2
ffffffffc0200352:	2d5010ef          	jal	ra,ffffffffc0201e26 <readline>
ffffffffc0200356:	842a                	mv	s0,a0
ffffffffc0200358:	dd65                	beqz	a0,ffffffffc0200350 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035a:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020035e:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	e1bd                	bnez	a1,ffffffffc02003c6 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200362:	fe0c87e3          	beqz	s9,ffffffffc0200350 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200366:	6582                	ld	a1,0(sp)
ffffffffc0200368:	00002d17          	auipc	s10,0x2
ffffffffc020036c:	df0d0d13          	addi	s10,s10,-528 # ffffffffc0202158 <commands>
        argv[argc ++] = buf;
ffffffffc0200370:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200372:	4401                	li	s0,0
ffffffffc0200374:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200376:	5ec010ef          	jal	ra,ffffffffc0201962 <strcmp>
ffffffffc020037a:	c919                	beqz	a0,ffffffffc0200390 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037c:	2405                	addiw	s0,s0,1
ffffffffc020037e:	0b540063          	beq	s0,s5,ffffffffc020041e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200382:	000d3503          	ld	a0,0(s10)
ffffffffc0200386:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200388:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020038a:	5d8010ef          	jal	ra,ffffffffc0201962 <strcmp>
ffffffffc020038e:	f57d                	bnez	a0,ffffffffc020037c <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200390:	00141793          	slli	a5,s0,0x1
ffffffffc0200394:	97a2                	add	a5,a5,s0
ffffffffc0200396:	078e                	slli	a5,a5,0x3
ffffffffc0200398:	97e2                	add	a5,a5,s8
ffffffffc020039a:	6b9c                	ld	a5,16(a5)
ffffffffc020039c:	865e                	mv	a2,s7
ffffffffc020039e:	002c                	addi	a1,sp,8
ffffffffc02003a0:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003a4:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003a6:	fa0555e3          	bgez	a0,ffffffffc0200350 <kmonitor+0x6a>
}
ffffffffc02003aa:	60ee                	ld	ra,216(sp)
ffffffffc02003ac:	644e                	ld	s0,208(sp)
ffffffffc02003ae:	64ae                	ld	s1,200(sp)
ffffffffc02003b0:	690e                	ld	s2,192(sp)
ffffffffc02003b2:	79ea                	ld	s3,184(sp)
ffffffffc02003b4:	7a4a                	ld	s4,176(sp)
ffffffffc02003b6:	7aaa                	ld	s5,168(sp)
ffffffffc02003b8:	7b0a                	ld	s6,160(sp)
ffffffffc02003ba:	6bea                	ld	s7,152(sp)
ffffffffc02003bc:	6c4a                	ld	s8,144(sp)
ffffffffc02003be:	6caa                	ld	s9,136(sp)
ffffffffc02003c0:	6d0a                	ld	s10,128(sp)
ffffffffc02003c2:	612d                	addi	sp,sp,224
ffffffffc02003c4:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c6:	8526                	mv	a0,s1
ffffffffc02003c8:	5de010ef          	jal	ra,ffffffffc02019a6 <strchr>
ffffffffc02003cc:	c901                	beqz	a0,ffffffffc02003dc <kmonitor+0xf6>
ffffffffc02003ce:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003d2:	00040023          	sb	zero,0(s0)
ffffffffc02003d6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d8:	d5c9                	beqz	a1,ffffffffc0200362 <kmonitor+0x7c>
ffffffffc02003da:	b7f5                	j	ffffffffc02003c6 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003dc:	00044783          	lbu	a5,0(s0)
ffffffffc02003e0:	d3c9                	beqz	a5,ffffffffc0200362 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003e2:	033c8963          	beq	s9,s3,ffffffffc0200414 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003e6:	003c9793          	slli	a5,s9,0x3
ffffffffc02003ea:	0118                	addi	a4,sp,128
ffffffffc02003ec:	97ba                	add	a5,a5,a4
ffffffffc02003ee:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f2:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003f6:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003f8:	e591                	bnez	a1,ffffffffc0200404 <kmonitor+0x11e>
ffffffffc02003fa:	b7b5                	j	ffffffffc0200366 <kmonitor+0x80>
ffffffffc02003fc:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200400:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200402:	d1a5                	beqz	a1,ffffffffc0200362 <kmonitor+0x7c>
ffffffffc0200404:	8526                	mv	a0,s1
ffffffffc0200406:	5a0010ef          	jal	ra,ffffffffc02019a6 <strchr>
ffffffffc020040a:	d96d                	beqz	a0,ffffffffc02003fc <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020040c:	00044583          	lbu	a1,0(s0)
ffffffffc0200410:	d9a9                	beqz	a1,ffffffffc0200362 <kmonitor+0x7c>
ffffffffc0200412:	bf55                	j	ffffffffc02003c6 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200414:	45c1                	li	a1,16
ffffffffc0200416:	855a                	mv	a0,s6
ffffffffc0200418:	cc1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020041c:	b7e9                	j	ffffffffc02003e6 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020041e:	6582                	ld	a1,0(sp)
ffffffffc0200420:	00002517          	auipc	a0,0x2
ffffffffc0200424:	d2050513          	addi	a0,a0,-736 # ffffffffc0202140 <etext+0x266>
ffffffffc0200428:	cb1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc020042c:	b715                	j	ffffffffc0200350 <kmonitor+0x6a>

ffffffffc020042e <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020042e:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200430:	00002517          	auipc	a0,0x2
ffffffffc0200434:	d7050513          	addi	a0,a0,-656 # ffffffffc02021a0 <commands+0x48>
void dtb_init(void) {
ffffffffc0200438:	fc86                	sd	ra,120(sp)
ffffffffc020043a:	f8a2                	sd	s0,112(sp)
ffffffffc020043c:	e8d2                	sd	s4,80(sp)
ffffffffc020043e:	f4a6                	sd	s1,104(sp)
ffffffffc0200440:	f0ca                	sd	s2,96(sp)
ffffffffc0200442:	ecce                	sd	s3,88(sp)
ffffffffc0200444:	e4d6                	sd	s5,72(sp)
ffffffffc0200446:	e0da                	sd	s6,64(sp)
ffffffffc0200448:	fc5e                	sd	s7,56(sp)
ffffffffc020044a:	f862                	sd	s8,48(sp)
ffffffffc020044c:	f466                	sd	s9,40(sp)
ffffffffc020044e:	f06a                	sd	s10,32(sp)
ffffffffc0200450:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200452:	c87ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200456:	00006597          	auipc	a1,0x6
ffffffffc020045a:	baa5b583          	ld	a1,-1110(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc020045e:	00002517          	auipc	a0,0x2
ffffffffc0200462:	d5250513          	addi	a0,a0,-686 # ffffffffc02021b0 <commands+0x58>
ffffffffc0200466:	c73ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020046a:	00006417          	auipc	s0,0x6
ffffffffc020046e:	b9e40413          	addi	s0,s0,-1122 # ffffffffc0206008 <boot_dtb>
ffffffffc0200472:	600c                	ld	a1,0(s0)
ffffffffc0200474:	00002517          	auipc	a0,0x2
ffffffffc0200478:	d4c50513          	addi	a0,a0,-692 # ffffffffc02021c0 <commands+0x68>
ffffffffc020047c:	c5dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200480:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200484:	00002517          	auipc	a0,0x2
ffffffffc0200488:	d5450513          	addi	a0,a0,-684 # ffffffffc02021d8 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc020048c:	120a0463          	beqz	s4,ffffffffc02005b4 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200490:	57f5                	li	a5,-3
ffffffffc0200492:	07fa                	slli	a5,a5,0x1e
ffffffffc0200494:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200498:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020049e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004a4:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a8:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ac:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b4:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b6:	8ec9                	or	a3,a3,a0
ffffffffc02004b8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004bc:	1b7d                	addi	s6,s6,-1
ffffffffc02004be:	0167f7b3          	and	a5,a5,s6
ffffffffc02004c2:	8dd5                	or	a1,a1,a3
ffffffffc02004c4:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02004c6:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ca:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02004cc:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc02004d0:	10f59163          	bne	a1,a5,ffffffffc02005d2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02004d4:	471c                	lw	a5,8(a4)
ffffffffc02004d6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02004d8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004da:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004de:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02004e2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ea:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ee:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fa:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fe:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200502:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	01146433          	or	s0,s0,a7
ffffffffc0200508:	0086969b          	slliw	a3,a3,0x8
ffffffffc020050c:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200510:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200516:	8c49                	or	s0,s0,a0
ffffffffc0200518:	0166f6b3          	and	a3,a3,s6
ffffffffc020051c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200520:	0167f7b3          	and	a5,a5,s6
ffffffffc0200524:	8c55                	or	s0,s0,a3
ffffffffc0200526:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020052a:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020052c:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020052e:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200530:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200534:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200536:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200538:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020053c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020053e:	00002917          	auipc	s2,0x2
ffffffffc0200542:	cea90913          	addi	s2,s2,-790 # ffffffffc0202228 <commands+0xd0>
ffffffffc0200546:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200548:	4d91                	li	s11,4
ffffffffc020054a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020054c:	00002497          	auipc	s1,0x2
ffffffffc0200550:	cd448493          	addi	s1,s1,-812 # ffffffffc0202220 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200554:	000a2703          	lw	a4,0(s4)
ffffffffc0200558:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020055c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200560:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200564:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200568:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020056c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200570:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200572:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200576:	0087171b          	slliw	a4,a4,0x8
ffffffffc020057a:	8fd5                	or	a5,a5,a3
ffffffffc020057c:	00eb7733          	and	a4,s6,a4
ffffffffc0200580:	8fd9                	or	a5,a5,a4
ffffffffc0200582:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200584:	09778c63          	beq	a5,s7,ffffffffc020061c <dtb_init+0x1ee>
ffffffffc0200588:	00fbea63          	bltu	s7,a5,ffffffffc020059c <dtb_init+0x16e>
ffffffffc020058c:	07a78663          	beq	a5,s10,ffffffffc02005f8 <dtb_init+0x1ca>
ffffffffc0200590:	4709                	li	a4,2
ffffffffc0200592:	00e79763          	bne	a5,a4,ffffffffc02005a0 <dtb_init+0x172>
ffffffffc0200596:	4c81                	li	s9,0
ffffffffc0200598:	8a56                	mv	s4,s5
ffffffffc020059a:	bf6d                	j	ffffffffc0200554 <dtb_init+0x126>
ffffffffc020059c:	ffb78ee3          	beq	a5,s11,ffffffffc0200598 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005a0:	00002517          	auipc	a0,0x2
ffffffffc02005a4:	d0050513          	addi	a0,a0,-768 # ffffffffc02022a0 <commands+0x148>
ffffffffc02005a8:	b31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	d2c50513          	addi	a0,a0,-724 # ffffffffc02022d8 <commands+0x180>
}
ffffffffc02005b4:	7446                	ld	s0,112(sp)
ffffffffc02005b6:	70e6                	ld	ra,120(sp)
ffffffffc02005b8:	74a6                	ld	s1,104(sp)
ffffffffc02005ba:	7906                	ld	s2,96(sp)
ffffffffc02005bc:	69e6                	ld	s3,88(sp)
ffffffffc02005be:	6a46                	ld	s4,80(sp)
ffffffffc02005c0:	6aa6                	ld	s5,72(sp)
ffffffffc02005c2:	6b06                	ld	s6,64(sp)
ffffffffc02005c4:	7be2                	ld	s7,56(sp)
ffffffffc02005c6:	7c42                	ld	s8,48(sp)
ffffffffc02005c8:	7ca2                	ld	s9,40(sp)
ffffffffc02005ca:	7d02                	ld	s10,32(sp)
ffffffffc02005cc:	6de2                	ld	s11,24(sp)
ffffffffc02005ce:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02005d0:	b621                	j	ffffffffc02000d8 <cprintf>
}
ffffffffc02005d2:	7446                	ld	s0,112(sp)
ffffffffc02005d4:	70e6                	ld	ra,120(sp)
ffffffffc02005d6:	74a6                	ld	s1,104(sp)
ffffffffc02005d8:	7906                	ld	s2,96(sp)
ffffffffc02005da:	69e6                	ld	s3,88(sp)
ffffffffc02005dc:	6a46                	ld	s4,80(sp)
ffffffffc02005de:	6aa6                	ld	s5,72(sp)
ffffffffc02005e0:	6b06                	ld	s6,64(sp)
ffffffffc02005e2:	7be2                	ld	s7,56(sp)
ffffffffc02005e4:	7c42                	ld	s8,48(sp)
ffffffffc02005e6:	7ca2                	ld	s9,40(sp)
ffffffffc02005e8:	7d02                	ld	s10,32(sp)
ffffffffc02005ea:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	c0c50513          	addi	a0,a0,-1012 # ffffffffc02021f8 <commands+0xa0>
}
ffffffffc02005f4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02005f6:	b4cd                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc02005f8:	8556                	mv	a0,s5
ffffffffc02005fa:	332010ef          	jal	ra,ffffffffc020192c <strlen>
ffffffffc02005fe:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200600:	4619                	li	a2,6
ffffffffc0200602:	85a6                	mv	a1,s1
ffffffffc0200604:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200606:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200608:	378010ef          	jal	ra,ffffffffc0201980 <strncmp>
ffffffffc020060c:	e111                	bnez	a0,ffffffffc0200610 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020060e:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200610:	0a91                	addi	s5,s5,4
ffffffffc0200612:	9ad2                	add	s5,s5,s4
ffffffffc0200614:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200618:	8a56                	mv	s4,s5
ffffffffc020061a:	bf2d                	j	ffffffffc0200554 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020061c:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200620:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200624:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200628:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020062c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200630:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200634:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200638:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200640:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200644:	00eaeab3          	or	s5,s5,a4
ffffffffc0200648:	00fb77b3          	and	a5,s6,a5
ffffffffc020064c:	00faeab3          	or	s5,s5,a5
ffffffffc0200650:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200652:	000c9c63          	bnez	s9,ffffffffc020066a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200656:	1a82                	slli	s5,s5,0x20
ffffffffc0200658:	00368793          	addi	a5,a3,3
ffffffffc020065c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200660:	9abe                	add	s5,s5,a5
ffffffffc0200662:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200666:	8a56                	mv	s4,s5
ffffffffc0200668:	b5f5                	j	ffffffffc0200554 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020066a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020066e:	85ca                	mv	a1,s2
ffffffffc0200670:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200672:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020067e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200682:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200686:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200688:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020068c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200690:	8d59                	or	a0,a0,a4
ffffffffc0200692:	00fb77b3          	and	a5,s6,a5
ffffffffc0200696:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200698:	1502                	slli	a0,a0,0x20
ffffffffc020069a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020069c:	9522                	add	a0,a0,s0
ffffffffc020069e:	2c4010ef          	jal	ra,ffffffffc0201962 <strcmp>
ffffffffc02006a2:	66a2                	ld	a3,8(sp)
ffffffffc02006a4:	f94d                	bnez	a0,ffffffffc0200656 <dtb_init+0x228>
ffffffffc02006a6:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200656 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006aa:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006ae:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006b2:	00002517          	auipc	a0,0x2
ffffffffc02006b6:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0202230 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc02006ba:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02006c2:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02006ca:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ce:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d6:	0187d693          	srli	a3,a5,0x18
ffffffffc02006da:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02006de:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006e2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02006ea:	010f6f33          	or	t5,t5,a6
ffffffffc02006ee:	0187529b          	srliw	t0,a4,0x18
ffffffffc02006f2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006fa:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fe:	0186f6b3          	and	a3,a3,s8
ffffffffc0200702:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200706:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020070e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200712:	8361                	srli	a4,a4,0x18
ffffffffc0200714:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200718:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020071c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200720:	00cb7633          	and	a2,s6,a2
ffffffffc0200724:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200728:	0085959b          	slliw	a1,a1,0x8
ffffffffc020072c:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200730:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200740:	011b78b3          	and	a7,s6,a7
ffffffffc0200744:	005eeeb3          	or	t4,t4,t0
ffffffffc0200748:	00c6e733          	or	a4,a3,a2
ffffffffc020074c:	006c6c33          	or	s8,s8,t1
ffffffffc0200750:	010b76b3          	and	a3,s6,a6
ffffffffc0200754:	00bb7b33          	and	s6,s6,a1
ffffffffc0200758:	01d7e7b3          	or	a5,a5,t4
ffffffffc020075c:	016c6b33          	or	s6,s8,s6
ffffffffc0200760:	01146433          	or	s0,s0,a7
ffffffffc0200764:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200766:	1702                	slli	a4,a4,0x20
ffffffffc0200768:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020076a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020076c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020076e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200770:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200774:	0167eb33          	or	s6,a5,s6
ffffffffc0200778:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020077a:	95fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020077e:	85a2                	mv	a1,s0
ffffffffc0200780:	00002517          	auipc	a0,0x2
ffffffffc0200784:	ad050513          	addi	a0,a0,-1328 # ffffffffc0202250 <commands+0xf8>
ffffffffc0200788:	951ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020078c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200790:	85da                	mv	a1,s6
ffffffffc0200792:	00002517          	auipc	a0,0x2
ffffffffc0200796:	ad650513          	addi	a0,a0,-1322 # ffffffffc0202268 <commands+0x110>
ffffffffc020079a:	93fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020079e:	008b05b3          	add	a1,s6,s0
ffffffffc02007a2:	15fd                	addi	a1,a1,-1
ffffffffc02007a4:	00002517          	auipc	a0,0x2
ffffffffc02007a8:	ae450513          	addi	a0,a0,-1308 # ffffffffc0202288 <commands+0x130>
ffffffffc02007ac:	92dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	b2850513          	addi	a0,a0,-1240 # ffffffffc02022d8 <commands+0x180>
        memory_base = mem_base;
ffffffffc02007b8:	00006797          	auipc	a5,0x6
ffffffffc02007bc:	c887b823          	sd	s0,-880(a5) # ffffffffc0206448 <memory_base>
        memory_size = mem_size;
ffffffffc02007c0:	00006797          	auipc	a5,0x6
ffffffffc02007c4:	c967b823          	sd	s6,-880(a5) # ffffffffc0206450 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02007c8:	b3f5                	j	ffffffffc02005b4 <dtb_init+0x186>

ffffffffc02007ca <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007ca:	00006517          	auipc	a0,0x6
ffffffffc02007ce:	c7e53503          	ld	a0,-898(a0) # ffffffffc0206448 <memory_base>
ffffffffc02007d2:	8082                	ret

ffffffffc02007d4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007d4:	00006517          	auipc	a0,0x6
ffffffffc02007d8:	c7c53503          	ld	a0,-900(a0) # ffffffffc0206450 <memory_size>
ffffffffc02007dc:	8082                	ret

ffffffffc02007de <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc02007de:	1141                	addi	sp,sp,-16
ffffffffc02007e0:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc02007e2:	02000793          	li	a5,32
ffffffffc02007e6:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02007ea:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02007ee:	67e1                	lui	a5,0x18
ffffffffc02007f0:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02007f4:	953e                	add	a0,a0,a5
ffffffffc02007f6:	5e0010ef          	jal	ra,ffffffffc0201dd6 <sbi_set_timer>
}
ffffffffc02007fa:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc02007fc:	00006797          	auipc	a5,0x6
ffffffffc0200800:	c407be23          	sd	zero,-932(a5) # ffffffffc0206458 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200804:	00002517          	auipc	a0,0x2
ffffffffc0200808:	aec50513          	addi	a0,a0,-1300 # ffffffffc02022f0 <commands+0x198>
}
ffffffffc020080c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020080e:	8cbff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200812 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200812:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200816:	67e1                	lui	a5,0x18
ffffffffc0200818:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020081c:	953e                	add	a0,a0,a5
ffffffffc020081e:	5b80106f          	j	ffffffffc0201dd6 <sbi_set_timer>

ffffffffc0200822 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200824:	0ff57513          	zext.b	a0,a0
ffffffffc0200828:	5940106f          	j	ffffffffc0201dbc <sbi_console_putchar>

ffffffffc020082c <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020082c:	5c40106f          	j	ffffffffc0201df0 <sbi_console_getchar>

ffffffffc0200830 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200830:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200834:	8082                	ret

ffffffffc0200836 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200836:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020083a:	8082                	ret

ffffffffc020083c <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020083c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200840:	00000797          	auipc	a5,0x0
ffffffffc0200844:	39478793          	addi	a5,a5,916 # ffffffffc0200bd4 <__alltraps>
ffffffffc0200848:	10579073          	csrw	stvec,a5
}
ffffffffc020084c:	8082                	ret

ffffffffc020084e <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020084e:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200850:	1141                	addi	sp,sp,-16
ffffffffc0200852:	e022                	sd	s0,0(sp)
ffffffffc0200854:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200856:	00002517          	auipc	a0,0x2
ffffffffc020085a:	aba50513          	addi	a0,a0,-1350 # ffffffffc0202310 <commands+0x1b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020085e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200860:	879ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200864:	640c                	ld	a1,8(s0)
ffffffffc0200866:	00002517          	auipc	a0,0x2
ffffffffc020086a:	ac250513          	addi	a0,a0,-1342 # ffffffffc0202328 <commands+0x1d0>
ffffffffc020086e:	86bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200872:	680c                	ld	a1,16(s0)
ffffffffc0200874:	00002517          	auipc	a0,0x2
ffffffffc0200878:	acc50513          	addi	a0,a0,-1332 # ffffffffc0202340 <commands+0x1e8>
ffffffffc020087c:	85dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200880:	6c0c                	ld	a1,24(s0)
ffffffffc0200882:	00002517          	auipc	a0,0x2
ffffffffc0200886:	ad650513          	addi	a0,a0,-1322 # ffffffffc0202358 <commands+0x200>
ffffffffc020088a:	84fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020088e:	700c                	ld	a1,32(s0)
ffffffffc0200890:	00002517          	auipc	a0,0x2
ffffffffc0200894:	ae050513          	addi	a0,a0,-1312 # ffffffffc0202370 <commands+0x218>
ffffffffc0200898:	841ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020089c:	740c                	ld	a1,40(s0)
ffffffffc020089e:	00002517          	auipc	a0,0x2
ffffffffc02008a2:	aea50513          	addi	a0,a0,-1302 # ffffffffc0202388 <commands+0x230>
ffffffffc02008a6:	833ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008aa:	780c                	ld	a1,48(s0)
ffffffffc02008ac:	00002517          	auipc	a0,0x2
ffffffffc02008b0:	af450513          	addi	a0,a0,-1292 # ffffffffc02023a0 <commands+0x248>
ffffffffc02008b4:	825ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008b8:	7c0c                	ld	a1,56(s0)
ffffffffc02008ba:	00002517          	auipc	a0,0x2
ffffffffc02008be:	afe50513          	addi	a0,a0,-1282 # ffffffffc02023b8 <commands+0x260>
ffffffffc02008c2:	817ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008c6:	602c                	ld	a1,64(s0)
ffffffffc02008c8:	00002517          	auipc	a0,0x2
ffffffffc02008cc:	b0850513          	addi	a0,a0,-1272 # ffffffffc02023d0 <commands+0x278>
ffffffffc02008d0:	809ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008d4:	642c                	ld	a1,72(s0)
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	b1250513          	addi	a0,a0,-1262 # ffffffffc02023e8 <commands+0x290>
ffffffffc02008de:	ffaff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e2:	682c                	ld	a1,80(s0)
ffffffffc02008e4:	00002517          	auipc	a0,0x2
ffffffffc02008e8:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0202400 <commands+0x2a8>
ffffffffc02008ec:	fecff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008f0:	6c2c                	ld	a1,88(s0)
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	b2650513          	addi	a0,a0,-1242 # ffffffffc0202418 <commands+0x2c0>
ffffffffc02008fa:	fdeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008fe:	702c                	ld	a1,96(s0)
ffffffffc0200900:	00002517          	auipc	a0,0x2
ffffffffc0200904:	b3050513          	addi	a0,a0,-1232 # ffffffffc0202430 <commands+0x2d8>
ffffffffc0200908:	fd0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020090c:	742c                	ld	a1,104(s0)
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0202448 <commands+0x2f0>
ffffffffc0200916:	fc2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020091a:	782c                	ld	a1,112(s0)
ffffffffc020091c:	00002517          	auipc	a0,0x2
ffffffffc0200920:	b4450513          	addi	a0,a0,-1212 # ffffffffc0202460 <commands+0x308>
ffffffffc0200924:	fb4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200928:	7c2c                	ld	a1,120(s0)
ffffffffc020092a:	00002517          	auipc	a0,0x2
ffffffffc020092e:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0202478 <commands+0x320>
ffffffffc0200932:	fa6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200936:	604c                	ld	a1,128(s0)
ffffffffc0200938:	00002517          	auipc	a0,0x2
ffffffffc020093c:	b5850513          	addi	a0,a0,-1192 # ffffffffc0202490 <commands+0x338>
ffffffffc0200940:	f98ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200944:	644c                	ld	a1,136(s0)
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	b6250513          	addi	a0,a0,-1182 # ffffffffc02024a8 <commands+0x350>
ffffffffc020094e:	f8aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200952:	684c                	ld	a1,144(s0)
ffffffffc0200954:	00002517          	auipc	a0,0x2
ffffffffc0200958:	b6c50513          	addi	a0,a0,-1172 # ffffffffc02024c0 <commands+0x368>
ffffffffc020095c:	f7cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200960:	6c4c                	ld	a1,152(s0)
ffffffffc0200962:	00002517          	auipc	a0,0x2
ffffffffc0200966:	b7650513          	addi	a0,a0,-1162 # ffffffffc02024d8 <commands+0x380>
ffffffffc020096a:	f6eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020096e:	704c                	ld	a1,160(s0)
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	b8050513          	addi	a0,a0,-1152 # ffffffffc02024f0 <commands+0x398>
ffffffffc0200978:	f60ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020097c:	744c                	ld	a1,168(s0)
ffffffffc020097e:	00002517          	auipc	a0,0x2
ffffffffc0200982:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0202508 <commands+0x3b0>
ffffffffc0200986:	f52ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020098a:	784c                	ld	a1,176(s0)
ffffffffc020098c:	00002517          	auipc	a0,0x2
ffffffffc0200990:	b9450513          	addi	a0,a0,-1132 # ffffffffc0202520 <commands+0x3c8>
ffffffffc0200994:	f44ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200998:	7c4c                	ld	a1,184(s0)
ffffffffc020099a:	00002517          	auipc	a0,0x2
ffffffffc020099e:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0202538 <commands+0x3e0>
ffffffffc02009a2:	f36ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009a6:	606c                	ld	a1,192(s0)
ffffffffc02009a8:	00002517          	auipc	a0,0x2
ffffffffc02009ac:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202550 <commands+0x3f8>
ffffffffc02009b0:	f28ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009b4:	646c                	ld	a1,200(s0)
ffffffffc02009b6:	00002517          	auipc	a0,0x2
ffffffffc02009ba:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202568 <commands+0x410>
ffffffffc02009be:	f1aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c2:	686c                	ld	a1,208(s0)
ffffffffc02009c4:	00002517          	auipc	a0,0x2
ffffffffc02009c8:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0202580 <commands+0x428>
ffffffffc02009cc:	f0cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009d0:	6c6c                	ld	a1,216(s0)
ffffffffc02009d2:	00002517          	auipc	a0,0x2
ffffffffc02009d6:	bc650513          	addi	a0,a0,-1082 # ffffffffc0202598 <commands+0x440>
ffffffffc02009da:	efeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009de:	706c                	ld	a1,224(s0)
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	bd050513          	addi	a0,a0,-1072 # ffffffffc02025b0 <commands+0x458>
ffffffffc02009e8:	ef0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009ec:	746c                	ld	a1,232(s0)
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	bda50513          	addi	a0,a0,-1062 # ffffffffc02025c8 <commands+0x470>
ffffffffc02009f6:	ee2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009fa:	786c                	ld	a1,240(s0)
ffffffffc02009fc:	00002517          	auipc	a0,0x2
ffffffffc0200a00:	be450513          	addi	a0,a0,-1052 # ffffffffc02025e0 <commands+0x488>
ffffffffc0200a04:	ed4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a08:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a0a:	6402                	ld	s0,0(sp)
ffffffffc0200a0c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	bea50513          	addi	a0,a0,-1046 # ffffffffc02025f8 <commands+0x4a0>
}
ffffffffc0200a16:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a18:	ec0ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a1c <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a1c:	1141                	addi	sp,sp,-16
ffffffffc0200a1e:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a20:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a22:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a24:	00002517          	auipc	a0,0x2
ffffffffc0200a28:	bec50513          	addi	a0,a0,-1044 # ffffffffc0202610 <commands+0x4b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2c:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2e:	eaaff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a32:	8522                	mv	a0,s0
ffffffffc0200a34:	e1bff0ef          	jal	ra,ffffffffc020084e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a38:	10043583          	ld	a1,256(s0)
ffffffffc0200a3c:	00002517          	auipc	a0,0x2
ffffffffc0200a40:	bec50513          	addi	a0,a0,-1044 # ffffffffc0202628 <commands+0x4d0>
ffffffffc0200a44:	e94ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a48:	10843583          	ld	a1,264(s0)
ffffffffc0200a4c:	00002517          	auipc	a0,0x2
ffffffffc0200a50:	bf450513          	addi	a0,a0,-1036 # ffffffffc0202640 <commands+0x4e8>
ffffffffc0200a54:	e84ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a58:	11043583          	ld	a1,272(s0)
ffffffffc0200a5c:	00002517          	auipc	a0,0x2
ffffffffc0200a60:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0202658 <commands+0x500>
ffffffffc0200a64:	e74ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a68:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a6c:	6402                	ld	s0,0(sp)
ffffffffc0200a6e:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	c0050513          	addi	a0,a0,-1024 # ffffffffc0202670 <commands+0x518>
}
ffffffffc0200a78:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a7a:	e5eff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a7e <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a7e:	11853783          	ld	a5,280(a0)
ffffffffc0200a82:	472d                	li	a4,11
ffffffffc0200a84:	0786                	slli	a5,a5,0x1
ffffffffc0200a86:	8385                	srli	a5,a5,0x1
ffffffffc0200a88:	08f76363          	bltu	a4,a5,ffffffffc0200b0e <interrupt_handler+0x90>
ffffffffc0200a8c:	00002717          	auipc	a4,0x2
ffffffffc0200a90:	cc470713          	addi	a4,a4,-828 # ffffffffc0202750 <commands+0x5f8>
ffffffffc0200a94:	078a                	slli	a5,a5,0x2
ffffffffc0200a96:	97ba                	add	a5,a5,a4
ffffffffc0200a98:	439c                	lw	a5,0(a5)
ffffffffc0200a9a:	97ba                	add	a5,a5,a4
ffffffffc0200a9c:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a9e:	00002517          	auipc	a0,0x2
ffffffffc0200aa2:	c4a50513          	addi	a0,a0,-950 # ffffffffc02026e8 <commands+0x590>
ffffffffc0200aa6:	e32ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200aaa:	00002517          	auipc	a0,0x2
ffffffffc0200aae:	c1e50513          	addi	a0,a0,-994 # ffffffffc02026c8 <commands+0x570>
ffffffffc0200ab2:	e26ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ab6:	00002517          	auipc	a0,0x2
ffffffffc0200aba:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202688 <commands+0x530>
ffffffffc0200abe:	e1aff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ac2:	00002517          	auipc	a0,0x2
ffffffffc0200ac6:	c4650513          	addi	a0,a0,-954 # ffffffffc0202708 <commands+0x5b0>
ffffffffc0200aca:	e0eff06f          	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200ace:	1141                	addi	sp,sp,-16
ffffffffc0200ad0:	e406                	sd	ra,8(sp)
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
           
            // 设置下次时钟中断
            clock_set_next_event();
ffffffffc0200ad2:	d41ff0ef          	jal	ra,ffffffffc0200812 <clock_set_next_event>
            
            // 计数器加一
            ticks++;
ffffffffc0200ad6:	00006797          	auipc	a5,0x6
ffffffffc0200ada:	98278793          	addi	a5,a5,-1662 # ffffffffc0206458 <ticks>
ffffffffc0200ade:	6398                	ld	a4,0(a5)
ffffffffc0200ae0:	0705                	addi	a4,a4,1
ffffffffc0200ae2:	e398                	sd	a4,0(a5)
            
            // 定义一个静态变量来记录打印次数
            static int print_count = 0;
            
            // 当计数器加到100的时候，输出信息并重置计数器
            if (ticks % TICK_NUM == 0) {
ffffffffc0200ae4:	639c                	ld	a5,0(a5)
ffffffffc0200ae6:	06400713          	li	a4,100
ffffffffc0200aea:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200aee:	c38d                	beqz	a5,ffffffffc0200b10 <interrupt_handler+0x92>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200af0:	60a2                	ld	ra,8(sp)
ffffffffc0200af2:	0141                	addi	sp,sp,16
ffffffffc0200af4:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200af6:	00002517          	auipc	a0,0x2
ffffffffc0200afa:	c3a50513          	addi	a0,a0,-966 # ffffffffc0202730 <commands+0x5d8>
ffffffffc0200afe:	ddaff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	ba650513          	addi	a0,a0,-1114 # ffffffffc02026a8 <commands+0x550>
ffffffffc0200b0a:	dceff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200b0e:	b739                	j	ffffffffc0200a1c <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b10:	06400593          	li	a1,100
ffffffffc0200b14:	00002517          	auipc	a0,0x2
ffffffffc0200b18:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0202720 <commands+0x5c8>
ffffffffc0200b1c:	dbcff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
                print_count++;
ffffffffc0200b20:	00006717          	auipc	a4,0x6
ffffffffc0200b24:	94070713          	addi	a4,a4,-1728 # ffffffffc0206460 <print_count.0>
ffffffffc0200b28:	431c                	lw	a5,0(a4)
                if (print_count == 10) {
ffffffffc0200b2a:	46a9                	li	a3,10
                print_count++;
ffffffffc0200b2c:	0017861b          	addiw	a2,a5,1
ffffffffc0200b30:	c310                	sw	a2,0(a4)
                if (print_count == 10) {
ffffffffc0200b32:	fad61fe3          	bne	a2,a3,ffffffffc0200af0 <interrupt_handler+0x72>
}
ffffffffc0200b36:	60a2                	ld	ra,8(sp)
ffffffffc0200b38:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200b3a:	2d20106f          	j	ffffffffc0201e0c <sbi_shutdown>

ffffffffc0200b3e <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b3e:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b42:	1141                	addi	sp,sp,-16
ffffffffc0200b44:	e022                	sd	s0,0(sp)
ffffffffc0200b46:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b48:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b4a:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b4c:	04e78663          	beq	a5,a4,ffffffffc0200b98 <exception_handler+0x5a>
ffffffffc0200b50:	02f76c63          	bltu	a4,a5,ffffffffc0200b88 <exception_handler+0x4a>
ffffffffc0200b54:	4709                	li	a4,2
ffffffffc0200b56:	02e79563          	bne	a5,a4,ffffffffc0200b80 <exception_handler+0x42>
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            // 输出异常类型
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b5a:	00002517          	auipc	a0,0x2
ffffffffc0200b5e:	c2650513          	addi	a0,a0,-986 # ffffffffc0202780 <commands+0x628>
ffffffffc0200b62:	d76ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
            // 输出异常指令地址
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b66:	10843583          	ld	a1,264(s0)
ffffffffc0200b6a:	00002517          	auipc	a0,0x2
ffffffffc0200b6e:	c3e50513          	addi	a0,a0,-962 # ffffffffc02027a8 <commands+0x650>
ffffffffc0200b72:	d66ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
            // 更新epc寄存器，指向下一条指令（指令长度为4字节）
            tf->epc += 4;
ffffffffc0200b76:	10843783          	ld	a5,264(s0)
ffffffffc0200b7a:	0791                	addi	a5,a5,4
ffffffffc0200b7c:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b80:	60a2                	ld	ra,8(sp)
ffffffffc0200b82:	6402                	ld	s0,0(sp)
ffffffffc0200b84:	0141                	addi	sp,sp,16
ffffffffc0200b86:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b88:	17f1                	addi	a5,a5,-4
ffffffffc0200b8a:	471d                	li	a4,7
ffffffffc0200b8c:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b80 <exception_handler+0x42>
}
ffffffffc0200b90:	6402                	ld	s0,0(sp)
ffffffffc0200b92:	60a2                	ld	ra,8(sp)
ffffffffc0200b94:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b96:	b559                	j	ffffffffc0200a1c <print_trapframe>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200b98:	00002517          	auipc	a0,0x2
ffffffffc0200b9c:	c3850513          	addi	a0,a0,-968 # ffffffffc02027d0 <commands+0x678>
ffffffffc0200ba0:	d38ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200ba4:	10843583          	ld	a1,264(s0)
ffffffffc0200ba8:	00002517          	auipc	a0,0x2
ffffffffc0200bac:	c4850513          	addi	a0,a0,-952 # ffffffffc02027f0 <commands+0x698>
ffffffffc0200bb0:	d28ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
            tf->epc += 2;
ffffffffc0200bb4:	10843783          	ld	a5,264(s0)
}
ffffffffc0200bb8:	60a2                	ld	ra,8(sp)
            tf->epc += 2;
ffffffffc0200bba:	0789                	addi	a5,a5,2
ffffffffc0200bbc:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200bc0:	6402                	ld	s0,0(sp)
ffffffffc0200bc2:	0141                	addi	sp,sp,16
ffffffffc0200bc4:	8082                	ret

ffffffffc0200bc6 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200bc6:	11853783          	ld	a5,280(a0)
ffffffffc0200bca:	0007c363          	bltz	a5,ffffffffc0200bd0 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200bce:	bf85                	j	ffffffffc0200b3e <exception_handler>
        interrupt_handler(tf);
ffffffffc0200bd0:	b57d                	j	ffffffffc0200a7e <interrupt_handler>
	...

ffffffffc0200bd4 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200bd4:	14011073          	csrw	sscratch,sp
ffffffffc0200bd8:	712d                	addi	sp,sp,-288
ffffffffc0200bda:	e002                	sd	zero,0(sp)
ffffffffc0200bdc:	e406                	sd	ra,8(sp)
ffffffffc0200bde:	ec0e                	sd	gp,24(sp)
ffffffffc0200be0:	f012                	sd	tp,32(sp)
ffffffffc0200be2:	f416                	sd	t0,40(sp)
ffffffffc0200be4:	f81a                	sd	t1,48(sp)
ffffffffc0200be6:	fc1e                	sd	t2,56(sp)
ffffffffc0200be8:	e0a2                	sd	s0,64(sp)
ffffffffc0200bea:	e4a6                	sd	s1,72(sp)
ffffffffc0200bec:	e8aa                	sd	a0,80(sp)
ffffffffc0200bee:	ecae                	sd	a1,88(sp)
ffffffffc0200bf0:	f0b2                	sd	a2,96(sp)
ffffffffc0200bf2:	f4b6                	sd	a3,104(sp)
ffffffffc0200bf4:	f8ba                	sd	a4,112(sp)
ffffffffc0200bf6:	fcbe                	sd	a5,120(sp)
ffffffffc0200bf8:	e142                	sd	a6,128(sp)
ffffffffc0200bfa:	e546                	sd	a7,136(sp)
ffffffffc0200bfc:	e94a                	sd	s2,144(sp)
ffffffffc0200bfe:	ed4e                	sd	s3,152(sp)
ffffffffc0200c00:	f152                	sd	s4,160(sp)
ffffffffc0200c02:	f556                	sd	s5,168(sp)
ffffffffc0200c04:	f95a                	sd	s6,176(sp)
ffffffffc0200c06:	fd5e                	sd	s7,184(sp)
ffffffffc0200c08:	e1e2                	sd	s8,192(sp)
ffffffffc0200c0a:	e5e6                	sd	s9,200(sp)
ffffffffc0200c0c:	e9ea                	sd	s10,208(sp)
ffffffffc0200c0e:	edee                	sd	s11,216(sp)
ffffffffc0200c10:	f1f2                	sd	t3,224(sp)
ffffffffc0200c12:	f5f6                	sd	t4,232(sp)
ffffffffc0200c14:	f9fa                	sd	t5,240(sp)
ffffffffc0200c16:	fdfe                	sd	t6,248(sp)
ffffffffc0200c18:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c1c:	100024f3          	csrr	s1,sstatus
ffffffffc0200c20:	14102973          	csrr	s2,sepc
ffffffffc0200c24:	143029f3          	csrr	s3,stval
ffffffffc0200c28:	14202a73          	csrr	s4,scause
ffffffffc0200c2c:	e822                	sd	s0,16(sp)
ffffffffc0200c2e:	e226                	sd	s1,256(sp)
ffffffffc0200c30:	e64a                	sd	s2,264(sp)
ffffffffc0200c32:	ea4e                	sd	s3,272(sp)
ffffffffc0200c34:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c36:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c38:	f8fff0ef          	jal	ra,ffffffffc0200bc6 <trap>

ffffffffc0200c3c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c3c:	6492                	ld	s1,256(sp)
ffffffffc0200c3e:	6932                	ld	s2,264(sp)
ffffffffc0200c40:	10049073          	csrw	sstatus,s1
ffffffffc0200c44:	14191073          	csrw	sepc,s2
ffffffffc0200c48:	60a2                	ld	ra,8(sp)
ffffffffc0200c4a:	61e2                	ld	gp,24(sp)
ffffffffc0200c4c:	7202                	ld	tp,32(sp)
ffffffffc0200c4e:	72a2                	ld	t0,40(sp)
ffffffffc0200c50:	7342                	ld	t1,48(sp)
ffffffffc0200c52:	73e2                	ld	t2,56(sp)
ffffffffc0200c54:	6406                	ld	s0,64(sp)
ffffffffc0200c56:	64a6                	ld	s1,72(sp)
ffffffffc0200c58:	6546                	ld	a0,80(sp)
ffffffffc0200c5a:	65e6                	ld	a1,88(sp)
ffffffffc0200c5c:	7606                	ld	a2,96(sp)
ffffffffc0200c5e:	76a6                	ld	a3,104(sp)
ffffffffc0200c60:	7746                	ld	a4,112(sp)
ffffffffc0200c62:	77e6                	ld	a5,120(sp)
ffffffffc0200c64:	680a                	ld	a6,128(sp)
ffffffffc0200c66:	68aa                	ld	a7,136(sp)
ffffffffc0200c68:	694a                	ld	s2,144(sp)
ffffffffc0200c6a:	69ea                	ld	s3,152(sp)
ffffffffc0200c6c:	7a0a                	ld	s4,160(sp)
ffffffffc0200c6e:	7aaa                	ld	s5,168(sp)
ffffffffc0200c70:	7b4a                	ld	s6,176(sp)
ffffffffc0200c72:	7bea                	ld	s7,184(sp)
ffffffffc0200c74:	6c0e                	ld	s8,192(sp)
ffffffffc0200c76:	6cae                	ld	s9,200(sp)
ffffffffc0200c78:	6d4e                	ld	s10,208(sp)
ffffffffc0200c7a:	6dee                	ld	s11,216(sp)
ffffffffc0200c7c:	7e0e                	ld	t3,224(sp)
ffffffffc0200c7e:	7eae                	ld	t4,232(sp)
ffffffffc0200c80:	7f4e                	ld	t5,240(sp)
ffffffffc0200c82:	7fee                	ld	t6,248(sp)
ffffffffc0200c84:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c86:	10200073          	sret

ffffffffc0200c8a <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200c8a:	100027f3          	csrr	a5,sstatus
ffffffffc0200c8e:	8b89                	andi	a5,a5,2
ffffffffc0200c90:	e799                	bnez	a5,ffffffffc0200c9e <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200c92:	00005797          	auipc	a5,0x5
ffffffffc0200c96:	7e67b783          	ld	a5,2022(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200c9a:	6f9c                	ld	a5,24(a5)
ffffffffc0200c9c:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200c9e:	1141                	addi	sp,sp,-16
ffffffffc0200ca0:	e406                	sd	ra,8(sp)
ffffffffc0200ca2:	e022                	sd	s0,0(sp)
ffffffffc0200ca4:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200ca6:	b91ff0ef          	jal	ra,ffffffffc0200836 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200caa:	00005797          	auipc	a5,0x5
ffffffffc0200cae:	7ce7b783          	ld	a5,1998(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200cb2:	6f9c                	ld	a5,24(a5)
ffffffffc0200cb4:	8522                	mv	a0,s0
ffffffffc0200cb6:	9782                	jalr	a5
ffffffffc0200cb8:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200cba:	b77ff0ef          	jal	ra,ffffffffc0200830 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200cbe:	60a2                	ld	ra,8(sp)
ffffffffc0200cc0:	8522                	mv	a0,s0
ffffffffc0200cc2:	6402                	ld	s0,0(sp)
ffffffffc0200cc4:	0141                	addi	sp,sp,16
ffffffffc0200cc6:	8082                	ret

ffffffffc0200cc8 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200cc8:	100027f3          	csrr	a5,sstatus
ffffffffc0200ccc:	8b89                	andi	a5,a5,2
ffffffffc0200cce:	e799                	bnez	a5,ffffffffc0200cdc <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200cd0:	00005797          	auipc	a5,0x5
ffffffffc0200cd4:	7a87b783          	ld	a5,1960(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200cd8:	739c                	ld	a5,32(a5)
ffffffffc0200cda:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200cdc:	1101                	addi	sp,sp,-32
ffffffffc0200cde:	ec06                	sd	ra,24(sp)
ffffffffc0200ce0:	e822                	sd	s0,16(sp)
ffffffffc0200ce2:	e426                	sd	s1,8(sp)
ffffffffc0200ce4:	842a                	mv	s0,a0
ffffffffc0200ce6:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200ce8:	b4fff0ef          	jal	ra,ffffffffc0200836 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200cec:	00005797          	auipc	a5,0x5
ffffffffc0200cf0:	78c7b783          	ld	a5,1932(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200cf4:	739c                	ld	a5,32(a5)
ffffffffc0200cf6:	85a6                	mv	a1,s1
ffffffffc0200cf8:	8522                	mv	a0,s0
ffffffffc0200cfa:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200cfc:	6442                	ld	s0,16(sp)
ffffffffc0200cfe:	60e2                	ld	ra,24(sp)
ffffffffc0200d00:	64a2                	ld	s1,8(sp)
ffffffffc0200d02:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200d04:	b635                	j	ffffffffc0200830 <intr_enable>

ffffffffc0200d06 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200d06:	100027f3          	csrr	a5,sstatus
ffffffffc0200d0a:	8b89                	andi	a5,a5,2
ffffffffc0200d0c:	e799                	bnez	a5,ffffffffc0200d1a <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200d0e:	00005797          	auipc	a5,0x5
ffffffffc0200d12:	76a7b783          	ld	a5,1898(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200d16:	779c                	ld	a5,40(a5)
ffffffffc0200d18:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200d1a:	1141                	addi	sp,sp,-16
ffffffffc0200d1c:	e406                	sd	ra,8(sp)
ffffffffc0200d1e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200d20:	b17ff0ef          	jal	ra,ffffffffc0200836 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200d24:	00005797          	auipc	a5,0x5
ffffffffc0200d28:	7547b783          	ld	a5,1876(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0200d2c:	779c                	ld	a5,40(a5)
ffffffffc0200d2e:	9782                	jalr	a5
ffffffffc0200d30:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200d32:	affff0ef          	jal	ra,ffffffffc0200830 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200d36:	60a2                	ld	ra,8(sp)
ffffffffc0200d38:	8522                	mv	a0,s0
ffffffffc0200d3a:	6402                	ld	s0,0(sp)
ffffffffc0200d3c:	0141                	addi	sp,sp,16
ffffffffc0200d3e:	8082                	ret

ffffffffc0200d40 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200d40:	00002797          	auipc	a5,0x2
ffffffffc0200d44:	f6078793          	addi	a5,a5,-160 # ffffffffc0202ca0 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200d48:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200d4a:	7179                	addi	sp,sp,-48
ffffffffc0200d4c:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200d4e:	00002517          	auipc	a0,0x2
ffffffffc0200d52:	ac250513          	addi	a0,a0,-1342 # ffffffffc0202810 <commands+0x6b8>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200d56:	00005417          	auipc	s0,0x5
ffffffffc0200d5a:	72240413          	addi	s0,s0,1826 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc0200d5e:	f406                	sd	ra,40(sp)
ffffffffc0200d60:	ec26                	sd	s1,24(sp)
ffffffffc0200d62:	e44e                	sd	s3,8(sp)
ffffffffc0200d64:	e84a                	sd	s2,16(sp)
ffffffffc0200d66:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200d68:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200d6a:	b6eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc0200d6e:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200d70:	00005497          	auipc	s1,0x5
ffffffffc0200d74:	72048493          	addi	s1,s1,1824 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200d78:	679c                	ld	a5,8(a5)
ffffffffc0200d7a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200d7c:	57f5                	li	a5,-3
ffffffffc0200d7e:	07fa                	slli	a5,a5,0x1e
ffffffffc0200d80:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200d82:	a49ff0ef          	jal	ra,ffffffffc02007ca <get_memory_base>
ffffffffc0200d86:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200d88:	a4dff0ef          	jal	ra,ffffffffc02007d4 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200d8c:	16050163          	beqz	a0,ffffffffc0200eee <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200d90:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200d92:	00002517          	auipc	a0,0x2
ffffffffc0200d96:	ac650513          	addi	a0,a0,-1338 # ffffffffc0202858 <commands+0x700>
ffffffffc0200d9a:	b3eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200d9e:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200da2:	864e                	mv	a2,s3
ffffffffc0200da4:	fffa0693          	addi	a3,s4,-1
ffffffffc0200da8:	85ca                	mv	a1,s2
ffffffffc0200daa:	00002517          	auipc	a0,0x2
ffffffffc0200dae:	ac650513          	addi	a0,a0,-1338 # ffffffffc0202870 <commands+0x718>
ffffffffc0200db2:	b26ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200db6:	c80007b7          	lui	a5,0xc8000
ffffffffc0200dba:	8652                	mv	a2,s4
ffffffffc0200dbc:	0d47e863          	bltu	a5,s4,ffffffffc0200e8c <pmm_init+0x14c>
ffffffffc0200dc0:	00006797          	auipc	a5,0x6
ffffffffc0200dc4:	6df78793          	addi	a5,a5,1759 # ffffffffc020749f <end+0xfff>
ffffffffc0200dc8:	757d                	lui	a0,0xfffff
ffffffffc0200dca:	8d7d                	and	a0,a0,a5
ffffffffc0200dcc:	8231                	srli	a2,a2,0xc
ffffffffc0200dce:	00005597          	auipc	a1,0x5
ffffffffc0200dd2:	69a58593          	addi	a1,a1,1690 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200dd6:	00005817          	auipc	a6,0x5
ffffffffc0200dda:	69a80813          	addi	a6,a6,1690 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0200dde:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200de0:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200de4:	000807b7          	lui	a5,0x80
ffffffffc0200de8:	02f60663          	beq	a2,a5,ffffffffc0200e14 <pmm_init+0xd4>
ffffffffc0200dec:	4701                	li	a4,0
ffffffffc0200dee:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200df0:	4305                	li	t1,1
ffffffffc0200df2:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0200df6:	953a                	add	a0,a0,a4
ffffffffc0200df8:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc0200dfc:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e00:	6190                	ld	a2,0(a1)
ffffffffc0200e02:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0200e04:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e08:	011606b3          	add	a3,a2,a7
ffffffffc0200e0c:	02870713          	addi	a4,a4,40
ffffffffc0200e10:	fed7e3e3          	bltu	a5,a3,ffffffffc0200df6 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e14:	00261693          	slli	a3,a2,0x2
ffffffffc0200e18:	96b2                	add	a3,a3,a2
ffffffffc0200e1a:	fec007b7          	lui	a5,0xfec00
ffffffffc0200e1e:	97aa                	add	a5,a5,a0
ffffffffc0200e20:	068e                	slli	a3,a3,0x3
ffffffffc0200e22:	96be                	add	a3,a3,a5
ffffffffc0200e24:	c02007b7          	lui	a5,0xc0200
ffffffffc0200e28:	0af6e763          	bltu	a3,a5,ffffffffc0200ed6 <pmm_init+0x196>
ffffffffc0200e2c:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200e2e:	77fd                	lui	a5,0xfffff
ffffffffc0200e30:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e34:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200e36:	04b6ee63          	bltu	a3,a1,ffffffffc0200e92 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200e3a:	601c                	ld	a5,0(s0)
ffffffffc0200e3c:	7b9c                	ld	a5,48(a5)
ffffffffc0200e3e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200e40:	00002517          	auipc	a0,0x2
ffffffffc0200e44:	ab850513          	addi	a0,a0,-1352 # ffffffffc02028f8 <commands+0x7a0>
ffffffffc0200e48:	a90ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200e4c:	00004597          	auipc	a1,0x4
ffffffffc0200e50:	1b458593          	addi	a1,a1,436 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200e54:	00005797          	auipc	a5,0x5
ffffffffc0200e58:	62b7ba23          	sd	a1,1588(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e5c:	c02007b7          	lui	a5,0xc0200
ffffffffc0200e60:	0af5e363          	bltu	a1,a5,ffffffffc0200f06 <pmm_init+0x1c6>
ffffffffc0200e64:	6090                	ld	a2,0(s1)
}
ffffffffc0200e66:	7402                	ld	s0,32(sp)
ffffffffc0200e68:	70a2                	ld	ra,40(sp)
ffffffffc0200e6a:	64e2                	ld	s1,24(sp)
ffffffffc0200e6c:	6942                	ld	s2,16(sp)
ffffffffc0200e6e:	69a2                	ld	s3,8(sp)
ffffffffc0200e70:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e72:	40c58633          	sub	a2,a1,a2
ffffffffc0200e76:	00005797          	auipc	a5,0x5
ffffffffc0200e7a:	60c7b523          	sd	a2,1546(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200e7e:	00002517          	auipc	a0,0x2
ffffffffc0200e82:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0202918 <commands+0x7c0>
}
ffffffffc0200e86:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200e88:	a50ff06f          	j	ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200e8c:	c8000637          	lui	a2,0xc8000
ffffffffc0200e90:	bf05                	j	ffffffffc0200dc0 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200e92:	6705                	lui	a4,0x1
ffffffffc0200e94:	177d                	addi	a4,a4,-1
ffffffffc0200e96:	96ba                	add	a3,a3,a4
ffffffffc0200e98:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200e9a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200e9e:	02c7f063          	bgeu	a5,a2,ffffffffc0200ebe <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0200ea2:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200ea4:	fff80737          	lui	a4,0xfff80
ffffffffc0200ea8:	973e                	add	a4,a4,a5
ffffffffc0200eaa:	00271793          	slli	a5,a4,0x2
ffffffffc0200eae:	97ba                	add	a5,a5,a4
ffffffffc0200eb0:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200eb2:	8d95                	sub	a1,a1,a3
ffffffffc0200eb4:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200eb6:	81b1                	srli	a1,a1,0xc
ffffffffc0200eb8:	953e                	add	a0,a0,a5
ffffffffc0200eba:	9702                	jalr	a4
}
ffffffffc0200ebc:	bfbd                	j	ffffffffc0200e3a <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0200ebe:	00002617          	auipc	a2,0x2
ffffffffc0200ec2:	a0a60613          	addi	a2,a2,-1526 # ffffffffc02028c8 <commands+0x770>
ffffffffc0200ec6:	06b00593          	li	a1,107
ffffffffc0200eca:	00002517          	auipc	a0,0x2
ffffffffc0200ece:	a1e50513          	addi	a0,a0,-1506 # ffffffffc02028e8 <commands+0x790>
ffffffffc0200ed2:	a8eff0ef          	jal	ra,ffffffffc0200160 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200ed6:	00002617          	auipc	a2,0x2
ffffffffc0200eda:	9ca60613          	addi	a2,a2,-1590 # ffffffffc02028a0 <commands+0x748>
ffffffffc0200ede:	07100593          	li	a1,113
ffffffffc0200ee2:	00002517          	auipc	a0,0x2
ffffffffc0200ee6:	96650513          	addi	a0,a0,-1690 # ffffffffc0202848 <commands+0x6f0>
ffffffffc0200eea:	a76ff0ef          	jal	ra,ffffffffc0200160 <__panic>
        panic("DTB memory info not available");
ffffffffc0200eee:	00002617          	auipc	a2,0x2
ffffffffc0200ef2:	93a60613          	addi	a2,a2,-1734 # ffffffffc0202828 <commands+0x6d0>
ffffffffc0200ef6:	05a00593          	li	a1,90
ffffffffc0200efa:	00002517          	auipc	a0,0x2
ffffffffc0200efe:	94e50513          	addi	a0,a0,-1714 # ffffffffc0202848 <commands+0x6f0>
ffffffffc0200f02:	a5eff0ef          	jal	ra,ffffffffc0200160 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f06:	86ae                	mv	a3,a1
ffffffffc0200f08:	00002617          	auipc	a2,0x2
ffffffffc0200f0c:	99860613          	addi	a2,a2,-1640 # ffffffffc02028a0 <commands+0x748>
ffffffffc0200f10:	08c00593          	li	a1,140
ffffffffc0200f14:	00002517          	auipc	a0,0x2
ffffffffc0200f18:	93450513          	addi	a0,a0,-1740 # ffffffffc0202848 <commands+0x6f0>
ffffffffc0200f1c:	a44ff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0200f20 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f20:	00005797          	auipc	a5,0x5
ffffffffc0200f24:	10878793          	addi	a5,a5,264 # ffffffffc0206028 <free_area>
ffffffffc0200f28:	e79c                	sd	a5,8(a5)
ffffffffc0200f2a:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f2c:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f30:	8082                	ret

ffffffffc0200f32 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200f32:	00005517          	auipc	a0,0x5
ffffffffc0200f36:	10656503          	lwu	a0,262(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200f3a:	8082                	ret

ffffffffc0200f3c <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200f3c:	c14d                	beqz	a0,ffffffffc0200fde <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200f3e:	00005617          	auipc	a2,0x5
ffffffffc0200f42:	0ea60613          	addi	a2,a2,234 # ffffffffc0206028 <free_area>
ffffffffc0200f46:	01062803          	lw	a6,16(a2)
ffffffffc0200f4a:	86aa                	mv	a3,a0
ffffffffc0200f4c:	02081793          	slli	a5,a6,0x20
ffffffffc0200f50:	9381                	srli	a5,a5,0x20
ffffffffc0200f52:	08a7e463          	bltu	a5,a0,ffffffffc0200fda <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f56:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200f58:	0018059b          	addiw	a1,a6,1
ffffffffc0200f5c:	1582                	slli	a1,a1,0x20
ffffffffc0200f5e:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200f60:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f62:	06c78b63          	beq	a5,a2,ffffffffc0200fd8 <best_fit_alloc_pages+0x9c>
        if(p->property >= n && p->property < min_size){
ffffffffc0200f66:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200f6a:	00d76763          	bltu	a4,a3,ffffffffc0200f78 <best_fit_alloc_pages+0x3c>
ffffffffc0200f6e:	00b77563          	bgeu	a4,a1,ffffffffc0200f78 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200f72:	fe878513          	addi	a0,a5,-24
ffffffffc0200f76:	85ba                	mv	a1,a4
ffffffffc0200f78:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f7a:	fec796e3          	bne	a5,a2,ffffffffc0200f66 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200f7e:	cd29                	beqz	a0,ffffffffc0200fd8 <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200f80:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200f82:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200f84:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200f86:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200f8a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200f8c:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200f8e:	02059793          	slli	a5,a1,0x20
ffffffffc0200f92:	9381                	srli	a5,a5,0x20
ffffffffc0200f94:	02f6f863          	bgeu	a3,a5,ffffffffc0200fc4 <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200f98:	00269793          	slli	a5,a3,0x2
ffffffffc0200f9c:	97b6                	add	a5,a5,a3
ffffffffc0200f9e:	078e                	slli	a5,a5,0x3
ffffffffc0200fa0:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200fa2:	411585bb          	subw	a1,a1,a7
ffffffffc0200fa6:	cb8c                	sw	a1,16(a5)
ffffffffc0200fa8:	4689                	li	a3,2
ffffffffc0200faa:	00878593          	addi	a1,a5,8
ffffffffc0200fae:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200fb2:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200fb4:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200fb8:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200fbc:	e28c                	sd	a1,0(a3)
ffffffffc0200fbe:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200fc0:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200fc2:	ef98                	sd	a4,24(a5)
ffffffffc0200fc4:	4118083b          	subw	a6,a6,a7
ffffffffc0200fc8:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200fcc:	57f5                	li	a5,-3
ffffffffc0200fce:	00850713          	addi	a4,a0,8
ffffffffc0200fd2:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200fd6:	8082                	ret
}
ffffffffc0200fd8:	8082                	ret
        return NULL;
ffffffffc0200fda:	4501                	li	a0,0
ffffffffc0200fdc:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200fde:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200fe0:	00002697          	auipc	a3,0x2
ffffffffc0200fe4:	97868693          	addi	a3,a3,-1672 # ffffffffc0202958 <commands+0x800>
ffffffffc0200fe8:	00002617          	auipc	a2,0x2
ffffffffc0200fec:	97860613          	addi	a2,a2,-1672 # ffffffffc0202960 <commands+0x808>
ffffffffc0200ff0:	06500593          	li	a1,101
ffffffffc0200ff4:	00002517          	auipc	a0,0x2
ffffffffc0200ff8:	98450513          	addi	a0,a0,-1660 # ffffffffc0202978 <commands+0x820>
best_fit_alloc_pages(size_t n) {
ffffffffc0200ffc:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ffe:	962ff0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0201002 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0201002:	715d                	addi	sp,sp,-80
ffffffffc0201004:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0201006:	00005417          	auipc	s0,0x5
ffffffffc020100a:	02240413          	addi	s0,s0,34 # ffffffffc0206028 <free_area>
ffffffffc020100e:	641c                	ld	a5,8(s0)
ffffffffc0201010:	e486                	sd	ra,72(sp)
ffffffffc0201012:	fc26                	sd	s1,56(sp)
ffffffffc0201014:	f84a                	sd	s2,48(sp)
ffffffffc0201016:	f44e                	sd	s3,40(sp)
ffffffffc0201018:	f052                	sd	s4,32(sp)
ffffffffc020101a:	ec56                	sd	s5,24(sp)
ffffffffc020101c:	e85a                	sd	s6,16(sp)
ffffffffc020101e:	e45e                	sd	s7,8(sp)
ffffffffc0201020:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201022:	26878b63          	beq	a5,s0,ffffffffc0201298 <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0201026:	4481                	li	s1,0
ffffffffc0201028:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020102a:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020102e:	8b09                	andi	a4,a4,2
ffffffffc0201030:	26070863          	beqz	a4,ffffffffc02012a0 <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0201034:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201038:	679c                	ld	a5,8(a5)
ffffffffc020103a:	2905                	addiw	s2,s2,1
ffffffffc020103c:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020103e:	fe8796e3          	bne	a5,s0,ffffffffc020102a <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201042:	89a6                	mv	s3,s1
ffffffffc0201044:	cc3ff0ef          	jal	ra,ffffffffc0200d06 <nr_free_pages>
ffffffffc0201048:	33351c63          	bne	a0,s3,ffffffffc0201380 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020104c:	4505                	li	a0,1
ffffffffc020104e:	c3dff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc0201052:	8a2a                	mv	s4,a0
ffffffffc0201054:	36050663          	beqz	a0,ffffffffc02013c0 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201058:	4505                	li	a0,1
ffffffffc020105a:	c31ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc020105e:	89aa                	mv	s3,a0
ffffffffc0201060:	34050063          	beqz	a0,ffffffffc02013a0 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201064:	4505                	li	a0,1
ffffffffc0201066:	c25ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc020106a:	8aaa                	mv	s5,a0
ffffffffc020106c:	2c050a63          	beqz	a0,ffffffffc0201340 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201070:	253a0863          	beq	s4,s3,ffffffffc02012c0 <best_fit_check+0x2be>
ffffffffc0201074:	24aa0663          	beq	s4,a0,ffffffffc02012c0 <best_fit_check+0x2be>
ffffffffc0201078:	24a98463          	beq	s3,a0,ffffffffc02012c0 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020107c:	000a2783          	lw	a5,0(s4)
ffffffffc0201080:	26079063          	bnez	a5,ffffffffc02012e0 <best_fit_check+0x2de>
ffffffffc0201084:	0009a783          	lw	a5,0(s3)
ffffffffc0201088:	24079c63          	bnez	a5,ffffffffc02012e0 <best_fit_check+0x2de>
ffffffffc020108c:	411c                	lw	a5,0(a0)
ffffffffc020108e:	24079963          	bnez	a5,ffffffffc02012e0 <best_fit_check+0x2de>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201092:	00005797          	auipc	a5,0x5
ffffffffc0201096:	3de7b783          	ld	a5,990(a5) # ffffffffc0206470 <pages>
ffffffffc020109a:	40fa0733          	sub	a4,s4,a5
ffffffffc020109e:	870d                	srai	a4,a4,0x3
ffffffffc02010a0:	00002597          	auipc	a1,0x2
ffffffffc02010a4:	e885b583          	ld	a1,-376(a1) # ffffffffc0202f28 <nbase+0x8>
ffffffffc02010a8:	02b70733          	mul	a4,a4,a1
ffffffffc02010ac:	00002617          	auipc	a2,0x2
ffffffffc02010b0:	e7463603          	ld	a2,-396(a2) # ffffffffc0202f20 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010b4:	00005697          	auipc	a3,0x5
ffffffffc02010b8:	3b46b683          	ld	a3,948(a3) # ffffffffc0206468 <npage>
ffffffffc02010bc:	06b2                	slli	a3,a3,0xc
ffffffffc02010be:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010c0:	0732                	slli	a4,a4,0xc
ffffffffc02010c2:	22d77f63          	bgeu	a4,a3,ffffffffc0201300 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02010c6:	40f98733          	sub	a4,s3,a5
ffffffffc02010ca:	870d                	srai	a4,a4,0x3
ffffffffc02010cc:	02b70733          	mul	a4,a4,a1
ffffffffc02010d0:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010d2:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010d4:	3ed77663          	bgeu	a4,a3,ffffffffc02014c0 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02010d8:	40f507b3          	sub	a5,a0,a5
ffffffffc02010dc:	878d                	srai	a5,a5,0x3
ffffffffc02010de:	02b787b3          	mul	a5,a5,a1
ffffffffc02010e2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010e4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010e6:	3ad7fd63          	bgeu	a5,a3,ffffffffc02014a0 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc02010ea:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010ec:	00043c03          	ld	s8,0(s0)
ffffffffc02010f0:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02010f4:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02010f8:	e400                	sd	s0,8(s0)
ffffffffc02010fa:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02010fc:	00005797          	auipc	a5,0x5
ffffffffc0201100:	f207ae23          	sw	zero,-196(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201104:	b87ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc0201108:	36051c63          	bnez	a0,ffffffffc0201480 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc020110c:	4585                	li	a1,1
ffffffffc020110e:	8552                	mv	a0,s4
ffffffffc0201110:	bb9ff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    free_page(p1);
ffffffffc0201114:	4585                	li	a1,1
ffffffffc0201116:	854e                	mv	a0,s3
ffffffffc0201118:	bb1ff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    free_page(p2);
ffffffffc020111c:	4585                	li	a1,1
ffffffffc020111e:	8556                	mv	a0,s5
ffffffffc0201120:	ba9ff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    assert(nr_free == 3);
ffffffffc0201124:	4818                	lw	a4,16(s0)
ffffffffc0201126:	478d                	li	a5,3
ffffffffc0201128:	32f71c63          	bne	a4,a5,ffffffffc0201460 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020112c:	4505                	li	a0,1
ffffffffc020112e:	b5dff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc0201132:	89aa                	mv	s3,a0
ffffffffc0201134:	30050663          	beqz	a0,ffffffffc0201440 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201138:	4505                	li	a0,1
ffffffffc020113a:	b51ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc020113e:	8aaa                	mv	s5,a0
ffffffffc0201140:	2e050063          	beqz	a0,ffffffffc0201420 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201144:	4505                	li	a0,1
ffffffffc0201146:	b45ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc020114a:	8a2a                	mv	s4,a0
ffffffffc020114c:	2a050a63          	beqz	a0,ffffffffc0201400 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0201150:	4505                	li	a0,1
ffffffffc0201152:	b39ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc0201156:	28051563          	bnez	a0,ffffffffc02013e0 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc020115a:	4585                	li	a1,1
ffffffffc020115c:	854e                	mv	a0,s3
ffffffffc020115e:	b6bff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201162:	641c                	ld	a5,8(s0)
ffffffffc0201164:	1a878e63          	beq	a5,s0,ffffffffc0201320 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0201168:	4505                	li	a0,1
ffffffffc020116a:	b21ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc020116e:	52a99963          	bne	s3,a0,ffffffffc02016a0 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0201172:	4505                	li	a0,1
ffffffffc0201174:	b17ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc0201178:	50051463          	bnez	a0,ffffffffc0201680 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc020117c:	481c                	lw	a5,16(s0)
ffffffffc020117e:	4e079163          	bnez	a5,ffffffffc0201660 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0201182:	854e                	mv	a0,s3
ffffffffc0201184:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201186:	01843023          	sd	s8,0(s0)
ffffffffc020118a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020118e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201192:	b37ff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    free_page(p1);
ffffffffc0201196:	4585                	li	a1,1
ffffffffc0201198:	8556                	mv	a0,s5
ffffffffc020119a:	b2fff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    free_page(p2);
ffffffffc020119e:	4585                	li	a1,1
ffffffffc02011a0:	8552                	mv	a0,s4
ffffffffc02011a2:	b27ff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02011a6:	4515                	li	a0,5
ffffffffc02011a8:	ae3ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc02011ac:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02011ae:	48050963          	beqz	a0,ffffffffc0201640 <best_fit_check+0x63e>
ffffffffc02011b2:	651c                	ld	a5,8(a0)
ffffffffc02011b4:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc02011b6:	8b85                	andi	a5,a5,1
ffffffffc02011b8:	46079463          	bnez	a5,ffffffffc0201620 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02011bc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011be:	00043a83          	ld	s5,0(s0)
ffffffffc02011c2:	00843a03          	ld	s4,8(s0)
ffffffffc02011c6:	e000                	sd	s0,0(s0)
ffffffffc02011c8:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02011ca:	ac1ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc02011ce:	42051963          	bnez	a0,ffffffffc0201600 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc02011d2:	4589                	li	a1,2
ffffffffc02011d4:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc02011d8:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc02011dc:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc02011e0:	00005797          	auipc	a5,0x5
ffffffffc02011e4:	e407ac23          	sw	zero,-424(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc02011e8:	ae1ff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc02011ec:	8562                	mv	a0,s8
ffffffffc02011ee:	4585                	li	a1,1
ffffffffc02011f0:	ad9ff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02011f4:	4511                	li	a0,4
ffffffffc02011f6:	a95ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc02011fa:	3e051363          	bnez	a0,ffffffffc02015e0 <best_fit_check+0x5de>
ffffffffc02011fe:	0309b783          	ld	a5,48(s3)
ffffffffc0201202:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201204:	8b85                	andi	a5,a5,1
ffffffffc0201206:	3a078d63          	beqz	a5,ffffffffc02015c0 <best_fit_check+0x5be>
ffffffffc020120a:	0389a703          	lw	a4,56(s3)
ffffffffc020120e:	4789                	li	a5,2
ffffffffc0201210:	3af71863          	bne	a4,a5,ffffffffc02015c0 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201214:	4505                	li	a0,1
ffffffffc0201216:	a75ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc020121a:	8baa                	mv	s7,a0
ffffffffc020121c:	38050263          	beqz	a0,ffffffffc02015a0 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0201220:	4509                	li	a0,2
ffffffffc0201222:	a69ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc0201226:	34050d63          	beqz	a0,ffffffffc0201580 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc020122a:	337c1b63          	bne	s8,s7,ffffffffc0201560 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc020122e:	854e                	mv	a0,s3
ffffffffc0201230:	4595                	li	a1,5
ffffffffc0201232:	a97ff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201236:	4515                	li	a0,5
ffffffffc0201238:	a53ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc020123c:	89aa                	mv	s3,a0
ffffffffc020123e:	30050163          	beqz	a0,ffffffffc0201540 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0201242:	4505                	li	a0,1
ffffffffc0201244:	a47ff0ef          	jal	ra,ffffffffc0200c8a <alloc_pages>
ffffffffc0201248:	2c051c63          	bnez	a0,ffffffffc0201520 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc020124c:	481c                	lw	a5,16(s0)
ffffffffc020124e:	2a079963          	bnez	a5,ffffffffc0201500 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201252:	4595                	li	a1,5
ffffffffc0201254:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201256:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc020125a:	01543023          	sd	s5,0(s0)
ffffffffc020125e:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0201262:	a67ff0ef          	jal	ra,ffffffffc0200cc8 <free_pages>
    return listelm->next;
ffffffffc0201266:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201268:	00878963          	beq	a5,s0,ffffffffc020127a <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020126c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201270:	679c                	ld	a5,8(a5)
ffffffffc0201272:	397d                	addiw	s2,s2,-1
ffffffffc0201274:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201276:	fe879be3          	bne	a5,s0,ffffffffc020126c <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc020127a:	26091363          	bnez	s2,ffffffffc02014e0 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc020127e:	e0ed                	bnez	s1,ffffffffc0201360 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0201280:	60a6                	ld	ra,72(sp)
ffffffffc0201282:	6406                	ld	s0,64(sp)
ffffffffc0201284:	74e2                	ld	s1,56(sp)
ffffffffc0201286:	7942                	ld	s2,48(sp)
ffffffffc0201288:	79a2                	ld	s3,40(sp)
ffffffffc020128a:	7a02                	ld	s4,32(sp)
ffffffffc020128c:	6ae2                	ld	s5,24(sp)
ffffffffc020128e:	6b42                	ld	s6,16(sp)
ffffffffc0201290:	6ba2                	ld	s7,8(sp)
ffffffffc0201292:	6c02                	ld	s8,0(sp)
ffffffffc0201294:	6161                	addi	sp,sp,80
ffffffffc0201296:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201298:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020129a:	4481                	li	s1,0
ffffffffc020129c:	4901                	li	s2,0
ffffffffc020129e:	b35d                	j	ffffffffc0201044 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc02012a0:	00001697          	auipc	a3,0x1
ffffffffc02012a4:	6f068693          	addi	a3,a3,1776 # ffffffffc0202990 <commands+0x838>
ffffffffc02012a8:	00001617          	auipc	a2,0x1
ffffffffc02012ac:	6b860613          	addi	a2,a2,1720 # ffffffffc0202960 <commands+0x808>
ffffffffc02012b0:	0f900593          	li	a1,249
ffffffffc02012b4:	00001517          	auipc	a0,0x1
ffffffffc02012b8:	6c450513          	addi	a0,a0,1732 # ffffffffc0202978 <commands+0x820>
ffffffffc02012bc:	ea5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012c0:	00001697          	auipc	a3,0x1
ffffffffc02012c4:	76068693          	addi	a3,a3,1888 # ffffffffc0202a20 <commands+0x8c8>
ffffffffc02012c8:	00001617          	auipc	a2,0x1
ffffffffc02012cc:	69860613          	addi	a2,a2,1688 # ffffffffc0202960 <commands+0x808>
ffffffffc02012d0:	0c500593          	li	a1,197
ffffffffc02012d4:	00001517          	auipc	a0,0x1
ffffffffc02012d8:	6a450513          	addi	a0,a0,1700 # ffffffffc0202978 <commands+0x820>
ffffffffc02012dc:	e85fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012e0:	00001697          	auipc	a3,0x1
ffffffffc02012e4:	76868693          	addi	a3,a3,1896 # ffffffffc0202a48 <commands+0x8f0>
ffffffffc02012e8:	00001617          	auipc	a2,0x1
ffffffffc02012ec:	67860613          	addi	a2,a2,1656 # ffffffffc0202960 <commands+0x808>
ffffffffc02012f0:	0c600593          	li	a1,198
ffffffffc02012f4:	00001517          	auipc	a0,0x1
ffffffffc02012f8:	68450513          	addi	a0,a0,1668 # ffffffffc0202978 <commands+0x820>
ffffffffc02012fc:	e65fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201300:	00001697          	auipc	a3,0x1
ffffffffc0201304:	78868693          	addi	a3,a3,1928 # ffffffffc0202a88 <commands+0x930>
ffffffffc0201308:	00001617          	auipc	a2,0x1
ffffffffc020130c:	65860613          	addi	a2,a2,1624 # ffffffffc0202960 <commands+0x808>
ffffffffc0201310:	0c800593          	li	a1,200
ffffffffc0201314:	00001517          	auipc	a0,0x1
ffffffffc0201318:	66450513          	addi	a0,a0,1636 # ffffffffc0202978 <commands+0x820>
ffffffffc020131c:	e45fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201320:	00001697          	auipc	a3,0x1
ffffffffc0201324:	7f068693          	addi	a3,a3,2032 # ffffffffc0202b10 <commands+0x9b8>
ffffffffc0201328:	00001617          	auipc	a2,0x1
ffffffffc020132c:	63860613          	addi	a2,a2,1592 # ffffffffc0202960 <commands+0x808>
ffffffffc0201330:	0e100593          	li	a1,225
ffffffffc0201334:	00001517          	auipc	a0,0x1
ffffffffc0201338:	64450513          	addi	a0,a0,1604 # ffffffffc0202978 <commands+0x820>
ffffffffc020133c:	e25fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201340:	00001697          	auipc	a3,0x1
ffffffffc0201344:	6c068693          	addi	a3,a3,1728 # ffffffffc0202a00 <commands+0x8a8>
ffffffffc0201348:	00001617          	auipc	a2,0x1
ffffffffc020134c:	61860613          	addi	a2,a2,1560 # ffffffffc0202960 <commands+0x808>
ffffffffc0201350:	0c300593          	li	a1,195
ffffffffc0201354:	00001517          	auipc	a0,0x1
ffffffffc0201358:	62450513          	addi	a0,a0,1572 # ffffffffc0202978 <commands+0x820>
ffffffffc020135c:	e05fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(total == 0);
ffffffffc0201360:	00002697          	auipc	a3,0x2
ffffffffc0201364:	8e068693          	addi	a3,a3,-1824 # ffffffffc0202c40 <commands+0xae8>
ffffffffc0201368:	00001617          	auipc	a2,0x1
ffffffffc020136c:	5f860613          	addi	a2,a2,1528 # ffffffffc0202960 <commands+0x808>
ffffffffc0201370:	13b00593          	li	a1,315
ffffffffc0201374:	00001517          	auipc	a0,0x1
ffffffffc0201378:	60450513          	addi	a0,a0,1540 # ffffffffc0202978 <commands+0x820>
ffffffffc020137c:	de5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201380:	00001697          	auipc	a3,0x1
ffffffffc0201384:	62068693          	addi	a3,a3,1568 # ffffffffc02029a0 <commands+0x848>
ffffffffc0201388:	00001617          	auipc	a2,0x1
ffffffffc020138c:	5d860613          	addi	a2,a2,1496 # ffffffffc0202960 <commands+0x808>
ffffffffc0201390:	0fc00593          	li	a1,252
ffffffffc0201394:	00001517          	auipc	a0,0x1
ffffffffc0201398:	5e450513          	addi	a0,a0,1508 # ffffffffc0202978 <commands+0x820>
ffffffffc020139c:	dc5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013a0:	00001697          	auipc	a3,0x1
ffffffffc02013a4:	64068693          	addi	a3,a3,1600 # ffffffffc02029e0 <commands+0x888>
ffffffffc02013a8:	00001617          	auipc	a2,0x1
ffffffffc02013ac:	5b860613          	addi	a2,a2,1464 # ffffffffc0202960 <commands+0x808>
ffffffffc02013b0:	0c200593          	li	a1,194
ffffffffc02013b4:	00001517          	auipc	a0,0x1
ffffffffc02013b8:	5c450513          	addi	a0,a0,1476 # ffffffffc0202978 <commands+0x820>
ffffffffc02013bc:	da5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013c0:	00001697          	auipc	a3,0x1
ffffffffc02013c4:	60068693          	addi	a3,a3,1536 # ffffffffc02029c0 <commands+0x868>
ffffffffc02013c8:	00001617          	auipc	a2,0x1
ffffffffc02013cc:	59860613          	addi	a2,a2,1432 # ffffffffc0202960 <commands+0x808>
ffffffffc02013d0:	0c100593          	li	a1,193
ffffffffc02013d4:	00001517          	auipc	a0,0x1
ffffffffc02013d8:	5a450513          	addi	a0,a0,1444 # ffffffffc0202978 <commands+0x820>
ffffffffc02013dc:	d85fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013e0:	00001697          	auipc	a3,0x1
ffffffffc02013e4:	70868693          	addi	a3,a3,1800 # ffffffffc0202ae8 <commands+0x990>
ffffffffc02013e8:	00001617          	auipc	a2,0x1
ffffffffc02013ec:	57860613          	addi	a2,a2,1400 # ffffffffc0202960 <commands+0x808>
ffffffffc02013f0:	0de00593          	li	a1,222
ffffffffc02013f4:	00001517          	auipc	a0,0x1
ffffffffc02013f8:	58450513          	addi	a0,a0,1412 # ffffffffc0202978 <commands+0x820>
ffffffffc02013fc:	d65fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201400:	00001697          	auipc	a3,0x1
ffffffffc0201404:	60068693          	addi	a3,a3,1536 # ffffffffc0202a00 <commands+0x8a8>
ffffffffc0201408:	00001617          	auipc	a2,0x1
ffffffffc020140c:	55860613          	addi	a2,a2,1368 # ffffffffc0202960 <commands+0x808>
ffffffffc0201410:	0dc00593          	li	a1,220
ffffffffc0201414:	00001517          	auipc	a0,0x1
ffffffffc0201418:	56450513          	addi	a0,a0,1380 # ffffffffc0202978 <commands+0x820>
ffffffffc020141c:	d45fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201420:	00001697          	auipc	a3,0x1
ffffffffc0201424:	5c068693          	addi	a3,a3,1472 # ffffffffc02029e0 <commands+0x888>
ffffffffc0201428:	00001617          	auipc	a2,0x1
ffffffffc020142c:	53860613          	addi	a2,a2,1336 # ffffffffc0202960 <commands+0x808>
ffffffffc0201430:	0db00593          	li	a1,219
ffffffffc0201434:	00001517          	auipc	a0,0x1
ffffffffc0201438:	54450513          	addi	a0,a0,1348 # ffffffffc0202978 <commands+0x820>
ffffffffc020143c:	d25fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201440:	00001697          	auipc	a3,0x1
ffffffffc0201444:	58068693          	addi	a3,a3,1408 # ffffffffc02029c0 <commands+0x868>
ffffffffc0201448:	00001617          	auipc	a2,0x1
ffffffffc020144c:	51860613          	addi	a2,a2,1304 # ffffffffc0202960 <commands+0x808>
ffffffffc0201450:	0da00593          	li	a1,218
ffffffffc0201454:	00001517          	auipc	a0,0x1
ffffffffc0201458:	52450513          	addi	a0,a0,1316 # ffffffffc0202978 <commands+0x820>
ffffffffc020145c:	d05fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 3);
ffffffffc0201460:	00001697          	auipc	a3,0x1
ffffffffc0201464:	6a068693          	addi	a3,a3,1696 # ffffffffc0202b00 <commands+0x9a8>
ffffffffc0201468:	00001617          	auipc	a2,0x1
ffffffffc020146c:	4f860613          	addi	a2,a2,1272 # ffffffffc0202960 <commands+0x808>
ffffffffc0201470:	0d800593          	li	a1,216
ffffffffc0201474:	00001517          	auipc	a0,0x1
ffffffffc0201478:	50450513          	addi	a0,a0,1284 # ffffffffc0202978 <commands+0x820>
ffffffffc020147c:	ce5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201480:	00001697          	auipc	a3,0x1
ffffffffc0201484:	66868693          	addi	a3,a3,1640 # ffffffffc0202ae8 <commands+0x990>
ffffffffc0201488:	00001617          	auipc	a2,0x1
ffffffffc020148c:	4d860613          	addi	a2,a2,1240 # ffffffffc0202960 <commands+0x808>
ffffffffc0201490:	0d300593          	li	a1,211
ffffffffc0201494:	00001517          	auipc	a0,0x1
ffffffffc0201498:	4e450513          	addi	a0,a0,1252 # ffffffffc0202978 <commands+0x820>
ffffffffc020149c:	cc5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02014a0:	00001697          	auipc	a3,0x1
ffffffffc02014a4:	62868693          	addi	a3,a3,1576 # ffffffffc0202ac8 <commands+0x970>
ffffffffc02014a8:	00001617          	auipc	a2,0x1
ffffffffc02014ac:	4b860613          	addi	a2,a2,1208 # ffffffffc0202960 <commands+0x808>
ffffffffc02014b0:	0ca00593          	li	a1,202
ffffffffc02014b4:	00001517          	auipc	a0,0x1
ffffffffc02014b8:	4c450513          	addi	a0,a0,1220 # ffffffffc0202978 <commands+0x820>
ffffffffc02014bc:	ca5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02014c0:	00001697          	auipc	a3,0x1
ffffffffc02014c4:	5e868693          	addi	a3,a3,1512 # ffffffffc0202aa8 <commands+0x950>
ffffffffc02014c8:	00001617          	auipc	a2,0x1
ffffffffc02014cc:	49860613          	addi	a2,a2,1176 # ffffffffc0202960 <commands+0x808>
ffffffffc02014d0:	0c900593          	li	a1,201
ffffffffc02014d4:	00001517          	auipc	a0,0x1
ffffffffc02014d8:	4a450513          	addi	a0,a0,1188 # ffffffffc0202978 <commands+0x820>
ffffffffc02014dc:	c85fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(count == 0);
ffffffffc02014e0:	00001697          	auipc	a3,0x1
ffffffffc02014e4:	75068693          	addi	a3,a3,1872 # ffffffffc0202c30 <commands+0xad8>
ffffffffc02014e8:	00001617          	auipc	a2,0x1
ffffffffc02014ec:	47860613          	addi	a2,a2,1144 # ffffffffc0202960 <commands+0x808>
ffffffffc02014f0:	13a00593          	li	a1,314
ffffffffc02014f4:	00001517          	auipc	a0,0x1
ffffffffc02014f8:	48450513          	addi	a0,a0,1156 # ffffffffc0202978 <commands+0x820>
ffffffffc02014fc:	c65fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 0);
ffffffffc0201500:	00001697          	auipc	a3,0x1
ffffffffc0201504:	64868693          	addi	a3,a3,1608 # ffffffffc0202b48 <commands+0x9f0>
ffffffffc0201508:	00001617          	auipc	a2,0x1
ffffffffc020150c:	45860613          	addi	a2,a2,1112 # ffffffffc0202960 <commands+0x808>
ffffffffc0201510:	12f00593          	li	a1,303
ffffffffc0201514:	00001517          	auipc	a0,0x1
ffffffffc0201518:	46450513          	addi	a0,a0,1124 # ffffffffc0202978 <commands+0x820>
ffffffffc020151c:	c45fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201520:	00001697          	auipc	a3,0x1
ffffffffc0201524:	5c868693          	addi	a3,a3,1480 # ffffffffc0202ae8 <commands+0x990>
ffffffffc0201528:	00001617          	auipc	a2,0x1
ffffffffc020152c:	43860613          	addi	a2,a2,1080 # ffffffffc0202960 <commands+0x808>
ffffffffc0201530:	12900593          	li	a1,297
ffffffffc0201534:	00001517          	auipc	a0,0x1
ffffffffc0201538:	44450513          	addi	a0,a0,1092 # ffffffffc0202978 <commands+0x820>
ffffffffc020153c:	c25fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201540:	00001697          	auipc	a3,0x1
ffffffffc0201544:	6d068693          	addi	a3,a3,1744 # ffffffffc0202c10 <commands+0xab8>
ffffffffc0201548:	00001617          	auipc	a2,0x1
ffffffffc020154c:	41860613          	addi	a2,a2,1048 # ffffffffc0202960 <commands+0x808>
ffffffffc0201550:	12800593          	li	a1,296
ffffffffc0201554:	00001517          	auipc	a0,0x1
ffffffffc0201558:	42450513          	addi	a0,a0,1060 # ffffffffc0202978 <commands+0x820>
ffffffffc020155c:	c05fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0201560:	00001697          	auipc	a3,0x1
ffffffffc0201564:	6a068693          	addi	a3,a3,1696 # ffffffffc0202c00 <commands+0xaa8>
ffffffffc0201568:	00001617          	auipc	a2,0x1
ffffffffc020156c:	3f860613          	addi	a2,a2,1016 # ffffffffc0202960 <commands+0x808>
ffffffffc0201570:	12000593          	li	a1,288
ffffffffc0201574:	00001517          	auipc	a0,0x1
ffffffffc0201578:	40450513          	addi	a0,a0,1028 # ffffffffc0202978 <commands+0x820>
ffffffffc020157c:	be5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0201580:	00001697          	auipc	a3,0x1
ffffffffc0201584:	66868693          	addi	a3,a3,1640 # ffffffffc0202be8 <commands+0xa90>
ffffffffc0201588:	00001617          	auipc	a2,0x1
ffffffffc020158c:	3d860613          	addi	a2,a2,984 # ffffffffc0202960 <commands+0x808>
ffffffffc0201590:	11f00593          	li	a1,287
ffffffffc0201594:	00001517          	auipc	a0,0x1
ffffffffc0201598:	3e450513          	addi	a0,a0,996 # ffffffffc0202978 <commands+0x820>
ffffffffc020159c:	bc5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02015a0:	00001697          	auipc	a3,0x1
ffffffffc02015a4:	62868693          	addi	a3,a3,1576 # ffffffffc0202bc8 <commands+0xa70>
ffffffffc02015a8:	00001617          	auipc	a2,0x1
ffffffffc02015ac:	3b860613          	addi	a2,a2,952 # ffffffffc0202960 <commands+0x808>
ffffffffc02015b0:	11e00593          	li	a1,286
ffffffffc02015b4:	00001517          	auipc	a0,0x1
ffffffffc02015b8:	3c450513          	addi	a0,a0,964 # ffffffffc0202978 <commands+0x820>
ffffffffc02015bc:	ba5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02015c0:	00001697          	auipc	a3,0x1
ffffffffc02015c4:	5d868693          	addi	a3,a3,1496 # ffffffffc0202b98 <commands+0xa40>
ffffffffc02015c8:	00001617          	auipc	a2,0x1
ffffffffc02015cc:	39860613          	addi	a2,a2,920 # ffffffffc0202960 <commands+0x808>
ffffffffc02015d0:	11c00593          	li	a1,284
ffffffffc02015d4:	00001517          	auipc	a0,0x1
ffffffffc02015d8:	3a450513          	addi	a0,a0,932 # ffffffffc0202978 <commands+0x820>
ffffffffc02015dc:	b85fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02015e0:	00001697          	auipc	a3,0x1
ffffffffc02015e4:	5a068693          	addi	a3,a3,1440 # ffffffffc0202b80 <commands+0xa28>
ffffffffc02015e8:	00001617          	auipc	a2,0x1
ffffffffc02015ec:	37860613          	addi	a2,a2,888 # ffffffffc0202960 <commands+0x808>
ffffffffc02015f0:	11b00593          	li	a1,283
ffffffffc02015f4:	00001517          	auipc	a0,0x1
ffffffffc02015f8:	38450513          	addi	a0,a0,900 # ffffffffc0202978 <commands+0x820>
ffffffffc02015fc:	b65fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201600:	00001697          	auipc	a3,0x1
ffffffffc0201604:	4e868693          	addi	a3,a3,1256 # ffffffffc0202ae8 <commands+0x990>
ffffffffc0201608:	00001617          	auipc	a2,0x1
ffffffffc020160c:	35860613          	addi	a2,a2,856 # ffffffffc0202960 <commands+0x808>
ffffffffc0201610:	10f00593          	li	a1,271
ffffffffc0201614:	00001517          	auipc	a0,0x1
ffffffffc0201618:	36450513          	addi	a0,a0,868 # ffffffffc0202978 <commands+0x820>
ffffffffc020161c:	b45fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201620:	00001697          	auipc	a3,0x1
ffffffffc0201624:	54868693          	addi	a3,a3,1352 # ffffffffc0202b68 <commands+0xa10>
ffffffffc0201628:	00001617          	auipc	a2,0x1
ffffffffc020162c:	33860613          	addi	a2,a2,824 # ffffffffc0202960 <commands+0x808>
ffffffffc0201630:	10600593          	li	a1,262
ffffffffc0201634:	00001517          	auipc	a0,0x1
ffffffffc0201638:	34450513          	addi	a0,a0,836 # ffffffffc0202978 <commands+0x820>
ffffffffc020163c:	b25fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(p0 != NULL);
ffffffffc0201640:	00001697          	auipc	a3,0x1
ffffffffc0201644:	51868693          	addi	a3,a3,1304 # ffffffffc0202b58 <commands+0xa00>
ffffffffc0201648:	00001617          	auipc	a2,0x1
ffffffffc020164c:	31860613          	addi	a2,a2,792 # ffffffffc0202960 <commands+0x808>
ffffffffc0201650:	10500593          	li	a1,261
ffffffffc0201654:	00001517          	auipc	a0,0x1
ffffffffc0201658:	32450513          	addi	a0,a0,804 # ffffffffc0202978 <commands+0x820>
ffffffffc020165c:	b05fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(nr_free == 0);
ffffffffc0201660:	00001697          	auipc	a3,0x1
ffffffffc0201664:	4e868693          	addi	a3,a3,1256 # ffffffffc0202b48 <commands+0x9f0>
ffffffffc0201668:	00001617          	auipc	a2,0x1
ffffffffc020166c:	2f860613          	addi	a2,a2,760 # ffffffffc0202960 <commands+0x808>
ffffffffc0201670:	0e700593          	li	a1,231
ffffffffc0201674:	00001517          	auipc	a0,0x1
ffffffffc0201678:	30450513          	addi	a0,a0,772 # ffffffffc0202978 <commands+0x820>
ffffffffc020167c:	ae5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201680:	00001697          	auipc	a3,0x1
ffffffffc0201684:	46868693          	addi	a3,a3,1128 # ffffffffc0202ae8 <commands+0x990>
ffffffffc0201688:	00001617          	auipc	a2,0x1
ffffffffc020168c:	2d860613          	addi	a2,a2,728 # ffffffffc0202960 <commands+0x808>
ffffffffc0201690:	0e500593          	li	a1,229
ffffffffc0201694:	00001517          	auipc	a0,0x1
ffffffffc0201698:	2e450513          	addi	a0,a0,740 # ffffffffc0202978 <commands+0x820>
ffffffffc020169c:	ac5fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02016a0:	00001697          	auipc	a3,0x1
ffffffffc02016a4:	48868693          	addi	a3,a3,1160 # ffffffffc0202b28 <commands+0x9d0>
ffffffffc02016a8:	00001617          	auipc	a2,0x1
ffffffffc02016ac:	2b860613          	addi	a2,a2,696 # ffffffffc0202960 <commands+0x808>
ffffffffc02016b0:	0e400593          	li	a1,228
ffffffffc02016b4:	00001517          	auipc	a0,0x1
ffffffffc02016b8:	2c450513          	addi	a0,a0,708 # ffffffffc0202978 <commands+0x820>
ffffffffc02016bc:	aa5fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc02016c0 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc02016c0:	1141                	addi	sp,sp,-16
ffffffffc02016c2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016c4:	14058a63          	beqz	a1,ffffffffc0201818 <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc02016c8:	00259693          	slli	a3,a1,0x2
ffffffffc02016cc:	96ae                	add	a3,a3,a1
ffffffffc02016ce:	068e                	slli	a3,a3,0x3
ffffffffc02016d0:	96aa                	add	a3,a3,a0
ffffffffc02016d2:	87aa                	mv	a5,a0
ffffffffc02016d4:	02d50263          	beq	a0,a3,ffffffffc02016f8 <best_fit_free_pages+0x38>
ffffffffc02016d8:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016da:	8b05                	andi	a4,a4,1
ffffffffc02016dc:	10071e63          	bnez	a4,ffffffffc02017f8 <best_fit_free_pages+0x138>
ffffffffc02016e0:	6798                	ld	a4,8(a5)
ffffffffc02016e2:	8b09                	andi	a4,a4,2
ffffffffc02016e4:	10071a63          	bnez	a4,ffffffffc02017f8 <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc02016e8:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02016ec:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02016f0:	02878793          	addi	a5,a5,40
ffffffffc02016f4:	fed792e3          	bne	a5,a3,ffffffffc02016d8 <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc02016f8:	2581                	sext.w	a1,a1
ffffffffc02016fa:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02016fc:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201700:	4789                	li	a5,2
ffffffffc0201702:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201706:	00005697          	auipc	a3,0x5
ffffffffc020170a:	92268693          	addi	a3,a3,-1758 # ffffffffc0206028 <free_area>
ffffffffc020170e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201710:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201712:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201716:	9db9                	addw	a1,a1,a4
ffffffffc0201718:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020171a:	0ad78863          	beq	a5,a3,ffffffffc02017ca <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc020171e:	fe878713          	addi	a4,a5,-24
ffffffffc0201722:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201726:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201728:	00e56a63          	bltu	a0,a4,ffffffffc020173c <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc020172c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020172e:	06d70263          	beq	a4,a3,ffffffffc0201792 <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201732:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201734:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201738:	fee57ae3          	bgeu	a0,a4,ffffffffc020172c <best_fit_free_pages+0x6c>
ffffffffc020173c:	c199                	beqz	a1,ffffffffc0201742 <best_fit_free_pages+0x82>
ffffffffc020173e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201742:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0201744:	e390                	sd	a2,0(a5)
ffffffffc0201746:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201748:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020174a:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020174c:	02d70063          	beq	a4,a3,ffffffffc020176c <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201750:	ff872803          	lw	a6,-8(a4) # fffffffffff7fff8 <end+0x3fd79b58>
        p = le2page(le, page_link);
ffffffffc0201754:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201758:	02081613          	slli	a2,a6,0x20
ffffffffc020175c:	9201                	srli	a2,a2,0x20
ffffffffc020175e:	00261793          	slli	a5,a2,0x2
ffffffffc0201762:	97b2                	add	a5,a5,a2
ffffffffc0201764:	078e                	slli	a5,a5,0x3
ffffffffc0201766:	97ae                	add	a5,a5,a1
ffffffffc0201768:	02f50f63          	beq	a0,a5,ffffffffc02017a6 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc020176c:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020176e:	00d70f63          	beq	a4,a3,ffffffffc020178c <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201772:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201774:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201778:	02059613          	slli	a2,a1,0x20
ffffffffc020177c:	9201                	srli	a2,a2,0x20
ffffffffc020177e:	00261793          	slli	a5,a2,0x2
ffffffffc0201782:	97b2                	add	a5,a5,a2
ffffffffc0201784:	078e                	slli	a5,a5,0x3
ffffffffc0201786:	97aa                	add	a5,a5,a0
ffffffffc0201788:	04f68863          	beq	a3,a5,ffffffffc02017d8 <best_fit_free_pages+0x118>
}
ffffffffc020178c:	60a2                	ld	ra,8(sp)
ffffffffc020178e:	0141                	addi	sp,sp,16
ffffffffc0201790:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201792:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201794:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201796:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201798:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020179a:	02d70563          	beq	a4,a3,ffffffffc02017c4 <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc020179e:	8832                	mv	a6,a2
ffffffffc02017a0:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02017a2:	87ba                	mv	a5,a4
ffffffffc02017a4:	bf41                	j	ffffffffc0201734 <best_fit_free_pages+0x74>
            p->property += base->property;
ffffffffc02017a6:	491c                	lw	a5,16(a0)
ffffffffc02017a8:	0107883b          	addw	a6,a5,a6
ffffffffc02017ac:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02017b0:	57f5                	li	a5,-3
ffffffffc02017b2:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017b6:	6d10                	ld	a2,24(a0)
ffffffffc02017b8:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02017ba:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc02017bc:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02017be:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02017c0:	e390                	sd	a2,0(a5)
ffffffffc02017c2:	b775                	j	ffffffffc020176e <best_fit_free_pages+0xae>
ffffffffc02017c4:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02017c6:	873e                	mv	a4,a5
ffffffffc02017c8:	b761                	j	ffffffffc0201750 <best_fit_free_pages+0x90>
}
ffffffffc02017ca:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02017cc:	e390                	sd	a2,0(a5)
ffffffffc02017ce:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017d0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017d2:	ed1c                	sd	a5,24(a0)
ffffffffc02017d4:	0141                	addi	sp,sp,16
ffffffffc02017d6:	8082                	ret
            base->property += p->property;
ffffffffc02017d8:	ff872783          	lw	a5,-8(a4)
ffffffffc02017dc:	ff070693          	addi	a3,a4,-16
ffffffffc02017e0:	9dbd                	addw	a1,a1,a5
ffffffffc02017e2:	c90c                	sw	a1,16(a0)
ffffffffc02017e4:	57f5                	li	a5,-3
ffffffffc02017e6:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017ea:	6314                	ld	a3,0(a4)
ffffffffc02017ec:	671c                	ld	a5,8(a4)
}
ffffffffc02017ee:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02017f0:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02017f2:	e394                	sd	a3,0(a5)
ffffffffc02017f4:	0141                	addi	sp,sp,16
ffffffffc02017f6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017f8:	00001697          	auipc	a3,0x1
ffffffffc02017fc:	45868693          	addi	a3,a3,1112 # ffffffffc0202c50 <commands+0xaf8>
ffffffffc0201800:	00001617          	auipc	a2,0x1
ffffffffc0201804:	16060613          	addi	a2,a2,352 # ffffffffc0202960 <commands+0x808>
ffffffffc0201808:	08900593          	li	a1,137
ffffffffc020180c:	00001517          	auipc	a0,0x1
ffffffffc0201810:	16c50513          	addi	a0,a0,364 # ffffffffc0202978 <commands+0x820>
ffffffffc0201814:	94dfe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(n > 0);
ffffffffc0201818:	00001697          	auipc	a3,0x1
ffffffffc020181c:	14068693          	addi	a3,a3,320 # ffffffffc0202958 <commands+0x800>
ffffffffc0201820:	00001617          	auipc	a2,0x1
ffffffffc0201824:	14060613          	addi	a2,a2,320 # ffffffffc0202960 <commands+0x808>
ffffffffc0201828:	08600593          	li	a1,134
ffffffffc020182c:	00001517          	auipc	a0,0x1
ffffffffc0201830:	14c50513          	addi	a0,a0,332 # ffffffffc0202978 <commands+0x820>
ffffffffc0201834:	92dfe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc0201838 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0201838:	1141                	addi	sp,sp,-16
ffffffffc020183a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020183c:	c9e1                	beqz	a1,ffffffffc020190c <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020183e:	00259693          	slli	a3,a1,0x2
ffffffffc0201842:	96ae                	add	a3,a3,a1
ffffffffc0201844:	068e                	slli	a3,a3,0x3
ffffffffc0201846:	96aa                	add	a3,a3,a0
ffffffffc0201848:	87aa                	mv	a5,a0
ffffffffc020184a:	00d50f63          	beq	a0,a3,ffffffffc0201868 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020184e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201850:	8b05                	andi	a4,a4,1
ffffffffc0201852:	cf49                	beqz	a4,ffffffffc02018ec <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201854:	0007a823          	sw	zero,16(a5)
ffffffffc0201858:	0007b423          	sd	zero,8(a5)
ffffffffc020185c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201860:	02878793          	addi	a5,a5,40
ffffffffc0201864:	fed795e3          	bne	a5,a3,ffffffffc020184e <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc0201868:	2581                	sext.w	a1,a1
ffffffffc020186a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020186c:	4789                	li	a5,2
ffffffffc020186e:	00850713          	addi	a4,a0,8
ffffffffc0201872:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201876:	00004697          	auipc	a3,0x4
ffffffffc020187a:	7b268693          	addi	a3,a3,1970 # ffffffffc0206028 <free_area>
ffffffffc020187e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201880:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201882:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201886:	9db9                	addw	a1,a1,a4
ffffffffc0201888:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020188a:	04d78a63          	beq	a5,a3,ffffffffc02018de <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc020188e:	fe878713          	addi	a4,a5,-24
ffffffffc0201892:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201896:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201898:	00e56a63          	bltu	a0,a4,ffffffffc02018ac <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc020189c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020189e:	02d70263          	beq	a4,a3,ffffffffc02018c2 <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02018a2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02018a4:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02018a8:	fee57ae3          	bgeu	a0,a4,ffffffffc020189c <best_fit_init_memmap+0x64>
ffffffffc02018ac:	c199                	beqz	a1,ffffffffc02018b2 <best_fit_init_memmap+0x7a>
ffffffffc02018ae:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018b2:	6398                	ld	a4,0(a5)
}
ffffffffc02018b4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018b6:	e390                	sd	a2,0(a5)
ffffffffc02018b8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018ba:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018bc:	ed18                	sd	a4,24(a0)
ffffffffc02018be:	0141                	addi	sp,sp,16
ffffffffc02018c0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018c2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018c4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018c6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018c8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02018ca:	00d70663          	beq	a4,a3,ffffffffc02018d6 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc02018ce:	8832                	mv	a6,a2
ffffffffc02018d0:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02018d2:	87ba                	mv	a5,a4
ffffffffc02018d4:	bfc1                	j	ffffffffc02018a4 <best_fit_init_memmap+0x6c>
}
ffffffffc02018d6:	60a2                	ld	ra,8(sp)
ffffffffc02018d8:	e290                	sd	a2,0(a3)
ffffffffc02018da:	0141                	addi	sp,sp,16
ffffffffc02018dc:	8082                	ret
ffffffffc02018de:	60a2                	ld	ra,8(sp)
ffffffffc02018e0:	e390                	sd	a2,0(a5)
ffffffffc02018e2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018e4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018e6:	ed1c                	sd	a5,24(a0)
ffffffffc02018e8:	0141                	addi	sp,sp,16
ffffffffc02018ea:	8082                	ret
        assert(PageReserved(p));
ffffffffc02018ec:	00001697          	auipc	a3,0x1
ffffffffc02018f0:	38c68693          	addi	a3,a3,908 # ffffffffc0202c78 <commands+0xb20>
ffffffffc02018f4:	00001617          	auipc	a2,0x1
ffffffffc02018f8:	06c60613          	addi	a2,a2,108 # ffffffffc0202960 <commands+0x808>
ffffffffc02018fc:	04a00593          	li	a1,74
ffffffffc0201900:	00001517          	auipc	a0,0x1
ffffffffc0201904:	07850513          	addi	a0,a0,120 # ffffffffc0202978 <commands+0x820>
ffffffffc0201908:	859fe0ef          	jal	ra,ffffffffc0200160 <__panic>
    assert(n > 0);
ffffffffc020190c:	00001697          	auipc	a3,0x1
ffffffffc0201910:	04c68693          	addi	a3,a3,76 # ffffffffc0202958 <commands+0x800>
ffffffffc0201914:	00001617          	auipc	a2,0x1
ffffffffc0201918:	04c60613          	addi	a2,a2,76 # ffffffffc0202960 <commands+0x808>
ffffffffc020191c:	04700593          	li	a1,71
ffffffffc0201920:	00001517          	auipc	a0,0x1
ffffffffc0201924:	05850513          	addi	a0,a0,88 # ffffffffc0202978 <commands+0x820>
ffffffffc0201928:	839fe0ef          	jal	ra,ffffffffc0200160 <__panic>

ffffffffc020192c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020192c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201930:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201932:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201934:	cb81                	beqz	a5,ffffffffc0201944 <strlen+0x18>
        cnt ++;
ffffffffc0201936:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201938:	00a707b3          	add	a5,a4,a0
ffffffffc020193c:	0007c783          	lbu	a5,0(a5)
ffffffffc0201940:	fbfd                	bnez	a5,ffffffffc0201936 <strlen+0xa>
ffffffffc0201942:	8082                	ret
    }
    return cnt;
}
ffffffffc0201944:	8082                	ret

ffffffffc0201946 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201946:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201948:	e589                	bnez	a1,ffffffffc0201952 <strnlen+0xc>
ffffffffc020194a:	a811                	j	ffffffffc020195e <strnlen+0x18>
        cnt ++;
ffffffffc020194c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020194e:	00f58863          	beq	a1,a5,ffffffffc020195e <strnlen+0x18>
ffffffffc0201952:	00f50733          	add	a4,a0,a5
ffffffffc0201956:	00074703          	lbu	a4,0(a4)
ffffffffc020195a:	fb6d                	bnez	a4,ffffffffc020194c <strnlen+0x6>
ffffffffc020195c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020195e:	852e                	mv	a0,a1
ffffffffc0201960:	8082                	ret

ffffffffc0201962 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201962:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201966:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020196a:	cb89                	beqz	a5,ffffffffc020197c <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020196c:	0505                	addi	a0,a0,1
ffffffffc020196e:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201970:	fee789e3          	beq	a5,a4,ffffffffc0201962 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201974:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201978:	9d19                	subw	a0,a0,a4
ffffffffc020197a:	8082                	ret
ffffffffc020197c:	4501                	li	a0,0
ffffffffc020197e:	bfed                	j	ffffffffc0201978 <strcmp+0x16>

ffffffffc0201980 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201980:	c20d                	beqz	a2,ffffffffc02019a2 <strncmp+0x22>
ffffffffc0201982:	962e                	add	a2,a2,a1
ffffffffc0201984:	a031                	j	ffffffffc0201990 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201986:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201988:	00e79a63          	bne	a5,a4,ffffffffc020199c <strncmp+0x1c>
ffffffffc020198c:	00b60b63          	beq	a2,a1,ffffffffc02019a2 <strncmp+0x22>
ffffffffc0201990:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201994:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201996:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020199a:	f7f5                	bnez	a5,ffffffffc0201986 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020199c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02019a0:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019a2:	4501                	li	a0,0
ffffffffc02019a4:	8082                	ret

ffffffffc02019a6 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02019a6:	00054783          	lbu	a5,0(a0)
ffffffffc02019aa:	c799                	beqz	a5,ffffffffc02019b8 <strchr+0x12>
        if (*s == c) {
ffffffffc02019ac:	00f58763          	beq	a1,a5,ffffffffc02019ba <strchr+0x14>
    while (*s != '\0') {
ffffffffc02019b0:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02019b4:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02019b6:	fbfd                	bnez	a5,ffffffffc02019ac <strchr+0x6>
    }
    return NULL;
ffffffffc02019b8:	4501                	li	a0,0
}
ffffffffc02019ba:	8082                	ret

ffffffffc02019bc <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02019bc:	ca01                	beqz	a2,ffffffffc02019cc <memset+0x10>
ffffffffc02019be:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02019c0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02019c2:	0785                	addi	a5,a5,1
ffffffffc02019c4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02019c8:	fec79de3          	bne	a5,a2,ffffffffc02019c2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02019cc:	8082                	ret

ffffffffc02019ce <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02019ce:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019d2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02019d4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019d8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019da:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019de:	f022                	sd	s0,32(sp)
ffffffffc02019e0:	ec26                	sd	s1,24(sp)
ffffffffc02019e2:	e84a                	sd	s2,16(sp)
ffffffffc02019e4:	f406                	sd	ra,40(sp)
ffffffffc02019e6:	e44e                	sd	s3,8(sp)
ffffffffc02019e8:	84aa                	mv	s1,a0
ffffffffc02019ea:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019ec:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02019f0:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02019f2:	03067e63          	bgeu	a2,a6,ffffffffc0201a2e <printnum+0x60>
ffffffffc02019f6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02019f8:	00805763          	blez	s0,ffffffffc0201a06 <printnum+0x38>
ffffffffc02019fc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019fe:	85ca                	mv	a1,s2
ffffffffc0201a00:	854e                	mv	a0,s3
ffffffffc0201a02:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a04:	fc65                	bnez	s0,ffffffffc02019fc <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a06:	1a02                	slli	s4,s4,0x20
ffffffffc0201a08:	00001797          	auipc	a5,0x1
ffffffffc0201a0c:	2d078793          	addi	a5,a5,720 # ffffffffc0202cd8 <best_fit_pmm_manager+0x38>
ffffffffc0201a10:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a14:	9a3e                	add	s4,s4,a5
}
ffffffffc0201a16:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a18:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a1c:	70a2                	ld	ra,40(sp)
ffffffffc0201a1e:	69a2                	ld	s3,8(sp)
ffffffffc0201a20:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a22:	85ca                	mv	a1,s2
ffffffffc0201a24:	87a6                	mv	a5,s1
}
ffffffffc0201a26:	6942                	ld	s2,16(sp)
ffffffffc0201a28:	64e2                	ld	s1,24(sp)
ffffffffc0201a2a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a2c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a2e:	03065633          	divu	a2,a2,a6
ffffffffc0201a32:	8722                	mv	a4,s0
ffffffffc0201a34:	f9bff0ef          	jal	ra,ffffffffc02019ce <printnum>
ffffffffc0201a38:	b7f9                	j	ffffffffc0201a06 <printnum+0x38>

ffffffffc0201a3a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a3a:	7119                	addi	sp,sp,-128
ffffffffc0201a3c:	f4a6                	sd	s1,104(sp)
ffffffffc0201a3e:	f0ca                	sd	s2,96(sp)
ffffffffc0201a40:	ecce                	sd	s3,88(sp)
ffffffffc0201a42:	e8d2                	sd	s4,80(sp)
ffffffffc0201a44:	e4d6                	sd	s5,72(sp)
ffffffffc0201a46:	e0da                	sd	s6,64(sp)
ffffffffc0201a48:	fc5e                	sd	s7,56(sp)
ffffffffc0201a4a:	f06a                	sd	s10,32(sp)
ffffffffc0201a4c:	fc86                	sd	ra,120(sp)
ffffffffc0201a4e:	f8a2                	sd	s0,112(sp)
ffffffffc0201a50:	f862                	sd	s8,48(sp)
ffffffffc0201a52:	f466                	sd	s9,40(sp)
ffffffffc0201a54:	ec6e                	sd	s11,24(sp)
ffffffffc0201a56:	892a                	mv	s2,a0
ffffffffc0201a58:	84ae                	mv	s1,a1
ffffffffc0201a5a:	8d32                	mv	s10,a2
ffffffffc0201a5c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a5e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a62:	5b7d                	li	s6,-1
ffffffffc0201a64:	00001a97          	auipc	s5,0x1
ffffffffc0201a68:	2a8a8a93          	addi	s5,s5,680 # ffffffffc0202d0c <best_fit_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a6c:	00001b97          	auipc	s7,0x1
ffffffffc0201a70:	47cb8b93          	addi	s7,s7,1148 # ffffffffc0202ee8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a74:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a78:	001d0413          	addi	s0,s10,1
ffffffffc0201a7c:	01350a63          	beq	a0,s3,ffffffffc0201a90 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a80:	c121                	beqz	a0,ffffffffc0201ac0 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a82:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a84:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a86:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a88:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a8c:	ff351ae3          	bne	a0,s3,ffffffffc0201a80 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a90:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a94:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a98:	4c81                	li	s9,0
ffffffffc0201a9a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201a9c:	5c7d                	li	s8,-1
ffffffffc0201a9e:	5dfd                	li	s11,-1
ffffffffc0201aa0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201aa4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aa6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201aaa:	0ff5f593          	zext.b	a1,a1
ffffffffc0201aae:	00140d13          	addi	s10,s0,1
ffffffffc0201ab2:	04b56263          	bltu	a0,a1,ffffffffc0201af6 <vprintfmt+0xbc>
ffffffffc0201ab6:	058a                	slli	a1,a1,0x2
ffffffffc0201ab8:	95d6                	add	a1,a1,s5
ffffffffc0201aba:	4194                	lw	a3,0(a1)
ffffffffc0201abc:	96d6                	add	a3,a3,s5
ffffffffc0201abe:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201ac0:	70e6                	ld	ra,120(sp)
ffffffffc0201ac2:	7446                	ld	s0,112(sp)
ffffffffc0201ac4:	74a6                	ld	s1,104(sp)
ffffffffc0201ac6:	7906                	ld	s2,96(sp)
ffffffffc0201ac8:	69e6                	ld	s3,88(sp)
ffffffffc0201aca:	6a46                	ld	s4,80(sp)
ffffffffc0201acc:	6aa6                	ld	s5,72(sp)
ffffffffc0201ace:	6b06                	ld	s6,64(sp)
ffffffffc0201ad0:	7be2                	ld	s7,56(sp)
ffffffffc0201ad2:	7c42                	ld	s8,48(sp)
ffffffffc0201ad4:	7ca2                	ld	s9,40(sp)
ffffffffc0201ad6:	7d02                	ld	s10,32(sp)
ffffffffc0201ad8:	6de2                	ld	s11,24(sp)
ffffffffc0201ada:	6109                	addi	sp,sp,128
ffffffffc0201adc:	8082                	ret
            padc = '0';
ffffffffc0201ade:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201ae0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae4:	846a                	mv	s0,s10
ffffffffc0201ae6:	00140d13          	addi	s10,s0,1
ffffffffc0201aea:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201aee:	0ff5f593          	zext.b	a1,a1
ffffffffc0201af2:	fcb572e3          	bgeu	a0,a1,ffffffffc0201ab6 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201af6:	85a6                	mv	a1,s1
ffffffffc0201af8:	02500513          	li	a0,37
ffffffffc0201afc:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201afe:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b02:	8d22                	mv	s10,s0
ffffffffc0201b04:	f73788e3          	beq	a5,s3,ffffffffc0201a74 <vprintfmt+0x3a>
ffffffffc0201b08:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b0c:	1d7d                	addi	s10,s10,-1
ffffffffc0201b0e:	ff379de3          	bne	a5,s3,ffffffffc0201b08 <vprintfmt+0xce>
ffffffffc0201b12:	b78d                	j	ffffffffc0201a74 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201b14:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b18:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b1c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b1e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b22:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b26:	02d86463          	bltu	a6,a3,ffffffffc0201b4e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b2a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b2e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201b32:	0186873b          	addw	a4,a3,s8
ffffffffc0201b36:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b3a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201b3c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b40:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b42:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201b46:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b4a:	fed870e3          	bgeu	a6,a3,ffffffffc0201b2a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201b4e:	f40ddce3          	bgez	s11,ffffffffc0201aa6 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201b52:	8de2                	mv	s11,s8
ffffffffc0201b54:	5c7d                	li	s8,-1
ffffffffc0201b56:	bf81                	j	ffffffffc0201aa6 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201b58:	fffdc693          	not	a3,s11
ffffffffc0201b5c:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b5e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b62:	00144603          	lbu	a2,1(s0)
ffffffffc0201b66:	2d81                	sext.w	s11,s11
ffffffffc0201b68:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b6a:	bf35                	j	ffffffffc0201aa6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201b6c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b70:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201b74:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b76:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201b78:	bfd9                	j	ffffffffc0201b4e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201b7a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b7c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b80:	01174463          	blt	a4,a7,ffffffffc0201b88 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b84:	1a088e63          	beqz	a7,ffffffffc0201d40 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b88:	000a3603          	ld	a2,0(s4)
ffffffffc0201b8c:	46c1                	li	a3,16
ffffffffc0201b8e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b90:	2781                	sext.w	a5,a5
ffffffffc0201b92:	876e                	mv	a4,s11
ffffffffc0201b94:	85a6                	mv	a1,s1
ffffffffc0201b96:	854a                	mv	a0,s2
ffffffffc0201b98:	e37ff0ef          	jal	ra,ffffffffc02019ce <printnum>
            break;
ffffffffc0201b9c:	bde1                	j	ffffffffc0201a74 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b9e:	000a2503          	lw	a0,0(s4)
ffffffffc0201ba2:	85a6                	mv	a1,s1
ffffffffc0201ba4:	0a21                	addi	s4,s4,8
ffffffffc0201ba6:	9902                	jalr	s2
            break;
ffffffffc0201ba8:	b5f1                	j	ffffffffc0201a74 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201baa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bac:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bb0:	01174463          	blt	a4,a7,ffffffffc0201bb8 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201bb4:	18088163          	beqz	a7,ffffffffc0201d36 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201bb8:	000a3603          	ld	a2,0(s4)
ffffffffc0201bbc:	46a9                	li	a3,10
ffffffffc0201bbe:	8a2e                	mv	s4,a1
ffffffffc0201bc0:	bfc1                	j	ffffffffc0201b90 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bc2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201bc6:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bc8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bca:	bdf1                	j	ffffffffc0201aa6 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201bcc:	85a6                	mv	a1,s1
ffffffffc0201bce:	02500513          	li	a0,37
ffffffffc0201bd2:	9902                	jalr	s2
            break;
ffffffffc0201bd4:	b545                	j	ffffffffc0201a74 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bd6:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201bda:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bdc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bde:	b5e1                	j	ffffffffc0201aa6 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201be0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201be2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201be6:	01174463          	blt	a4,a7,ffffffffc0201bee <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201bea:	14088163          	beqz	a7,ffffffffc0201d2c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201bee:	000a3603          	ld	a2,0(s4)
ffffffffc0201bf2:	46a1                	li	a3,8
ffffffffc0201bf4:	8a2e                	mv	s4,a1
ffffffffc0201bf6:	bf69                	j	ffffffffc0201b90 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201bf8:	03000513          	li	a0,48
ffffffffc0201bfc:	85a6                	mv	a1,s1
ffffffffc0201bfe:	e03e                	sd	a5,0(sp)
ffffffffc0201c00:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c02:	85a6                	mv	a1,s1
ffffffffc0201c04:	07800513          	li	a0,120
ffffffffc0201c08:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c0a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c0c:	6782                	ld	a5,0(sp)
ffffffffc0201c0e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c10:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201c14:	bfb5                	j	ffffffffc0201b90 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c16:	000a3403          	ld	s0,0(s4)
ffffffffc0201c1a:	008a0713          	addi	a4,s4,8
ffffffffc0201c1e:	e03a                	sd	a4,0(sp)
ffffffffc0201c20:	14040263          	beqz	s0,ffffffffc0201d64 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c24:	0fb05763          	blez	s11,ffffffffc0201d12 <vprintfmt+0x2d8>
ffffffffc0201c28:	02d00693          	li	a3,45
ffffffffc0201c2c:	0cd79163          	bne	a5,a3,ffffffffc0201cee <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c30:	00044783          	lbu	a5,0(s0)
ffffffffc0201c34:	0007851b          	sext.w	a0,a5
ffffffffc0201c38:	cf85                	beqz	a5,ffffffffc0201c70 <vprintfmt+0x236>
ffffffffc0201c3a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c3e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c42:	000c4563          	bltz	s8,ffffffffc0201c4c <vprintfmt+0x212>
ffffffffc0201c46:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c48:	036c0263          	beq	s8,s6,ffffffffc0201c6c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201c4c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c4e:	0e0c8e63          	beqz	s9,ffffffffc0201d4a <vprintfmt+0x310>
ffffffffc0201c52:	3781                	addiw	a5,a5,-32
ffffffffc0201c54:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d4a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201c58:	03f00513          	li	a0,63
ffffffffc0201c5c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c5e:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c62:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c64:	0a05                	addi	s4,s4,1
ffffffffc0201c66:	0007851b          	sext.w	a0,a5
ffffffffc0201c6a:	ffe1                	bnez	a5,ffffffffc0201c42 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201c6c:	01b05963          	blez	s11,ffffffffc0201c7e <vprintfmt+0x244>
ffffffffc0201c70:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201c72:	85a6                	mv	a1,s1
ffffffffc0201c74:	02000513          	li	a0,32
ffffffffc0201c78:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c7a:	fe0d9be3          	bnez	s11,ffffffffc0201c70 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c7e:	6a02                	ld	s4,0(sp)
ffffffffc0201c80:	bbd5                	j	ffffffffc0201a74 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c82:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c84:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c88:	01174463          	blt	a4,a7,ffffffffc0201c90 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c8c:	08088d63          	beqz	a7,ffffffffc0201d26 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c90:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c94:	0a044d63          	bltz	s0,ffffffffc0201d4e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c98:	8622                	mv	a2,s0
ffffffffc0201c9a:	8a66                	mv	s4,s9
ffffffffc0201c9c:	46a9                	li	a3,10
ffffffffc0201c9e:	bdcd                	j	ffffffffc0201b90 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201ca0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ca4:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201ca6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201ca8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201cac:	8fb5                	xor	a5,a5,a3
ffffffffc0201cae:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cb2:	02d74163          	blt	a4,a3,ffffffffc0201cd4 <vprintfmt+0x29a>
ffffffffc0201cb6:	00369793          	slli	a5,a3,0x3
ffffffffc0201cba:	97de                	add	a5,a5,s7
ffffffffc0201cbc:	639c                	ld	a5,0(a5)
ffffffffc0201cbe:	cb99                	beqz	a5,ffffffffc0201cd4 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201cc0:	86be                	mv	a3,a5
ffffffffc0201cc2:	00001617          	auipc	a2,0x1
ffffffffc0201cc6:	04660613          	addi	a2,a2,70 # ffffffffc0202d08 <best_fit_pmm_manager+0x68>
ffffffffc0201cca:	85a6                	mv	a1,s1
ffffffffc0201ccc:	854a                	mv	a0,s2
ffffffffc0201cce:	0ce000ef          	jal	ra,ffffffffc0201d9c <printfmt>
ffffffffc0201cd2:	b34d                	j	ffffffffc0201a74 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201cd4:	00001617          	auipc	a2,0x1
ffffffffc0201cd8:	02460613          	addi	a2,a2,36 # ffffffffc0202cf8 <best_fit_pmm_manager+0x58>
ffffffffc0201cdc:	85a6                	mv	a1,s1
ffffffffc0201cde:	854a                	mv	a0,s2
ffffffffc0201ce0:	0bc000ef          	jal	ra,ffffffffc0201d9c <printfmt>
ffffffffc0201ce4:	bb41                	j	ffffffffc0201a74 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201ce6:	00001417          	auipc	s0,0x1
ffffffffc0201cea:	00a40413          	addi	s0,s0,10 # ffffffffc0202cf0 <best_fit_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cee:	85e2                	mv	a1,s8
ffffffffc0201cf0:	8522                	mv	a0,s0
ffffffffc0201cf2:	e43e                	sd	a5,8(sp)
ffffffffc0201cf4:	c53ff0ef          	jal	ra,ffffffffc0201946 <strnlen>
ffffffffc0201cf8:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201cfc:	01b05b63          	blez	s11,ffffffffc0201d12 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d00:	67a2                	ld	a5,8(sp)
ffffffffc0201d02:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d06:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d08:	85a6                	mv	a1,s1
ffffffffc0201d0a:	8552                	mv	a0,s4
ffffffffc0201d0c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d0e:	fe0d9ce3          	bnez	s11,ffffffffc0201d06 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d12:	00044783          	lbu	a5,0(s0)
ffffffffc0201d16:	00140a13          	addi	s4,s0,1
ffffffffc0201d1a:	0007851b          	sext.w	a0,a5
ffffffffc0201d1e:	d3a5                	beqz	a5,ffffffffc0201c7e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d20:	05e00413          	li	s0,94
ffffffffc0201d24:	bf39                	j	ffffffffc0201c42 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d26:	000a2403          	lw	s0,0(s4)
ffffffffc0201d2a:	b7ad                	j	ffffffffc0201c94 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d2c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d30:	46a1                	li	a3,8
ffffffffc0201d32:	8a2e                	mv	s4,a1
ffffffffc0201d34:	bdb1                	j	ffffffffc0201b90 <vprintfmt+0x156>
ffffffffc0201d36:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d3a:	46a9                	li	a3,10
ffffffffc0201d3c:	8a2e                	mv	s4,a1
ffffffffc0201d3e:	bd89                	j	ffffffffc0201b90 <vprintfmt+0x156>
ffffffffc0201d40:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d44:	46c1                	li	a3,16
ffffffffc0201d46:	8a2e                	mv	s4,a1
ffffffffc0201d48:	b5a1                	j	ffffffffc0201b90 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201d4a:	9902                	jalr	s2
ffffffffc0201d4c:	bf09                	j	ffffffffc0201c5e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201d4e:	85a6                	mv	a1,s1
ffffffffc0201d50:	02d00513          	li	a0,45
ffffffffc0201d54:	e03e                	sd	a5,0(sp)
ffffffffc0201d56:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d58:	6782                	ld	a5,0(sp)
ffffffffc0201d5a:	8a66                	mv	s4,s9
ffffffffc0201d5c:	40800633          	neg	a2,s0
ffffffffc0201d60:	46a9                	li	a3,10
ffffffffc0201d62:	b53d                	j	ffffffffc0201b90 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201d64:	03b05163          	blez	s11,ffffffffc0201d86 <vprintfmt+0x34c>
ffffffffc0201d68:	02d00693          	li	a3,45
ffffffffc0201d6c:	f6d79de3          	bne	a5,a3,ffffffffc0201ce6 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201d70:	00001417          	auipc	s0,0x1
ffffffffc0201d74:	f8040413          	addi	s0,s0,-128 # ffffffffc0202cf0 <best_fit_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d78:	02800793          	li	a5,40
ffffffffc0201d7c:	02800513          	li	a0,40
ffffffffc0201d80:	00140a13          	addi	s4,s0,1
ffffffffc0201d84:	bd6d                	j	ffffffffc0201c3e <vprintfmt+0x204>
ffffffffc0201d86:	00001a17          	auipc	s4,0x1
ffffffffc0201d8a:	f6ba0a13          	addi	s4,s4,-149 # ffffffffc0202cf1 <best_fit_pmm_manager+0x51>
ffffffffc0201d8e:	02800513          	li	a0,40
ffffffffc0201d92:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d96:	05e00413          	li	s0,94
ffffffffc0201d9a:	b565                	j	ffffffffc0201c42 <vprintfmt+0x208>

ffffffffc0201d9c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d9c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d9e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201da2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201da4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201da6:	ec06                	sd	ra,24(sp)
ffffffffc0201da8:	f83a                	sd	a4,48(sp)
ffffffffc0201daa:	fc3e                	sd	a5,56(sp)
ffffffffc0201dac:	e0c2                	sd	a6,64(sp)
ffffffffc0201dae:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201db0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201db2:	c89ff0ef          	jal	ra,ffffffffc0201a3a <vprintfmt>
}
ffffffffc0201db6:	60e2                	ld	ra,24(sp)
ffffffffc0201db8:	6161                	addi	sp,sp,80
ffffffffc0201dba:	8082                	ret

ffffffffc0201dbc <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201dbc:	4781                	li	a5,0
ffffffffc0201dbe:	00004717          	auipc	a4,0x4
ffffffffc0201dc2:	25a73703          	ld	a4,602(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201dc6:	88ba                	mv	a7,a4
ffffffffc0201dc8:	852a                	mv	a0,a0
ffffffffc0201dca:	85be                	mv	a1,a5
ffffffffc0201dcc:	863e                	mv	a2,a5
ffffffffc0201dce:	00000073          	ecall
ffffffffc0201dd2:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201dd4:	8082                	ret

ffffffffc0201dd6 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201dd6:	4781                	li	a5,0
ffffffffc0201dd8:	00004717          	auipc	a4,0x4
ffffffffc0201ddc:	6c073703          	ld	a4,1728(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201de0:	88ba                	mv	a7,a4
ffffffffc0201de2:	852a                	mv	a0,a0
ffffffffc0201de4:	85be                	mv	a1,a5
ffffffffc0201de6:	863e                	mv	a2,a5
ffffffffc0201de8:	00000073          	ecall
ffffffffc0201dec:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201dee:	8082                	ret

ffffffffc0201df0 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201df0:	4501                	li	a0,0
ffffffffc0201df2:	00004797          	auipc	a5,0x4
ffffffffc0201df6:	21e7b783          	ld	a5,542(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201dfa:	88be                	mv	a7,a5
ffffffffc0201dfc:	852a                	mv	a0,a0
ffffffffc0201dfe:	85aa                	mv	a1,a0
ffffffffc0201e00:	862a                	mv	a2,a0
ffffffffc0201e02:	00000073          	ecall
ffffffffc0201e06:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e08:	2501                	sext.w	a0,a0
ffffffffc0201e0a:	8082                	ret

ffffffffc0201e0c <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e0c:	4781                	li	a5,0
ffffffffc0201e0e:	00004717          	auipc	a4,0x4
ffffffffc0201e12:	21273703          	ld	a4,530(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e16:	88ba                	mv	a7,a4
ffffffffc0201e18:	853e                	mv	a0,a5
ffffffffc0201e1a:	85be                	mv	a1,a5
ffffffffc0201e1c:	863e                	mv	a2,a5
ffffffffc0201e1e:	00000073          	ecall
ffffffffc0201e22:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e24:	8082                	ret

ffffffffc0201e26 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201e26:	715d                	addi	sp,sp,-80
ffffffffc0201e28:	e486                	sd	ra,72(sp)
ffffffffc0201e2a:	e0a6                	sd	s1,64(sp)
ffffffffc0201e2c:	fc4a                	sd	s2,56(sp)
ffffffffc0201e2e:	f84e                	sd	s3,48(sp)
ffffffffc0201e30:	f452                	sd	s4,40(sp)
ffffffffc0201e32:	f056                	sd	s5,32(sp)
ffffffffc0201e34:	ec5a                	sd	s6,24(sp)
ffffffffc0201e36:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e38:	c901                	beqz	a0,ffffffffc0201e48 <readline+0x22>
ffffffffc0201e3a:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e3c:	00001517          	auipc	a0,0x1
ffffffffc0201e40:	ecc50513          	addi	a0,a0,-308 # ffffffffc0202d08 <best_fit_pmm_manager+0x68>
ffffffffc0201e44:	a94fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
readline(const char *prompt) {
ffffffffc0201e48:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e4a:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e4c:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e4e:	4aa9                	li	s5,10
ffffffffc0201e50:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e52:	00004b97          	auipc	s7,0x4
ffffffffc0201e56:	1eeb8b93          	addi	s7,s7,494 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e5a:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201e5e:	af2fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e62:	00054a63          	bltz	a0,ffffffffc0201e76 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e66:	00a95a63          	bge	s2,a0,ffffffffc0201e7a <readline+0x54>
ffffffffc0201e6a:	029a5263          	bge	s4,s1,ffffffffc0201e8e <readline+0x68>
        c = getchar();
ffffffffc0201e6e:	ae2fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e72:	fe055ae3          	bgez	a0,ffffffffc0201e66 <readline+0x40>
            return NULL;
ffffffffc0201e76:	4501                	li	a0,0
ffffffffc0201e78:	a091                	j	ffffffffc0201ebc <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e7a:	03351463          	bne	a0,s3,ffffffffc0201ea2 <readline+0x7c>
ffffffffc0201e7e:	e8a9                	bnez	s1,ffffffffc0201ed0 <readline+0xaa>
        c = getchar();
ffffffffc0201e80:	ad0fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e84:	fe0549e3          	bltz	a0,ffffffffc0201e76 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e88:	fea959e3          	bge	s2,a0,ffffffffc0201e7a <readline+0x54>
ffffffffc0201e8c:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201e8e:	e42a                	sd	a0,8(sp)
ffffffffc0201e90:	a7efe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i ++] = c;
ffffffffc0201e94:	6522                	ld	a0,8(sp)
ffffffffc0201e96:	009b87b3          	add	a5,s7,s1
ffffffffc0201e9a:	2485                	addiw	s1,s1,1
ffffffffc0201e9c:	00a78023          	sb	a0,0(a5)
ffffffffc0201ea0:	bf7d                	j	ffffffffc0201e5e <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201ea2:	01550463          	beq	a0,s5,ffffffffc0201eaa <readline+0x84>
ffffffffc0201ea6:	fb651ce3          	bne	a0,s6,ffffffffc0201e5e <readline+0x38>
            cputchar(c);
ffffffffc0201eaa:	a64fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i] = '\0';
ffffffffc0201eae:	00004517          	auipc	a0,0x4
ffffffffc0201eb2:	19250513          	addi	a0,a0,402 # ffffffffc0206040 <buf>
ffffffffc0201eb6:	94aa                	add	s1,s1,a0
ffffffffc0201eb8:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201ebc:	60a6                	ld	ra,72(sp)
ffffffffc0201ebe:	6486                	ld	s1,64(sp)
ffffffffc0201ec0:	7962                	ld	s2,56(sp)
ffffffffc0201ec2:	79c2                	ld	s3,48(sp)
ffffffffc0201ec4:	7a22                	ld	s4,40(sp)
ffffffffc0201ec6:	7a82                	ld	s5,32(sp)
ffffffffc0201ec8:	6b62                	ld	s6,24(sp)
ffffffffc0201eca:	6bc2                	ld	s7,16(sp)
ffffffffc0201ecc:	6161                	addi	sp,sp,80
ffffffffc0201ece:	8082                	ret
            cputchar(c);
ffffffffc0201ed0:	4521                	li	a0,8
ffffffffc0201ed2:	a3cfe0ef          	jal	ra,ffffffffc020010e <cputchar>
            i --;
ffffffffc0201ed6:	34fd                	addiw	s1,s1,-1
ffffffffc0201ed8:	b759                	j	ffffffffc0201e5e <readline+0x38>
