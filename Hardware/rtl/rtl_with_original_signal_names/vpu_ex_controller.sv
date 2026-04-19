import vpu_definitions::*;

module vpu_ex_controller #(
  parameter VLEN        = 128,          // vector length
  parameter ELEN        = 32,           // max. Element size
  parameter VLEN_B      = VLEN/8,       // vector length in bytes
  parameter BW_VL       = 8             // Bit width of VLEN
)
(
  //Lane Interface
  input  logic              clk_i,
  input  logic              rst_ni,

  input  logic [4:0]        vd_i,
  output logic [4:0]        vs3_o,

  // Signals to controll lanes
  input  logic              mac_insn_i,
  input  mem_mode_s         mem_mode_i,
  input  alu_mode_s         alu_mode_i,

  input  sew_mode_e         sew_i,
  input  logic [BW_VL-1:0]  vstart_i,
  input  logic [BW_VL-1:0]  vl_i,
  input  logic              vm_i,
  input  logic              lanes_done_i,
  input  logic [ VLEN-1:0]  store_data_i,
  output logic [VLEN_B-1:0] alu_cin_o,
  output logic [VLEN_B-1:0] byte_enable_o,

  // Internal data interface
  input  logic              ls_grant_i,
  input  logic              ls_valid_i,

  output logic              ls_request_o,
  output logic              store_enable_o,
  output logic [VLEN-1:0]   store_data_o,

  output logic              ls_enable_o
  );


//  ________  ___     _      _____      _____ _   _  _____ ___________
// /  ___|  \/  |    | |    /  ___|    |_   _| \ | |/  ___|_   _| ___ \
// \ `--.| .  . |    | |    \ `--.       | | |  \| |\ `--.  | | | |_/ /
//  `--. \ |\/| |    | |     `--. \      | | | . ` | `--. \ | | |    /
// /\__/ / |  | |    | |____/\__/ /     _| |_| |\  |/\__/ / | | | |\ \
// \____/\_|  |_/    \_____/\____/      \___/\_| \_/\____/  \_/ \_| \_|
typedef enum logic[2:0] { LS_IDLE, LS_HOLD, LS_RESP} ls_fsm_e;
ls_fsm_e ls_state_q, ls_state_d;

logic     ls_req;
logic     load_insn;
logic     store_insn;
logic     mem_insn;
mem_op_e  mem_op;

