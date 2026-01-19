`timescale 1ns / 1ps

`define CLK 10

module testbench();

    // Parameters
    parameter DATA_DEPTH = 1024;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter PROT_WIDTH = 3;
    parameter RESP_WIDTH = 2;

    // Basic Signal
    logic                  clk       = 0;
    logic                  rstn      = 0;
    logic [ADDR_WIDTH-1:0] boot_addr = 32'h0000_0000;

    // Instruction Memory Interface (AXI4-Lite)
    logic                  m_axi_arready_fe;
    logic                  m_axi_arvalid_fe;
    logic [ADDR_WIDTH-1:0] m_axi_araddr_fe;
    logic [PROT_WIDTH-1:0] m_axi_arprot_fe;
    logic                  m_axi_rvalid_fe;
    logic [DATA_WIDTH-1:0] m_axi_rdata_fe;
    logic [RESP_WIDTH-1:0] m_axi_rresp_fe;
    logic                  m_axi_rready_fe;

    // HEX_FILE
    int hex_file  = 0;
    int inst_size = 1024;
    int data_size = 512;

    string hex;
    int fcheck;
    int freturn;

    initial forever clk = #(`CLK/2) ~clk;

    initial begin
        $fsdbDumpfile("CoreTop.fsdb");
        $fsdbDumpvars(0);
    end

    initial begin
        //
        hex_file = $fopen("test.hex", "r");
        // Load instruction to memory
        for (int i=0; i<inst_size; i++)
            begin : LOAD_INST_MEM
                fcheck  = $fgets(hex, hex_file);
                freturn = $sscanf(hex, "%x", i_MemoryModel.mem[i]);
            end
        // Load data to memory
        //for (int i=0; i<data_size; i++)
        //    begin : LOAD_DATA_MEM
        //        fcheck  = $fgets(hex, hex_file);
        //        freturn = $sscanf(hex, "%x\n", i_CoreTop.i6_DataMemory.mem[i]);
        //    end
        //
        // Set boot address (initial PC)
        boot_addr = 32'hFFFF_0000;
        #100;
        rstn = 1;

        //fork
        //    begin
        //        wait(testbench.i_CoreTop.i10_CSRTop.i0_CSR.mscratch == 32'h1234_FFFF);
        //        $display("Code Failed\n");
        //    end
        //
        //    begin
        //        wait(testbench.i_CoreTop.i10_CSRTop.i0_CSR.mscratch == 32'hFFFF_1234);
        //        $display("Code Finish\n");
        //    end
        //join_any
        
        #10;
        $finish;
    end

    //CoreTop i_CoreTop (
    //    boot_addr,
    //    clk,
    //    rstn
    //);
    MemoryModel #( 
        .DATA_WIDTH ( DATA_WIDTH ),
        .DATA_DEPTH ( DATA_DEPTH )
    ) i_MemoryModel (
        .mem_rdata  (),
        .mem_rvld   (),
        .mem_en     (),
        .mem_addr   (),
        .mem_wdata  (),
        .mem_wen    (),
        .CLK        ( clk  ),
        .RSTN       ( rstn )
    );

    Core #(
        .ADDR_WIDTH         ( ADDR_WIDTH         ),
        .DATA_WIDTH         ( DATA_WIDTH         ),
        .PROT_WIDTH         ( PROT_WIDTH         ),
        .RESP_WIDTH         ( RESP_WIDTH         ) 
    ) i_Core (
        // AR Channel (AXI4-Lite)
        .m_axi_arready_fe   ( m_axi_arready_fe   ),
        .m_axi_arvalid_fe   ( m_axi_arvalid_fe   ),
        .m_axi_araddr_fe    ( m_axi_araddr_fe    ),
        .m_axi_arprot_fe    ( m_axi_arprot_fe    ),
        //  R Channel (AXI4-Lite)
        .m_axi_rvalid_fe    ( m_axi_rvalid_fe    ),
        .m_axi_rdata_fe     ( m_axi_rdata_fe     ),
        .m_axi_rresp_fe     ( m_axi_rresp_fe     ),
        .m_axi_rready_fe    ( m_axi_rready_fe    ),
        // AW Channel
        .m_axi_awready_be   (      1'b1  ),
        // W Channel
        .m_axi_wready_be    (      1'b1  ),
        // B Channel
        .m_axi_bvalid_be    (      1'b0  ),
        .m_axi_bresp_be     ({( 2){1'b0}}),
        .m_axi_bid_be       ({( 4){1'b0}}),
        .m_axi_buser_be     ({(32){1'b0}}),
        // AR Channel
        .m_axi_arready_be   (      1'b1  ),
        // R Channel
        .m_axi_rvalid_be    (      1'b0  ),
        .m_axi_rdata_be     ({(32){1'b0}}),
        .m_axi_rresp_be     ({( 2){1'b0}}),
        .m_axi_rid_be       ({( 4){1'b0}}),
        .m_axi_rlast_be     (      1'b0  ),
        .m_axi_ruser_be     ({(32){1'b0}}),
        //
        .BOOT_ADDR          ( boot_addr  ),
        .CLK                ( clk        ),
        .RSTN               ( rstn       )
    );

endmodule