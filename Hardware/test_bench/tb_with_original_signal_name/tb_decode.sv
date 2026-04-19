`timescale 1ns / 1ps

module vpu_decoder_tb;

// Parameters of the DUT
localparam BW_VL = 8;

// Inputs
logic 				clk_i;
logic 				rst_ni;
logic	[31:0] 		insn_i;
logic	[31:0] 		cs_data_i;
logic	[31:0] 		ls_addr_i;
// Outputs
logic 				inv_insn_o;
logic 	[4:0]		vs1_o;
logic 	[4:0]		vs2_o;
logic 	[4:0]		vd_o;
logic 	[BW_VL-1:0] vl_o;
logic 	[BW_VL-1:0] vstart_o;
logic 				vm_o;
sew_mode_e			sew_o;
mem_mode_s			mem_mode_o;
alu_mode_s			alu_mode_o;
mul_mode_s			mul_mode_o;
immediate_s 		immediate_o;

logic				if_id_req_i;
    
    // Instantiate the Unit Under Test (UUT)
    vpu_decoder vpu_decoder_uut(
	.clk_i                        ( clk_i                 ),
	.rst_ni                       ( rst_ni                ),
	.insn_i                       ( insn_i                ),
	.cs_data_i                    ( cs_data_i             ),
	.ls_addr_i                    ( ls_addr_i             ),
	.vs1_o                        ( vs1_o                 ),
	.vs2_o                        ( vs2_o                 ),
	.vd_o                         ( vd_o                  ),
	.vm_o                         ( vm_o                  ),
	.immediate_o                  ( immediate_o           ),
	.sew_o                        ( sew_o                 ),
	.vstart_o                     ( vstart_o              ),
	.vl_o                         ( vl_o                  ),
	.alu_mode_o                   ( alu_mode_o            ),
	.mul_mode_o                   ( mul_mode_o            ),
	.mem_mode_o                   ( mem_mode_o            ),
	.inv_insn_o                   ( inv_insn_o            )
);

    // Clock generation
initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // 100 MHz Clock
end

    // Initial Setup and Reset
initial begin
    // Initialize Inputs
    rst_ni = 0;

    insn_i = 32'h00000000;
    ls_addr_i = 32'h00000000;
   

    // Wait for global reset
    #100;
    rst_ni = 1;
    #10;

        // Test Cases
//    ___   _     _   _  ______                   _           
//   / _ \ | |   | | | | |  _  \                 | |          
//  / /_\ \| |   | | | | | | | |___  ___ ___   __| | ___ _ __ 
//  |  _  || |   | | | | | | | / _ \/ __/ _ \ / _` |/ _ \ '__|
//  | | | || |___| |_| | | |/ /  __/ (_| (_) | (_| |  __/ |   
//  \_| |_/\_____/\___/  |___/ \___|\___\___/ \__,_|\___|_|   
                                                               
        // Test Case 1: Simple ALU operation (VADD)
        insn_i = {6'b000000, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // R-type: ADD x3, x1, x2
        if_id_req_i = 1'b1;    // Request signal active
        #10 if_id_req_i = 1'b0; // Simulate handshake;
        
        // Test Case 2: Addition With Carry (VADC)
        #10;
        insn_i = {6'b010000, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VADC V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 3: Multiply-Add with Carry (VMADC)
        #10;
        insn_i = {6'b010001, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // VMADC V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;

        // Test Case 4: Subtraction (VSUB)
        #10;
        insn_i = {6'b000010, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VSUB V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 5: Reverse Subtraction (VRSUB)
        #10;
        insn_i = {6'b000011, 1'b1, 5'b00010, 5'b00001, 3'b011, 5'b00011, 7'b1010111}; // VRSUB V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 6: Subtract with Borrow (VSBC)
        #10;
        insn_i = {6'b010010, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VSBC V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 7: Multiply-Subtract with Borrow (VMSBC)
        #10;
        insn_i = {6'b010011, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // VMSBC V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;

        // Test Case 8: Bitwise VAND
        #10;
        insn_i = {6'b001001, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VAND V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 9: Logical VOR
        #10;
        insn_i = {6'b001010, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // VOR V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 10: Logical VXOR
        #10;
        insn_i = {6'b001011, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VXOR V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 11: Mask Set Equal (VMSEQ)
        #10;
        insn_i = {6'b011000, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // VMSEQV1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 12: Mask Set Not Equal (VMSNE)
        #10;
        insn_i = {6'b011001, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VMSNE V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 13: Mask Set Less Than Unsigned (VMSLTU)
        #10;
        insn_i = {6'b011010, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // VMSLT V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 14: Mask Set Less Than (VMSLT)
        #10;
        insn_i = {6'b011011, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VMSLT V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 15: Mask Set Less Than or Equal Unsigned (VMSLEU)
        #10;
        insn_i = {6'b011100, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // VMSLEU V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 16: Mask Set Less Than or Equal (VMSLE)
        #10;
        insn_i = {6'b011101, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VMSGTU V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 17: Mask Set Greater Than Unsigned (VMSGTU)
        #10;
        insn_i = {6'b011110, 1'b1, 5'b00010, 5'b00001, 3'b011, 5'b00011, 7'b1010111}; // VMSGTU V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 18: Mask Set Greater Than (VMSGT)
        #10;
        insn_i = {6'b011111, 1'b1, 5'b00001, 5'b00010, 3'b011, 5'b00110, 7'b1010111}; // VMSGTV1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
    
        // Test Case 19: Shift Left Logic (VSLL)
        #10;
        insn_i = {6'b100101, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // VSLL V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 20: Shift Right Logic (VSRL)
        #10;
        insn_i = {6'b101000, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VSRL V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 21: Shift Right Arithmetic (VSRA)
        #10;
        insn_i = {6'b101001, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // VSRA V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
    
        // Additional Test Case 22: Invalid Opcode
        #10;
        insn_i = 32'hFFFFFFFF; // Completely invalid opcode to test error handling
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 23: Max Unsigned (VMAXU)
        #10;
        insn_i = {6'b000110, 1'b1, 5'b00010, 5'b00001, 3'b000, 5'b00011, 7'b1010111}; // VMAXU V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0; 
        
        // Test Case 24: Max Unsigned (VMAX)
        #10;
        insn_i = {6'b000111, 1'b1, 5'b00001, 5'b00010, 3'b000, 5'b00110, 7'b1010111}; // VMAX V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
           
//  ___  ___      _ _   _       _        ______                   _           
//  |  \/  |     | | | (_)     | |       |  _  \                 | |          
//  | .  . |_   _| | |_ _ _ __ | |_   _  | | | |___  ___ ___   __| | ___ _ __ 
//  | |\/| | | | | | __| | '_ \| | | | | | | | / _ \/ __/ _ \ / _` |/ _ \ '__|
//  | |  | | |_| | | |_| | |_) | | |_| | | |/ /  __/ (_| (_) | (_| |  __/ |   
//  \_|  |_/\__,_|_|\__|_| .__/|_|\__, | |___/ \___|\___\___/ \__,_|\___|_|   
//                       | |       __/ |                                      
//                       |_|      |___/                                       
        
        // Test Case 25: Multiply (MUL)
        #10;
        insn_i = {6'b100101, 1'b1, 5'b00010, 5'b00001, 3'b010, 5'b00011, 7'b1010111}; // VMUL V1, V2, V3
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 26: Multiply High (VMULH)
        #10;
        insn_i = {6'b100111, 1'b1, 5'b00001, 5'b00010, 3'b010, 5'b00110, 7'b1010111}; 
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test Case 27: Multiply High Unsigned (VMULHU)
        #10;
        insn_i = {6'b100100, 1'b1, 5'b00010, 5'b00001, 3'b010, 5'b00011, 7'b1010111}; 
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
    
        // Test Case 28: Multiply-Accumulate (VMACC)
        #10;
        insn_i = {6'b101101, 1'b1, 5'b00001, 5'b00010, 3'b010, 5'b00110, 7'b1010111}; 
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
//  ___  ___                                 ______                   _           
//  |  \/  |                                 |  _  \                 | |          
//  | .  . | ___ _ __ ___   ___  _ __ _   _  | | | |___  ___ ___   __| | ___ _ __ 
//  | |\/| |/ _ \ '_ ` _ \ / _ \| '__| | | | | | | / _ \/ __/ _ \ / _` |/ _ \ '__|
//  | |  | |  __/ | | | | | (_) | |  | |_| | | |/ /  __/ (_| (_) | (_| |  __/ |   
//  \_|  |_/\___|_| |_| |_|\___/|_|   \__, | |___/ \___|\___\___/ \__,_|\___|_|   
//                                     __/ |                                      
//                                    |___/                                       
        
	// Test case 1: Load Operation
	#10;
	ls_addr_i = 32'h12345678;
        insn_i = {3'b010, 1'b1, 2'b01, 1'b1, 5'b00001, 5'b00010, 3'b010, 5'b00110, 7'b0000111}; 
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;

        // Test case 2: Store Operation
        #10;
        ls_addr_i = 32'h00000001;
        insn_i = {3'b010, 1'b1, 2'b01, 1'b1, 5'b00001, 5'b00010, 3'b010, 5'b00110, 7'b0100111}; 
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;
        
        // Test case 3: Load Operation
	#10;
	ls_addr_i = 32'h87654321;
        insn_i = {3'b010, 1'b1, 2'b01, 1'b1, 5'b01000, 5'b00010, 3'b010, 5'b00110, 7'b0000111}; 
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;

        // Test case 4: Store Operation
        #10;
        ls_addr_i = 32'h10000000;
        insn_i = {3'b010, 1'b1, 2'b01, 1'b1, 5'b01000, 5'b00010, 3'b010, 5'b00110, 7'b0100111}; 
        if_id_req_i = 1'b1;
        #10 if_id_req_i = 1'b0;

        $finish;
    end

endmodule




