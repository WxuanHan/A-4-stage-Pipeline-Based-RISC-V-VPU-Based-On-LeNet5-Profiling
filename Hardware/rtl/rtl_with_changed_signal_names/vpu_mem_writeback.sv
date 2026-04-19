import vpu_definitions::*;
import insn_formats::*;

module vpu_writeback #(
  parameter VLEN        = 128,            // vector length
  parameter ELEN        = 32,             // max. Element size
  parameter LANES       = 2,              // Number of lanes
  parameter VLEN_B      = VLEN/8,         // vector length
  parameter BW_VL       = 8,
  parameter BW_I        = $clog2((VLEN/(LANES*ELEN))) // Bitwidth for iterations
)(
  input logic              			   clk_i,
  input logic                    	   rst_ni,
  input logic             [ LANES-1:0] lane_done_i,
  input logic 			  [VLEN_B-1:0] byte_enable_i,
  input logic                          if_req_i,
//  input logic              			   ls_valid_i,
  
  input logic  				    [ 4:0] vs1_i,
  input logic  				    [ 4:0] vs2_i,
  input logic  				    [ 4:0] vd_i,
  input logic  				    	   vm_i,
  input immediate_s			    	   immediate_i,
  input sew_mode_e					   sew_i,
  input logic 			   [BW_VL-1:0] vstart_i,
  input logic 			   [BW_VL-1:0] vl_i,
  input alu_mode_s					   alu_mode_i,
  input mul_mode_s					   mul_mode_i,
  input mem_mode_s					   mem_mode_i,
  
  output logic                         wb_gnt_o,
//  output logic       			[31:0] ls_address_o,
//  output logic 			  [VLEN_B-1:0] ls_byte_enable_o,	

  output logic  				[ 4:0] vs1_o,
  output logic  				[ 4:0] vs2_o,
  output logic  				[ 4:0] vd_o,
  output logic  					   vm_o,
  output immediate_s				   immediate_o,
  output sew_mode_e					   sew_o,
  output logic 			   [BW_VL-1:0] vstart_o,
  output logic 			   [BW_VL-1:0] vl_o,
  output alu_mode_s					   alu_mode_o,
  output mul_mode_s					   mul_mode_o,
  output mem_mode_s					   mem_mode_o,
  output logic						   lanes_done_o,
  
  input  logic              		   ls_req_i,
  input  logic              		   store_enable_i,
  input  logic 			  [  VLEN-1:0] store_data_i,
  output logic              		   ls_gnt_o,
  output logic              		   ls_valid_o,
  output logic 			  [  VLEN-1:0] load_data_o,
  output logic              		   data_req_o,
  output logic 			  [  ELEN-1:0] data_addr_o,
  output logic 			               data_we_o,
  output logic 			  [ELEN/8-1:0] data_be_o,
  output logic 			  [  ELEN-1:0] data_wdata_o,
  input  logic 			               data_gnt_i,
  input  logic 			  [  ELEN-1:0] data_rdata_i,
  input  logic 			               data_rvalid_i,
	
  output logic                         dbg_insn_complete_o,
  output logic                         dbg_wb_hs_o,
  output logic                         dbg_wb_en_o,
  output logic            [VLEN/8-1:0] dbg_byte_enable_o
);
logic             wb_gnt_d, wb_gnt_q;
logic [ 4:0]      vs1_d, vs1_q;
logic [ 4:0]      vs2_d, vs2_q;
logic [ 4:0]      vd_d, vd_q;
logic             vm_d, vm_q;
immediate_s       immediate_d, immediate_q;
sew_mode_e        sew_d, sew_q;
logic [BW_VL-1:0] vstart, vstart_d, vstart_q;
logic [BW_VL-1:0] vl_d, vl_q;
alu_mode_s        alu_mode_d, alu_mode_q;
mul_mode_s        mul_mode_d, mul_mode_q;
mem_mode_s        mem_mode_d, mem_mode_q;
logic             ls_valid;

// ______ ___________ _____ _     _____ _   _  _____
// | ___ \_   _| ___ \  ___| |   |_   _| \ | ||  ___|
// | |_/ / | | | |_/ / |__ | |     | | |  \| || |__
// |  __/  | | |  __/|  __|| |     | | | . ` ||  __|
// | |    _| |_| |   | |___| |_____| |_| |\  || |___
// \_|    \___/\_|   \____/\_____/\___/\_| \_/\____/
logic wb_hs;
logic wb_done_d, wb_done_q;
logic wb_en_d, wb_en_q;

assign wb_done_d = (mem_mode_d.enable) ? ls_valid : lanes_done_o;

assign wb_gnt_d = wb_done_d | ~wb_en_d;

