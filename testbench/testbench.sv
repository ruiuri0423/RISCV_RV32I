`timescale 1ns / 1ps

`define CLK 10

module testbench();

    reg        clk       = 0;
    reg        rstn      = 0;
    reg [31:0] boot_addr = 32'h0000_0000;

    initial forever clk = #(`CLK/2) ~clk;

    initial begin
        $fsdbDumpfile("CoreTop.fsdb");
        $fsdbDumpvars(0);
    end

    initial begin
        // Load Instruction to Memory
        $readmemh("test.hex", i_CoreTop.i1_InstMemory.mem);
        // Set boot address (initial PC)
        boot_addr = 32'hFFFF_0000;
        #100;
        rstn = 1;

        fork
            begin
                wait(testbench.i_CoreTop.i6_DataMemory.mem[1023] == 32'h1234_FFFF);
                $display("Code Failed\n");
            end
        
            begin
                wait(testbench.i_CoreTop.i6_DataMemory.mem[1023] == 32'hFFFF_1234);
                $display("Code Finish\n");
            end
        join_any

        $finish;
    end

    CoreTop i_CoreTop (
        boot_addr,
        clk,
        rstn
    );

endmodule