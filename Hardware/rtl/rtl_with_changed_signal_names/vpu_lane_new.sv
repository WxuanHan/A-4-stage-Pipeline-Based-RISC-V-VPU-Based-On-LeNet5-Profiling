import vpu_definitions::*;

module vpu_lane_new #(
  parameter LLEN        = 128,                  // vector length
  parameter ELEN        = 32,                   // max. Element size
  parameter ITERATIONS  = LLEN/ELEN,            // Iterations
  parameter ELEN_B      = ELEN/8,
  parameter LLEN_B      = LLEN/8,
  parameter BW_I        = $clog2(ITERATIONS)
)
(
  input logic               clk_i,
  input logic               rst_ni,
  //--------------------------------------------
  // Inputs
  //--------------------------------------------
  // Register Addresses
  //input logic [4:0]          vs1_i,
  //input logic [4:0]          vs2_i,
  //input logic [4:0]          vs3_i,
  input logic [4:0]         vd_i,
  
  input logic [  LLEN-1:0]  rdata_a_i,
  input logic [  LLEN-1:0]  rdata_b_i,
  input logic [  LLEN-1:0]  rdata_c_i,
  
  output logic				we_a_o,
  output logic [  LLEN-1:0] wdata_a_o,
  // Environment
  input sew_mode_e          sew_i,
  //input logic [LLEN_B-1:0]  byte_enable_i,
  input logic [LLEN_B-1:0]  alu_cin_i,

  // arithmetic
  input alu_mode_s          alu_mode_i,
  input immediate_s         immediate_i,
  input mul_mode_s          mul_mode_i,
  // register file
  input logic               ls_enable_i,
  input mem_op_e            ls_op_i,
  input logic [LLEN-1:0]    load_data_i,
  //--------------------------------------------
  //Outputs
  //--------------------------------------------
  output logic              done_o,
  output logic [LLEN-1:0]   store_data_o,

  //--------------------------------------------
  // Debug
  //--------------------------------------------
  output logic [ELEN/8-1:0] dbg_alu_carry_o,
  output logic [ELEN-1:0]   dbg_arith_result_o,
  output logic              dbg_arith_valid_o,
  output logic [ BW_I:0]    dbg_iteration_o,
  output logic              dbg_rv_we_o
);

// wires for register file
//logic [       4:0] raddr_a;
//logic [       4:0] raddr_b;
//logic [       4:0] raddr_c;
//logic [  LLEN-1:0] rdata_a;
//logic [  LLEN-1:0] rdata_b;
//logic [  LLEN-1:0] rdata_c;

logic              we;
//logic [       4:0] waddr;
//logic [LLEN_B-1:0] wbe;
logic [  LLEN-1:0] wdata;

// wires for slicer
logic [ELEN-1:0] op_a;
logic [ELEN-1:0] op_b;
logic [ELEN-1:0] op_c;

// wires for execution unit inputs
logic [ELEN-1:0] arith_result;
logic            arith_valid;

//alu_mode_s          alu_mode;
//mul_mode_s          mul_mode;

/* vpu_register_file #(LLEN) reg_file (
  // Clock and Reset
  .clk_i              ( clk_i                 ),
  .rst_ni             ( rst_ni                ),
  // Read
  .raddr_b_i          ( vs1_i                 ),
  .rdata_b_o          ( rdata_b_i             ),

  .raddr_a_i          ( vs2_i                 ),
  .rdata_a_o          ( rdata_a_i             ),
  .raddr_c_i          ( vs3_i                 ),
  .rdata_c_o          ( rdata_c_i             ),
  // Write
  .we_a_i             ( we_a_o                ),
  .waddr_a_i          ( vd_i                  ),
  .wbe_a_i            ( byte_enable_i         ),
  .wdata_a_i          ( wdata_a_o             )
); */

vpu_arith_unit arith (
  .clk_i              ( clk_i                 ),
  .rst_ni             ( rst_ni                ),
  .operand_a_i        ( op_a                  ),
  .operand_b_i        ( op_b                  ),
  .operand_c_i        ( op_c                  ),
  .sew_i              ( sew_i                 ),
  .alu_mode_i         ( alu_mode_i            ),
  .mul_mode_i         ( mul_mode_i            ),
  .result_o           ( arith_result          ),
  .valid_o            ( arith_valid           ),
  .dbg_alu_carry_o    ( dbg_alu_carry_o       )
);

vpu_lane_controller #(
  .LLEN                ( LLEN                 ),
  .ELEN                ( ELEN                 )
) controller_i (
  .clk_i               ( clk_i                ),
  .rst_ni              ( rst_ni               ),
  .alu_mode_i          ( alu_mode_i           ),
  .alu_cin_i           ( alu_cin_i            ),
  .mul_mode_i          ( mul_mode_i           ),
  .sew_i               ( sew_i                ),
  .immediate_i         ( immediate_i          ),

  .rf_data_a_i         ( rdata_a_i            ),
  .rf_data_b_i         ( rdata_b_i            ),
  .rf_data_c_i         ( rdata_c_i            ),

  .ls_enable_i         ( ls_enable_i          ),
  .ls_op_i             ( ls_op_i              ),
  .load_data_i         ( load_data_i          ),

  .arith_result_i      ( arith_result         ),
  .arith_valid_i       ( arith_valid          ),

  .op_a_o              ( op_a                 ),
  .op_b_o              ( op_b                 ),
  .op_c_o              ( op_c                 ),

  .we_o                ( we                   ),
  .wdata_o             ( wdata                ),

  .done_o              ( done_o               ),

  .dbg_iteration_o     ( dbg_iteration_o      )
);

// Read Addresses for Register File Part
//assign raddr_b  = vs1_i;
//assign raddr_a  = vs2_i;
//assign raddr_c  = vs3_i;
//assign wbe      = byte_enable_i;
//assign waddr    = vd_i;

// Use we and wdata to get always latest value for store (bypass)
assign store_data_o = (vd_i == '0 && we) ? wdata : rdata_c_i;
assign we_a_o = we;
assign wdata_a_o = wdata;

// Debug
assign dbg_arith_result_o = arith_result;
assign dbg_arith_valid_o  = arith_valid;
assign dbg_rv_we_o        = we;

endmodule : vpu_lane_new
