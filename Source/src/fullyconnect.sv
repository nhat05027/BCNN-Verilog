`define BROM "../mem/biasrom.mem"

// module SIPO110 (
//     input wire clk,              // Clock input
//     input wire reset,            // Reset input
//     input wire serial_in,        // Serial input data
//     input wire shift,            // Shift control input
//     output reg [9:0] parallel_out // Parallel output data
// );

//     reg [9:0] shift_register;

//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             shift_register <= 0;
//             parallel_out <= 0;
//         end else if (shift) begin
//             shift_register <= {shift_register[8:0], serial_in};
//             parallel_out <= shift_register;
//         end
//     end
// endmodule

module fullyconnect (
    input wire clk,
    input wire rst,
    input wire[11:0] data_in, // Data in type Q4.8
    // input wire[11:0] w, // Weight in type Q4.8
    input wire[119:0] w, // Weight in type Q4.8
    output reg[3:0] pos_data,
    // output wire load_weight,
    output reg[3:0] cnn_out, // Data out type Q4.8
    output reg finish
);

    wire [23:0] mul_res[9:0];
    reg [15:0] dense[9:0]; // Preload bias
//    initial $readmemb(`BROM, dense);
    wire [15:0] dense_temp[9:0];
    reg [11:0] n_weight[9:0];
    reg [3:0]counter;
    reg pos_data_ovf;
    
    initial begin
        cnn_out = 15;
        pos_data = 0;
        pos_data_ovf = 0;
        counter = 0;
        $readmemb(`BROM, dense);
    end

    // assign {n_weight[9], n_weight[8], n_weight[7], n_weight[6], n_weight[5], n_weight[4], n_weight[3], n_weight[2], n_weight[1], n_weight[0]} = w;
    assign {n_weight[0], n_weight[1], n_weight[2], n_weight[3], n_weight[4], n_weight[5], n_weight[6], n_weight[7], n_weight[8], n_weight[9]} = w;
    // assign load_weight = (counter>10) ? 0 : 1;

    genvar i;
    generate
        for(i=0;i<10;i=i+1)
        // for(i=0;i<12;i=i+1)
        begin
            // SIPO110 G (
            //     .clk(clk),
            //     .reset(rst),
            //     .serial_in(w[i]),
            //     .shift(load_weight),
            //     .parallel_out({n_weight[9][i],
            //                     n_weight[8][i],
            //                     n_weight[7][i],
            //                     n_weight[6][i],
            //                     n_weight[5][i],
            //                     n_weight[4][i],
            //                     n_weight[3][i],
            //                     n_weight[2][i],
            //                     n_weight[1][i],
            //                     n_weight[0][i]})
            // );
            // if(i<10) assign mul_res[i] = {12'b0, data_in}*{{12{n_weight[i][11]}}, n_weight[i]};
            // if(i<10) assign dense_temp[i] = dense[i] + mul_res[i][23:8];
            assign mul_res[i] = {12'b0, data_in}*{{12{n_weight[i][11]}}, n_weight[i]};
            assign dense_temp[i] = dense[i] + mul_res[i][23:8];

        end
    endgenerate

    reg[15:0] tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8;
    reg[3:0] itmp1, itmp2, itmp3, itmp4, itmp5, itmp6, itmp7, itmp8;
    always @(*) begin
        if (rst) cnn_out <= 4'b1111;
        else begin
        // 1
        if ((dense[0]>dense[1])^((!dense[0][15])&dense[1][15])^((dense[0][15])&!dense[1][15])) begin
            tmp1 = dense[0];
            itmp1 = 4'b0000;
        end else begin
            tmp1 = dense[1];
            itmp1 = 4'b0001;
        end
        // 2
        if ((dense[2]>dense[3])^((!dense[2][15])&dense[3][15])^((dense[2][15])&!dense[3][15])) begin
            tmp2 = dense[2];
            itmp2 = 4'b0010;
        end else begin
            tmp2 = dense[3];
            itmp2 = 4'b0011;
        end
        // 3
        if ((dense[4]>dense[5])^((!dense[4][15])&dense[5][15])^((dense[4][15])&!dense[5][15])) begin
            tmp3 = dense[4];
            itmp3 = 4'b0100;
        end else begin
            tmp3 = dense[5];
            itmp3 = 4'b0101;
        end
        // 4
        if ((dense[6]>dense[7])^((!dense[6][15])&dense[7][15])^((dense[6][15])&!dense[7][15])) begin
            tmp4 = dense[6];
            itmp4 = 4'b0110;
        end else begin
            tmp4 = dense[7];
            itmp4 = 4'b0111;
        end
        // 5
        if ((dense[8]>dense[9])^((!dense[8][15])&dense[9][15])^((dense[8][15])&!dense[9][15])) begin
            tmp5 = dense[8];
            itmp5 = 4'b1000;
        end else begin
            tmp5 = dense[9];
            itmp5 = 4'b1001;
        end
        // 6
        if ((tmp1>tmp2)^((!tmp1[15])&tmp2[15])^((tmp1[15])&!tmp2[15])) begin
            tmp6 = tmp1;
            itmp6 = itmp1;
        end else begin
            tmp6 = tmp2;
            itmp6 = itmp2;
        end
        // 7
        if ((tmp3>tmp4)^((!tmp3[15])&tmp4[15])^((tmp3[15])&!tmp4[15])) begin
            tmp7 = tmp3;
            itmp7 = itmp3;
        end else begin
            tmp7 = tmp4;
            itmp7 = itmp4;
        end
        // 8
        if ((tmp6>tmp7)^((!tmp6[15])&tmp7[15])^((tmp6[15])&!tmp7[15])) begin
            tmp8 = tmp6;
            itmp8 = itmp6;
        end else begin
            tmp8 = tmp7;
            itmp8 = itmp7;
        end
        // 9
        if ((tmp8>tmp5)^((!tmp8[15])&tmp5[15])^((tmp8[15])&!tmp5[15])) begin
            cnn_out <= itmp8;
        end else begin
            cnn_out <= itmp5;
        end
    end
    end
    
    reg sync;
    initial sync=0;
    reg next_state;
    initial next_state=0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // counter <= 4'b0;
            sync <= 0;
            next_state <=0;
            pos_data <= 0;
            finish <= 0;
            pos_data_ovf <= 0;
            dense[9] <= 16'b1111111111100111;
            dense[8] <= 16'b1111111111101110;
            dense[7] <= 16'b0000000000001000;
            dense[6] <= 16'b1111111111101001;
            dense[5] <= 16'b1111111111010110;
            dense[4] <= 16'b0000000000000110;
            dense[3] <= 16'b1111111111111100;
            dense[2] <= 16'b1111111111101110;
            dense[1] <= 16'b0000000001101111;
            dense[0] <= 16'b1111111111010001;
            // $readmemb(`BROM, dense);
        end else if (pos_data_ovf) begin
            finish <= 1;
        // end else if (!load_weight) begin
        //     dense[9] <= dense_temp[9];
        //     dense[8] <= dense_temp[8];
        //     dense[7] <= dense_temp[7];
        //     dense[6] <= dense_temp[6];
        //     dense[5] <= dense_temp[5];
        //     dense[4] <= dense_temp[4];
        //     dense[3] <= dense_temp[3];
        //     dense[2] <= dense_temp[2];
        //     dense[1] <= dense_temp[1];
        //     dense[0] <= dense_temp[0];
        //     {pos_data_ovf, pos_data} <= pos_data + 1;
        //     counter <= 0;
        // end else counter <= counter +1;
        end else if (sync & !next_state) begin
            dense[9] <= dense_temp[9];
            dense[8] <= dense_temp[8];
            dense[7] <= dense_temp[7];
            dense[6] <= dense_temp[6];
            dense[5] <= dense_temp[5];
            dense[4] <= dense_temp[4];
            dense[3] <= dense_temp[3];
            dense[2] <= dense_temp[2];
            dense[1] <= dense_temp[1];
            dense[0] <= dense_temp[0];
            next_state <= 1;
        end else if (sync & next_state) begin
            {pos_data_ovf, pos_data} <= pos_data + 1;
            next_state <= 0;
        end else begin
            sync <=1;
        end
        // {n_weight[0], n_weight[1], n_weight[2], n_weight[3], n_weight[4], n_weight[5], n_weight[6], n_weight[7], n_weight[8], n_weight[9]} <= w;
        // {n_weight[9], n_weight[8], n_weight[7], n_weight[6], n_weight[5], n_weight[4], n_weight[3], n_weight[2], n_weight[1], n_weight[0]} <= w;
    end

endmodule


