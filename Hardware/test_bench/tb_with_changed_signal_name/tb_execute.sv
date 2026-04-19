`timescale 1ns / 1ps

import vpu_definitions::*;
import insn_formats::*;

module vpu_execute_tb();

parameter VLEN    = 128;                          // vector length (max 256)
parameter ELEN    = 32;                           // max. Element size
parameter LANES   = 2;                            // Number of lanes
parameter VLEN_B  = VLEN/8;                       // VLEN in Bytes
parameter BW_VL   = 8;                            // Reduced length of vstart and vl
parameter BW_I    = $clog2((VLEN/(LANES*ELEN)));   // Bitwidth for iterations

logic				clk_i;
logic				rst_ni;
logic [       4:0]  vd_i;
logic [  VLEN-1:0]  rdata_a_i;
logic [  VLEN-1:0]  rdata_b_i;
logic [  VLEN-1:0]  rdata_c_i;
logic				we_a_o;
logic [  VLEN-1:0]  wdata_a_o;

immediate_s         immediate_i;
sew_mode_e          sew_i;
logic [VLEN_B-1:0]  alu_cin_i;
alu_mode_s          alu_mode_i;
mul_mode_s          mul_mode_i;
logic               ls_enable_i;
mem_mode_s          mem_mode_i;
logic [  VLEN-1:0]  load_data_i;
logic [  VLEN-1:0]  store_data_o;
logic [ LANES-1:0]  lanes_done_o;
logic [LANES-1:0][ELEN/8-1:0] dbg_alu_carry_o;
logic [LANES-1:0][  ELEN-1:0] dbg_arith_result_o;
logic [LANES-1:0]             dbg_arith_valid_o;
logic            [    BW_I:0] dbg_iteration_o;

// Clock generation
initial begin
	clk_i = 1;
	forever #5 clk_i = ~clk_i; // 100 MHz Clock
end

initial begin
	rst_ni = 1'b0;
	vd_i = '0;
	rdata_a_i = '0;
	rdata_b_i = '0;
	rdata_c_i = '0;
	immediate_i = '0;
	sew_i = SEW8;
	alu_cin_i = '0;
	alu_mode_i = '0;
	mul_mode_i = '0;
	ls_enable_i = '0;
	mem_mode_i = '0;
	load_data_i = '0;
	#100;
	rst_ni = 1'b1; // release reset
	#20;
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
	
	// NOP
	ls_enable_i = 1'b0;
	mem_mode_i = {1'b0,32'h0000_0000,1'b0};
	#40;
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
	// VADC
	alu_mode_i = {1'b1,16'h0001,1'b1,1'b1};
	#20
	alu_mode_i = {1'b0,16'h0001,1'b0,1'b0};
	#40;
	alu_cin_i = '0;
	// VMACC
	rdata_a_i = {32'h0000_0001,32'h0000_0001,32'h0000_0001,32'h0000_0001};
	rdata_b_i = {32'h0000_0002,32'h0000_0002,32'h0000_0002,32'h0000_0002};
	rdata_c_i = {32'h0000_0003,32'h0000_0003,32'h0000_0003,32'h0000_0003};
	mul_mode_i = {1'b1,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0};
	#40;
	mul_mode_i = {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
	
	// VSUB (a-b)
	rdata_a_i = {32'h0000_0003,32'h0000_0003,32'h0000_0003,32'h0000_0003};
	rdata_b_i = {32'h0000_0002,32'h0000_0002,32'h0000_0002,32'h0000_0002};
	alu_cin_i = {(VLEN_B){1'b1}};
	alu_mode_i = {1'b1,16'h0002,1'b0,1'b1};
	#20
	alu_mode_i = {1'b0,16'h0002,1'b0,1'b0};
	#40;
	// VRSUB
	alu_mode_i = {1'b1,16'h0002,1'b0,1'b1};
	#20
	alu_mode_i = {1'b0,16'h0002,1'b0,1'b0};
	#40;
	// VSBC
	alu_mode_i = {1'b1,16'h0002,1'b1,1'b1};
	#20
	alu_mode_i = {1'b0,16'h0002,1'b0,1'b0};
	#40;
	alu_mode_i = {1'b0,16'h0002,1'b0,1'b0};
/* 	// VMSBC
	mul_mode_i = {1'b1,1'b0,1'b1,1'b1};
	#20;
	mul_mode_i = {1'b0,1'b0,1'b0,1'b0}; */
	
	// VAND
	rdata_a_i = {32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0};
	rdata_b_i = {32'hff00_ff00,32'hff00_ff00,32'hff00_ff00,32'hff00_ff00};
	alu_mode_i = {1'b1,16'h0020,1'b0,1'b0};
	#20
	alu_mode_i = {1'b0,16'h0020,1'b0,1'b0};
	#40;
	
	// VOR
	alu_mode_i = {1'b1,16'h0040,1'b0,1'b0};
	#20
	alu_mode_i = {1'b0,16'h0040,1'b0,1'b0};
	#40;
	
	// VXOR
	alu_mode_i = {1'b1,16'h0080,1'b0,1'b0};
	#20
	alu_mode_i = {1'b0,16'h0080,1'b0,1'b0};
	#40;
	
	// VMSEQ
	alu_mode_i = {1'b1,16'h0100,1'b0,1'b0};
	#20;
	rdata_a_i = {32'hffff_ffff,32'hffff_ffff,32'hffff_ffff,32'hffff_ffff};
	rdata_b_i = {32'hffff_ffff,32'hffff_ffff,32'hffff_ffff,32'hffff_ffff};
	#20
	alu_mode_i = {1'b0,16'h0100,1'b0,1'b0};
	#40;
	
	// VMSNE
	alu_mode_i = {1'b1,16'h0200,1'b0,1'b0};
	#20;
	rdata_a_i = {32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0};
	rdata_b_i = {32'hff00_ff00,32'hff00_ff00,32'hff00_ff00,32'hff00_ff00};
	#20
	alu_mode_i = {1'b0,16'h0200,1'b0,1'b0};
	#40;
	
	// VMSLTU
	alu_mode_i = {1'b1,16'h0400,1'b0,1'b0};
	#20;
	rdata_a_i = {32'hffff_ffff,32'hffff_ffff,32'hffff_ffff,32'hffff_ffff};
	rdata_b_i = {32'hffff_ffff,32'hffff_ffff,32'hffff_ffff,32'hffff_ffff};
	#20
	alu_mode_i = {1'b0,16'h0400,1'b0,1'b0};
	#40;
	
	// VMSLT
	alu_mode_i = {1'b1,16'h0800,1'b0,1'b0};
	#20;
	rdata_a_i = {32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0};
	rdata_b_i = {32'hff00_ff00,32'hff00_ff00,32'hff00_ff00,32'hff00_ff00};
	#20
	alu_mode_i = {1'b0,16'h0800,1'b0,1'b0};
	#40;
	
	// VMSLEU
	alu_mode_i = {1'b1,16'h1000,1'b0,1'b0};
	#20;
	rdata_a_i = {32'hffff_ffff,32'hffff_ffff,32'hffff_ffff,32'hffff_ffff};
	rdata_b_i = {32'hffff_ffff,32'hffff_ffff,32'hffff_ffff,32'hffff_ffff};
	#20
	alu_mode_i = {1'b0,16'h1000,1'b0,1'b0};
	#40;
	
	// VMSLE
	alu_mode_i = {1'b1,16'h2000,1'b0,1'b0};
	#20;
	rdata_a_i = {32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0};
	rdata_b_i = {32'hff00_ff00,32'hff00_ff00,32'hff00_ff00,32'hff00_ff00};
	#20
	alu_mode_i = {1'b0,16'h2000,1'b0,1'b0};
	#40;
	
	// VMSGTU
	alu_mode_i = {1'b1,16'h4000,1'b0,1'b0};
	#20;
	rdata_b_i = {32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0};
	rdata_a_i = {32'hff00_ff00,32'hff00_ff00,32'hff00_ff00,32'hff00_ff00};
	#20
	alu_mode_i = {1'b0,16'h4000,1'b0,1'b0};
	#40;
	
	// VMSGT
	alu_mode_i = {1'b1,16'h8000,1'b0,1'b0};
	#20;
	rdata_a_i = {32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0};
	rdata_b_i = {32'hff00_ff00,32'hff00_ff00,32'hff00_ff00,32'hff00_ff00};
	#20
	alu_mode_i = {1'b0,16'h8000,1'b0,1'b0};
	#40;
	
	// VSLL
	alu_mode_i = {1'b1,16'h0010,1'b0,1'b0};
	rdata_a_i = {32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0,32'hf0f0_f0f0};
	rdata_b_i = {32'h0000_0004,32'h0000_0004,32'h0000_0004,32'h0000_0004};
	#20
	alu_mode_i = {1'b0,16'h0010,1'b0,1'b0};
	#40
	
	// VSRL
	alu_mode_i = {1'b1,16'h0008,1'b0,1'b0};
	#20
	alu_mode_i = {1'b0,16'h0008,1'b0,1'b0};
	#40;
	
	// VSRA
	alu_mode_i = {1'b1,16'h0004,1'b0,1'b0};
	#20
	alu_mode_i = {1'b0,16'h0004,1'b0,1'b0};
	#40;
	
	// NOP
	alu_mode_i = {1'b0,16'h0000,1'b0,1'b0};
	#40
	
	// MUL
	rdata_a_i = {32'h0000_0003,32'h0000_0003,32'h0000_0003,32'h0000_0003};
	rdata_b_i = {32'h0000_0003,32'h0000_0003,32'h0000_0003,32'h0000_0003};
	rdata_c_i = {32'h0000_0003,32'h0000_0003,32'h0000_0003,32'h0000_0003};
	mul_mode_i = {1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
	#20
	mul_mode_i = {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
	#40
	
	// VMULH
	mul_mode_i = {1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0};
	#20
	mul_mode_i = {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
	#40;
	
	// VREDSUM
	mul_mode_i = {1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0};
	#30
	mul_mode_i = {1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0};
	#100;
	
	$finish;
end

vpu_execute#(
  .VLEN				  			( VLEN				  	  ),       
  .ELEN				  			( ELEN				  	  ),        
  .LANES				  		( LANES				  	  ),       
  .VLEN_B				  		( VLEN_B				  ),      
  .BW_VL				  		( BW_VL				  	  ),       
  .BW_I				  			( BW_I				  	  )        	
)vpu_execute_inst(
  .clk_i				  		( clk_i				  	  ),
  .rst_ni				  		( rst_ni				  ),
  .vd_i				  			( vd_i				  	  ),
  .rdata_a_i					( rdata_a_i				  ),
  .rdata_b_i					( rdata_b_i				  ),
  .rdata_c_i					( rdata_c_i				  ),
  .we_a_o						( we_a_o				  ),
  .wdata_a_o					( wdata_a_o				  ),
  
  .immediate_i		  			( immediate_i			  ),
  .sew_i				  		( sew_i				  	  ),
  .alu_cin_i			  		( alu_cin_i				  ),
  .alu_mode_i			  		( alu_mode_i			  ),
  .mul_mode_i			  		( mul_mode_i			  ),
  .ls_enable_i		  			( ls_enable_i			  ),
  .mem_mode_i			  		( mem_mode_i.op		  	  ),
  .load_data_i		  			( load_data_i			  ),
  .store_data_o		  			( store_data_o			  ),
  .lanes_done_o		  			( lanes_done_o			  ),
  // Debug Signals
  .dbg_alu_carry_o	  			( dbg_alu_carry_o		  ),
  .dbg_arith_result_o	  		( dbg_arith_result_o	  ),
  .dbg_arith_valid_o	  		( dbg_arith_valid_o       ),
  .dbg_iteration_o	  			( dbg_iteration_o		  )
);


endmodule