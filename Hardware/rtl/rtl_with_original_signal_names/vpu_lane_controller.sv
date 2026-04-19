import vpu_definitions::*;
import insn_formats::*;

module vpu_lane_controller #(
  parameter LLEN        = 128,                  // vector length
  parameter ELEN        = 32,                   // max. Element size
  parameter LLEN_B      = LLEN/8,
  parameter ITERATIONS  = LLEN/ELEN,
  parameter BW_I        = $clog2(ITERATIONS)
)
(
  input logic clk_i,
  input logic rst_ni,
  //--------------------------------------------
  // Inputs
  //--------------------------------------------

  input  alu_mode_s         alu_mode_i,
  input  mul_mode_s         mul_mode_i,

  input  sew_mode_e         sew_i,
  input  immediate_s        immediate_i,
  input  logic [LLEN_B-1:0] alu_cin_i,

  input  logic [  LLEN-1:0] rf_data_a_i,
  input  logic [  LLEN-1:0] rf_data_b_i,
  input  logic [  LLEN-1:0] rf_data_c_i,

  input  logic              arith_valid_i,
  input  logic [  ELEN-1:0] arith_result_i,

  input  logic              ls_enable_i,
  input  mem_op_e           ls_op_i,
  input  logic [  LLEN-1:0] load_data_i,

  //Outputs
  output logic [  ELEN-1:0] op_a_o,
  output logic [  ELEN-1:0] op_b_o,
  output logic [  ELEN-1:0] op_c_o,

  output logic              we_o,
  output logic [  LLEN-1:0] wdata_o,

  output logic              done_o,

  // Debug
  output logic [    BW_I:0] dbg_iteration_o
);


//localparam ITERATIONS = LLEN/ELEN;            // Iterations
//localparam BW_I       = $clog2(ITERATIONS);
localparam ELEN_B     = ELEN/8;

logic arith_enable;
logic next_iteration;
logic last_iteration;
logic [BW_I:0] iteration_q, iteration_d;


assign arith_enable   = mul_mode_i.enable | alu_mode_i.enable;
assign next_iteration = arith_valid_i & arith_enable;
assign last_iteration = (iteration_q == ITERATIONS-1) ? 1'b1 : 1'b0;

