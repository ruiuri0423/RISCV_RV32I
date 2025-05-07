
lsu.elf:     file format elf32-littleriscv


Disassembly of section .text:

ffff0000 <_start>:
ffff0000:	123452b7          	lui	t0,0x12345
ffff0004:	67828293          	addi	t0,t0,1656 # 12345678 <__stack_size+0x12344678>
ffff0008:	ffff1337          	lui	t1,0xffff1
ffff000c:	00532023          	sw	t0,0(t1) # ffff1000 <end+0xf54>
ffff0010:	00032383          	lw	t2,0(t1)
ffff0014:	08729263          	bne	t0,t2,ffff0098 <error>
ffff0018:	000052b7          	lui	t0,0x5
ffff001c:	67828293          	addi	t0,t0,1656 # 5678 <__stack_size+0x4678>
ffff0020:	ffff1337          	lui	t1,0xffff1
ffff0024:	01030313          	addi	t1,t1,16 # ffff1010 <end+0xf64>
ffff0028:	00531023          	sh	t0,0(t1)
ffff002c:	00031383          	lh	t2,0(t1)
ffff0030:	00005e37          	lui	t3,0x5
ffff0034:	678e0e13          	addi	t3,t3,1656 # 5678 <__stack_size+0x4678>
ffff0038:	07c39063          	bne	t2,t3,ffff0098 <error>
ffff003c:	08800293          	li	t0,136
ffff0040:	ffff1337          	lui	t1,0xffff1
ffff0044:	01130313          	addi	t1,t1,17 # ffff1011 <end+0xf65>
ffff0048:	00530023          	sb	t0,0(t1)
ffff004c:	00030383          	lb	t2,0(t1)
ffff0050:	f8800e13          	li	t3,-120
ffff0054:	05c39263          	bne	t2,t3,ffff0098 <error>
ffff0058:	000102b7          	lui	t0,0x10
ffff005c:	fff28293          	addi	t0,t0,-1 # ffff <__stack_size+0xefff>
ffff0060:	ffff1337          	lui	t1,0xffff1
ffff0064:	02030313          	addi	t1,t1,32 # ffff1020 <end+0xf74>
ffff0068:	00531023          	sh	t0,0(t1)
ffff006c:	00035383          	lhu	t2,0(t1)
ffff0070:	02729463          	bne	t0,t2,ffff0098 <error>
ffff0074:	0ff00293          	li	t0,255
ffff0078:	ffff1337          	lui	t1,0xffff1
ffff007c:	02130313          	addi	t1,t1,33 # ffff1021 <end+0xf75>
ffff0080:	00530023          	sb	t0,0(t1)
ffff0084:	00034383          	lbu	t2,0(t1)
ffff0088:	00729863          	bne	t0,t2,ffff0098 <error>
ffff008c:	00000013          	nop
ffff0090:	00000013          	nop
ffff0094:	0180006f          	j	ffff00ac <end>

ffff0098 <error>:
ffff0098:	123502b7          	lui	t0,0x12350
ffff009c:	fff28293          	addi	t0,t0,-1 # 1234ffff <__stack_size+0x1234efff>
ffff00a0:	ffff2337          	lui	t1,0xffff2
ffff00a4:	fff30313          	addi	t1,t1,-1 # ffff1fff <end+0x1f53>
ffff00a8:	00532023          	sw	t0,0(t1)

ffff00ac <end>:
ffff00ac:	ffff12b7          	lui	t0,0xffff1
ffff00b0:	23428293          	addi	t0,t0,564 # ffff1234 <end+0x1188>
ffff00b4:	ffff2337          	lui	t1,0xffff2
ffff00b8:	fff30313          	addi	t1,t1,-1 # ffff1fff <end+0x1f53>
ffff00bc:	00532023          	sw	t0,0(t1)
