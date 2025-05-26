`define IMAGE "../test/mnist_test_images.mem"
`define LABEL "../test/mnist_test_labels.mem"
`define DATA_LENTH 10000
module tb_cnn_data;

    logic clk;
    logic rst;
    logic en;
    logic [7:0] data_in; // Data in type 8bit
    logic [9:0] pos_data;
    logic finish;
    logic [3:0] cnn_out; // output

    reg [13:0] counter;
    reg [22:0] image_addr;
    reg [13:0] score;

    cnn dut (
        .*
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    reg [7:0] test_image [784*`DATA_LENTH-1:0];
    reg [7:0] test_label [`DATA_LENTH-1:0];
    initial begin
        $readmemb(`IMAGE, test_image);
        $readmemb(`LABEL, test_label);
    end

    // Test procedure
    initial begin
        // Initialize signals
        rst = 1;
        en = 1;
        counter = 0;
        score = 0;

        #10 rst = 0;
        
        $display("---------------------------------");

    end

    always @(posedge clk) begin
        if (!finish) begin
            rst <=0;
            data_in <= test_image[counter*784+pos_data];
        end
        else begin
            $write("Test %d: ", counter+1);
            if (test_label[counter][3:0] == cnn_out) begin
                 $write("[ CORRECT ] Predict %d|Label %d", cnn_out, test_label[counter][3:0]);
                score <= score + 1;
            end
            else $write("[INCORRECT] Predict %d|Label %d", cnn_out, test_label[counter][3:0]);
            counter <= counter+1;
            rst <= 1;
        end
    end

    always @(counter) begin
        $write("(%d/%d)\n", score, counter);
        if (counter==`DATA_LENTH) begin
            $display("---------------------------------");
            $display("---------------------------------");
            $write("Result: %d/%d \n", score, `DATA_LENTH);
            $finish;
        end
    end

endmodule