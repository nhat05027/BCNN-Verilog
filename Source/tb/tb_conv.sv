`timescale 1ns/1ps

module tb_conv();
    reg clk;
    reg rst;
    reg en_conv;
    reg [11:0] data_in;
    reg [8:0] w;
    wire finish;
    wire [15:0] out;
    
    // Instantiate DUT
    conv dut (
        .clk(clk),
        .rst(rst),
        .en_conv(en_conv),
        .data_in(data_in),
        .w(w),
        .finish(finish),
        .out(out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        rst = 1;
        en_conv = 0;
        data_in = 0;
        w = 0;
        
        // Reset sequence
        #20;
        rst = 0;
        en_conv = 1;
        #10;
        
        // Test Case 1: All weights 0 (pure addition)
        $display("Test Case 1: All weights 0 (pure addition)");
        w = 9'b000000000;
        data_in = 12'h100; // Q4.8 value = 1.0
        wait(finish);
        #10;
        $display("Output: %h (expected ~9.0 in Q8.8)", out);
        
        rst = 1;
        #10;
        rst = 0;

        // Test Case 2: All weights 1 (pure subtraction)
        $display("\nTest Case 2: All weights 1 (pure subtraction)");
        w = 9'b111111111;
        data_in = 12'h100; // Q4.8 value = 1.0
        wait(finish);
        #10;
        $display("Output: %h (expected ~-9.0 in Q8.8)", out);
        
        rst = 1;
        #10;
        rst = 0;

        // Test Case 3: Mixed weights
        $display("\nTest Case 3: Mixed weights");
        w = 9'b010101010;
        data_in = 12'h200; // Q4.8 value = 2.0
        wait(finish);
        #10;
        $display("Output: %h (expected ~16.0 in Q8.8)", out);
        
        rst = 1;
        #10;
        rst = 0;

        // Test Case 4: Multiple cycles with different data
        $display("\nTest Case 4: Multiple cycles");
        w = 9'b001100110;
        
        // First convolution
        data_in = 12'h080; // 0.5
        #10;
        
        // Second convolution
        data_in = 12'h180; // 1.5
        wait(finish);
        #10;
        $display("Output: %h", out);

        rst = 1;
        #10;
        rst = 0;
        
        // Test Case 5: Reset during operation
        $display("\nTest Case 5: Reset during operation");
        data_in = 12'h100;
        #15; // Reset before finish
        rst = 1;
        #10;
        rst = 0;
        #10;
        $display("Output after reset: %h (should be 0)", out);

        rst = 1;
        #10;
        rst = 0;
        
        // Test Case 6: Edge cases
        $display("\nTest Case 6: Edge cases");
        // Maximum input value
        w = 9'b010101010;
        data_in = 12'h7FF; // Maximum positive
        wait(finish);
        #10;
        $display("Max input output: %h", out);
        
        rst = 1;
        #10;
        rst = 0;

        // Minimum input value
        data_in = 12'h800; // Minimum (negative)
        wait(finish);
        #10;
        $display("Min input output: %h", out);
        
        $display("\nAll tests completed");
        $finish;
    end
    
    // Monitoring
    always @(posedge clk) begin
        // $display("Time: %t, en_conv: %b, finish: %b, out: %h", 
        //         $time, en_conv, finish, out);
    end
    
    // Assertions
    property finish_goes_high;
        @(posedge clk) (dut.counter > 9) |-> ##1 dut.finish;
    endproperty
    
    assert property(finish_goes_high) 
        else $error("Finish signal didn't go high when counter > 9");
    
    property reset_values;
        @(posedge rst) ##1 (dut.counter == 0 && dut.finish == 0 && dut.sync == 0);
    endproperty
    
    assert property(reset_values)
        else $error("Reset values not properly initialized");
    
endmodule
