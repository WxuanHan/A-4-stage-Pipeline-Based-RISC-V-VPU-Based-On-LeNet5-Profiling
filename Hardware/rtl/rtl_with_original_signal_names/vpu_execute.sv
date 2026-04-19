import vpu_definitions::*;
import insn_formats::*;

module vpu_execute#(
  parameter VLEN        = 128,            // vector length
  parameter ELEN        = 32,             // max. Element size
  parameter LANES       = 2,              // Number of lanes
  parameter VLEN_B      = VLEN/8,         // vector length
  parameter BW_VL       = 8,
  parameter BW_I        = $clog2((VLEN/(LANES*ELEN))) // Bitwidth for iterations
)
(
	input   logic             		clk_i,
	input   logic             		rst_ni,
	//input	logic	[		4:0]	vs1_i,
	//input	logic	[		4:0]	vs2_i,
	//input	logic	[		4:0]	vs3_i,
	input	logic	[		4:0]	vd_i,
	
	input   logic   [  VLEN-1:0]  	rdata_a_i,
	input   logic   [  VLEN-1:0]  	rdata_b_i,
	input   logic   [  VLEN-1:0]  	rdata_c_i,
	
	output  logic	 				we_a_o,
	output  logic	[  VLEN-1:0]	wdata_a_o,
	
	input	immediate_s		  		immediate_i,
	input	sew_mode_e		  		sew_i,
//	input	logic	[VLEN_B-1:0]	byte_enable_i,
	input	logic	[VLEN_B-1:0]	alu_cin_i,
	input	alu_mode_s				alu_mode_i,
	input	mul_mode_s				mul_mode_i,
	input	logic					ls_enable_i,
	input	mem_mode_s				mem_mode_i,
	input	logic	[  VLEN-1:0]	load_data_i,
	output	logic	[  VLEN-1:0]	store_data_o,
	output	logic   [ LANES-1:0] 	lanes_done_o,
	  // Debug Signals
	output logic [LANES-1:0][ELEN/8-1:0] dbg_alu_carry_o,
	output logic [LANES-1:0][  ELEN-1:0] dbg_arith_result_o,
	output logic [LANES-1:0]             dbg_arith_valid_o,
	output logic            [    BW_I:0] dbg_iteration_o
);
localparam LLEN   = VLEN/LANES;          // bit Length for each lane
localparam LLEN_B = LLEN/8;              // length in byte for byte_enable

logic [LANES-1:0][   LLEN-1:0] lane_load_data;
logic [LANES-1:0][   LLEN-1:0] lane_store_data;
logic [LANES-1:0][ LLEN_B-1:0] lane_byte_enable;
logic [LANES-1:0][ LLEN_B-1:0] lane_alu_cin;

logic [LANES-1:0][   LLEN-1:0] rdata_a;
logic [LANES-1:0][   LLEN-1:0] rdata_b;
logic [LANES-1:0][   LLEN-1:0] rdata_c;
logic [LANES-1:0]			   we_a;
logic [LANES-1:0][   LLEN-1:0] wdata_a;

logic [LANES-1:0][     BW_I:0] dbg_iteration;

logic [LANES-1:0] 			   lanes_done;
  
genvar i;
generate
for (i = 0; i < LANES; i++) begin : n
  vpu_lane_new #(LLEN, ELEN) lane (
    .clk_i                  ( clk_i            		),
    .rst_ni                 ( rst_ni           		),
    //.vs1_i                  ( vs1_i	     			),
    //.vs2_i                  ( vs2_i	     			),
    //.vs3_i                  ( vs3_i       			),
    .vd_i                   ( vd_i                  ), 
	.rdata_a_i				( rdata_a[i]			), // vs2
	.rdata_b_i				( rdata_b[i]			), // vs1
	.rdata_c_i				( rdata_c[i]			), // vs3 -- (normally v0)
	.we_a_o					( we_a[i]				),
	.wdata_a_o				( wdata_a[i]		    ),
	
    .immediate_i            ( immediate_i      		),

    .sew_i                  ( sew_i            		),
//    .byte_enable_i          ( lane_byte_enable[i]   ),
    .alu_cin_i              ( lane_alu_cin[i]       ),
    .alu_mode_i             ( alu_mode_i          	),
    .mul_mode_i             ( mul_mode_i       		),
    .ls_enable_i            ( ls_enable_i           ),
    .ls_op_i                ( mem_mode_i.op     	),
    .load_data_i            ( lane_load_data[i]     ),
    .store_data_o           ( lane_store_data[i]    ),
    .done_o                 ( lanes_done[i]   		),

    .dbg_alu_carry_o        ( dbg_alu_carry_o[i]    ),
    .dbg_arith_result_o     ( dbg_arith_result_o[i] ),
    .dbg_arith_valid_o      ( dbg_arith_valid_o[i]  ),
    .dbg_iteration_o        ( dbg_iteration[i]      )
  );
end : n
endgenerate

logic 				we_a_d,we_a_q;
logic [ VLEN-1:0]	wdata_a_d,wdata_a_q,wdata_a_f;
logic [ VLEN-1:0]	store_data_d,store_data_q,store_data_f;
logic [LANES-1:0] 	lanes_done_d,lanes_done_q;

