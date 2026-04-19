/**
* Simple ALU
*
* The ALU spports add, subtract, logical and arithmetical shifting
* Further, it has the typical flags: Carry_in, Carry_out, Overflow, Sign and Zero
*/

import vpu_definitions::*;

module vpu_alu #(
  parameter ELEN = 32 // Standard Element Width
)
(
  input logic [ELEN-1:0]      op_a_i,
  input logic [ELEN-1:0]      op_b_i,
  input logic [ELEN/8-1:0]    carry_i,
  input alu_op_e              alu_op_i,
  input sew_mode_e            sew_i,

  output logic [ELEN-1:0]     result_o,
  output logic [ELEN/8-1:0]   carry_o

);

localparam BW_ELEN = $clog2(ELEN);
//   ___ ____________            _____ _   _______
//  / _ \|  _  \  _  \   ___    /  ___| | | | ___ \
// / /_\ \ | | | | | |  ( _ )   \ `--.| | | | |_/ /
// |  _  | | | | | | |  / _ \/\  `--. \ | | | ___ \
// | | | | |/ /| |/ /  | (_>  < /\__/ / |_| | |_/ /
// \_| |_/___/ |___/    \___/\/ \____/ \___/\____/
//

//Internal Logic for opcode ADD and SUB
logic [       ELEN-1:0] op_b_neg;
logic                   is_subtract;
logic [       ELEN-1:0] add_a;
logic [       ELEN-1:0] add_b;
logic [     ELEN/8-1:0] add_carry_in;
logic [     ELEN/8-1:0] add_carry_out;
logic [ELEN+ELEN/8  :0] add_a_exp;
logic [ELEN+ELEN/8  :0] add_b_exp;
logic [ELEN+ELEN/8  :0] add_result_exp;
logic [       ELEN-1:0] add_result;

// 1. complement, by correct extension it
assign op_b_neg    = ~op_b_i;
assign is_subtract = (alu_op_i == SUBTRACT) ? 1'b1 : 1'b0;

assign add_a = op_a_i;
assign add_b = (is_subtract) ? op_b_neg :op_b_i;

always_comb begin : addition_carry_in
  for (int i = 0; i < ELEN/8; i++) begin
    add_carry_in[i] = is_subtract ^ carry_i[i];
  end
end : addition_carry_in

always_comb begin : expands_operands

  // prepare operands
  for (int i = 0; i < ELEN/8; i++) begin

    // operand byte + fill bit
    add_a_exp[(i*9+1) +: 8] = add_a[i*8+: 8];
    add_b_exp[(i*9+1) +: 8] = add_b[i*8+: 8];

  end

  // prepare first carries
  add_a_exp[0] = 1'b1;
  add_b_exp[0] = add_carry_in[0];

  for (int i = 1; i < ELEN/8; i++) begin

    case (sew_i)

      SEW8: begin
        add_a_exp[(i*9) +: 1] = add_carry_in[i];
        add_b_exp[(i*9) +: 1] = add_carry_in[i];
      end

      SEW16: begin
        add_a_exp[(i*9) +: 1] = (i%2 == 0) ?  add_carry_in[i] : 1'b1;
        add_b_exp[(i*9) +: 1] = (i%2 == 0) ?  add_carry_in[i] : 1'b0;
      end

      SEW32: begin
        add_a_exp[(i*9) +: 1] = (i%4 == 0) ?  add_carry_in[i] : 1'b1;
        add_b_exp[(i*9) +: 1] = (i%4 == 0) ?  add_carry_in[i] : 1'b0;
      end

      default: begin
        add_a_exp[(i*9) +: 1] = 1'b1;
        add_b_exp[(i*9) +: 1] = 1'b0;
      end

    endcase
  end

  // to use unsigned addition and able to get carry out
  add_a_exp[ELEN+ELEN/8] = 0;
  add_b_exp[ELEN+ELEN/8] = 0;


end : expands_operands

assign add_result_exp = add_a_exp + add_b_exp;

always_comb begin
  for (int i = 0; i < ELEN/8; i++) begin
    add_result[i*8 +: 8] = add_result_exp[(i*9)+1 +: 8];
  end
end

