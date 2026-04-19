import vpu_definitions::*;

/**
 "Simple" Multiplier without MAC support

 The number of used multipliers depend on ELEN
 For recommanded ELEN 32
 1 x  8 bit multipliers
 3 x 16 bit multipliers

            | SEW8     | SEW16   | SEW32
------------|------------------------------
 Lower part | 1 Cycle  | 1 Cycle | 1 Cycle
 upper part | 1 Cycle  | 1 Cycle | 2 Cycles
*/

module vpu_mult #(
  parameter ELEN = 32 // Element Length
)
(
  input logic clk_i,
  input logic rst_ni,

  input logic [ELEN-1:0]    op_a_i,
  input logic [ELEN-1:0]    op_b_i,

  input logic               enable_i,
  input logic               sign_i,
  input logic               upper_i,
  input sew_mode_e          sew_i,

  output logic [ELEN-1:0]   result_o,
  output mult_valid_s       valid_o
);

// signals to share the 3 16bit mulitpliers with 8bit and 32bit multiply calculation
logic signed [2:0][16:0] mul16_multiplex_op_a;
logic signed [2:0][16:0] mul16_multiplex_op_b;
logic signed [2:0][33:0] mul16_multiplex_res;

//  _____   _     _ _     _____ _____ _    _
// |  _  | | |   (_) |   /  ___|  ___| |  | |
//  \ V /  | |__  _| |_  \ `--.| |__ | |  | |
//  / _ \  | '_ \| | __|  `--. \  __|| |/\| |
// | |_| | | |_) | | |_  /\__/ / |___\  /\  /
// \_____/ |_.__/|_|\__| \____/\____/ \/  \/

logic signed [(ELEN/8)-1:0][ 8:0] mul8_op_a;
logic signed [(ELEN/8)-1:0][ 8:0] mul8_op_b;
logic signed [(ELEN/8)-1:0][15:0] mul8_res;

logic signed           [ELEN-1:0] mul8_comb_res_high;
logic signed           [ELEN-1:0] mul8_comb_res_low;

always_comb begin
  for (int i = 0; i < ELEN/8; i++) begin
    mul8_op_a[i] = {sign_i & op_a_i[i*8+7], op_a_i[i*8 +: 8]};
    mul8_op_b[i] = {sign_i & op_b_i[i*8+7], op_b_i[i*8 +: 8]};
  end
end

assign mul8_res[0] = mul16_multiplex_res[0][15:0];
assign mul8_res[1] = mul16_multiplex_res[1][15:0];
assign mul8_res[2] = mul16_multiplex_res[2][15:0];
assign mul8_res[3] = signed'(mul8_op_a[3]) * signed'(mul8_op_b[3]);


always_comb begin
  for (int i = 0; i < ELEN/8; i++) begin
    mul8_comb_res_high[i*8 +: 8] = mul8_res[i][15:8];
    mul8_comb_res_low [i*8 +: 8] = mul8_res[i][ 7:0];
  end
end


//  __    ____   _     _ _     _____ _____ _    _
// /  |  / ___| | |   (_) |   /  ___|  ___| |  | |
// `| | / /___  | |__  _| |_  \ `--.| |__ | |  | |
//  | | | ___ \ | '_ \| | __|  `--. \  __|| |/\| |
// _| |_| \_/ | | |_) | | |_  /\__/ / |___\  /\  /
// \___/\_____/ |_.__/|_|\__| \____/\____/ \/  \/
logic signed [(ELEN/16)-1:0][16:0] mul16_op_a;
logic signed [(ELEN/16)-1:0][16:0] mul16_op_b;
logic signed [(ELEN/16)-1:0][31:0] mul16_res;
logic signed            [ELEN-1:0] mul16_comb_res_high;
logic signed            [ELEN-1:0] mul16_comb_res_low;

always_comb begin
  for (int i = 0; i < ELEN/16; i++) begin
    mul16_op_a[i] = {sign_i & op_a_i[i*16+15], op_a_i[i*16 +: 16]};
    mul16_op_b[i] = {sign_i & op_b_i[i*16+15], op_b_i[i*16 +: 16]};
    mul16_res[i]  = mul16_multiplex_res[i];
  end
end

always_comb begin
  for (int i = 0; i < ELEN/16; i++) begin
    mul16_comb_res_high[i*16 +: 16] = mul16_res[i][31:16];
    mul16_comb_res_low [i*16 +: 16] = mul16_res[i][15: 0];
  end
