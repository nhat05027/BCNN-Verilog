module tb_cnn;

    logic clk;
    logic rst;
    logic en;
    logic [7:0] data_in; // Data in type 8bit
    logic [9:0] pos_data;
    logic finish;
    logic [3:0] cnn_out; // output

    cnn dut (
        .*
    );

    // Clock generation (100 MHz)
    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    reg [7:0] data_test [783:0];
    initial $readmemb("../test/testdata.mem", data_test);

    // Test procedure
    initial begin
        // Initialize signals
        rst = 1;
        en = 1;

        #100 rst = 0;
        
        #100

        // Test Case 1: Verify reset state
        $display("Test Case 1: Reset State");
        // $display("PC (After Reset): %h", o_pc_debug);
        $display("---------------------------------");

        // // Test Case 2: Execute instructions from isa.mem (e.g., add and store)
        // #100; // Allow time for instruction execution
        // $display("Test Case 2: Post-Execution State");
        // $display("PC: %h", o_pc_debug);
        // $display("LEDR (Expected: 0xDEADBEEF): %h", o_io_ledr); // Example expected value
        // $display("---------------------------------");

        // // Test Case 3: Test I/O switches (simulate input)
        // i_io_sw = 32'h12345678;
        // #40;
        // $display("Test Case 3: Switch Input");
        // $display("Read Switches (Expected: 0x12345678): %h", o_ld_data); // Assuming a load instruction
        // $display("---------------------------------");

        // // Add more test cases as needed...

        // #1000000005 $finish;
    end

    // Monitor critical signals
    always @(posedge clk) begin
        data_in <= data_test[pos_data];
        // $display("i_pc_sel = %h, i_imm_sel = %h, i_rd_wren = %h", dut.DP.i_pc_sel, dut.DP.i_imm_sel, dut.DP.i_rd_wren);

        // $display("i_br_un = %h, o_br_less = %h, o_br_equal = %h ", dut.DP.i_br_un, dut.DP.o_br_less, dut.DP.o_br_equal);
        
        // $display("i_opa_sel = %h, i_opb_sel = %h, i_alu_op = %h", dut.DP.i_opa_sel, dut.DP.i_opb_sel, dut.DP.i_alu_op);

        // $display("i_mem_wren = %h, i_wb_sel = %h, i_lsu_op = %h", dut.DP.i_mem_wren, dut.DP.i_wb_sel, dut.DP.i_lsu_op);

        // $display("alu = %h", dut.DP.alu_data);
        // $display("opa = %h", dut.DP.operand_a);
        // $display("opb = %h", dut.DP.operand_b);

        // $display("ledr = %h", o_io_ledr);
        // $display("Time: %0t | PC: %h | Instr: %h", $time, dut.DP.pc, dut.DP.instr);
        //if (dut.DP.finish_conv) $write("%d", dut.DP.out_conv); //$write("Conv %d, %d: %d ", dut.x_pos_temp_conv, dut.y_pos_temp_conv, dut.DP.out_conv);
        // if (posedge dut.DP.finish_bn == 1) $write("Bn %h: %d\n", dut.DP.addr_ram, dut.DP.out_bn);
    end
    always @(posedge dut.DP.finish_bn) begin  
        // if (dut.block_no==1) if (dut.DP.finish_bn) $write("%d,", dut.DP.out_bn); 
        // if (dut.block_no==2) if (dut.DP.finish_bn&dut.window_no_conv==3) $write("%d,", dut.DP.out_bn); 
        // if (dut.block_no==3) if (dut.DP.finish_mp) $write("%d,", dut.DP.out_mp); 
    end
    always @(dut.kernel_no_conv) begin
        // $write("\n\n\n");
        // if (dut.block_no==2) $write("\nConv2\n");
        // if (dut.block_no==3) $write("\nMpool1\n");
        
    end
    always @(dut.block_no) begin
        if (dut.block_no==15) begin
            $write("Predict: %d", cnn_out);
            $finish;
        end
    end

endmodule