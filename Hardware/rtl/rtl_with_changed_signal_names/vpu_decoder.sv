import vpu_definitions::*;
import insn_formats::*;

module vpu_decoder #(
  parameter BW_VL = 8                    // Reduced length of vstart and vl
)
(
  input logic              clk_i,
  input logic              rst_ni,
  input logic [      31:0] insn_i,
  input logic [      31:0] cs_data_i,
  input logic [      31:0] ls_addr_i,

  output logic             inv_insn_o,

  // Operand inputs
  output logic [      4:0] vs1_o,
  output logic [      4:0] vs2_o,
  output immediate_s       immediate_o,
  output logic [      4:0] vd_o,

  // Settings
  output sew_mode_e        sew_o,
  output logic [BW_VL-1:0] vstart_o,
  output logic [BW_VL-1:0] vl_o,
  output logic             vm_o,          // enable_masking
  output mem_mode_s        mem_mode_o,    // Configuration Memory
  output alu_mode_s        alu_mode_o,    // Configuration ALU
  output mul_mode_s        mul_mode_o     // Configuration Multiplier
);

//   ___          _                                  _
//  / _ \        (_)                                | |
// / /_\ \___ ___ _  __ _ _ __  _ __ ___   ___ _ __ | |_
// |  _  / __/ __| |/ _` | '_ \| '_ ` _ \ / _ \ '_ \| __|
// | | | \__ \__ \ | (_| | | | | | | | | |  __/ | | | |_
// \_| |_/___/___/_|\__, |_| |_|_| |_| |_|\___|_| |_|\__|
//                   __/ |
//                  |___/
//------------------------------------------------------------------
// Control & Status Data
//------------------------------------------------------------------
cs_data_s   cs_data;
//------------------------------------------------------------------
// Instruction format: Independent
//------------------------------------------------------------------
opcodes_e   opcode; // opcode
logic       vm;     // vector mask
logic [4:0] vd;     // destination vector register address

//------------------------------------------------------------------
// Instruction format: OP-V
//------------------------------------------------------------------
logic [2:0] funct3; // function field (OPIVV || OPIVI || OPMVV)
logic [5:0] funct6; // function field
logic [4:0] vs2;    // second vector register address
// For subtype: OPIVV
logic [4:0] vs1;    // first vecor register address
// For subtype: OPIVI
logic [4:0] simm5;  // immediate for ALU op

//------------------------------------------------------------------
// Instruction format: LOAD_FP, STORE_FP
//------------------------------------------------------------------
logic [2:0] width;  // specifies size of memory elements, and distinguishes from FP scalar
logic [1:0] mop;    // first general purpose register
logic       mew;    // first general purpose register
logic [2:0] nf;    // first general purpose register

// For Instruction Format: OP_VL
logic [4:0] lumop;  // load unit stride config

// For Instruction Format: OP_VS
logic [4:0] sumop;  // store unit stride config

// assign to cs_data
assign cs_data  = cs_data_s'(cs_data_i);

// Instruction partitioning
assign funct6   = insn_i[31:26]; // OP-V
assign nf       = insn_i[31:29]; // LOAD_FP, STORE_FP
assign mew      = insn_i[28];    // LOAD_FP, STORE_FP
assign mop      = insn_i[27:26]; // LOAD_FP, STORE_FP

assign vm       = insn_i[25];

assign vs2      = insn_i[24:20]; // OP-V
assign sumop    = insn_i[24:20]; // STORE_FP: VS
assign lumop    = insn_i[24:20]; // LOAD_FP: VL


assign vs1      = insn_i[19:15]; // OP-V: OPIVV, OPMVV
assign simm5    = insn_i[19:15]; // OP-V: OPIVI

assign funct3   = insn_i[14:12]; // OP-V
assign width    = insn_i[14:12]; // LOAD_FP, STORE_FP

assign vd       = insn_i[11: 7]; // OP-V, LOAD_FP
// assign vs3 = insn_i[11: 7]; // == vd

assign opcode   = opcodes_e'(insn_i[6:0]);

