`timescale 1ns / 1ps

import vpu_definitions::*;
import insn_formats::*;

module vpu_core_tb();

parameter VLEN    = 128;                          // vector length (max 256)
parameter ELEN    = 32;                           // max. Element size
parameter LANES   = 2;                            // Number of lanes
parameter VLEN_B  = VLEN/8;                       // VLEN in Bytes
parameter BW_VL   = 8;                            // Reduced length of vstart and vl
parameter BW_I    = $clog2((VLEN/(LANES*ELEN)));   // Bitwidth for iterations

logic 				clk_i;
logic 				rst_ni;
logic				insn_req_i;
logic				insn_i;
logic [		 31:0]	cs_data_i;
logic [		 31:0]	ls_addr_i;
logic				inv_insn_i;

logic              		data_req_o;
logic 		  [  ELEN-1:0] data_addr_o;
logic                         data_we_o;
logic 		  [ELEN/8-1:0] data_be_o;
logic 		  [  ELEN-1:0] data_wdata_o;

logic 		               data_gnt_i;
logic 		  [  ELEN-1:0] data_rdata_i;
logic 		               data_rvalid_i;

// Clock generation
initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // 100 MHz Clock
end

initial begin
	rst_ni = 1'b0;
	insn_req_i = 1'b0;
	insn_data_i = 32'd0;
	insn_csr_i = 32'd0;
	insn_addr_i = 32'd0;
	inv_insn_i = 1'b0;
        data_req_o = '0;
        data_addr_o = '0;
        data_we_o = '0;
        data_be_o = '0;
        data_wdata_o = '0;
        data_gnt_i = '0;
        data_rdata_i = '0;
        data_rvalid_i = '0;

	#20;
	rst_ni = 1'b1;
	#20;
	
    
    // Test Case 1: Simple ALU operation (VADD)
	insn_i = {6'b000000, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // R-type: ADD x3, x1, x2
	if_id_req_i = 1'b1;    // Request signal active
	#10 if_id_req_i = 1'b0; // Simulate handshake;
	// VADD (a+b)
	sew_i = SEW32;
	vd_i = '0;
	rdata_a_i = {32'h0000_0001,32'h0000_0001,32'h0000_0001,32'h0000_0001};
	rdata_b_i = {32'h0000_0002,32'h0000_0002,32'h0000_0002,32'h0000_0002};
	alu_cin_i = {(VLEN_B){1'b1}};
	alu_mode_i = {1'b1,16'h0001,1'b0,1'b1};
	#20
	alu_mode_i = {1'b0,16'h0001,1'b0,1'b0};
	#40;
	
    // Test case 2: Load Operation
	#10;
	ls_addr_i = 32'h12345678;
	insn_i = {3'b010, 1'b1, 2'b01, 1'b1, 5'b00001, 5'b00010, 3'b010, 5'b00110, 7'b0000111}; 
	if_id_req_i = 1'b1;
	#10 if_id_req_i = 1'b0;
	// Load 
	ls_enable_i = 1'b1;
	sew_i = SEW8; // SEW8
	mem_mode_i = {1'b1,32'h0000_0000,1'b1};
	load_data_i = {32'h76543210,32'h76543210,32'h76543210,32'h76543210};
	#40;
	sew_i = SEW16; // SEW16
	load_data_i = {32'habcdefff,32'habcdefff,32'habcdefff,32'habcdefff};
	#40;
	sew_i = SEW32; // SEW32
	load_data_i = {32'ha5a5a5a5,32'ha5a5a5a5,32'ha5a5a5a5,32'ha5a5a5a5};
	#40;
	// LOAD DATA
	ex_wb_req_i = '0;
	vd_i = 5'd1;
	sew_i = SEW32;
	mem_mode_i = {1'b0,32'h0000_0008,1'b1};
	ls_req_i = '1;
	data_gnt_i = '1;
	#10;
	data_rvalid_i = '1;
	data_rdata_i = 32'h0000_0001;
	#10;
	data_rdata_i = 32'h0000_0002;
	#10;
	data_rdata_i = 32'h0000_0003;
	#10;
	data_gnt_i = '0;
	data_rdata_i = 32'h0000_0004;
	#10;
	ex_wb_req_i = '0;
	data_rvalid_i = '0;
	#100;
	
    // Test case 3: Store Operation
	#10;
	ls_addr_i = 32'h00000001;
	insn_i = {3'b010, 1'b1, 2'b01, 1'b1, 5'b00001, 5'b00010, 3'b010, 5'b00110, 7'b0100111}; 
	if_id_req_i = 1'b1;
	#10 if_id_req_i = 1'b0;
	// Store
	ls_enable_i = 1'b1;
	sew_i = SEW8; // SEW8
	mem_mode_i = {1'b1,32'h0000_0000,1'b1};
	load_data_i = {32'h76543210,32'h76543210,32'h76543210,32'h76543210};
	#40;
	sew_i = SEW16; // SEW16
	load_data_i = {32'habcdefff,32'habcdefff,32'habcdefff,32'habcdefff};
	#40;
	sew_i = SEW32; // SEW32
	load_data_i = {32'ha5a5a5a5,32'ha5a5a5a5,32'ha5a5a5a5,32'ha5a5a5a5};
	#40;

    // Finish simulation
    $finish;
end

vpu_core vpu_core_uut(
	.clk_i						( clk_i					),
	.rst_ni						( rst_ni				),
	// From CPU                     
	.if_id_req_i				( insn_req_i			),
	.if_id_gnt_o				( insn_gnt_o			),
									
	.insn_i						( insn_data_i			),
	.cs_data_i					( insn_csr_i			),
	.ls_addr_i					( insn_addr_i			),
	.inv_insn_i					( inv_insn_i			),
	// Pipelining                   
	.ex_wb_req_o				( ex_wb_req_o			),
	.ex_wb_gnt_i				( ex_wb_gnt_i			),
	// Decoder                      
	.insn_o						( insn_o				),
	.cs_data_o					( cs_data_o				),
	.ls_addr_o					( ls_addr_o				),
	.if_id_rvalid_o				( insn_rvalid_o			),
	.if_id_rcs_data_o			( insn_rcsr_o			)
);


endmodule
