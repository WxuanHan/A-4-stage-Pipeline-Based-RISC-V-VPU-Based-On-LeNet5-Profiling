import vpu_definitions::*;

module vpu_arith_unit #(
  parameter ELEN        = 32                   // max. Element size
)
(
  input logic clk_i,
  input logic rst_ni,

  input logic [   ELEN-1:0] operand_a_i,
  input logic [   ELEN-1:0] operand_b_i,
  input logic [   ELEN-1:0] operand_c_i,

  input sew_mode_e          sew_i,

  // ALU Inputs
  input alu_mode_s          alu_mode_i,

  // Multiplier Inputs
  input mul_mode_s          mul_mode_i,

  output logic [  ELEN-1:0] result_o,
  output logic              valid_o,

  //Debug
  output logic [ELEN/8-1:0] dbg_alu_carry_o
);

// wires for alu results
logic [ELEN-1:0]    alu_op_a, alu_op_b;
logic [ELEN/8-1:0]  alu_cin;
alu_op_e            alu_op;
logic [ELEN-1:0]    alu_result;
logic [ELEN/8-1:0]  alu_cout;

// wires for multiplier results
logic [ELEN-1:0]    mul_op_a, mul_op_b;
logic               mul_enable;
logic               mul_upper;
logic [ELEN-1:0]    mul_result;
mult_valid_s        mul_valid;

// wires for execution results
logic [ELEN-1:0] result;
logic            valid;

vpu_alu #(ELEN) alu (
  .op_a_i             ( alu_op_a              ),
  .op_b_i             ( alu_op_b              ),
  .carry_i            ( alu_cin               ),
  .alu_op_i           ( alu_op                ),
  .sew_i              ( sew_i                 ),
  .result_o           ( alu_result            ),
  .carry_o            ( alu_cout              )
);

vpu_mult #(ELEN) multiplier (
  .clk_i              ( clk_i                 ),
  .rst_ni             ( rst_ni                ),
  .sew_i              ( sew_i                 ),
  .op_a_i             ( mul_op_a              ),
  .op_b_i             ( mul_op_b              ),
  .enable_i           ( mul_enable            ),
  .sign_i             ( mul_mode_i.sign       ),
  .upper_i            ( mul_upper             ),
  .result_o           ( mul_result            ),
  .valid_o            ( mul_valid             )
);

// ___  ___  ___  _____     _____ _        _                            _     _
// |  \/  | / _ \/  __ \   /  ___| |      | |                          | |   (_)
// | .  . |/ /_\ \ /  \/   \ `--.| |_ __ _| |_ ___ _ __ ___   __ _  ___| |__  _ _ __   ___
// | |\/| ||  _  | |        `--. \ __/ _` | __/ _ \ '_ ` _ \ / _` |/ __| '_ \| | '_ \ / _ \
// | |  | || | | | \__/\   /\__/ / || (_| | ||  __/ | | | | | (_| | (__| | | | | | | |  __/
// \_|  |_/\_| |_/\____/   \____/ \__\__,_|\__\___|_| |_| |_|\__,_|\___|_| |_|_|_| |_|\___|


typedef enum logic[2:0] {
MAC_IDLE = 3'b001,
MAC_LOW  = 3'b010,
MAC_HIGH = 3'b100
} mac_fsm_e;
mac_fsm_e           mac_state_q, mac_state_d;

logic               mac_enable;
logic				sum_enable;
logic               mac_mul_enable;
logic               mac_mul_upper;

logic [ELEN-1:0]    mac_alu_op_a, mac_alu_op_b;
logic [ELEN/8-1:0]  addend_sign;
logic [  ELEN-1:0]  addend_ext;

logic [ELEN/8-1:0]  mac_alu_cin;
logic [ELEN-1:0]    mac_result;
logic               mac_valid;

logic [ELEN/8-1:0]  alu_cout_d, alu_cout_q;
logic [ELEN-1:0]    mul_result_d, mul_result_q;