always_comb begin
	wdata_a_d = wdata_a_q;
	for(int k = 0; k < LANES; k++)begin
		rdata_a[k] = rdata_a_i[k*LLEN +: LLEN];
	//	rdata_b[k] = rdata_b_i[k*LLEN +: LLEN];
		rdata_c[k] = rdata_c_i[k*LLEN +: LLEN];
		wdata_a_d[k*LLEN +: LLEN] = wdata_a[k];
	end
end

always_comb begin
	for(int l = 0; l < LANES; l++)begin
		if(mul_mode_i.redsum == 1'b1)begin
			if(l == 0)begin
				rdata_b[l] = {{(LLEN-ELEN){1'b0}},rdata_b_i[l*ELEN +: ELEN]};
			end
			else begin
				rdata_b[l] = {(LLEN){1'b0}};
			end
		end
		else begin
			rdata_b[l] = rdata_b_i[l*LLEN +: LLEN];
		end
	end
end

always_ff @ (posedge clk_i) begin
	if(~rst_ni)begin
		wdata_a_q <= '0;
	end
	else begin
		wdata_a_q <= wdata_a_d;
	end
end

always_comb begin
	for(int h = 0; h < LANES; h++)begin
		if(mul_mode_i.redsum == 1'b1)begin
			if(h == 0)begin
				wdata_a_f[h*LLEN +: LLEN] = wdata_a_q[h*LLEN +: LLEN];
			end
			else begin
				wdata_a_f[h*LLEN +: LLEN] = wdata_a_f[(h-1)*LLEN +: LLEN] + wdata_a_q[h*LLEN +: LLEN];
			end
		end
		else begin
			wdata_a_f[h*LLEN +: LLEN] = wdata_a_q[h*LLEN +: LLEN];
		end
	end
end

always_ff @ (posedge clk_i)begin
	if(~rst_ni)begin
		wdata_a_o <= '0;
	end
	else begin
		if(mul_mode_i.redsum == 1'b1)begin
			wdata_a_o <= {{(VLEN-LLEN){1'b0}},wdata_a_f[(VLEN-LLEN-1) -: LLEN]};
		end
		else begin
			wdata_a_o <= wdata_a_f;
		end
	end
end

always_ff @ (posedge clk_i)begin
	if(~rst_ni)begin
		we_a_d <= '0;
	end
	else begin
		we_a_d <= |we_a;
	end
end

/* always_ff @ (posedge clk_i)begin
	if(~rst_ni)begin
		we_a_q <= '0;
	end
	else begin
		we_a_q <= we_a_d;
	end
end */

always_ff @ (posedge clk_i)begin
	if(~rst_ni)begin
		we_a_o <= '0;
	end
	else begin
		we_a_o <= we_a_d;
	end
end

always_ff @ (posedge clk_i) begin
	if(~rst_ni)begin
		store_data_q <= '0;
	end
	else begin
		store_data_q <= store_data_d;
	end
end

always_comb begin
	for(int g = 0; g < LANES; g++)begin
		if(mul_mode_i.redsum == 1'b1)begin
			if(g == 0)begin
				store_data_f[g*LLEN +: LLEN] = store_data_q[g*LLEN +: LLEN];
			end
			else begin
				store_data_f[g*LLEN +: LLEN] = store_data_f[(g-1)*LLEN +: LLEN] + store_data_q[g*LLEN +: LLEN];
			end
		end
		else begin
			store_data_f[g*LLEN +: LLEN] = store_data_q[g*LLEN +: LLEN];
		end
	end
end

always_ff @ (posedge clk_i)begin
	if(~rst_ni)begin
		store_data_o <= '0;
	end
	else begin
		if(mul_mode_i.redsum == 1'b1)begin
			store_data_o <= {{(VLEN-LLEN){1'b0}},store_data_f[(VLEN-LLEN-1) -: LLEN]};
		end
		else begin
			store_data_o <= store_data_f;
		end
	end
end

always_ff @ (posedge clk_i)begin
	if(~rst_ni)begin
		lanes_done_d <= '0;
	end
	else begin
		lanes_done_d <= lanes_done;
	end
end

always_ff @ (posedge clk_i)begin
	if(~rst_ni)begin
		lanes_done_o <= '0;
	end
	else begin
		lanes_done_o <= lanes_done_d;
	end
end

always_comb begin

  for (int j = 0; j < LANES; j++) begin

//    lane_byte_enable[j]         = byte_enable_i[j*LLEN_B +: LLEN_B];
    lane_alu_cin[j]             = alu_cin_i[j*LLEN_B +: LLEN_B];
    lane_load_data[j]           = load_data_i[j*LLEN +: LLEN];
    store_data_d[j*LLEN +: LLEN]= lane_store_data[j];

    // disable lane if until all lanes are ready
    //lane_enable[j]              = ex_wb_req_i;
  end
end



//assign we_a_o = |we_a;
assign dbg_iteration_o = dbg_iteration[0];
endmodule