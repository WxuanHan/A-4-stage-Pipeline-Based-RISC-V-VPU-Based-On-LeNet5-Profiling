/* This file contain all definitions regarding the Vector Processing Unit This includes:
- struct for multiplier modes
- struct for multiplier valid port
- enum opcode for ALU
*/
package vpu_definitions;

localparam XLEN = 32;

//  _____             _             _              _____ _        _               ______           _     _
// /  __ \           | |           | |    ___     /  ___| |      | |              | ___ \         (_)   | |
// | /  \/ ___  _ __ | |_ _ __ ___ | |   ( _ )    \ `--.| |_ __ _| |_ _   _ ___   | |_/ /___  __ _ _ ___| |_ ___ _ __ ___
// | |    / _ \| '_ \| __| '__/ _ \| |   / _ \/\   `--. \ __/ _` | __| | | / __|  |    // _ \/ _` | / __| __/ _ \ '__/ __|
// | \__/\ (_) | | | | |_| | | (_) | |  | (_>  <  /\__/ / || (_| | |_| |_| \__ \  | |\ \  __/ (_| | \__ \ ||  __/ |  \__ \
//  \____/\___/|_| |_|\__|_|  \___/|_|   \___/\/  \____/ \__\__,_|\__|\__,_|___/  \_| \_\___|\__, |_|___/\__\___|_|  |___/
//                                                                                            __/ |
//                                                                                           |___/

typedef struct packed {
  logic [XLEN-1:XLEN-1] vill;     // vector illegal value
  logic [XLEN-2:     8] reserved;
  logic [     7:     7] vma;
  logic [     6:     6] vta;
  logic [     5:     5] vlmul_u;
  logic [     4:     2] vsew;       // standard element width
  logic [     1:     0] vlmul_l;    // vector length multiplier
} csr_vtype_s;

// Struct for csr vtype
typedef logic [XLEN-1:0] csr_vl_s;

// Struct for csr vtype
typedef logic [XLEN-1:0] csr_vstart_s;

typedef struct packed {
  logic [XLEN-2:24] vill;
  logic [XLEN-2:24] reserved;
  logic [    23:16] vstart;     // 8 bit => VLEN support up to 256 bit, when LMUL = 8
  logic [    15: 8] vl;         // 8 bit => VLEN support up to 256 bit, when LMUL = 8
  logic [     7: 7] vma;
  logic [     6: 6] vta;
  logic [     5: 5] vlmul_u;
  logic [     4: 2] vsew;       // standard element width
  logic [     1: 0] vlmul_l;    // vector length multiplier
} cs_data_s;


//    _   _           _               _
//   | | | |         | |             | |
//   | | | | ___  ___| |_ ___  _ __  | |     __ _ _ __   ___
//   | | | |/ _ \/ __| __/ _ \| '__| | |    / _` | '_ \ / _ \
//   \ \_/ /  __/ (__| || (_) | |    | |___| (_| | | | |  __/
//    \___/ \___|\___|\__\___/|_|    \_____/\__,_|_| |_|\___|
//

typedef struct packed {
  logic       enable;
  logic       sign;
  logic [4:0] value;
} immediate_s;

function string immediate_to_string;
  input immediate_s i;

  automatic bit[7:0] extended_value;
  automatic string   s_enable;
  automatic string   s_sign;
  automatic string   s_value;

  extended_value = (i.sign) ? signed'(i.value) : unsigned'(i.value);

  s_enable.bintoa(i.enable);
  s_sign.bintoa(i.sign);
  s_value.bintoa(extended_value);

  return {"Enable: ", s_enable , " Sign: ", s_sign , " Value: ", s_value };

endfunction

typedef enum logic [2:0] {
  SEW8  = 3'b000,
  SEW16 = 3'b001,
  SEW32 = 3'b010
} sew_mode_e;

function string sew_to_string;
  input sew_mode_e sew;

  automatic string name = "Undefined";

  case (sew)
    SEW8:   name = "SEW8";
    SEW16:  name = "SEW16";
    SEW32:  name = "SEW32";
  endcase

  return name;

endfunction

function int unsigned sew_to_int;
  input sew_mode_e sew_mode;

  automatic int unsigned  sew = 0;

  unique case (sew_mode)
    SEW8:     sew = 8;
    SEW16:    sew = 16;
    SEW32:    sew = 32;
    default: begin
      $display("Undefined SEW width (0x%h). Cannot convert it to an integer.", sew_mode);
      end
  endcase

  return sew;

endfunction

