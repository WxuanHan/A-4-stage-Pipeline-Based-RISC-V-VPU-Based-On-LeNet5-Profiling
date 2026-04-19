package insn_formats;

//  ___________  _____ ___________ _____ _____
// |  _  | ___ \/  __ \  _  |  _  \  ___/  ___|
// | | | | |_/ /| /  \/ | | | | | | |__ \ `--.
// | | | |  __/ | |   | | | | | | |  __| `--. \
// \ \_/ / |    | \__/\ \_/ / |/ /| |___/\__/ /
//  \___/\_|     \____/\___/|___/ \____/\____/
//

typedef enum logic [6:0] {
  OP_V      = 7'b1010111,
  LOAD_FP   = 7'b0000111,
  STORE_FP  = 7'b0100111
} opcodes_e;

function string opcode_to_string(opcodes_e opcode);

  automatic string name = {"undefinded = ", $sformatf("%b", opcode), ""};

  case (opcode)
    OP_V:       name = "OP-V";
    LOAD_FP:    name = "LOAD-FP";
    STORE_FP:   name = "STORE-FP";
  endcase

  return name;

endfunction

// ______ _   _ _   _ _____ _____ _____
// |  ___| | | | \ | /  __ \_   _|____ |
// | |_  | | | |  \| | /  \/ | |     / /
// |  _| | | | | . ` | |     | |     \ \
// | |   | |_| | |\  | \__/\ | | .___/ /
// \_|    \___/\_| \_/\____/ \_/ \____/
//
typedef enum logic [2:0] {
  OPIVV = 3'b000,
  OPMVV = 3'b010,
  OPIVI = 3'b011,
  OPIVX = 3'b100,
  OPMVX = 3'b110
} funct3_op_v;

function string funct3_to_string(funct3_op_v funct3);

    automatic string name = "undefinded";

    unique case (funct3)
      OPIVV: name = "OPIVV";
      OPMVV: name = "OPMVV";
      OPIVI: name = "OPIVI";
      OPIVX: name = "OPIVX";
      OPMVX: name = "OPMVX";
    endcase

    return name;

endfunction

// ______ _   _ _   _ _____ _____ ____
// |  ___| | | | \ | /  __ \_   _/ ___|
// | |_  | | | |  \| | /  \/ | |/ /___
// |  _| | | | | . ` | |     | || ___ \
// | |   | |_| | |\  | \__/\ | || \_/ |
// \_|    \___/\_| \_/\____/ \_/\_____/
typedef enum logic [5:0] {

  VADD   = 6'b000000,  // ADDITION
  VADC   = 6'b010000,  // ADDITION WITH Carry     (Store Sum)
  VMADC  = 6'b010001,  // ADDITION WITH Carry     (Store Carry Out)

  VSUB   = 6'b000010,  // SUBSTRACT               (not with immediate)
  VRSUB  = 6'b000011,  // REVERSE SUBSTRACT       (only with enabled immediate)
  VSBC   = 6'b010010,  // SUBTRACTION WITH BORROW (Store Difference, no immediate)
  VMSBC  = 6'b010011,  // SUBTRACTION WITH BORROW (Store Borrow Out, no immediate)

  VAND   = 6'b001001,  // BITWISE AND
  VOR    = 6'b001010,  // BITWISE OR
  VXOR   = 6'b001011,  // BITWISE XOR

  VMSEQ  = 6'b011000,  // EQUAL
  VMSNE  = 6'b011001,  // NOT EQUAL
  VMSLTU = 6'b011010,  // LESS THEN UNSIGNED
  VMSLT  = 6'b011011,  // LESS THEN SIGNED
  VMSLEU = 6'b011100,  // LESS EQUAL UNSIGNED
  VMSLE  = 6'b011101,  // LESS EQUAL SIGNED
  VMSGTU = 6'b011110,  // GREATER THEN UNSIGNED
  VMSGT  = 6'b011111,  // GREATER THEN SIGNED
  VMAX   = 6'b000111,  // MAX
  VMAXU  = 6'b000110,  // MAX UNSIGNED
  
  VSLL   = 6'b100101,  // SHIFT LEFT LOGIC
  VSRL   = 6'b101000,  // SHIFT RIGHT LOGIC
  VSRA   = 6'b101001   // SHIFT RIGHT ARITHMETIC

} funct6_opi_e;

function string opi_to_string(funct6_opi_e opi);

  automatic string name = "unknown";

  case (opi)

    VADD:     name = "VADD";
    VADC:     name = "VADC";
    VMADC:    name = "VMADC";
    VSUB:     name = "VSUB";
    VSBC:     name = "VSBC";
    VMSBC:    name = "VMSBC";
    VRSUB:    name = "VRSUB";
    VAND:     name = "VAND";
    VOR:      name = "VOR";
    VXOR:     name = "VXOR";
    VMSEQ:    name = "VMSEQ";
    VMSNE:    name = "VMSNE";
    VMSLTU:   name = "VMSLTU";
    VMSLEU:   name = "VMSLEU";
    VMSLE:    name = "VMSLE";
    VMSGTU:   name = "VMSGTU";
    VMSGT:    name = "VMSGT";
    VMAX:     name = "VMAX";
    VMAXU:    name = "VMAXU";
    VSLL:     name = "VSLL";
    VSRL:     name = "VSRL";
    VSRA:     name = "VSRA";

    endcase

  return name;

endfunction

