import vpu_definitions::*;
import insn_formats::*;

module vpu_core #(
  parameter VLEN    = 128,                          // vector length (max 256)
  parameter ELEN    = 32,                           // max. Element size
  parameter LANES   = 2,                            // Number of lanes
  parameter VLEN_B  = VLEN/8,                       // VLEN in Bytes
  parameter BW_VL   = 8,                            // Reduced length of vstart and vl
  parameter BW_I    = $clog2((VLEN/(LANES*ELEN)))   // Bitwidth for iterations
)
(
  //Lane Interface
  input  logic              clk_i,
  input  logic              rst_ni,

  input  logic              insn_req_i,
  output logic              insn_gnt_o,
  input  logic [      31:0] insn_data_i,
  input  logic [      31:0] insn_csr_i,
  input  logic [      31:0] insn_addr_i,

  output logic              insn_rvalid_o,
  output logic [      31:0] insn_rcsr_o,

  // External memory interface
  input  logic              data_gnt_i,
  input  logic [  ELEN-1:0] data_rdata_i,
  input  logic              data_rvalid_i,
  output logic              data_req_o,
  output logic [  ELEN-1:0] data_addr_o,
  output logic              data_we_o,
  output logic [ELEN/8-1:0] data_be_o,
  output logic [  ELEN-1:0] data_wdata_o,

  // Debug Signals
  output logic [LANES-1:0][ELEN/8-1:0] dbg_alu_carry_o,
  output logic [LANES-1:0][  ELEN-1:0] dbg_arith_result_o,
  output logic [LANES-1:0]             dbg_arith_valid_o,
  output logic            [    BW_I:0] dbg_iteration_o,
  output logic            [VLEN/8-1:0] dbg_byte_enable_o,
  output logic                         dbg_insn_complete_o,
  output logic                         dbg_ex_wb_hs_o,
  output logic                         dbg_ex_wb_en_o,
  output logic                         dbg_if_id_en_o
);

// from ID to EX stage
logic         vm;
logic [ 4:0]  vs1;
logic [ 4:0]  vs2;
logic [ 4:0]  vd;
immediate_s   immediate;
alu_mode_s    alu_mode;
mul_mode_s    mul_mode;
mem_mode_s    mem_mode;

logic 		  ex_wb_req;
logic 		  ex_wb_gnt;

// Internal memory interface
logic              ls_gnt;
logic [      31:0] ls_addr;
logic [  VLEN-1:0] load_data;
logic              ls_valid;
logic              ls_req;
logic [VLEN_B-1:0] ls_be;
logic              store_enable;
logic [  VLEN-1:0] store_data;


sew_mode_e         sew;
logic [ BW_VL-1:0] vstart;
logic [ BW_VL-1:0] vl;

logic [		 31:0] insn_d;
logic [		 31:0] cs_data_d;
logic [		 31:0] ls_addr_d;
logic		 	   inv_insn;

// to hold ack inputs
logic [       4:0] vs1_d;
logic [       4:0] vs2_d;
logic [       4:0] vd_d;
logic              vm_d;
immediate_s        immediate_d;
sew_mode_e         sew_d;
logic [ BW_VL-1:0] vstart_d;
logic [ BW_VL-1:0] vl_d;
alu_mode_s         alu_mode_d;
mul_mode_s         mul_mode_d;
mem_mode_s         mem_mode_d;
logic              lanes_done;
logic              ls_enable;
logic [		  4:0] vs3;
logic [VLEN_B-1:0] byte_enable;
logic [VLEN_B-1:0] alu_cin;
logic [ LANES-1:0] lane_done;
logic [  VLEN-1:0] store_data_d;

logic [  VLEN-1:0]  rdata_a;
logic [  VLEN-1:0]  rdata_b;
logic [  VLEN-1:0]  rdata_c;
  
logic				we_a;
logic [  VLEN-1:0]  wdata_a;

vpu_fetch vpu_fetch_inst(
  .clk_i						( clk_i					),
  .rst_ni						( rst_ni				),
  // From CPU                     
  .if_id_req_i					( insn_req_i			),
  .if_id_gnt_o					( insn_gnt_o			),
                                  
  .insn_i						( insn_data_i			),
  .cs_data_i					( insn_csr_i			),
  .ls_addr_i					( insn_addr_i			),
  .inv_insn_i					( inv_insn				),
  // Pipelining                   
  .ex_wb_req_o					( ex_wb_req				),
  .ex_wb_gnt_i					( ex_wb_gnt				),
  // Decoder                      
  .insn_o						( insn_d				),
  .cs_data_o					( cs_data_d				),
  .ls_addr_o					( ls_addr_d				),
  .if_id_rvalid_o				( insn_rvalid_o			),
  .if_id_rcs_data_o				( insn_rcsr_o			)
);