end


//  _____  _____   _     _ _     _____ _____ _    _
// |____ |/ __  \ | |   (_) |   /  ___|  ___| |  | |
//     / /`' / /' | |__  _| |_  \ `--.| |__ | |  | |
//     \ \  / /   | '_ \| | __|  `--. \  __|| |/\| |
// .___/ /./ /___ | |_) | | |_  /\__/ / |___\  /\  /
// \____/ \_____/ |_.__/|_|\__| \____/\____/ \/  \/

// The 32 multiplier uses also 16 bit multipliers
typedef enum logic { MUL32_HIGH, MUL32_LOW
} mult_fsm_e;
mult_fsm_e                 mul32_state_q, mul32_state_d;

logic signed        [16:0] mul32_op_a_low;
logic signed        [16:0] mul32_op_a_high;
logic signed        [16:0] mul32_op_b_low;
logic signed        [16:0] mul32_op_b_high;
logic signed        [16:0] mul32_op_a_state;
logic signed        [16:0] mul32_op_b_state;

logic signed   [2:0][33:0] mul32_part_res;
logic signed   [2:0][33:0] mul32_summand;
logic signed        [31:0] mul32_res;
logic signed        [33:0] mul32_sum_q, mul32_sum_d;

always_comb begin
  mul32_op_a_low  = signed'({1'b0,                op_a_i[15: 0]});
  mul32_op_a_high = signed'({sign_i & op_a_i[31], op_a_i[31:16]});

  mul32_op_b_low  = signed'({1'b0,                op_b_i[15: 0]});
  mul32_op_b_high = signed'({sign_i & op_b_i[31], op_b_i[31:16]});
end

always_comb begin

  mul32_part_res[0] = mul16_multiplex_res[0]; // a_low  *b_low
  mul32_part_res[1] = mul16_multiplex_res[1]; // a_low  *b_high
  mul32_part_res[2] = mul16_multiplex_res[2]; // a_low  *b_high

end

