
branch.elf:     file format elf32-littleriscv


Disassembly of section .text:

ffff0000 <_start>:
ffff0000:	00000013          	nop
ffff0004:	00000013          	nop
ffff0008:	01000293          	li	t0,16
ffff000c:	00000313          	li	t1,0
ffff0010:	00500393          	li	t2,5
ffff0014:	00000e13          	li	t3,0

ffff0018 <outer_loop>:
ffff0018:	00130313          	addi	t1,t1,1
ffff001c:	00000e13          	li	t3,0
ffff0020:	00535e63          	bge	t1,t0,ffff003c <end>

ffff0024 <inner_loop>:
ffff0024:	001e0e13          	addi	t3,t3,1
ffff0028:	0040006f          	j	ffff002c <check_inner_loop>

ffff002c <check_inner_loop>:
ffff002c:	00300e93          	li	t4,3
ffff0030:	01de5463          	bge	t3,t4,ffff0038 <break_inner>
ffff0034:	ff1ff06f          	j	ffff0024 <inner_loop>

ffff0038 <break_inner>:
ffff0038:	fe1ff06f          	j	ffff0018 <outer_loop>

ffff003c <end>:
ffff003c:	00000013          	nop