//  _____                     _          _          _
// |  _  |                   | |        | |        | |
// | | | |_ __   ___ ___   __| | ___    | |__   ___| |_ __   ___ _ __
// | | | | '_ \ / __/ _ \ / _` |/ _ \   | '_ \ / _ \ | '_ \ / _ \ '__|
// \ \_/ / |_) | (_| (_) | (_| |  __/   | | | |  __/ | |_) |  __/ |
//  \___/| .__/ \___\___/ \__,_|\___|   |_| |_|\___|_| .__/ \___|_|
//       | |                                         | |
//       |_|                                         |_|

logic       is_op_v;
logic       is_store_fp;
logic       is_load_fp;
logic       unknown_opcode;

always_comb begin : decode_opcode_field

  is_op_v         = '0;
  is_store_fp     = '0;
  is_load_fp      = '0;
  unknown_opcode  = '0;

  case (opcode)

    OP_V:     is_op_v         = '1;
    LOAD_FP:  is_load_fp      = '1;
    STORE_FP: is_store_fp     = '1;
    default:  unknown_opcode  = '1;

  endcase

end : decode_opcode_field

//   ___   _     _   _  ______                   _
//  / _ \ | |   | | | | |  _  \                 | |
// / /_\ \| |   | | | | | | | |___  ___ ___   __| | ___ _ __
// |  _  || |   | | | | | | | / _ \/ __/ _ \ / _` |/ _ \ '__|
// | | | || |___| |_| | | |/ /  __/ (_| (_) | (_| |  __/ |
// \_| |_/\_____/\___/  |___/ \___|\___\___/ \__,_|\___|_|

funct6_opi_e  opi;
immediate_s   immediate;
alu_mode_s    alu_mode;
alu_op_e      alu_insn;
logic         unk_alu_insn;
logic         inv_alu_insn;

assign opi   = funct6_opi_e'(funct6);

always_comb begin : decode_alu

  alu_insn = ADD;
  unk_alu_insn = 1'b0;

    unique case (opi)

      VADD,
      VADC,
      VMADC:   alu_insn = ADD;

      VSUB,
      VSBC,
      VMSBC: begin
        alu_insn        = SUBTRACT;
        // if immediate is enabled, insn are not defined
        unk_alu_insn    = immediate.enable;
      end

      VRSUB: begin
        alu_insn        = SUBTRACT;
        // insn is only defined if immediate is enabled
        unk_alu_insn    = ~immediate.enable;
      end

      VAND:    alu_insn = AND;
      VOR:     alu_insn = OR;
      VXOR:    alu_insn = XOR;

      VMSEQ:   alu_insn = EQUAL;
      VMSNE:   alu_insn = NOT_EQUAL;

      VMSLTU: begin
        alu_insn = LESS_U;
        // if immediate is enabled, insn isn not defined
        unk_alu_insn    = immediate.enable;
      end
      VMSLT: begin
        alu_insn = LESS_S;
        // if immediate is enabled, insn is not defined
        unk_alu_insn    = immediate.enable;
      end

      VMSLEU:  alu_insn = LESS_EQUAL_U;
      VMSLE:   alu_insn = LESS_EQUAL_S;

      VMSGTU:  alu_insn = GREATER_U;
      VMSGT:   alu_insn = GREATER_S;

      VSLL:    alu_insn = LOGIC_SHIFT_LEFT;
      VSRL:    alu_insn = LOGIC_SHIFT_RIGHT;
      VSRA:    alu_insn = ARITH_SHIFT_RIGHT;

      default: unk_alu_insn = 1'b1;

    endcase
end : decode_alu

