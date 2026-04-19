module vpu_register_file # (
  parameter LLEN = 128
) (
  // Clock and Reset
  input  logic              clk_i,
  input logic rst_ni,
  //Read port R1
  input  logic [       4:0] raddr_a_i,
  output logic [  LLEN-1:0] rdata_a_o,
  //Read port R
  input  logic [       4:0] raddr_b_i,
  output logic [  LLEN-1:0] rdata_b_o,
  //Read port R3
  input  logic [       4:0] raddr_c_i,
  output logic [  LLEN-1:0] rdata_c_o,
  // Write port W1
  input  logic [       4:0] waddr_a_i,
  input  logic [  LLEN-1:0] wdata_a_i,
  input  logic [LLEN/8-1:0] wbe_a_i,
  input  logic              we_a_i
);

localparam BYTE         = 8;
localparam ADDR_WIDTH   = 5;
localparam NUM_REGISTER = 2**ADDR_WIDTH; // 32
localparam NUM_BYTES    = LLEN / BYTE;

logic [NUM_BYTES-1:0][7:0] mem[NUM_REGISTER];

// async_read a
assign rdata_a_o = mem[raddr_a_i];

// async_read b
assign rdata_b_o = mem[raddr_b_i];

// async_read c
assign rdata_c_o = mem[raddr_c_i];

always_ff @(posedge clk_i) begin : sync_write

  if (rst_ni == 1'b1 && we_a_i == 1'b1) begin

    for (int i = 0; i < LLEN/8; i++) begin
      if (wbe_a_i[i]) mem[waddr_a_i][i] <= wdata_a_i[i*8 +: 8];
    end

  end

end

endmodule : vpu_register_file
