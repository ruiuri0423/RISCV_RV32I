`timescale 1ns / 1ps

`define CLK 10

module testbench();

    // Parameters
    parameter DATA_DEPTH = 1024;

    parameter     ID_WIDTH = 4;
    parameter   ADDR_WIDTH = 32;
    parameter    LEN_WIDTH = 8;
    parameter   SIZE_WIDTH = 4;
    parameter  BURST_WIDTH = 2;
    parameter   LOCK_WIDTH = 1;
    parameter  CACHE_WIDTH = 4;
    parameter   PROT_WIDTH = 3;
    parameter    QOS_WIDTH = 4;
    parameter REGION_WIDTH = 4;
    parameter   USER_WIDTH = 32;
    parameter   DATA_WIDTH = 32;
    parameter   STRB_WIDTH = 4;
    parameter   RESP_WIDTH = 2;

    // Basic Signal
    logic                  clk       = 0;
    logic                  rstn      = 0;
    logic [ADDR_WIDTH-1:0] boot_addr = 32'h0000_0000;

    // Instruction Memory Interface (AXI4-Lite)
    logic                  m_aclk    = 0;
    logic                  m_aresetn = 0;
    logic                  m_axi_arready_fe;
    logic                  m_axi_arvalid_fe;
    logic [ADDR_WIDTH-1:0] m_axi_araddr_fe;
    logic [PROT_WIDTH-1:0] m_axi_arprot_fe;
    logic                  m_axi_rvalid_fe;
    logic [DATA_WIDTH-1:0] m_axi_rdata_fe;
    logic [RESP_WIDTH-1:0] m_axi_rresp_fe;
    logic                  m_axi_rready_fe;

    // AXI Master Wrapper
    // AW Channel
    logic                    m_axi_awready;
    logic                    m_axi_awvalid;
    logic [  ADDR_WIDTH-1:0] m_axi_awaddr;
    logic [  PROT_WIDTH-1:0] m_axi_awprot;
    // W Chan   DATA_WIDTHnel
    logic                    m_axi_wready;
    logic                    m_axi_wvalid;
    logic [  DATA_WIDTH-1:0] m_axi_wdata;
    logic [  STRB_WIDTH-1:0] m_axi_wstrb;
    // B Channel
    logic                    m_axi_bready;
    logic                    m_axi_bvalid;
    logic [  RESP_WIDTH-1:0] m_axi_bresp;
    // AR Channel
    logic                    m_axi_arready;
    logic                    m_axi_arvalid; 
    logic [  ADDR_WIDTH-1:0] m_axi_araddr;
    logic [  PROT_WIDTH-1:0] m_axi_arprot;
    // R Channel
    logic                    m_axi_rready;
    logic                    m_axi_rvalid;
    logic [  DATA_WIDTH-1:0] m_axi_rdata;
    logic [  RESP_WIDTH-1:0] m_axi_rresp;
    // USER
    logic                    u_wr_ren;
    logic                    u_wr_gnt;
    logic                    u_wr_rok  = 0;
    logic                    u_wr_req  = 0;
    logic [   LEN_WIDTH-1:0] u_wr_len  = 0;
    logic [  ADDR_WIDTH-1:0] u_wr_addr = 0;
    logic [  DATA_WIDTH-1:0] u_wr_data = 0;
    logic [  STRB_WIDTH-1:0] u_wr_strb = 0;
    logic [  DATA_WIDTH-1:0] u_rd_data;
    logic                    u_rd_wen;
    logic                    u_rd_gnt;
    logic                    u_rd_wok  = 0;
    logic                    u_rd_req  = 0;
    logic [   LEN_WIDTH-1:0] u_rd_len  = 0;
    logic [  ADDR_WIDTH-1:0] u_rd_addr = 0;

    // HEX_FILE
    int hex_file  = 0;
    int inst_size = 1024;
    int data_size = 512;

    string hex;
    int fcheck;
    int freturn;

    initial forever clk = #(`CLK/2) ~clk;
    initial forever m_aclk = #(`CLK/2) ~m_aclk;

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
                freturn = $sscanf(hex, "%x\n", i_InstructionMemory.inst.axi_mem_module.blk_mem_gen_v8_4_5_inst.memory[i]);
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
        m_aresetn = 1;

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

        // Simulation the AXI SRAM behavior
        @(posedge m_aclk);
        u_wr_rok  = 'd1;
        u_wr_req  = 'd1;
        u_wr_len  = 'd1;
        u_wr_addr = 'h0000_0004;
        u_wr_data = 'hAA55_AA55;
        u_wr_strb = {(STRB_WIDTH){1'b1}};
        fork
            begin
                wait (u_wr_gnt);
                @(posedge m_aclk);
                u_wr_rok  = 'd0;
                u_wr_req  = 'd0;
                u_wr_len  = 'd0;
                u_wr_addr = 'h0000_0000;
            end
            begin
                wait (u_wr_ren);
                u_wr_data = 'h0000_0000;
                u_wr_strb = {(STRB_WIDTH){1'b0}};
            end
        join

        @(posedge m_aclk);
        u_rd_wok  = 'd1;
        u_rd_req  = 'd1;
        u_rd_len  = 'd1;
        u_rd_addr = 'h0000_0004;
        fork
            begin
                wait (u_rd_gnt);
                @(posedge m_aclk);
                u_rd_wok  = 'd0;
                u_rd_req  = 'd0;
                u_rd_len  = 'd0;
                u_rd_addr = 'h0000_0000;
            end
            begin
                wait (u_rd_wen);
                $display("AXI read data is: %x", u_rd_data);
            end
        join
        
        #10000;
        $finish;
    end

    //CoreTop i_CoreTop (
    //    boot_addr,
    //    clk,
    //    rstn
    //);

    AxiMasterWrapper #(
        .ID_WIDTH     ( ID_WIDTH     ),
        .ADDR_WIDTH   ( ADDR_WIDTH   ),
        .LEN_WIDTH    ( LEN_WIDTH    ),
        .SIZE_WIDTH   ( SIZE_WIDTH   ),
        .BURST_WIDTH  ( BURST_WIDTH  ),
        .LOCK_WIDTH   ( LOCK_WIDTH   ),
        .CACHE_WIDTH  ( CACHE_WIDTH  ),
        .PROT_WIDTH   ( PROT_WIDTH   ),
        .QOS_WIDTH    ( QOS_WIDTH    ),
        .REGION_WIDTH ( REGION_WIDTH ),
        .USER_WIDTH   ( USER_WIDTH   ),
        .DATA_WIDTH   ( DATA_WIDTH   ),
        .STRB_WIDTH   ( STRB_WIDTH   ),
        .RESP_WIDTH   ( RESP_WIDTH   ) 
    ) i_AxiMasterWrapper (
        .aclk          ( m_aclk        ),
        .aresetn       ( m_aresetn     ),
      // AW Channel
        .m_axi_awready ( m_axi_awready ),
        .m_axi_awvalid ( m_axi_awvalid ),
        .m_axi_awaddr  ( m_axi_awaddr  ),
        .m_axi_awprot  ( m_axi_awprot  ),
      // W Chan   DATA_WIDTHnel
        .m_axi_wready  ( m_axi_wready  ),
        .m_axi_wvalid  ( m_axi_wvalid  ),
        .m_axi_wdata   ( m_axi_wdata   ),
        .m_axi_wstrb   ( m_axi_wstrb   ),
      // B Channel
        .m_axi_bready  ( m_axi_bready  ),
        .m_axi_bvalid  ( m_axi_bvalid  ),
        .m_axi_bresp   ( m_axi_bresp   ),
      // AR Channel
        .m_axi_arready ( m_axi_arready ),
        .m_axi_arvalid ( m_axi_arvalid ), 
        .m_axi_araddr  ( m_axi_araddr  ),
        .m_axi_arprot  ( m_axi_arprot  ),
      // R Channel
        .m_axi_rready  ( m_axi_rready  ),
        .m_axi_rvalid  ( m_axi_rvalid  ),
        .m_axi_rdata   ( m_axi_rdata   ),
        .m_axi_rresp   ( m_axi_rresp   ),
      // USER
        .u_wr_ren      ( u_wr_ren      ),
        .u_wr_gnt      ( u_wr_gnt      ),
        .u_wr_rok      ( u_wr_rok      ),
        .u_wr_req      ( u_wr_req      ),
        .u_wr_len      ( u_wr_len      ),
        .u_wr_addr     ( u_wr_addr     ),
        .u_wr_data     ( u_wr_data     ),
        .u_wr_strb     ( u_wr_strb     ),
        .u_rd_data     ( u_rd_data     ),
        .u_rd_wen      ( u_rd_wen      ),
        .u_rd_gnt      ( u_rd_gnt      ),
        .u_rd_wok      ( u_rd_wok      ),
        .u_rd_req      ( u_rd_req      ),
        .u_rd_len      ( u_rd_len      ),
        .u_rd_addr     ( u_rd_addr     ) 
    );

    blk_mem_gen_0 i_InstructionMemory (
      .rsta_busy     (                     ),  // output wire rsta_busy
      .rstb_busy     (                     ),  // output wire rstb_busy
      .s_aclk        ( m_aclk              ),  // input wire s_aclk
      .s_aresetn     ( m_aresetn           ),  // input wire s_aresetn
      .s_axi_awaddr  ( m_axi_awaddr        ),  // input wire [31 : 0] s_axi_awaddr
      .s_axi_awvalid ( m_axi_awvalid       ),  // input wire s_axi_awvalid
      .s_axi_awready ( m_axi_awready       ),  // output wire s_axi_awready
      .s_axi_wdata   ( m_axi_wdata         ),  // input wire [31 : 0] s_axi_wdata
      .s_axi_wstrb   ( m_axi_wstrb         ),  // input wire [3 : 0] s_axi_wstrb
      .s_axi_wvalid  ( m_axi_wvalid        ),  // input wire s_axi_wvalid
      .s_axi_wready  ( m_axi_wready        ),  // output wire s_axi_wready
      .s_axi_bresp   ( m_axi_bresp         ),  // output wire [1 : 0] s_axi_bresp
      .s_axi_bvalid  ( m_axi_bvalid        ),  // output wire s_axi_bvalid
      .s_axi_bready  ( m_axi_bready        ),  // input wire s_axi_bready
      .s_axi_araddr  ( m_axi_araddr        ),  // input wire [31 : 0] s_axi_araddr
      .s_axi_arvalid ( m_axi_arvalid       ),  // input wire s_axi_arvalid
      .s_axi_arready ( m_axi_arready       ),  // output wire s_axi_arready
      .s_axi_rdata   ( m_axi_rdata         ),  // output wire [31 : 0] s_axi_rdata
      .s_axi_rresp   ( m_axi_rresp         ),  // output wire [1 : 0] s_axi_rresp
      .s_axi_rvalid  ( m_axi_rvalid        ),  // output wire s_axi_rvalid
      .s_axi_rready  ( m_axi_rready        )   // input wire s_axi_rready
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