typedef enum logic [5:0] {
  VREDSUM   = 6'b000000,  // vredsum
  VREDMAXU  = 6'b000110,  // vredmaxu
  VREDMAX   = 6'b000111,  // vredmax
  VMUL      = 6'b100101,  // MULTIPLY LOW
  VMULH     = 6'b100111,  // MULTIPLY HIGH SIGNED
  VMULHU    = 6'b100100,  // MULTIPLY HIGH UNSIGNED
  VMACC     = 6'b101101   // MULTIPLY ADD overwrite ADDEND
} funct6_opm_e;

function string opm_to_string(funct6_opm_e opm);

  automatic string name = "unknown";

  case (opm)

    VREDSUM:  name = "VREDSUM";
    VREDMAXU: name = "VREDMAXU";
    VREDMAX:  name = "VREDMAX";
    VMUL:     name = "VMUL";
    VMULH:    name = "VMULH";
    VMULHU:   name = "VMULHU";
    VMACC:    name = "VMACC";
    endcase

  return name;

endfunction

//  _____                   ______                         _
// |_   _|                  |  ___|                       | |
//   | | _ __  ___ _ __     | |_ ___  _ __ _ __ ___   __ _| |_ ___
//   | || '_ \/ __| '_ \    |  _/ _ \| '__| '_ ` _ \ / _` | __/ __|
//  _| || | | \__ \ | | |   | || (_) | |  | | | | | | (_| | |_\__ \
//  \___/_| |_|___/_| |_|   \_| \___/|_|  |_| |_| |_|\__,_|\__|___/

// instruction integer vector vector
typedef struct packed {
  logic [31:26] funct6; // function field
  logic [25:25] vm;     // vector mask
  logic [24:20] vs2;    // second vector register
  logic [19:15] vs1;    // first vecor register
  logic [14:12] funct3; // Vector Arithmetic Instruction Encoding
  logic [11: 7] vd;     // destination vector register
  logic [ 6: 0] opcode; // opcode
} insn_format_opivv_s;

// instruction  integer vector immediate
typedef struct packed {
  logic [31:26] funct6; // function field
  logic [25:25] vm;     // vector mask
  logic [24:20] vs2;    // immediate
  logic [19:15] simm5;  // first vecor register
  logic [14:12] funct3; // Vector Arithmetic Instruction Encoding
  logic [11: 7] vd;     // destination vector register
  logic [ 6: 0] opcode; // opcode
} insn_format_opivi_s;

// instruction  multiply vector vector
typedef struct packed {
  logic [31:26] funct6; // function field
  logic [25:25] vm;     // vector mask
  logic [24:20] vs2;    // second vector register
  logic [19:15] vs1;    // first vecor register
  logic [14:12] funct3; // Vector Arithmetic Instruction Encoding
  logic [11: 7] vd;     // destination vector or general purpose register
  logic [ 6: 0] opcode; // opcode
} insn_format_opmvv_s;

// instruction unit stride load
typedef struct packed {
  logic [31:29] nf;     // the number of fields in each segment (segmented load)
  logic [28:28] mew;    // extended memory element size
  logic [27:26] mop;    // memory addressing mode
  logic [25:25] vm;     // vector mask
  logic [24:20] lumop;  // variants of unit-stride instruction
  logic [19:15] rs1;    // base address register
  logic [14:12] width;  // size of memory elements
  logic [11: 7] vd;     // destination vector register
  logic [ 6: 0] opcode; // opcode
} insn_format_vl_s;

// instruction unit stride load
typedef struct packed {
  logic [31:29] nf;     // the number of fields in each segment (segmented load)
  logic [28:28] mew;    // extended memory element size
  logic [27:26] mop;    // memory addressing mode
  logic [25:25] vm;     // vector mask
  logic [24:20] sumop;  // variants of unit-stride instruction
  logic [19:15] rs1;    // base address register
  logic [14:12] width;  // size of memory elements
  logic [11: 7] vs3;    // destination vector register
  logic [ 6: 0] opcode; // opcode
} insn_format_vs_s;

function string insn2str(bit[31:0] insn);

  opcodes_e opcode;
  automatic string res_str;
  automatic string insn_11_7;
  automatic string insn_14_12;
  automatic string insn_19_15;
  automatic string insn_24_20;

  opcode = opcodes_e'(insn[6:0]);

  case (opcode)

    OP_V: begin
      insn_11_7   = "vd";
      insn_14_12  = "funct3";
      insn_19_15  = "vs1";
      insn_24_20  = "vs2";
    end

    LOAD_FP: begin
      insn_11_7   = "vd";
      insn_14_12  = "width";
      insn_19_15  = "rs1";
      insn_24_20  = "lumop";
    end

    STORE_FP: begin
      insn_11_7   = "vs3";
      insn_14_12  = "width";
      insn_19_15  = "rs1";
      insn_24_20  = "sumop";
    end

  endcase

  res_str = {
    "Instruction"                                  , "\n",
    "opcode = "      , opcode_to_string(opcode)    , "\n",
    insn_11_7,  " = ", $sformatf("%b", insn[11: 7]), "\n",
    insn_14_12, " = ", $sformatf("%b", insn[14:12]), "\n",
    insn_19_15, " = ", $sformatf("%b", insn[19:15]), "\n",
    insn_24_20, " = ", $sformatf("%b", insn[24:20]), "\n",
    "vm = "          , $sformatf("%b", insn[25:25]), "\n"
  };

  if (opcode == OP_V) begin

    res_str = {res_str,  "funct6 = ", $sformatf("%b", insn[31:26]), "\n"};

  end else begin

    res_str = {
      res_str,
      "mop = ", $sformatf("%b", insn[27:26]), "\n",
      "mew = ", $sformatf("%b", insn[28:28]), "\n",
      "nf = " , $sformatf("%b", insn[31:29]), "\n"
    };

  end

  return res_str;
endfunction

endpackage : insn_formats
