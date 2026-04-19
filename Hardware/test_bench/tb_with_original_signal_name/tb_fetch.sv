`timescale 1ns / 1ps

module tb_vpu_fetch();

    // Parameters
    localparam BW_VL = 8;

    // Inputs
    reg clk_i;
    reg rst_ni;
    reg if_id_req_i;
    reg [31:0] insn_i;
    reg [31:0] cs_data_i;
    reg [31:0] ls_addr_i;
    reg inv_insn_i;
    reg ex_wb_gnt_i;

    // Outputs
    wire if_id_gnt_o;
    wire [31:0] insn_o;
    wire [31:0] cs_data_o;
    wire [31:0] ls_addr_o;
    wire if_id_rvalid_o;
    wire [31:0] if_id_rcs_data_o;
    wire ex_wb_req_o;

    // Instantiate the Unit Under Test (UUT)
    vpu_fetch #(.BW_VL(BW_VL)) uut (
        .clk_i(clk_i), 
        .rst_ni(rst_ni),
        .if_id_req_i(if_id_req_i), 
        .insn_i(insn_i), 
        .cs_data_i(cs_data_i),
        .ls_addr_i(ls_addr_i),
        .inv_insn_i(inv_insn_i),
        .ex_wb_gnt_i(ex_wb_gnt_i),
        .if_id_gnt_o(if_id_gnt_o),
        .insn_o(insn_o),
        .cs_data_o(cs_data_o),
        .ls_addr_o(ls_addr_o),
        .if_id_rvalid_o(if_id_rvalid_o),
        .if_id_rcs_data_o(if_id_rcs_data_o),
        .ex_wb_req_o(ex_wb_req_o)
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;  // 100 MHz Clock
    end

    // Test Cases
    initial begin
        // Initialize Inputs
        rst_ni = 0;
        if_id_req_i = 0;
        insn_i = 0;
        cs_data_i = 0;
        ls_addr_i = 0;
        inv_insn_i = 0;
        ex_wb_gnt_i = 0;

        // Wait for global reset to finish
        #100;
        rst_ni = 1;  // Release reset
        #20;

        // Test Case 1: Simple Request
        if_id_req_i = 1;
        insn_i = 32'h12345678;
        cs_data_i = 32'h87654321;
        ls_addr_i = 32'h0000ABCD;
        inv_insn_i = 1;
        ex_wb_gnt_i = 1;  // Grant request
        #10;
        if_id_req_i = 0;  // Remove request
        ex_wb_gnt_i = 0;  // Remove grant
        #50;

        // Additional Test Cases

        // Test Case 2: Continuous Requests
        repeat (5) begin
            #10;
            if_id_req_i = 1;
            insn_i = $random;
            cs_data_i = $random;
            ls_addr_i = $random;
            inv_insn_i = $random % 2; // Randomly true or false
            ex_wb_gnt_i = 1;  // Always grant to check throughput
            #10;
            if_id_req_i = 0;
        end

        // Test Case 3: Synchronous Request and Grant
        if_id_req_i = 1;
        ex_wb_gnt_i = 1;
        #10;
        if_id_req_i = 0;
        ex_wb_gnt_i = 0;
        #20;

        // Test Case 4: Reset Behavior
        rst_ni = 0;  // Assert reset
        #10;
        rst_ni = 1;  // Deassert reset
        #20;

        // Test Case 5: Invalid Instruction Input
        if_id_req_i = 1;
        insn_i = 32'hDEADBEEF;
        cs_data_i = 32'hFEEDBEEF;
        ls_addr_i = 32'hBEEFDEAD;
        inv_insn_i = 1;  // Invalid instruction
        ex_wb_gnt_i = 1;
        #10;
        if_id_req_i = 0;
        ex_wb_gnt_i = 0;
        #20;

        // Test Case 6: Boundary Condition Data
        if_id_req_i = 1;
        insn_i = 32'hFFFFFFFF;  // All ones
        cs_data_i = 32'h00000000;  // All zeros
        ls_addr_i = 32'h80000000;  // Negative number in two's complement
        inv_insn_i = 0;
        ex_wb_gnt_i = 1;
        #10;
        if_id_req_i = 0;
        ex_wb_gnt_i = 0;
        #20;

        // Test Case 7: Pipeline Backpressure
        if_id_req_i = 1;
        ex_wb_gnt_i = 0;  // No grant, should test stalling
        #30;
        ex_wb_gnt_i = 1;  // Now grant
        #10;
        if_id_req_i = 0;
        ex_wb_gnt_i = 0;
        #20;

        // Finish simulation
        $finish;
    end

endmodule