always_comb begin

  iteration_d = iteration_q;

  if (next_iteration == 1'b1)  begin
    iteration_d = (iteration_q + 1) % ITERATIONS;
  end

end

always_ff @ (posedge clk_i) begin
  if (~rst_ni) begin
    iteration_q <= 0;
  end else begin
    iteration_q <= iteration_d;
  end
end

logic [ELEN-1:0] immediate;

// Extend immediate to ELEN-1 in dependency of sew
always_comb begin : extend_immediate

  immediate = '0;

  case (sew_i)

    SEW8: begin
      for (int i = 0; i < ELEN/8; i++) begin
        immediate[i*8 +: 8] = signed'({immediate_i.sign & immediate_i.value[4], immediate_i.value});
      end
    end

    SEW16: begin
      for (int i = 0; i < ELEN/16; i++) begin
        immediate[i*16 +: 16] = signed'({immediate_i.sign & immediate_i.value[4], immediate_i.value});
      end
    end

    SEW32: begin
      for (int i = 0; i < ELEN/32; i++) begin
        immediate[i*32 +: 32] = signed'({immediate_i.sign & immediate_i.value[4], immediate_i.value});
      end
    end

    default: immediate = '0;

  endcase
end

logic [ELEN-1:0] slice_a;
logic [ELEN-1:0] slice_b;
logic [ELEN-1:0] slice_c;


always_comb begin : op_inputs

  slice_a = '0;
  slice_b = '0;
  slice_c = '0;

  for (int i = 0; i < ITERATIONS; i++) begin
    if (i == iteration_q ) begin
      slice_a = rf_data_a_i[ELEN*i +: ELEN];
      slice_b = (immediate_i.enable == 1'b1) ? immediate : rf_data_b_i[ELEN*i +: ELEN];
      slice_c = rf_data_c_i[ELEN*i +: ELEN];
    end
  end

end : op_inputs

logic [ELEN-1:0] op_a;
logic [ELEN-1:0] op_b;
logic [ELEN-1:0] op_c;

// reverse Substract (vrsub)
always_comb begin

  if (alu_mode_i.enable == '1 && alu_mode_i.op == SUBTRACT && immediate_i.enable == '1) begin

    op_a = slice_b;
    op_b = slice_a;

  end else begin

    op_a = slice_a;
    op_b = slice_b;

  end
end

// When cin is enabled, byte enable is cin
always_comb begin

  op_c = '0;

  if (alu_mode_i.enable == '1 && alu_mode_i.cin_en == '1) begin

    for (int i = 0; i < ITERATIONS; i++) begin
      if (iteration_q == i) begin
        op_c = { {(ELEN-ELEN_B){1'b0}}, alu_cin_i[ELEN_B*i +: ELEN_B]};
      end
    end

  end else  begin

    op_c = slice_c;

  end
end

logic [LLEN-1:0] arith_data_d, arith_data_q;
logic [LLEN-1:0] lane_sum;

always_comb begin : combine_arith_data

  arith_data_d = arith_data_q;
  //lane_sum_d = lane_sum_q;

  for (int i = 0; i < ITERATIONS; i++) begin
    if (i == iteration_q && arith_valid_i == 1'b1) begin
      arith_data_d[ELEN*i +: ELEN] = arith_result_i;
    end
	
/* 	if(i == 0 && arith_valid_i == 1'b1)begin
		lane_sum_d[ELEN*i +: ELEN] = arith_result_i;
	end
	else if(i > 0 && arith_valid_i == 1'b1)begin
		lane_sum_d[ELEN*i +: ELEN] = lane_sum_d[ELEN*(i-1) +: ELEN] + arith_result_i;
	end */
  end
end : combine_arith_data

assign lane_sum = {{(LLEN-ELEN){1'b0}},{arith_data_d[(LLEN-1) -: ELEN]+arith_data_d[0 +: ELEN]}};

//logic enable_d, enable_q;
logic done;
logic ls_enable;
logic we;
logic [LLEN-1:0] wdata;

assign ls_enable = ls_enable_i; //(enable_d == '1 ) ? ls_enable_i : '0;

always_comb begin : write_data
  if (arith_enable == '1) begin

    we    = last_iteration & arith_valid_i;
    wdata = arith_data_d;
  
  end else if (mul_mode_i.redsum == 1'b1) begin
    we    = last_iteration & arith_valid_i;
	wdata = lane_sum;

  end else if ( ls_enable == '1) begin

    we    = (ls_op_i == LOAD) ? 1'b1: 1'b0;
    wdata = load_data_i;

  end else begin

    we    = 1'b0;
    wdata = 0;

  end
end : write_data

/*
always_comb begin

  enable_d = enable_q;

  // External enable is only pulse -> widen it
  if (enable_i == '1) begin
    enable_d = '1;
  end

  // If lane is ready but no new enable_i, disable lane
  if (ready_q == '1 && enable_i == '0) begin
    enable_d = '0;
  end
end
*/

always_ff @ (posedge clk_i) begin
  if (~rst_ni) begin
//    enable_q  <= '0;
    arith_data_q  <= '0;
  end else begin
//    enable_q <= enable_d;
    arith_data_q <= arith_data_d;
  end
end


logic we_d;
logic [LLEN-1:0] wdata_d;

always_ff @ (posedge clk_i) begin
	if(~rst_ni) begin
		we_d <= 1'b0;
		wdata_d <= '0;
	end
	else begin
		we_d <= we;
		wdata_d <= wdata;
	end
end

// Ready for next instruction if
// 1. Register is writen
// 2. A Store operation is performed (Caller decide how long to hold the result
// 3. Nothing to do
assign done = (
  (ls_enable    == '1 && ls_op_i == STORE)  ||
//(arith_enable == '0 && ls_enable == '0) ||
  (we_d           == 1'b1)
) ? 1'b1 : 1'b0;

assign op_a_o       = op_a;
assign op_b_o       = op_b;
assign op_c_o       = op_c;
assign wdata_o      = wdata_d;
assign we_o         = we_d;
assign done_o       = done;

assign dbg_iteration_o = iteration_q;


endmodule : vpu_lane_controller