always_comb begin

  // DEFAULT  MUL32_LOW
  mul32_op_a_state = signed'(mul32_op_a_high);
  mul32_op_b_state = signed'(mul32_op_b_low);
  mul32_summand[0] = { {17{1'b0}}, mul32_part_res[0][31:16]};
  mul32_summand[1] = mul32_part_res[1];
  mul32_summand[2] = mul32_part_res[2];
  mul32_res        = {mul32_sum_d[15:0], mul32_part_res[0][15:0]};
  mul32_state_d    = (sew_i == SEW32 && upper_i == 1'b1) ? MUL32_HIGH : MUL32_LOW;

  if (mul32_state_q ==  MUL32_HIGH) begin

    mul32_op_a_state   = signed'(mul32_op_a_high);
    mul32_op_b_state   = signed'(mul32_op_b_high);
    mul32_summand[0]   = { {17{sign_i & mul32_sum_q[33]}}, mul32_sum_q[33:16]};
    mul32_summand[1]   = mul32_part_res[2];
    mul32_summand[2]   = 0;
    mul32_res          = mul32_sum_d[31:0];
    mul32_state_d      = MUL32_LOW;
  end

end

assign mul32_sum_d =  mul32_summand[0] + mul32_summand[1] + mul32_summand[2];

// Sequential process
always_ff @ (posedge clk_i) begin

  if (rst_ni == 1'b0) begin

    mul32_sum_q   <= 0;
    mul32_state_q <= MUL32_LOW;

  end else begin

    if (enable_i) begin

      mul32_sum_q   <= mul32_sum_d;
      mul32_state_q <= mul32_state_d;

    end
  end
end

// ___  ____   _ _    _____ ___________ _   __   __ ___  ____   _ _    _____ ___________ _      _______   __ ___________
// |  \/  | | | | |  |_   _|_   _| ___ \ |  \ \ / / |  \/  | | | | |  |_   _|_   _| ___ \ |    |  ___\ \ / /|  ___| ___ \
// | .  . | | | | |    | |   | | | |_/ / |   \ V /  | .  . | | | | |    | |   | | | |_/ / |    | |__  \ V / | |__ | |_/ /
// | |\/| | | | | |    | |   | | |  __/| |    \ /   | |\/| | | | | |    | |   | | |  __/| |    |  __| /   \ |  __||    /
// | |  | | |_| | |____| |  _| |_| |   | |____| |   | |  | | |_| | |____| |  _| |_| |   | |____| |___/ /^\ \| |___| |\ \
// \_|  |_/\___/\_____/\_/  \___/\_|   \_____/\_/   \_|  |_/\___/\_____/\_/  \___/\_|   \_____/\____/\/   \/\____/\_| \_|

// There are 3 16bit Multipliers, which are shared between the different sew

always_comb begin

  case (sew_i)

    SEW8: begin

      mul16_multiplex_op_a[0] = signed'(mul8_op_a[0]);
      mul16_multiplex_op_b[0] = signed'(mul8_op_b[0]);

      mul16_multiplex_op_a[1] = signed'(mul8_op_a[1]);
      mul16_multiplex_op_b[1] = signed'(mul8_op_b[1]);

      mul16_multiplex_op_a[2] = signed'(mul8_op_a[2]);
      mul16_multiplex_op_b[2] = signed'(mul8_op_b[2]);

    end

    SEW16: begin

      mul16_multiplex_op_a[0] = mul16_op_a[0];
      mul16_multiplex_op_b[0] = mul16_op_b[0];

      mul16_multiplex_op_a[1] = mul16_op_a[1];
      mul16_multiplex_op_b[1] = mul16_op_b[1];

      mul16_multiplex_op_a[2] = 0;
      mul16_multiplex_op_b[2] = 0;

    end

    default: begin // SEW32

      mul16_multiplex_op_a[0] = mul32_op_a_low;
      mul16_multiplex_op_b[0] = mul32_op_b_low;

      mul16_multiplex_op_a[1] = mul32_op_a_low;
      mul16_multiplex_op_b[1] = mul32_op_b_high;

      mul16_multiplex_op_a[2] = mul32_op_a_state;
      mul16_multiplex_op_b[2] = mul32_op_b_state;
    end
  endcase
end

always_comb begin
  for (int i = 0; i < ELEN/32; i++) begin
    mul16_multiplex_res[0]  = signed'(mul16_multiplex_op_a[0]) * signed'(mul16_multiplex_op_b[0]);
    mul16_multiplex_res[1]  = signed'(mul16_multiplex_op_a[1]) * signed'(mul16_multiplex_op_b[1]);
    mul16_multiplex_res[2]  = signed'(mul16_multiplex_op_a[2]) * signed'(mul16_multiplex_op_b[2]);
  end
end

// ______ _____ _____ _   _ _    _____  ___  ____   _ _    _____ ___________ _      _______   __ ___________
// | ___ \  ___/  ___| | | | |  |_   _| |  \/  | | | | |  |_   _|_   _| ___ \ |    |  ___\ \ / /|  ___| ___ \
// | |_/ / |__ \ `--.| | | | |    | |   | .  . | | | | |    | |   | | | |_/ / |    | |__  \ V / | |__ | |_/ /
// |    /|  __| `--. \ | | | |    | |   | |\/| | | | | |    | |   | | |  __/| |    |  __| /   \ |  __||    /
// | |\ \| |___/\__/ / |_| | |____| |   | |  | | |_| | |____| |  _| |_| |   | |____| |___/ /^\ \| |___| |\ \
// \_| \_\____/\____/ \___/\_____/\_/   \_|  |_/\___/\_____/\_/  \___/\_|   \_____/\____/\/   \/\____/\_| \_|
//
logic lower;
logic upper;

assign lower = ((sew_i == SEW32 && mul32_state_q == MUL32_LOW ) || (sew_i != SEW32 && upper_i == 1'b0)) ? 1'b1 : 1'b0;
assign upper = ((sew_i == SEW32 && mul32_state_q == MUL32_HIGH) || (sew_i != SEW32 && upper_i == 1'b1)) ? 1'b1 : 1'b0;

always_comb begin
  case (sew_i)
    SEW8:     result_o = (upper_i == 1'b1) ? mul8_comb_res_high  : mul8_comb_res_low;
    SEW16:    result_o = (upper_i == 1'b1) ? mul16_comb_res_high : mul16_comb_res_low;
    SEW32:    result_o = mul32_res;
    default:  result_o = '0;
  endcase
end


assign  valid_o.lower = (enable_i == 1'b1 && lower == 1'b1) ? 1'b1 : 1'b0;
assign  valid_o.upper = (enable_i == 1'b1 && upper == 1'b1) ? 1'b1 : 1'b0;


endmodule