vpu_decoder vpu_decoder_inst (
  .clk_i                        ( clk_i                 ),
  .rst_ni                       ( rst_ni                ),
  .insn_i                       ( insn_d                ),
  .cs_data_i                    ( cs_data_d             ),
  .ls_addr_i                    ( ls_addr_d             ),
  .vs1_o                        ( vs1                   ),
  .vs2_o                        ( vs2                   ),
  .vd_o                         ( vd                    ),
  .vm_o                         ( vm                    ),
  .immediate_o                  ( immediate             ),
  .sew_o                        ( sew                   ),
  .vstart_o                     ( vstart                ),
  .vl_o                         ( vl                    ),
  .alu_mode_o                   ( alu_mode              ),
  .mul_mode_o                   ( mul_mode              ),
  .mem_mode_o                   ( mem_mode              ),
  .inv_insn_o                   ( inv_insn              )
);

/* vpu_if_id_stage if_id_stage (
  .clk_i                        ( clk_i                   ),
  .rst_ni                       ( rst_ni                  ),

  //OBI handshake CPU Interface -> IF ID
  .if_id_req_i                  ( insn_req_i              ),
  .if_id_gnt_o                  ( insn_gnt_o              ),

  //OBI handshake IF ID -> EX WB
  .ex_wb_req_o                  ( ex_wb_req               ),
  .ex_wb_gnt_i                  ( ex_wb_gnt               ),

  // "WDATA"
  .insn_i                       ( insn_data_i             ),
  .cs_data_i                    ( insn_csr_i              ),
  .ls_addr_i                    ( insn_addr_i             ),
  .vs1_o                        ( vs1                     ),
  .vs2_o                        ( vs2                     ),
  .vd_o                         ( vd                      ),
  .vm_o                         ( vm                      ),
  .sew_o                        ( sew                     ),
  .vstart_o                     ( vstart                  ),
  .vl_o                         ( vl                      ),
  .immediate_o                  ( immediate               ),
  .alu_mode_o                   ( alu_mode                ),
  .mul_mode_o                   ( mul_mode                ),
  .mem_mode_o                   ( mem_mode                ),

  // response to cpu
  .if_id_rvalid_o               ( insn_rvalid_o           ),
  .if_id_rcs_data_o             ( insn_rcsr_o             )
); */

/* vpu_ex_wb_stage #(
  .VLEN   ( VLEN  ),
  .ELEN   ( ELEN  ),
  .LANES  ( LANES )
) ex_wb_stage (
  .clk_i                        ( clk_i                   ),
  .rst_ni                       ( rst_ni                  ),

  //OBI handshake IF ID -> EX WB
  .ex_wb_req_i                  ( ex_wb_req               ),
  .ex_wb_gnt_o                  ( ex_wb_gnt               ),

  // "WDATA"
  .vs1_i                        ( vs1                     ),
  .vs2_i                        ( vs2                     ),
  .vd_i                         ( vd                      ),
  .immediate_i                  ( immediate               ),
  .sew_i                        ( sew                     ),
  .vstart_i                     ( vstart                  ),
  .vl_i                         ( vl                      ),
  .vm_i                         ( vm                      ),
  .alu_mode_i                   ( alu_mode                ),
  .mul_mode_i                   ( mul_mode                ),
  .mem_mode_i                   ( mem_mode                ),

  // Interface to LSU
  .ls_request_o                 ( ls_req                  ),
  .ls_byte_enable_o             ( ls_be                   ),
  .ls_address_o                 ( ls_addr                 ),
  .store_enable_o               ( store_enable            ),
  .store_data_o                 ( store_data              ),
  .ls_grant_i                   ( ls_gnt                  ),
  .ls_valid_i                   ( ls_valid                ),
  .load_data_i                  ( load_data               ),

  // Debug
  .dbg_ex_wb_hs_o               ( dbg_ex_wb_hs_o          ),
  .dbg_ex_wb_en_o               ( dbg_ex_wb_en_o          ),
  .dbg_alu_carry_o              ( dbg_alu_carry_o         ),
  .dbg_arith_result_o           ( dbg_arith_result_o      ),
  .dbg_arith_valid_o            ( dbg_arith_valid_o       ),
  .dbg_byte_enable_o            ( dbg_byte_enable_o       ),
  .dbg_iteration_o              ( dbg_iteration_o         ),
  .dbg_insn_complete_o          ( dbg_insn_complete_o     )
);
 */
