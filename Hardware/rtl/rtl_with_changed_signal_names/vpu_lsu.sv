import vpu_definitions::*;

module vpu_lsu #(
  parameter VLEN        = 256,                  // vector length
  parameter ELEN        = 32,                   // max. Element size
  parameter ITERATIONS  = VLEN/ELEN,        // Iterations
  parameter BW_I        = $clog2(ITERATIONS)
)
(
  input logic clk_i,
  input logic rst_ni,

  // Internal memory interface
  output logic              ls_gnt_o,
  output logic [  VLEN-1:0] load_data_o,
  output logic              ls_valid_o,
  input  logic              ls_req_i,
  input  logic [      31:0] ls_addr_i,
  input  logic [VLEN/8-1:0] ls_be_i,
  input  logic              store_enable_i,
  input  logic [  VLEN-1:0] store_data_i,


  // External memory interface
  input  logic              data_gnt_i,
  input  logic [  ELEN-1:0] data_rdata_i,
  input  logic              data_rvalid_i,
  output logic              data_req_o,
  output logic [  ELEN-1:0] data_addr_o,
  output logic              data_we_o,
  output logic [ELEN/8-1:0] data_be_o,
  output logic [  ELEN-1:0] data_wdata_o
);

//  _     _____  ___ ______   _______ _____ ___________ _____   _____ _   _
// | |   |  _  |/ _ \|  _  \ / /  ___|_   _|  _  | ___ \  ___| |_   _| \ | |
// | |   | | | / /_\ \ | | |/ /\ `--.  | | | | | | |_/ / |__     | | |  \| |
// | |   | | | |  _  | | | / /  `--. \ | | | | | |    /|  __|    | | | . ` |
// | |___\ \_/ / | | | |/ / /  /\__/ / | | \ \_/ / |\ \| |___   _| |_| |\  |
// \_____/\___/\_| |_/___/_/   \____/  \_/  \___/\_| \_\____/   \___/\_| \_/


typedef enum logic[2:0] { LS_IDLE, LS_HOLD_REQ, LS_COMPL_RESP} ls_fsm_e;
ls_fsm_e ls_state_q, ls_state_d;

logic ls_start;
logic ls_valid;
logic ls_gnt;
logic data_last_gnt;
logic data_last_rvalid;
logic data_req;