// ___  ___ ________  ________________   __
// |  \/  ||  ___|  \/  |  _  | ___ \ \ / /
// | .  . || |__ | .  . | | | | |_/ /\ V /
// | |\/| ||  __|| |\/| | | | |    /  \ /
// | |  | || |___| |  | \ \_/ / |\ \  | |
// \_|  |_/\____/\_|  |_/\___/\_| \_| \_/
//
typedef enum logic {
  STORE = 1'b0,
  LOAD  = 1'b1
} mem_op_e;

function string mem_op_to_string;
input mem_op_e op;

  automatic string name = "UNNAMED";

    case (op)
      LOAD:   name = "LOAD";
      STORE:  name = "STORE";
    endcase

    return name;

endfunction

/*Struct to bundle modes of the alu*/
typedef struct packed {
  logic         enable;
  logic [31:0]  addr;
  mem_op_e      op;
  //logic [31:0]  stride;  // in bytes
} mem_mode_s;



//    ___   _     _   _
//   / _ \ | |   | | | |
//  / /_\ \| |   | | | |
//  |  _  || |   | | | |
//  | | | || |___| |_| |
//  \_| |_/\_____/\___/
//
/*Opcode Enum for ALU */
typedef enum logic [15:0] {
  ADD                = 16'b0000000000000001,
  SUBTRACT           = 16'b0000000000000010,
  ARITH_SHIFT_RIGHT  = 16'b0000000000000100,
  LOGIC_SHIFT_RIGHT  = 16'b0000000000001000,
  LOGIC_SHIFT_LEFT   = 16'b0000000000010000,
  AND                = 16'b0000000000100000,
  OR                 = 16'b0000000001000000,
  XOR                = 16'b0000000010000000,
  EQUAL              = 16'b0000000100000000,
  NOT_EQUAL          = 16'b0000001000000000,
  LESS_U             = 16'b0000010000000000,
  LESS_S             = 16'b0000100000000000,
  LESS_EQUAL_U       = 16'b0001000000000000,
  LESS_EQUAL_S       = 16'b0010000000000000,
  GREATER_U          = 16'b0100000000000000,
  GREATER_S          = 16'b1000000000000000
} alu_op_e;

function string alu_op_to_string;
input alu_op_e op;

  automatic string name = "UNNAMED";

    case (op)
      ADD:                name = "ADD";
      SUBTRACT:           name = "SUBTRACT";
      LOGIC_SHIFT_RIGHT:  name = "LOGIC_SHIFT_RIGHT";
      LOGIC_SHIFT_LEFT:   name = "LOGIC_SHIFT_LEFT";
      ARITH_SHIFT_RIGHT:  name = "ARITH_SHIFT_RIGHT";
      AND:                name = "AND";
      OR:                 name = "OR";
      XOR:                name = "XOR";
      EQUAL:              name = "EQUAL";
      NOT_EQUAL:          name = "NOT EQUAL";
      LESS_U:             name = "LESS THEN UNSIGNED";
      LESS_S:             name = "LESS THEN SIGNED";
      LESS_EQUAL_U:       name = "LESS EQUALS UNSIGNED";
      LESS_EQUAL_S:       name = "LESS EQUALS SIGNED";
      GREATER_U:          name = "GREATER UNSIGNED";
      GREATER_S:          name = "GREATER SIGNED";
    endcase

    return name;

endfunction

/*Struct to bundle modes of the alu*/
typedef struct packed {
  logic     enable;
  alu_op_e  op;
  logic     cin_en;
  logic     cout_en;
} alu_mode_s;

// ___  ____   _ _    _____ ___________ _     _____ ___________
// |  \/  | | | | |  |_   _|_   _| ___ \ |   |_   _|  ___| ___ \
// | .  . | | | | |    | |   | | | |_/ / |     | | | |__ | |_/ /
// | |\/| | | | | |    | |   | | |  __/| |     | | |  __||    /
// | |  | | |_| | |____| |  _| |_| |   | |_____| |_| |___| |\ \
// \_|  |_/\___/\_____/\_/  \___/\_|   \_____/\___/\____/\_| \_|

/*Struct to bundle modes of the multiplier*/
typedef struct packed {
  logic enable;
  logic upper;
  logic sign;
  logic mac;
  logic redsum;
  logic redmax;
  logic redmaxu;
} mul_mode_s;

/*Struct to name 2-bit output valid port of mulitplier */
typedef struct packed {
  logic lower;
  logic upper;
} mult_valid_s;

endpackage : vpu_definitions
