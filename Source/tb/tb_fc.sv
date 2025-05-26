`timescale 1ns/1ps
module tb_FullyConnect();
    reg clk, rst;
    reg [11:0] data_in, w;
    wire [3:0] pos_data;
    wire load_weight, finish;
    wire [3:0] cnn_out;
    
    // Khởi tạo DUT
    fullyconnect dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .w(w),
        .pos_data(pos_data),
        .load_weight(load_weight),
        .cnn_out(cnn_out),
        .finish(finish)
    );
    
    // Clock generator (100MHz)
    always #5 clk = ~clk;
    
    // Biến kiểm tra
    reg [11:0] weight_pattern [0:11];
    integer i, error_count;
    
    initial begin
        // Khởi tạo
        clk = 0; rst = 1; 
        data_in = 0; w = 0;
        error_count = 0;
        
        // Test 1: Reset Verification
        $display("[TEST] 1. Reset Verification");
        #20 rst = 0;
        if (cnn_out != 4'b1111) begin
            $error("Reset failed: cnn_out=%b (expected 1111)", cnn_out);
            error_count++;
        end
        #10 rst = 1;
        
        // Test 2: Weight Loading
        $display("\n[TEST] 2. Weight Loading");
        // Tạo weight pattern test (Q4.8 format)
        for (i=0; i<12; i=i+1) 
            weight_pattern[i] = $random % 4096; // Random Q4.8 values
            
        // Serial loading
        for (i=0; i<12; i=i+1) begin
            w = weight_pattern[i];
            #10; // Mỗi chu kỳ load 1 weight
        end
        
        // Kiểm tra parallel output (giả sử có test port internal)
        // if (dut.parallel_weights != expected) -> error_count++;
        
        // Test 3: Basic Inference
        $display("\n[TEST] 3. Basic Inference");
        rst = 0; #10;
        data_in = 12'h100; // 1.0 in Q4.8
        w = 12'h100;       // Tất cả weights = 1.0
        #120; // Chờ computation hoàn tất
        
        // Kiểm tra kết quả (giả sử có test port dense[i])
        for (i=0; i<10; i++) 
           if (dut.dense[i] != dut.bias_rom[i] + 256) // 1.0 = 256 in Q8.8
               error_count++;
        
        // Test 4: Boundary Cases
        $display("\n[TEST] 4. Boundary Cases");
        data_in = 12'h7FF; // 7.996 (max Q4.8)
        w = 12'h001;       // weight = 0.004
        #120;
        // Kiểm tra saturation
        if (dut.dense[0] != 16'h7FFF) error_count++;
        
        // Test 5: Negative Values
        $display("\n[TEST] 5. Negative Values");
        data_in = 12'h200; // +2.0
        w = 12'hF00;       // -1.0
        #120;
        // Kiểm tra signed arithmetic
        // if (dut.dense[0] != dut.bias_rom[0] - 512) error_count++;
        
        // Test 6: Timing Control
        $display("\n[TEST] 6. Timing Control");
        // Theo dõi pos_data và finish
        #1605;
        if (!finish) begin
            $error("Finish signal not asserted");
            error_count++;
        end

        rst = 1; #10;
        rst = 0;
        
        // Test 7: Comparison Logic
        $display("\n[TEST] 7. Comparison Logic");
        // Giả lập tất cả dense bằng nhau
        // force dut.dense[0] = 16'h1000;
        // for (i=1; i<10; i++) force dut.dense[i] = 16'h1000;
        #20;
        // Kiểm tra one-hot output hợp lệ
        if (cnn_out == 0) begin
            $error("Invalid comparison result");
            error_count++;
        end
        // release dut.dense;
        
        // Tổng kết
        $display("\n[TEST SUMMARY]");
        if (error_count == 0)
            $display("PASSED: All testcases completed successfully");
        else
            $display("FAILED: %d errors detected", error_count);
        
        $finish;
    end
    
    // Monitor tự động
    always @(posedge clk) begin
        if (finish)
            $display("t=%0t: Classification result = %b", $time, cnn_out);
            
    end
endmodule