always_comb begin

  ls_state_d  = ls_state_q;
  ls_valid    = '0;
  ls_gnt      = '0;
  ls_start    = '0;
  data_req    = '0;

  case (ls_state_q)

    LS_IDLE: begin

      if (ls_req_i == '1) begin
        ls_state_d  = LS_HOLD_REQ;
        ls_start    = 1'b1;
        data_req    = 1'b1;
      end
    end

    LS_HOLD_REQ: begin

      data_req = 1'b1;

      if (data_last_gnt == '1) begin
        ls_state_d  = LS_COMPL_RESP;
        ls_gnt      = 1'b1;
      end

    end

    LS_COMPL_RESP: begin

      if (data_last_rvalid == 1'b1) begin
        ls_state_d  = LS_IDLE;
        ls_valid    = '1;
      end
    end

    default: begin
      ls_state_d  = LS_IDLE;
      ls_start    = 1'b0;
      ls_valid    = 1'b0;
      ls_gnt      = 1'b0;
      data_req    = 1'b0;
    end

  endcase
end

//  _____                   _       _   _
// |_   _|                 | |     | | (_)
//   | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __
//   | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \
//   | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | |
//   \_/_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|

logic unsigned [BW_I:0] cnt_gnt_d, cnt_gnt_q;
logic unsigned [BW_I:0] cnt_rvalid_d, cnt_rvalid_q;

logic [  VLEN-1:0] load_data_d, load_data_q;
logic              data_gnt_q;
logic              data_rvalid_q;

logic data_we;
logic [  ELEN-1:0] data_wdata;
logic [ELEN/8-1:0] data_be;

assign cnt_gnt_d    = (data_gnt_i     == '1) ? ((cnt_gnt_q    + 1) % ITERATIONS) :cnt_gnt_q;
assign cnt_rvalid_d = (data_rvalid_i  == '1) ? ((cnt_rvalid_q + 1) % ITERATIONS) :cnt_rvalid_q;

assign data_last_gnt     = (cnt_gnt_q     == ITERATIONS-1 && data_gnt_i     == '1) ? '1 : '0;
assign data_last_rvalid  = (cnt_rvalid_q  == ITERATIONS-1 && data_rvalid_i  == '1) ? '1 : '0;

// load data using shift register
always_comb begin

  load_data_d = load_data_q;

  for (int i = 0; i < ITERATIONS; i++) begin
    if (i == cnt_rvalid_q) begin
      if (data_rvalid_i == 1'b1) begin
        load_data_d[i*ELEN +: ELEN] = data_rdata_i;
      end
    end
  end

end

assign data_we = store_enable_i;

always_comb begin

  data_be     = '0;
  data_wdata  = '0;

  for (int i = 0; i < ITERATIONS; i++) begin
    if (i == cnt_gnt_q) begin
      data_be     = ls_be_i[i*ELEN/8 +: ELEN/8];
      data_wdata  = store_data_i[i*ELEN +: ELEN];
    end
  end

end

// ___  ___ ________  ________________   __  _____ _   _ _____
// |  \/  ||  ___|  \/  |  _  | ___ \ \ / / |  _  | | | |_   _|
// | .  . || |__ | .  . | | | | |_/ /\ V /  | | | | | | | | |
// | |\/| ||  __|| |\/| | | | |    /  \ /   | | | | | | | | |
// | |  | || |___| |  | \ \_/ / |\ \  | |   \ \_/ / |_| | | |
// \_|  |_/\____/\_|  |_/\___/\_| \_| \_/    \___/ \___/  \_/

// The memory state machine
typedef enum logic [2:0] { MEM_IDLE, MEM_HOLD, MEM_RESP } memory_fsm_e;
memory_fsm_e data_state_q, data_state_d;

logic [  ELEN-1:0] data_addr_d, data_addr_q;

// Memory Addr managment
// only unit stride
always_comb begin

  data_addr_d = data_addr_q;

  if (ls_start == 1'b1) begin

    data_addr_d = ls_addr_i;

  end else if (1'b1 == data_gnt_q) begin

    data_addr_d = data_addr_q + ELEN/8;

  end
end

always_comb begin

  data_state_d = data_state_q;

  case(data_state_q)

    MEM_IDLE: begin

      if (data_req == 1'b1) begin
        data_state_d = (data_gnt_i == '1) ? MEM_RESP : MEM_HOLD;
      end

    end

    MEM_HOLD: begin

      if (data_gnt_i == 1'b1)
        data_state_d = MEM_RESP;

    end

    MEM_RESP: begin

      if (data_rvalid_i == '1 && data_req == '0 && data_gnt_i == '0) begin
        data_state_d = MEM_IDLE;
      end else if ( data_rvalid_i == '1 && data_req == '1 && data_gnt_i == '0) begin
        data_state_d = MEM_HOLD;
      end

    end

    default: data_state_d = MEM_IDLE;

  endcase
end

//  _____ _____ _____ _   _ _____ _   _ _____ _____  ___   _       ____________ _____ _____  _____ _____ _____
// /  ___|  ___|  _  | | | |  ___| \ | |_   _|_   _|/ _ \ | |      | ___ \ ___ \  _  /  __ \|  ___/  ___/  ___|
// \ `--.| |__ | | | | | | | |__ |  \| | | |   | | / /_\ \| |      | |_/ / |_/ / | | | /  \/| |__ \ `--.\ `--.
//  `--. \  __|| | | | | | |  __|| . ` | | |   | | |  _  || |      |  __/|    /| | | | |    |  __| `--. \`--. \
// /\__/ / |___\ \/' / |_| | |___| |\  | | |  _| |_| | | || |____  | |   | |\ \\ \_/ / \__/\| |___/\__/ /\__/ /
// \____/\____/ \_/\_\\___/\____/\_| \_/ \_/  \___/\_| |_/\_____/  \_|   \_| \_|\___/ \____/\____/\____/\____/

always_ff @ (posedge clk_i) begin

  if (rst_ni == 1'b0) begin

    ls_state_q    <= LS_IDLE;
    data_state_q  <= MEM_IDLE;
    cnt_gnt_q     <= {BW_I{1'b0}};
    cnt_rvalid_q  <= {BW_I{1'b0}};
    data_addr_q   <= '0;
    data_gnt_q    <= '0;
    data_rvalid_q <= data_rvalid_i;
    load_data_q   <= '0;

  end else begin

    data_state_q  <= data_state_d;
    ls_state_q    <= ls_state_d;

    cnt_gnt_q     <= cnt_gnt_d;
    cnt_rvalid_q  <= cnt_rvalid_d;

    data_gnt_q    <= data_gnt_i;
    data_rvalid_q <= data_rvalid_i;
    data_addr_q   <= data_addr_d;

    load_data_q   <= load_data_d;
  end
end

/* assign ls_gnt_o       = ls_gnt;
assign ls_valid_o     = ls_valid;
assign load_data_o    = load_data_d;

assign data_req_o     = data_req;
assign data_addr_o    = data_addr_d;
assign data_be_o      = data_be;
assign data_we_o      = data_we;
assign data_wdata_o   = data_wdata; */

always_ff @(posedge clk_i)begin
	if(~rst_ni)begin
		ls_gnt_o <= '0;
		ls_valid_o <= '0;
		load_data_o <= '0;
		data_req_o <= '0;
		data_addr_o <= '0;
		data_be_o <= '0;
		data_we_o <= '0;
		data_wdata_o <= '0;
	end
	else begin
		ls_gnt_o <= ls_gnt;
		ls_valid_o <= ls_valid;
		load_data_o <= load_data_d;
		data_req_o <= data_req;
		data_addr_o <= data_addr_d;
		data_be_o <= data_be;
		data_we_o <= data_we;
		data_wdata_o <= data_wdata;
	end
end

endmodule
