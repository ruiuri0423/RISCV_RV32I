
jalr.elf:     file format elf32-littleriscv


Disassembly of section .text:

ffff0000 <_start>:
ffff0000:	00002117          	auipc	sp,0x2
ffff0004:	00010113          	mv	sp,sp
ffff0008:	ff010113          	addi	sp,sp,-16 # ffff1ff0 <end+0x1f8c>
ffff000c:	014000ef          	jal	ffff0020 <function1>
ffff0010:	01010113          	addi	sp,sp,16
ffff0014:	00000013          	nop
ffff0018:	00000013          	nop
ffff001c:	0480006f          	j	ffff0064 <end>

ffff0020 <function1>:
ffff0020:	ff010113          	addi	sp,sp,-16
ffff0024:	00112623          	sw	ra,12(sp)
ffff0028:	00000013          	nop
ffff002c:	00000013          	nop
ffff0030:	00000317          	auipc	t1,0x0
ffff0034:	01830313          	addi	t1,t1,24 # ffff0048 <function2>
ffff0038:	000300e7          	jalr	t1
ffff003c:	00c12083          	lw	ra,12(sp)
ffff0040:	01010113          	addi	sp,sp,16
ffff0044:	00008067          	ret

ffff0048 <function2>:
ffff0048:	ff010113          	addi	sp,sp,-16
ffff004c:	00112623          	sw	ra,12(sp)
ffff0050:	00000013          	nop
ffff0054:	00000013          	nop
ffff0058:	00c12083          	lw	ra,12(sp)
ffff005c:	01010113          	addi	sp,sp,16
ffff0060:	00008067          	ret

ffff0064 <end>:
ffff0064:	ffff12b7          	lui	t0,0xffff1
ffff0068:	23428293          	addi	t0,t0,564 # ffff1234 <end+0x11d0>
ffff006c:	ffff2337          	lui	t1,0xffff2
ffff0070:	ffc30313          	addi	t1,t1,-4 # ffff1ffc <end+0x1f98>
ffff0074:	00532023          	sw	t0,0(t1)