vpu_execute#(
  .VLEN				  			( VLEN				  	  ),       
  .ELEN				  			( ELEN				  	  ),        
  .LANES				  		( LANES				  	  ),       
  .VLEN_B				  		( VLEN_B				  ),      
  .BW_VL				  		( BW_VL				  	  ),       
  .BW_I				  			( BW_I				  	  )        	
)vpu_execute_inst(
  .clk_i				  		( clk_i				  	  ),
  .rst_ni				  		( rst_ni				  ),
  //.vs1_i				  		( vs1_d				  	  ),
  //.vs2_i				  		( vs2_d				  	  ),
  //.vs3_i				  		( vs3					  ),
  .vd_i				  			( vd_d				  	  ),
  .rdata_a_i					( rdata_a				  ),
  .rdata_b_i					( rdata_b				  ),
  .rdata_c_i					( rdata_c				  ),
  .we_a_o						( we_a					  ),
  .wdata_a_o					( wdata_a				  ),
  
  .immediate_i		  			( immediate_d			  ),
  .sew_i				  		( sew_d				  	  ),
//  .byte_enable_i		  		( byte_enable			  ),
  .alu_cin_i			  		( alu_cin				  ),
  .alu_mode_i			  		( alu_mode_d			  ),
  .mul_mode_i			  		( mul_mode_d			  ),
  .ls_enable_i		  			( ls_enable			  	  ),
  .mem_mode_i			  		( mem_mode_d.op		  	  ),
  .load_data_i		  			( load_data				  ),
  .store_data_o		  			( store_data_d			  ),
  .lanes_done_o		  			( lanes_done			  	  ),
  // Debug Signals
  .dbg_alu_carry_o	  			( dbg_alu_carry_o		  ),
  .dbg_arith_result_o	  		( dbg_arith_result_o	  ),
  .dbg_arith_valid_o	  		( dbg_arith_valid_o       ),
  .dbg_iteration_o	  			( dbg_iteration_o		  )
);

vpu_register_file #(VLEN) vpu_register_file_inst (
  // Clock and Reset
  .clk_i                        ( clk_i                   ),
  .rst_ni                       ( rst_ni                  ),
  // Read                       
  .raddr_b_i                    ( vs1_d                   ),
  .rdata_b_o                    ( rdata_b                 ),
                                                          
  .raddr_a_i                    ( vs2_d                   ),
  .rdata_a_o                    ( rdata_a                 ),
  .raddr_c_i                    ( vs3                     ),
  .rdata_c_o                    ( rdata_c                 ),
  // Write                                                
  .we_a_i                       ( we_a                    ),
  .waddr_a_i                    ( vd_d					  ),
  .wbe_a_i                      ( byte_enable             ),
  .wdata_a_i                    ( wdata_a                 )
);

vpu_ex_controller #(
  .VLEN 						( VLEN					  ),
  .ELEN 						( ELEN					  )
)
vpu_ex_controller_inst
(
  .clk_i                  		( clk_i                   ),
  .rst_ni                 		( rst_ni                  ),
  .sew_i                  		( sew_d            	  	  ),
  .mem_mode_i             		( mem_mode_d              ),
  .mac_insn_i             		( mul_mode_d.mac          ),
  // masking		                                      
  .alu_mode_i             		( alu_mode_d              ),
  .vd_i                   		( vd_d                    ),
  .vstart_i               		( vstart_d                ),
  .vs3_o                  		( vs3                     ),
  .vl_i                   		( vl_d                    ),
  .vm_i                   		( vm_d                    ),
  .lanes_done_i           		( lanes_done              ),
  .store_data_i           		( store_data_d            ),
  .alu_cin_o              		( alu_cin                 ),
  .byte_enable_o          		( byte_enable             ),
  // Internal memory interface                            
  .ls_grant_i             		( ls_gnt	              ),
  .ls_valid_i             		( ls_valid                ),
  .ls_request_o           		( ls_req	              ),
  .store_enable_o         		( store_enable         	  ),
  .store_data_o           		( store_data              ),
  .ls_enable_o            		( ls_enable               )
);


