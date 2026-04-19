`timescale 1ns / 1ps

import vpu_definitions::*;
import insn_formats::*;

module vpu_writeback_tb();
parameter VLEN    = 128;                          // vector length (max 256)
parameter ELEN    = 32;                           // max. Element size
parameter LANES   = 2;                            // Number of lanes
parameter VLEN_B  = VLEN/8;                       // VLEN in Bytes
parameter BW_VL   = 8;                            // Reduced length of vstart and vl
parameter BW_I    = $clog2((VLEN/(LANES*ELEN)));   // Bitwidth for iterations

logic        			   clk_i;
logic                 	   rst_ni;
logic         [ LANES-1:0] lane_done_i;
logic 		  [VLEN_B-1:0] byte_enable_i;
logic                      ex_wb_req_i;
logic  				[ 4:0] vs1_i;
logic  				[ 4:0] vs2_i;
logic  				[ 4:0] vd_i;
logic  				       vm_i;
immediate_s			       immediate_i;
sew_mode_e				   sew_i;
logic 		   [BW_VL-1:0] vstart_i;
logic 		   [BW_VL-1:0] vl_i;
alu_mode_s				   alu_mode_i;
mul_mode_s				   mul_mode_i;
mem_mode_s				   mem_mode_i;
logic                      ex_wb_gnt_o;
logic  				[ 4:0] vs1_o;
logic  				[ 4:0] vs2_o;
logic  				[ 4:0] vd_o;
logic  					   vm_o;
immediate_s				   immediate_o;
sew_mode_e				   sew_o;
logic 		   [BW_VL-1:0] vstart_o;
logic 		   [BW_VL-1:0] vl_o;
alu_mode_s				   alu_mode_o;
mul_mode_s				   mul_mode_o;
mem_mode_s				   mem_mode_o;
logic					   lanes_done_o;
logic              		   ls_req_i;
logic              		   store_enable_i;
logic 		  [  VLEN-1:0] store_data_i;
logic              		   ls_gnt_o;
logic              		   ls_valid_o;
logic 		  [  VLEN-1:0] load_data_o;
logic              		   data_req_o;
logic 		  [  ELEN-1:0] data_addr_o;
logic 			           data_we_o;
logic 		  [ELEN/8-1:0] data_be_o;
logic 		  [  ELEN-1:0] data_wdata_o;
logic 		               data_gnt_i;
logic 		  [  ELEN-1:0] data_rdata_i;
logic 		               data_rvalid_i;
logic                      dbg_insn_complete_o;
logic                      dbg_ex_wb_hs_o;
logic                      dbg_ex_wb_en_o;
logic         [VLEN/8-1:0] dbg_byte_enable_o;

// Clock generation
initial begin
	clk_i = 1;
	forever #5 clk_i = ~clk_i; // 100 MHz Clock
end

initial begin
	rst_ni = 1'b0;
	lane_done_i = '0;
	byte_enable_i = 16'hffff;
	ex_wb_req_i = '0;
	vs1_i = '0;
	vs2_i = '0;
	vd_i = '0;
	vm_i = '0;
	immediate_i = '0;
	sew_i = SEW8;
	vstart_i = '0;
	vl_i = '0;
	alu_mode_i = '0;
	mul_mode_i = '0;
	mem_mode_i = '0;
	ls_req_i = '0;
	store_enable_i = '0;
	store_data_i = '0;
	data_gnt_i = '0;
	data_rdata_i = '0;
	data_rvalid_i = '0;
	#100;
	rst_ni = 1'b1;
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
	$finish;
end

vpu_writeback #(
  .VLEN        			  		( VLEN					  ),            // vector length
  .ELEN        			  		( ELEN					  ),             // max. Element size
  .LANES       			  		( LANES				      ),              // Number of lanes
  .VLEN_B      			  		( VLEN_B				  ),         // vector length
  .BW_VL       			  		( BW_VL				      ),
  .BW_I        			  		( BW_I					  ) // Bitwidth for iterations
)vpu_writeback_inst(
  .clk_i				  		( clk_i					  ),
  .rst_ni				  		( rst_ni				  ),
  .lane_done_i			  		( lane_done_i			  ),
  .byte_enable_i			  	( byte_enable_i			  ),
  .ex_wb_req_i			  		( ex_wb_req_i			  ),	                                                  
  .vs1_i				  		( vs1_i  				  ),
  .vs2_i				  		( vs2_i 				  ),
  .vd_i					  		( vd_i					  ),
  .vm_i					  		( vm_i					  ),
  .immediate_i			  		( immediate_i			  ),
  .sew_i				  		( sew_i					  ),
  .vstart_i				  		( vstart_i				  ),
  .vl_i					  		( vl_i					  ),
  .alu_mode_i			  		( alu_mode_i			  ),
  .mul_mode_i			  		( mul_mode_i			  ),
  .mem_mode_i			  		( mem_mode_i			  ),
		                                                  
  .ex_wb_gnt_o			  		( ex_wb_gnt_o			  ),
  .vs1_o				  		( vs1_o				      ),
  .vs2_o				  		( vs2_o				      ),
  .vd_o					  		( vd_o					  ),
  .vm_o					  		( vm_o					  ),
  .immediate_o			  		( immediate_o			  ),
  .sew_o				  		( sew_o					  ),
  .vstart_o				  		( vstart_o				  ),
  .vl_o					  		( vl_o					  ),
  .alu_mode_o			  		( alu_mode_o			  ),
  .mul_mode_o			  		( mul_mode_o			  ),
  .mem_mode_o			  		( mem_mode_o			  ),
  .lanes_done_o			  		( lanes_done_o			  ),
  
  .ls_req_i						( ls_req_i				  ),
  .store_enable_i				( store_enable_i		  ),
  .store_data_i					( store_data_i			  ),
  .ls_gnt_o						( ls_gnt_o				  ),
  .ls_valid_o					( ls_valid_o			  ),
  .load_data_o					( load_data_o			  ),
  .data_req_o					( data_req_o			  ),
  .data_addr_o					( data_addr_o			  ),
  .data_we_o					( data_we_o				  ),
  .data_be_o					( data_be_o				  ),
  .data_wdata_o					( data_wdata_o			  ),
  .data_gnt_i					( data_gnt_i			  ),
  .data_rdata_i					( data_rdata_i			  ),
  .data_rvalid_i				( data_rvalid_i			  ),
		                                                  
  .dbg_insn_complete_o	  		( dbg_insn_complete_o	  ),
  .dbg_ex_wb_hs_o		  		( dbg_ex_wb_hs_o		  ),
  .dbg_ex_wb_en_o		  		( dbg_ex_wb_en_o		  ),
  .dbg_byte_enable_o	  		( dbg_byte_enable_o		  )
);


endmodule;