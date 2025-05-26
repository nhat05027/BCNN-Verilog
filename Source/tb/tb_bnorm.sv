`timescale 1ns/1ps

module bnorm_tb;
    reg clk;
    reg rst;
    reg ready;
    reg [15:0] data_in;
    reg [11:0] theta;
    reg [11:0] phi;
    wire finish;
    wire [11:0] out;
    
    // Instantiate DUT
    bnorm dut (
        .clk(clk),
        .rst(rst),
        .ready(ready),
        .data_in(data_in),
        .theta(theta),
        .phi(phi),
        .finish(finish),
        .out(out)
    );
    
    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        ready = 0;
        data_in = 0;
        theta = 12'h100; // 1.0 in Q4.8
        phi = 12'h000;   // 0.0 in Q4.8
        
        // Reset sequence
        #20 rst = 0;
        #10 ready = 1;
        
        // Test 1: Identity transform
        data_in = 16'h0100; // 1.0 in Q8.8
        #10 check_output(12'h100, "Identity transform");
        
        // Test 2: Scale only
        theta = 12'h200; // 2.0 in Q4.8
        data_in = 16'h0100; // 1.0 in Q8.8
        #10 check_output(12'h200, "Scale only");
        
        // Test 3: Shift only
        theta = 12'h100; // 1.0 in Q4.8
        phi = 12'h080;  // 0.5 in Q4.8
        data_in = 16'h0100; // 1.0 in Q8.8
        #10 check_output(12'h180, "Shift only");
        
        // Test 4: Boundary case (max input)
        theta = 12'h100;
        phi = 12'h000;
        data_in = 16'h7FFF; // Max positive Q8.8
        #10 check_output(12'h000, "Max input");
        
        // Test 5: Negative handling
        data_in = 16'hFF00; // -1.0 in Q8.8
        #10 check_output(12'h000, "Negative input (ReLU)");
        
        // Test 6: Timing control
        ready = 0;
        #20 ready = 1;
        #5 if (finish !== 1) $error("Finish should assert when ready=1");
        
        // Test 7: Reset recovery
        #5 rst = 1;
        #5 rst = 0;
        #5 if (out !== 0) $error("Reset failed to clear output");
        
        #100 $display("All tests completed");
        $finish;
    end
    
    task check_output;
        input [11:0] expected;
        input [100:0] testname;
        begin
            wait(finish);
            #1; // Wait for output to settle
            if (out !== expected) begin
                $error("%s failed: got %h, expected %h", 
                      testname, out, expected);
            end else begin
                $display("%s passed", testname);
            end
        end
    endtask
    
    // Monitor results
    initial begin
        $monitor("At %0t: data_in=%h theta=%h phi=%h -> out=%h finish=%b",
                $time, data_in, theta, phi, out, finish);
    end
endmodule