// immediate signal assignments
assign immediate.enable = (is_op_v == '1 && funct3 == OPIVI) ? '1 : '0;
assign immediate.sign   = (opi inside {VADD, VADC, VMADC, VRSUB, VMSLE, VMSGT }) ? '1 : '0;
assign immediate.value  = simm5;

// alu mode signal assignments
always_comb begin : assign_alu_mode
  alu_mode.enable  = 0;
  alu_mode.op      = ADD;
  alu_mode.cin_en  = 0;
  alu_mode.cout_en = 0;

  if (is_op_v == '1 && (funct3 == OPIVV || funct3 == OPIVI)) begin
    alu_mode.enable  = '1;
    alu_mode.op      = alu_insn;
    alu_mode.cin_en  = (vm == '0 && (opi inside {VADC,VSBC, VMADC, VMSBC})) ? '1 : '0;
    alu_mode.cout_en = (opi inside {VMADC, VMSBC}) ? '1 : '0;
  end
end


always_comb begin : check_alu_insn

  inv_alu_insn = '0;

  if (
    (unk_alu_insn == '1                       ) ||
    (vd == '0 && (opi inside {VADC, VSBC})    ) ||
    (vm == '1 && (opi inside {VADC, VSBC})    )
  ) begin

    inv_alu_insn = '1;
  end

end : check_alu_insn

// ___  ___      _ _   _               ______                   _
// |  \/  |     | | | (_)              |  _  \                 | |
// | .  . |_   _| | |_ _ _ __  _   _   | | | |___  ___ ___   __| | ___ _ __
// | |\/| | | | | | __| | '_ \| | | |  | | | / _ \/ __/ _ \ / _` |/ _ \ '__|
// | |  | | |_| | | |_| | |_) | |_| |  | |/ /  __/ (_| (_) | (_| |  __/ |
// \_|  |_/\__,_|_|\__|_| .__/ \__, |  |___/ \___|\___\___/ \__,_|\___|_|
//                      | |     __/ |
//                      |_|    |___/

funct6_opm_e  opm;
mul_mode_s    mul_mode;
logic         inv_mul_insn;

assign opm = funct6_opm_e'(funct6);

always_comb begin : decode_multiply

  mul_mode.enable = '0;
  mul_mode.sign   = '0;
  mul_mode.mac    = '0;
  mul_mode.upper  = '0;
  inv_mul_insn    = '0;
  mul_mode.redsum = '0;
  mul_mode.redmax = '0;
  mul_mode.redmaxu= '0;
  if (is_op_v == '1 && funct3 == OPMVV) begin

    unique case (opm)

      VMUL: begin
        mul_mode.enable = '1;
      end

      VMULH: begin
        mul_mode.enable = '1;
        mul_mode.sign   = '1;
        mul_mode.upper  = '1;
      end

      VMULHU: begin
        mul_mode.enable = '1;
        mul_mode.upper  = '1;
      end

      VMACC: begin
        mul_mode.enable = '1;
        mul_mode.sign   = '1;
        mul_mode.mac    = '1;
      end
	  
	  VREDSUM: begin
		mul_mode.enable = '1;
		mul_mode.sign   = '1;
		mul_mode.redsum = '1;
	  end
	  
	  VREDMAX: begin
		mul_mode.enable = '1;
		mul_mode.sign   = '1;
		mul_mode.redmax = '1;
	  end
	  
	  VREDMAXU: begin
		mul_mode.enable = '1;
		mul_mode.redmaxu= '1;
	  end

      default: begin
        inv_mul_insn = 1'b1;
      end

    endcase
  end
end : decode_multiply

// ___  ___                                  ______                   _
// |  \/  |                                  |  _  \                 | |
// | .  . | ___ _ __ ___   ___  _ __ _   _   | | | |___  ___ ___   __| | ___ _ __
// | |\/| |/ _ \ '_ ` _ \ / _ \| '__| | | |  | | | / _ \/ __/ _ \ / _` |/ _ \ '__|
// | |  | |  __/ | | | | | (_) | |  | |_| |  | |/ /  __/ (_| (_) | (_| |  __/ |
// \_|  |_/\___|_| |_| |_|\___/|_|   \__, |  |___/ \___|\___\___/ \__,_|\___|_|
//                                    __/ |
//                                   |___/
mem_mode_s  mem_mode;
logic       inv_mem_insn;
assign mem_mode.enable = (is_load_fp == '1 || is_store_fp == '1) ? '1 : '0;
assign mem_mode.op     = (is_load_fp == '1) ? LOAD : STORE;
assign mem_mode.addr   = ls_addr_i;
//assign mem_mode.stride = '1;

always_comb begin : check_mem_insn

  inv_mem_insn = '0;

  if (width != 3'b110 || nf != '0 || sumop != '0 || lumop != '0 || mew != '0 || mop != '0) begin
    inv_mem_insn = '1;
  end

end : check_mem_insn
//  _____                  ______                   _
// |_   _|                 |  _  \                 | |
//   | | _ __  ___ _ __    | | | |___  ___ ___   __| | ___ _ __
//   | || '_ \/ __| '_ \   | | | / _ \/ __/ _ \ / _` |/ _ \ '__|
//  _| || | | \__ \ | | |  | |/ /  __/ (_| (_) | (_| |  __/ |
//  \___/_| |_|___/_| |_|  |___/ \___|\___\___/ \__,_|\___|_|

logic inv_insn;

assign inv_insn = (
    (alu_mode.enable == '1 && inv_alu_insn == '1) ||
    (mul_mode.enable == '1 && inv_mul_insn == '1) ||
    (mem_mode.enable == '1 && inv_mem_insn == '1) ||
    (unknown_opcode  == '1)
  ) ? '1 : '0;

//  _____       _               _
// |  _  |     | |             | |
// | | | |_   _| |_ _ __  _   _| |_ ___
// | | | | | | | __| '_ \| | | | __/ __|
// \ \_/ / |_| | |_| |_) | |_| | |_\__ \
//  \___/ \__,_|\__| .__/ \__,_|\__|___/
//                 | |
//                 |_|
//
logic [ 4:0]      vs1_q, vs1_d;
logic [ 4:0]      vs2_q, vs2_d;
logic [ 4:0]      vd_q, vd_d;
logic             vm_d, vm_q;
immediate_s       immediate_q, immediate_d;
sew_mode_e        sew_d, sew_q;
logic [BW_VL-1:0] vstart_d, vstart_q;
logic [BW_VL-1:0] vl_d, vl_q;
alu_mode_s        alu_mode_d, alu_mode_q;
mul_mode_s        mul_mode_d, mul_mode_q;
mem_mode_s        mem_mode_d, mem_mode_q;

assign vs1_d       = vs1;
assign vs2_d       = vs2;
assign immediate_d = immediate;
assign vm_d        = vm;
assign vd_d        = vd;
assign alu_mode_d  = alu_mode;
assign mul_mode_d  = mul_mode;
assign mem_mode_d  = mem_mode;
assign sew_d       = sew_mode_e'(cs_data.vsew);
assign vstart_d    = cs_data.vstart;
assign vl_d        = cs_data.vl;

always_ff @ (posedge clk_i) begin

  if (~rst_ni) begin

    vs1_q           <= '0;
    vs2_q           <= '0;
    immediate_q     <= '0;
    vm_q            <= '0;
    vd_q            <= '0;
    alu_mode_q      <= '0;
    mul_mode_q      <= '0;
    mem_mode_q      <= '0;
    sew_q           <= SEW32;
    vstart_q        <= '0;
    vl_q            <= '0;

  end else begin

    vs1_q           <= vs1_d;
    vs2_q           <= vs2_d;
    immediate_q     <= immediate_d;
    vm_q            <= vm_d;
    vd_q            <= vd_d;
    sew_q           <= sew_d;
    vstart_q        <= vstart_d;
    vl_q            <= vl_d;
    alu_mode_q      <= alu_mode_d;
    mul_mode_q      <= mul_mode_d;
    mem_mode_q      <= mem_mode_d;
  end
end

assign inv_insn_o  = inv_insn;
assign vs1_o       = vs1_q;
assign vs2_o       = vs2_q;
assign immediate_o = immediate_q;
assign vm_o        = vm_q;
assign vd_o        = vd_q;
assign sew_o       = sew_q;
assign vstart_o    = vstart_q;
assign vl_o        = vl_q;
assign alu_mode_o  = alu_mode_q;
assign mul_mode_o  = mul_mode_q;
assign mem_mode_o  = mem_mode_q;

endmodule : vpu_decoder