// IF_ID->EX_WB
assign wb_hs    = (if_req_i) & (wb_gnt_q);
assign vs1_d       = (wb_hs) ? vs1_i : vs1_q;
assign vs2_d       = (wb_hs) ? vs2_i : vs2_q;
assign vd_d        = (wb_hs) ? vd_i : vd_q;
assign immediate_d = (wb_hs) ? immediate_i : immediate_q;
assign vm_d        = (wb_hs) ? vm_i : vm_q;
assign sew_d       = (wb_hs) ? sew_i : sew_q;
assign vstart_d    = (wb_hs) ? vstart_i : vstart_q;
assign vl_d        = (wb_hs) ? vl_i : vl_q;
assign wb_en_d  = (wb_hs) ? '1 : (wb_done_q) ? '0 : wb_en_q;

// enable gate
always_comb begin

  alu_mode_d = alu_mode_q;
  mul_mode_d = mul_mode_q;
  mem_mode_d = mem_mode_q;

  if (wb_hs == '1) begin
    alu_mode_d          = alu_mode_i;
    mul_mode_d          = mul_mode_i;
    mem_mode_d          = mem_mode_i;
  end else if (wb_en_d == '0) begin
    alu_mode_d.enable   = '0;
    mul_mode_d.enable   = '0;
    mem_mode_d.enable   = '0;
  end

end

always_ff @ (posedge clk_i) begin

  if (~rst_ni) begin

    wb_gnt_q <= '1;
    vs1_q       <= '0;
    vs2_q       <= '0;
    immediate_q <= '0;
    vm_q        <= '0;
    vd_q        <= '0;
    alu_mode_q  <= '0;
    mul_mode_q  <= '0;
    mem_mode_q  <= '0;
    sew_q       <= SEW32;
    vstart_q    <= '0;
    vl_q        <= '0;
    wb_en_q  <= '0;
    wb_done_q<= '0;

  end else begin

    wb_gnt_q <= wb_gnt_d;
    wb_en_q  <= wb_en_d;
    wb_done_q<= wb_done_d;
    vs1_q       <= vs1_d;
    vs2_q       <= vs2_d;
    immediate_q <= immediate_d;
    vm_q        <= vm_d;
    vd_q        <= vd_d;
    sew_q       <= sew_d;
    vstart_q    <= vstart_d;
    vl_q        <= vl_d;
    alu_mode_q  <= alu_mode_d;
    mul_mode_q  <= mul_mode_d;
    mem_mode_q  <= mem_mode_d;
  end

end

assign lanes_done_o    = &lane_done_i;
assign vs1_o = vs1_d;
assign vs2_o = vs2_d;
assign vd_o = vd_d;
assign vm_o = vm_d;
assign immediate_o = immediate_d;
assign sew_o = sew_d;
assign vstart_o = vstart_d;
assign vl_o = vl_d;
assign alu_mode_o = alu_mode_d;
assign mul_mode_o = mul_mode_d;
assign mem_mode_o = mem_mode_d;

//assign ls_address_o     = mem_mode_i.addr;
//assign ls_byte_enable_o = byte_enable_i;
assign wb_gnt_o      = wb_gnt_q;
// Debug
// so far all lanes are synchronous regarding rv_we and lanes
assign dbg_wb_hs_o     = wb_hs;
assign dbg_wb_en_o     = wb_en_d;
assign dbg_insn_complete_o= wb_done_d;
assign dbg_byte_enable_o  = byte_enable_i;

vpu_lsu #(
  .VLEN							( VLEN					  ), 
  .ELEN							( ELEN					  )
)lsu_inst
(
  .clk_i                        ( clk_i                   ),
  .rst_ni                       ( rst_ni                  ),

  // Internal memory to EX WB stage
  .ls_req_i                     ( ls_req_i                ),
  .ls_addr_i                    ( mem_mode_i.addr         ),
//  .ls_stride_i                ( mem_mode.stride         ),
  .ls_be_i                      ( byte_enable_i           ),
  .store_enable_i               ( store_enable_i          ),
  .store_data_i                 ( store_data_i            ),
  .ls_gnt_o                     ( ls_gnt_o                ),
  .ls_valid_o                   ( ls_valid                ),
  .load_data_o                  ( load_data_o             ),

  // External data memory interface
  .data_req_o                   ( data_req_o              ),
  .data_addr_o                  ( data_addr_o             ),
  .data_be_o                    ( data_be_o               ),
  .data_we_o                    ( data_we_o               ),
  .data_wdata_o                 ( data_wdata_o            ),
  .data_gnt_i                   ( data_gnt_i              ),
  .data_rvalid_i                ( data_rvalid_i           ),
  .data_rdata_i                 ( data_rdata_i            )
);

assign ls_valid_o = ls_valid;

endmodule
