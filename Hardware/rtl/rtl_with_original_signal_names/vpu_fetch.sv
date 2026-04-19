import vpu_definitions::*;
import insn_formats::*;

module vpu_fetch #(
	parameter BW_VL = 8                    // Reduced length of vstart and vl
)(
	input logic              clk_i,
	input logic              rst_ni,

	// From CPU
	input  logic             if_id_req_i,
	output logic             if_id_gnt_o,
	
	input  logic [     31:0] insn_i,
	input  logic [     31:0] cs_data_i,
	input  logic [     31:0] ls_addr_i,
	
	input  logic 			 inv_insn_i,
	
	// Pipelining
	output logic             ex_wb_req_o,
	input logic              ex_wb_gnt_i,
	
	// Decoder
	output  logic [     31:0] insn_o,
	output  logic [     31:0] cs_data_o,
	output  logic [     31:0] ls_addr_o,
	
	// outputs to cpu
	output logic              if_id_rvalid_o,
	output logic  [     31:0] if_id_rcs_data_o		 
);

logic [31:0] insn_q, insn_d;
logic [31:0] cs_data_q, cs_data_d;
logic [31:0] ls_addr_q, ls_addr_d;

logic [31:0] rcs_data_q, rcs_data_d;
logic [31:0] rvalid_q, rvalid_d;

logic ex_wb_req_d, ex_wb_req_q;
logic if_id_gnt;
logic if_id_enable;
logic ex_wb_enable;

assign ex_wb_enable = (ex_wb_req_q) & (ex_wb_gnt_i);
assign if_id_gnt    = ex_wb_gnt_i | ~ex_wb_req_q;

assign if_id_enable = (if_id_req_i) & (if_id_gnt);

assign insn_d       = (if_id_enable == '1) ? insn_i     : insn_q;
assign cs_data_d    = (if_id_enable == '1) ? cs_data_i  : cs_data_q;
assign ls_addr_d    = (if_id_enable == '1) ? ls_addr_i  : ls_addr_q;

always_comb begin

  ex_wb_req_d = ex_wb_req_q;

  // if if_id_stage is enabled it will contain a req insn in the next cycle
  if (if_id_enable == '1) begin

    ex_wb_req_d = '1;

  // if if_id_stage is disable and ex_wb_stage is enabled
  // --> if_id stage runs out of insn
  end else if (ex_wb_enable == '1) begin

    ex_wb_req_d = '0;

  end

end

always_ff @ (posedge clk_i) begin

  if (~rst_ni) begin

    ex_wb_req_q <= '0;
    insn_q      <= '0;
    cs_data_q   <= '0;
    ls_addr_q   <= '0;

  end else begin

    ex_wb_req_q <= ex_wb_req_d;
    insn_q      <= insn_d;
    cs_data_q   <= cs_data_d;
    ls_addr_q   <= ls_addr_d;

  end
end

assign rvalid_d = if_id_enable;
assign rcs_data_d   = {inv_insn_i, 15'b0 ,cs_data_i[15:0]};

always_ff @ (posedge clk_i) begin

  if (~rst_ni) begin
    rvalid_q        <= '0;
    rcs_data_q      <= '0;

  end else begin
    rvalid_q        <= rvalid_d;
    rcs_data_q      <= rcs_data_d;
  end
  
end

assign insn_o = insn_d;
assign cs_data_o = cs_data_d;
assign ls_addr_o = ls_addr_d;

  // outputs to cpu
assign if_id_rvalid_o   = rvalid_q;
assign if_id_rcs_data_o = rcs_data_q;

assign if_id_gnt_o    = if_id_gnt;
assign ex_wb_req_o    = ex_wb_req_q;
endmodule