assign mac_enable = mul_mode_i.enable & mul_mode_i.mac;
assign sum_enable = mul_mode_i.enable & mul_mode_i.redsum;
assign mul_enable = (mac_enable == 1'b1) ? mac_mul_enable : mul_mode_i.enable;
assign mul_upper  = (mac_enable == 1'b1) ? mac_mul_upper  : mul_mode_i.upper;

always_comb begin : mac_statemachine

  mac_alu_op_a    = 0;
  mac_alu_op_b    = 0;
  mac_alu_cin     = 0;
  mac_mul_enable  = 0;
  mac_mul_upper   = mul_mode_i.upper;

  mac_valid       = 1'b0;
  mac_state_d     = mac_state_q;

  mul_result_d    = mul_result_q;
  alu_cout_d      = alu_cout_q;


  case (mac_state_q)

    MAC_IDLE: begin // calculate mul_result_low

      mac_mul_enable = 1;
      mac_mul_upper  = (sew_i == SEW32) ? mul_mode_i.upper : 1'b0;

      if (mac_enable == 1'b1 && mul_valid.lower == 1'b1) begin
        mac_state_d   = MAC_LOW;
        mul_result_d  = mul_result;

      end else  begin

        mac_state_d     = MAC_IDLE;

      end
    end

    MAC_LOW: begin // add mac_res_low = op_c + mul_res_low

      // inputs for Alu
      mac_alu_op_a    = mul_result_q;
      mac_alu_op_b    = operand_c_i;
      mac_alu_cin     = {(ELEN/8-1){1'b0}};

      // mult enable calculation for upper part
      mac_mul_enable  = (mul_mode_i.upper == 1'b1) ? 1'b1 : 1'b0;

      if (mul_mode_i.upper == 1'b0) begin
        mac_valid       = 1'b1;
        mac_state_d     = MAC_IDLE;
      end else if (mul_valid.upper == 1'b1) begin
        mul_result_d    = mul_result;
        alu_cout_d      = alu_cout;
        mac_state_d     = MAC_HIGH;
      end
    end

    MAC_HIGH: begin // add mac_high = carry_out (of mac_res_low) + mul_res_high
      // inputs for Alu
      mac_alu_op_a    = mul_result_q;
      mac_alu_op_b    = addend_ext;
      mac_alu_cin     = alu_cout_q;
      //input multiplier
      mac_mul_enable  = 1'b0;
      mac_mul_upper   = 1'b0;
      //outputs
      mac_valid       = 1'b1;
      mac_state_d     = MAC_IDLE;
    end

    default: mac_state_d     = MAC_IDLE;
  endcase
end : mac_statemachine

// sign for addendend for upper half of mac result
always_comb begin
  for (int i = 0; i < (ELEN/8); i++) begin
   addend_sign[i] = mul_mode_i.sign & operand_c_i[(i*8)+7 +: 1];
  end
end

// sign extension for addendend for upper half of mac result
always_comb begin

  addend_ext = '0;

  case (sew_i)

    SEW8: begin
      for (int i = 0; i < ELEN/8; i++)
        addend_ext[i*8 +: 8] = { 8{addend_sign[i]}};
    end

    SEW16: begin
      for (int i = 0; i < ELEN/16; i++)
        addend_ext[(i)*16 +: 16] = {16{addend_sign[i*2]}};
    end

    SEW32: begin
      for (int i = 0; i < ELEN/32; i++)
        addend_ext[(i)*32 +: 32] = {32{addend_sign[i*4]}};
    end

    default: addend_ext = '0;

  endcase
end

// Sequential process
always_ff @ (posedge clk_i) begin

  if (rst_ni == 1'b0) begin

    mul_result_q  = 0;
    alu_cout_q    = 0;
    mac_state_q   = MAC_IDLE;

  end else begin

    if (mac_enable == 1'b1) begin
      mul_result_q  = mul_result_d;
      alu_cout_q    = alu_cout_d;
      mac_state_q   = mac_state_d;
    end

  end
end

// ___  ___      _ _   _       _               _                   _
// |  \/  |     | | | (_)     | |             (_)                 | |
// | .  . |_   _| | |_ _ _ __ | | _____  __    _ _ __  _ __  _   _| |_ ___
// | |\/| | | | | | __| | '_ \| |/ _ \ \/ /   | | '_ \| '_ \| | | | __/ __|
// | |  | | |_| | | |_| | |_) | |  __/>  <    | | | | | |_) | |_| | |_\__ \
// \_|  |_/\__,_|_|\__|_| .__/|_|\___/_/\_\   |_|_| |_| .__/ \__,_|\__|___/
//                      | |                           | |
//                      |_|                           |_|
//
always_comb begin : inputs_alu

  if (alu_mode_i.enable == '1) begin

    alu_op   = alu_mode_i.op;
    alu_op_a = operand_a_i;
    alu_op_b = operand_b_i;
    alu_cin  = (alu_mode_i.cin_en == '1) ? operand_c_i[ELEN/8-1:0] : '0;

  end else if (mac_enable == '1) begin

    alu_op   = ADD;
    alu_op_a = mac_alu_op_a;
    alu_op_b = mac_alu_op_b;
    alu_cin  = mac_alu_cin;
  end else if (sum_enable == 1'b1)begin
	alu_op   = ADD;
	alu_op_a = operand_a_i;
    alu_op_b = operand_b_i;
  end else begin

    alu_op   = ADD;
    alu_op_a = {(ELEN-1){1'b0}};
    alu_op_b = {(ELEN-1){1'b0}};
    alu_cin  = {(ELEN/8){1'b0}};

  end
end : inputs_alu

always_comb begin : inputs_multiplier

  if (mul_enable) begin
    mul_op_a = operand_a_i;
    mul_op_b = operand_b_i;
  end else begin
    mul_op_a = {ELEN{1'b0}};
    mul_op_b = {ELEN{1'b0}};
  end

end : inputs_multiplier

assign mac_result = alu_result;

// ___  ___      _ _   _       _                           _               _
// |  \/  |     | | | (_)     | |                         | |             | |
// | .  . |_   _| | |_ _ _ __ | | _____  __     ___  _   _| |_ _ __  _   _| |_ ___
// | |\/| | | | | | __| | '_ \| |/ _ \ \/ /    / _ \| | | | __| '_ \| | | | __/ __|
// | |  | | |_| | | |_| | |_) | |  __/>  <    | (_) | |_| | |_| |_) | |_| | |_\__ \
// \_|  |_/\__,_|_|\__|_| .__/|_|\___/_/\_\    \___/ \__,_|\__| .__/ \__,_|\__|___/
//                      | |                                   | |
//                      |_|                                   |_|
//
always_comb begin : outputs

  if (alu_mode_i.enable == '1 || sum_enable == '1) begin

    valid  = '1;
    result = alu_result;

  end else if (mul_mode_i.enable == '1) begin

    valid  = (mul_mode_i.mac) ? mac_valid   : ((mul_mode_i.upper) ? mul_valid.upper : mul_valid.lower);
    result = (mul_mode_i.mac) ? mac_result  : mul_result;

  end else begin

    valid  = 1'b0;
    result = 0;

  end

end : outputs

assign result_o     = result;
assign valid_o      = valid;

//Debug
assign dbg_alu_carry_o = alu_cout;

endmodule
