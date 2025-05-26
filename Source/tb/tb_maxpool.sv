`timescale 1ns/1ps

module maxpool_tb;
    reg clk = 0;
    reg rst = 1;
    reg [11:0] data_in;
    reg end_data;
    wire finish;
    wire [11:0] out;
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Instantiate DUT
    maxpool dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .end_data(end_data),
        .finish(finish),
        .out(out)
    );
    
    initial begin
        // Initialize waveform dump
        $dumpfile("maxpool.vcd");
        $dumpvars(0, maxpool_tb);
        
        // Reset sequence
        #10 rst = 0;
        
        // Test Case 1: Basic 2x2 window
        $display("Test Case 1: Basic window");
        data_in = 12'h100; // 1.0 in Q4.8
        #10 data_in = 12'h080; // 0.5
        #10 data_in = 12'h180; // 1.5
        #10 data_in = 12'h000; // 0.0
        end_data = 1;
        #10 end_data = 0;
        #20; // Wait for processing
        
        // Test Case 2: Boundary values
        $display("Test Case 2: Boundary values");
        data_in = 12'h7FF; // Max Q4.8 (7.996)
        #10 data_in = 12'h000; 
        #10 data_in = 12'h7FF;
        #10 data_in = 12'h700;
        end_data = 1;
        #10 end_data = 0;
        #20;
        
    
        // Test Case 3: Reset during operation
        $display("Test Case 3: Reset during operation");
        data_in = 12'h100;
        #10 data_in = 12'h200;
        #5 rst = 1;
        #5 rst = 0;
        #10 data_in = 12'h300;
        #10 data_in = 12'h400;
        end_data = 1;
        #10 end_data = 0;
        #20;
        
        $display("All tests completed");
        $finish;
    end
endmodule