always_comb begin

  add_carry_out = {(ELEN/8-1){1'b0}};

  for (int i = 0; i < ELEN/8; i++) begin
    case (sew_i)
      SEW8:     add_carry_out[i] = (is_subtract) ? ~add_result_exp[(i+1)*9 +: 1] : add_result_exp[(i+1)*9 +: 1];
      SEW16:    add_carry_out[i] = (i%2 == 0) ?  ((is_subtract) ? ~add_result_exp[(i+2)*9 +: 1] : add_result_exp[(i+2)*9 +: 1]) : 1'b0;
      SEW32:    add_carry_out[i] = (i%4 == 0) ?  ((is_subtract) ? ~add_result_exp[(i+4)*9 +: 1] : add_result_exp[(i+4)*9 +: 1]) : 1'b0;
      default:  add_carry_out[i] = 0;
    endcase
  end

end
//  _____ _   _ ___________ _____
// /  ___| | | |_   _|  ___|_   _|
// \ `--.| |_| | | | | |_    | |
//  `--. \  _  | | | |  _|   | |
// /\__/ / | | |_| |_| |     | |
// \____/\_| |_/\___/\_|     \_/
//

//Internal Logic for opcode SHIFT operations
logic [ELEN-1:0] op_a_rev;
logic [ELEN-1:0] shift_operand;
logic              shift_left;
logic              shift_arith;
logic [ELEN-1:0] shift_amt_left;
logic [ELEN-1:0] shift_amt_right;
logic [ELEN-1:0] shift_amt;
logic [ELEN-1:0] shift_left_res;
logic [ELEN-1:0] shift_right_res;
logic [ELEN-1:0] shift_result;

logic [ELEN/ 8-1:0][ 8:0] shift_operand_8;
logic [ELEN/16-1:0][16:0] shift_operand_16;
logic [ELEN/32-1:0][32:0] shift_operand_32;

logic [ELEN/ 8-1:0][ 7:0] shift_right_res_8;
logic [ELEN/16-1:0][15:0] shift_right_res_16;
logic [ELEN/32-1:0][31:0] shift_right_res_32;

generate
  genvar k;
  for(k = 0; k < ELEN; k++)  begin
    assign op_a_rev[k] = op_a_i[ELEN-1-k];
  end
endgenerate

always_comb begin

  shift_amt_right = '0;

  case (sew_i)

    SEW8: begin
      for (int i = 0; i < ELEN/8; i++) begin
        shift_amt_right[i*8 +: 3] = op_b_i[i*8 +: 3];
      end
    end

    SEW16: begin
      for (int i = 0; i < ELEN/16; i++) begin
        shift_amt_right[i*16 +: 4] = op_b_i[i*16 +: 4];
      end
    end

    SEW32: begin
      for (int i = 0; i < ELEN/32; i++) begin
        shift_amt_right[i*32 +: 5] = op_b_i[i*32 +: 5];
      end
    end

    default: begin
      shift_amt_right = '0;
    end

  endcase

end


always_comb begin

  shift_amt_left = '0;

  case (sew_i)

    SEW8: begin
      for (int i = 0; i < ELEN/8; i++) begin
        shift_amt_left[i*8 +: 3] = op_b_i[(ELEN/8-i-1)*8 +: 3];
      end
    end

    SEW16: begin
      for (int i = 0; i < ELEN/16; i++) begin
        shift_amt_left[i*16 +: 4] =op_b_i[(ELEN/16-i-1)*16 +: 4];
      end
    end

    SEW32: begin
      for (int i = 0; i < ELEN/32; i++) begin
        shift_amt_left[i*32 +: 5] = op_b_i[(ELEN/32-i-1)*32 +: 5];
      end
    end

    default: begin
      shift_amt_left = '0;
    end

  endcase

end

assign shift_left     = (alu_op_i == LOGIC_SHIFT_LEFT)  ? 1'b1 : 1'b0;
assign shift_arith    = (alu_op_i == ARITH_SHIFT_RIGHT) ? 1'b1 : 1'b0;
assign shift_operand  = (shift_left) ? op_a_rev : op_a_i;
assign shift_amt      = (shift_left) ? shift_amt_left : shift_amt_right;

// need one 33 bit shifter, one 17 bit shifter, two 8 bit shifter
always_comb begin : prepare_shift_operand_8

  for (int i = 0; i < ELEN/8; i++) begin
    shift_operand_8[i] = signed'({shift_arith & shift_operand[i*8+7], shift_operand[i*8 +: 8]});
  end

end : prepare_shift_operand_8

always_comb begin : prepare_shift_operand_16

  for (int i = 0; i < ELEN/16; i++) begin

    unique case (sew_i)
      SEW8:     shift_operand_16[i] = signed'(shift_operand_8[i*2]);
      default:  shift_operand_16[i] = signed'({shift_arith & shift_operand[i*16+15], shift_operand[i*16 +: 16]});

    endcase
  end

end : prepare_shift_operand_16

always_comb begin : prepare_shift_operand_32

  for (int i = 0; i < ELEN/32; i++) begin

    unique case (sew_i)
      SEW8:     shift_operand_32[i] = signed'(shift_operand_8[i*4]);
      SEW16:    shift_operand_32[i] = signed'(shift_operand_16[i*2]);
      default:  shift_operand_32[i] = signed'({shift_arith & shift_operand[i*32+31], shift_operand[i*32 +: 32]});
    endcase
  end

end : prepare_shift_operand_32

always_comb begin : use_33bit_shifter

  for (int i = 0; i < ELEN/32; i++) begin
    shift_right_res_32[i] = signed'(shift_operand_32[i]) >>> shift_amt[i*32 +: BW_ELEN];
  end

end : use_33bit_shifter

always_comb begin : use_17bit_shifter

  for (int i = 0; i < ELEN/16; i++) begin

    if (i%2 == 0) begin
      shift_right_res_16[i] = shift_right_res_32[i/2][15:0];
    end else
      shift_right_res_16[i] = signed'(shift_operand_16[i]) >>> shift_amt[i*16 +: BW_ELEN];
  end

end : use_17bit_shifter


always_comb begin : use_9bit_shifters

  for (int i = 0; i < ELEN/8; i++) begin

    if (i%2 == 0)  begin
      shift_right_res_8[i] = shift_right_res_16[i/2][7:0];
    end else begin
      shift_right_res_8[i] = signed'(shift_operand_8[i]) >>> shift_amt[i*8 +: BW_ELEN];
    end

  end

end : use_9bit_shifters


always_comb begin : mux_shift_right_res

  unique case (sew_i)
    SEW8: begin
      for (int i = 0; i < ELEN/8; i++) begin
        shift_right_res[i*8 +: 8] = shift_right_res_8[i];
      end
    end
    SEW16: begin
      for (int i = 0; i < ELEN/16; i++) begin
        shift_right_res[i*16 +: 16] = shift_right_res_16[i];
      end
    end
    SEW32: begin
      for (int i = 0; i < ELEN/32; i++) begin
        shift_right_res[i*32 +: 32] = shift_right_res_32[i];
      end
    end

    default:  shift_right_res = '0;

  endcase

end : mux_shift_right_res

// bit reverse the shift_right_result for left shifts
generate
genvar j;
  for(j = 0; j < ELEN; j++)
  begin
    assign shift_left_res[j] = shift_right_res[ELEN-1-j];
  end
endgenerate

assign shift_result = (shift_left) ? shift_left_res : shift_right_res;

//  _____ ________  _________  ___  ______ _____ _____  _____ _   _
// /  __ \  _  |  \/  || ___ \/ _ \ | ___ \_   _/  ___||  _  | \ | |
// | /  \/ | | | .  . || |_/ / /_\ \| |_/ / | | \ `--. | | | |  \| |
// | |   | | | | |\/| ||  __/|  _  ||    /  | |  `--. \| | | | . ` |
// | \__/\ \_/ / |  | || |   | | | || |\ \ _| |_/\__/ /\ \_/ / |\  |
//  \____/\___/\_|  |_/\_|   \_| |_/\_| \_|\___/\____/  \___/\_| \_/

logic [       ELEN-1: 0] comparison_result;
logic [     ELEN/8-1: 0] cmp_result;
logic [     ELEN/8-1: 0] cmp_signed;
logic [     ELEN/8-1: 0] is_equal;
logic [     ELEN/8-1: 0] is_greater;
logic [     ELEN/8-1: 0] is_equal_b;
logic [     ELEN/8-1: 0] is_greater_b;
logic [ELEN+ELEN/8-1: 0] cmp_op_a_s;
logic [ELEN+ELEN/8-1: 0] cmp_op_b_s;

// for signed compares
always_comb begin
  cmp_signed = {(ELEN/8){1'b0}};

  case (alu_op_i)

    LESS_S,
    LESS_EQUAL_S,
    GREATER_S:  begin

      for (int i = 0; i < ELEN/8; i++) begin
        case (sew_i)
          SEW8:     cmp_signed[i] = '1;
          SEW16:    cmp_signed[i] = (i%2 == 1) ? '1 : '0;
          SEW32:    cmp_signed[i] = (i%4 == 3) ? '1 : '0;
          default:  cmp_signed[i] = '0;
        endcase
      end

    end
  endcase
end

// prepare signed compare operands and compare {sign,byte} wise
always_comb begin
  for(int i = 0; i < ELEN/8; i++)  begin

    cmp_op_a_s[i*9 +: 9] = signed'({cmp_signed[i] & op_a_i[i*8+7], op_a_i[i*8 +: 8]});
    cmp_op_b_s[i*9 +: 9] = signed'({cmp_signed[i] & op_b_i[i*8+7], op_b_i[i*8 +: 8]});

    is_greater_b[i]      = (signed'(cmp_op_a_s[i*9 +: 9]) > signed'(cmp_op_b_s[i*9 +: 9]));

    is_equal_b[i]        = (op_a_i[i*8 +: 8] == op_b_i[i*8 +: 8]);
  end
end

// merge compare results in dependency of sew
always_comb begin

  is_equal   = {ELEN/8{1'b0}};
  is_greater = {ELEN/8{1'b0}};

  case (sew_i)

    SEW8:  begin
      is_equal   = is_equal_b;
      is_greater = is_greater_b;
    end

    SEW16: begin
      for (int i = 0; i < ELEN/8; i = i+2) begin
        is_equal[i +: 2]   = {2{is_equal_b[i+1]   & is_equal_b[i]}};
        is_greater[i +: 2] = {2{is_greater_b[i+1] | (is_equal_b[i+1] & is_greater_b[i])}};
      end
    end

    SEW32:  begin
      for (int i = 0; i < ELEN/8; i = i+4) begin
        is_equal[i +: 4]   = {4{is_equal_b[i+3] & is_equal_b[i+2] & is_equal_b[i+1] & is_equal_b[i]}};
        is_greater[i +: 4] = {4{is_greater_b[i+3] |
                                  (is_equal_b[i+3]  & (is_greater_b[i+2] |
                                  (is_equal_b[i+2]  & (is_greater_b[i+1] |
                                  (is_equal_b[i+1]  & (is_greater_b[i]   ))))))}};
      end
    end

    default: begin
      is_equal   = {ELEN/8{1'b0}};
      is_greater = {ELEN/8{1'b0}};
    end

  endcase
end

// get compare result (ELEN/8 bits)
always_comb begin

  cmp_result = '0;

  case (alu_op_i)
    EQUAL:                      cmp_result = is_equal;
    NOT_EQUAL:                  cmp_result = ~is_equal;
    LESS_U,LESS_S:              cmp_result = ~(is_greater | is_equal);
    LESS_EQUAL_U, LESS_EQUAL_S: cmp_result = ~is_greater;
    GREATER_U, GREATER_S:       cmp_result = is_greater;
    default:                    cmp_result = '0;
  endcase
end

// get final compare result (ELEN bits)
always_comb begin

  comparison_result = '0;

  for (int i = 0; i < ELEN/8; i++) begin
    case (sew_i)
      SEW8:     comparison_result[i*8] = cmp_result[i];
      SEW16:    comparison_result[i*8] = (i%2 == 0) ? cmp_result[i] : 1'b0;
      SEW32:    comparison_result[i*8] = (i%4 == 0) ? cmp_result[i] : 1'b0;
      default:  comparison_result[i*8] = '0;
    endcase

  end
end

// ______ _____ _____ _   _ _    _____   ___  ____   ___   __
// | ___ \  ___/  ___| | | | |  |_   _|  |  \/  | | | \ \ / /
// | |_/ / |__ \ `--.| | | | |    | |    | .  . | | | |\ V /
// |    /|  __| `--. \ | | | |    | |    | |\/| | | | |/   \
// | |\ \| |___/\__/ / |_| | |____| |    | |  | | |_| / /^\ \
// \_| \_\____/\____/ \___/\_____/\_/    \_|  |_/\___/\/   \/
//
always_comb begin

  result_o      = {(ELEN-1){1'b0}};
  carry_o       = {(ELEN/8-1){1'b0}};

  unique case (alu_op_i)

    ADD,
    SUBTRACT: begin
      result_o  = add_result;
      carry_o   = add_carry_out;
    end

    LOGIC_SHIFT_RIGHT,
    LOGIC_SHIFT_LEFT,
    ARITH_SHIFT_RIGHT:  result_o  = shift_result;
    EQUAL,
    NOT_EQUAL,
    LESS_U,
    LESS_S,
    LESS_EQUAL_U,
    LESS_EQUAL_S,
    GREATER_U,
    GREATER_S:         result_o = comparison_result;
    AND:               result_o = op_a_i & op_b_i;
    OR:                result_o = op_a_i | op_b_i;
    XOR:               result_o = op_a_i ^ op_b_i;

    default: begin
      result_o      = {(ELEN-1){1'b0}};
    end

  endcase
end

endmodule