vpu_writeback #(
  .VLEN        			  		( VLEN					  ),            // vector length
  .ELEN        			  		( ELEN					  ),             // max. Element size
  .LANES       			  		( LANES				      ),              // Number of lanes
  .VLEN_B      			  		( VLEN_B				  ),         // vector length
  .BW_VL       			  		( BW_VL				      ),
  .BW_I        			  		( BW_I					  ) // Bitwidth for iterations
)vpu_writeback_inst(
  .clk_i				  		( clk_i					  ),
  .rst_ni				  		( rst_ni				  ),
  .lane_done			  		( lane_done				  ),
  .byte_enable			  		( byte_enable			  ),
  .ex_wb_req_i			  		( ex_wb_req				  ),
//  .ls_valid_i			  		( ls_valid				  ),
		                                                  
  .vs1_i				  		( vs1  				      ),
  .vs2_i				  		( vs2 				      ),
  .vd_i					  		( vd					  ),
  .vm_i					  		( vm					  ),
  .immediate_i			  		( immediate				  ),
  .sew_i				  		( sew					  ),
  .vstart_i				  		( vstart				  ),
  .vl_i					  		( vl					  ),
  .alu_mode_i			  		( alu_mode				  ),
  .mul_mode_i			  		( mul_mode				  ),
  .mem_mode_i			  		( mem_mode				  ),
		                                                  
  .ex_wb_gnt_o			  		( ex_wb_gnt				  ),
//  .ls_address_o			  	( ls_addr				  ),
//  .ls_byte_enable_o		  	( ls_be					  ),	
		                                                  
  .vs1_o				  		( vs1_d				      ),
  .vs2_o				  		( vs2_d				      ),
  .vd_o					  		( vd_d					  ),
  .vm_o					  		( vm_d					  ),
  .immediate_o			  		( immediate_d			  ),
  .sew_o				  		( sew_d					  ),
  .vstart_o				  		( vstart_d				  ),
  .vl_o					  		( vl_d					  ),
  .alu_mode_o			  		( alu_mode_d			  ),
  .mul_mode_o			  		( mul_mode_d			  ),
  .mem_mode_o			  		( mem_mode_d			  ),
  .lanes_done_o			  		( lanes_done			  ),
  
  .ls_req_i						( ls_req				  ),
  .store_enable_i				( store_enable			  ),
  .store_data_i					( store_data			  ),
  .ls_gnt_o						( ls_gnt				  ),
  .ls_valid_o					( ls_valid				  ),
  .load_data_o					( load_data				  ),
  .data_req_o					( data_req_o			  ),
  .data_addr_o					( data_addr_o			  ),
  .data_we_o					( data_we_o				  ),
  .data_be_o					( data_be_o				  ),
  .data_wdata_o					( data_wdata_o			  ),
  .data_gnt_i					( data_gnt_i			  ),
  .data_rdata_i					( data_rdata_i			  ),
  .data_rvalid_i				( data_rvalid_i			  ),
		                                                  
  .dbg_insn_complete_o	  		( dbg_insn_complete_o	  ),
  .dbg_ex_wb_hs_o		  		( dbg_ex_wb_hs_o		  ),
  .dbg_ex_wb_en_o		  		( dbg_ex_wb_en_o		  ),
  .dbg_byte_enable_o	  		( dbg_byte_enable_o		  )
);

/* vpu_lsu #(VLEN, ELEN) lsu
(
  .clk_i                        ( clk_i                   ),
  .rst_ni                       ( rst_ni                  ),

  // Internal memory to EX WB stage
  .ls_req_i                     ( ls_req                  ),
  .ls_addr_i                    ( ls_addr                 ),
//  .ls_stride_i                ( mem_mode.stride         ),
  .ls_be_i                      ( ls_be                   ),
  .store_enable_i               ( store_enable            ),
  .store_data_i                 ( store_data              ),
  .ls_gnt_o                     ( ls_gnt                  ),
  .ls_valid_o                   ( ls_valid                ),
  .load_data_o                  ( load_data               ),

  // External data memory interface
  .data_req_o                   ( data_req_o              ),
  .data_addr_o                  ( data_addr_o             ),
  .data_be_o                    ( data_be_o               ),
  .data_we_o                    ( data_we_o               ),
  .data_wdata_o                 ( data_wdata_o            ),
  .data_gnt_i                   ( data_gnt_i              ),
  .data_rvalid_i                ( data_rvalid_i           ),
  .data_rdata_i                 ( data_rdata_i            )
); */


assign dbg_if_id_en_o  = ex_wb_req;

endmodule : vpu_core