assign mem_insn   = mem_mode_i.enable;
assign mem_op     = mem_mode_i.op;
assign load_insn  = (mem_insn == '1 && mem_op == LOAD) ? 1'b1 : 1'b0;
assign store_insn = (mem_insn == '1 && mem_op == STORE)? 1'b1 : 1'b0;

always_comb begin

  ls_state_d  = ls_state_q;
  ls_req      = '0;

  case(ls_state_q)

    LS_IDLE: begin
      if (mem_insn == '1) begin
        ls_req      = '1;
        ls_state_d  = LS_HOLD;
      end
    end

    LS_HOLD: begin

      ls_req   = '1;

      if (ls_grant_i == 1'b1) begin
        ls_state_d  = LS_RESP;
      end
    end

    LS_RESP: begin

      ls_req = '0;

      if (ls_valid_i == 1'b1) begin
        ls_state_d  = LS_IDLE;
      end

    end

    default: ls_state_d = LS_IDLE;

  endcase
end

// Register to hold store value, while lane is set to NOP after first cycle
logic [  VLEN-1:0] store_data_d, store_data_q;
always_comb begin

  store_data_d   = store_data_q;

  if (ls_state_q == LS_IDLE && store_insn == 1'b1) begin
    store_data_d = store_data_i;
  end
end

// Sequential to update state
always_ff @ (posedge clk_i) begin
  if (rst_ni == 1'b0) begin
    ls_state_q      <= LS_IDLE;
    store_data_q    <= '0;
  end else begin
    ls_state_q      <= ls_state_d;
    store_data_q    <= store_data_d;
  end
end

// ___  ___  ___   _____ _   _______ _   _ _____
// |  \/  | / _ \ /  ___| | / /_   _| \ | |  __ \
// | .  . |/ /_\ \\ `--.| |/ /  | | |  \| | |  \/
// | |\/| ||  _  | `--. \    \  | | | . ` | | __
// | |  | || | | |/\__/ / |\  \_| |_| |\  | |_\ \
// \_|  |_/\_| |_/\____/\_| \_/\___/\_| \_/\____/
//
logic              use_body_mask;
logic              use_activ_mask;
logic [VLEN_B-1:0] alu_cin;
logic [VLEN_B-1:0] byte_enable;
logic [  VLEN-1:0] mask_active;
logic [  VLEN-1:0] mask_body;
logic [  VLEN-1:0] mask;
logic [  VLEN-1:0] mask_register_d, mask_register_q;

// mask register is updated when vd == 0 and ex_ready
// store data holds always vd except when a store is performed but than vd = vs3
always_comb begin

  mask_register_d = mask_register_q;

  if (vd_i == '0 && lanes_done_i == '1) begin

    for (int i = 0; i < VLEN_B; i++) begin
      if (byte_enable[i] == '1) begin
        mask_register_d[8*i +: 8] = store_data_i[8*i +: 8];
      end
    end

  end
end

// Determine body mask elements
always_comb begin
  for (int unsigned i = 0; i < VLEN; i++) begin
    mask_body[i] = (i >= unsigned'(vstart_i) && i < unsigned'(vl_i)) ? '1 : '0;
  end
end
// Determine active mask elements
assign mask_active      = mask_register_q & mask_body;

//  use active mask elements if vm is '0 and alu as well at its cin is disabled
assign use_body_mask    = alu_mode_i.enable & alu_mode_i.cin_en;
assign use_activ_mask  = (use_body_mask) ? '0 : ~vm_i;
assign mask             = (use_activ_mask == '1) ? mask_active : mask_body;

// map mask to byteenable
always_comb begin : map_mask_to_byte_enable

  byte_enable = '0;
  alu_cin     = '0;

  case (sew_i)

    SEW8: begin
      for (int i = 0; i < VLEN/8; i++) begin
        byte_enable[i +:1] = mask[i];
        alu_cin[i +:1]     = mask_register_q[i];
      end
    end

    SEW16: begin
      for (int i = 0; i < VLEN/16; i++) begin
        byte_enable[i*2 +: 2] = {2{mask[i]}};
        alu_cin[i*2 +: 2]     = {2{mask_register_q[i]}};
      end
    end

    SEW32: begin
      for (int i = 0; i < VLEN/32; i++) begin
        byte_enable[i*4 +: 4] = {4{mask[i]}};
        alu_cin[i*4 +: 4]     = {4{mask_register_q[i]}};
      end
    end

    default: begin
      byte_enable = '0;
      alu_cin     = '0;
    end

  endcase

end : map_mask_to_byte_enable

always_ff @ (posedge clk_i) begin

  if (rst_ni == '0) begin
    mask_register_q = '0;
  end else begin
    mask_register_q = mask_register_d;
  end
end

//  _____ _   _ ___________ _   _ _____ _____
// |  _  | | | |_   _| ___ \ | | |_   _/  ___|
// | | | | | | | | | | |_/ / | | | | | \ `--.
// | | | | | | | | | |  __/| | | | | |  `--. \
// \ \_/ / |_| | | | | |   | |_| | | | /\__/ /
//  \___/ \___/  \_/ \_|    \___/  \_/ \____/

logic ex_store_en;
logic ex_load_en;

/*
* On a load or store the lanes are blocked
* LOAD:  NOPs until ls valid
* STORE: STORE then NOPS until ls valid
*/
assign ex_store_en    = (mem_insn == '1 && mem_op == STORE  && ls_state_q == LS_IDLE) ? '1 : '0;
assign ex_load_en     = (mem_insn == '1 && mem_op == LOAD   && ls_valid_i == '1)      ? '1 : '0;

assign ls_enable_o    = (mem_op == LOAD) ? ex_load_en : ex_store_en;
assign ls_request_o   = ls_req;
assign store_enable_o = store_insn;
assign store_data_o   = store_data_d;

assign alu_cin_o        = (use_body_mask == '1) ? alu_cin : '0;
assign byte_enable_o    = byte_enable;
assign vs3_o            = (mac_insn_i == 1'b1) || (store_insn == '1) ? vd_i : '0;

endmodule : vpu_ex_controller
