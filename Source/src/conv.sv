module SIPO19 (
    input wire clk,              // Clock input
    input wire reset,            // Reset input
    input wire serial_in,        // Serial input data
    input wire shift,            // Shift control input
    output reg [8:0] parallel_out // Parallel output data
);

    reg [8:0] shift_register;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_register <= 9'b0;
            parallel_out <= 9'b0;
        end else if (shift) begin
            shift_register <= {shift_register[7:0], serial_in};
            parallel_out <= shift_register;
        end
    end
endmodule

// single conv cell
module conv (
    input wire clk,
    input wire rst,
    input wire en_conv,
    input wire[11:0] data_in, // Data in type Q4.8
    input wire[8:0] w,
    output reg finish,
    output reg[15:0] out // Data out type Q8.8
);
    reg [3:0] counter;
    // wire [8:0] temp_val;
    // assign temp_val = {data, 1'b0} - 255; // Normalize 2*data-255
    wire [11:0] n_data[8:0];
    wire [11:0] d_w [8:0]; 
    wire read;

    reg sync;
    initial begin
        counter = 0;
        sync = 0;
    end
    assign read = (counter>9) ? 0 : 1;

    genvar i;
    generate
        for(i=0;i<12;i=i+1)
        begin
            SIPO19 F (
                .clk(clk),
                .reset(rst),
                .serial_in(data_in[i]),
                .shift(read&sync),
                .parallel_out({n_data[8][i],
                                n_data[7][i],
                                n_data[6][i],
                                n_data[5][i],
                                n_data[4][i],
                                n_data[3][i],
                                n_data[2][i],
                                n_data[1][i],
                                n_data[0][i]})
            );
            if(i<9) assign d_w[i] = (n_data[i]^{12{w[i]}})+{11'b0,w[i]};
        end
    endgenerate

    assign out = {{4{d_w[0][11]}},d_w[0]}
                + {{4{d_w[1][11]}},d_w[1]}
                + {{4{d_w[2][11]}},d_w[2]}
                + {{4{d_w[3][11]}},d_w[3]}
                + {{4{d_w[4][11]}},d_w[4]}
                + {{4{d_w[5][11]}},d_w[5]}
                + {{4{d_w[6][11]}},d_w[6]}
                + {{4{d_w[7][11]}},d_w[7]}
                + {{4{d_w[8][11]}},d_w[8]};


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync = 0;
            counter <= 4'b0;
            finish <= 0;
        end else if (!read) begin
            finish <= 1;
        end else if(en_conv&sync) counter <= counter +1;
        else sync <=1;
    end

endmodule