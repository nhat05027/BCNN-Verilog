// Batch normalize yi = gamma*(xi-mean)/sqrt(variance) + beta
module bnorm (
    input wire clk,
    input wire rst,
    input wire ready,
    input wire[15:0] data_in, // Data in type Q8.8
    input wire[11:0] theta, // theta = gamma/sqrt(variance)
    input wire[11:0] phi, // phi = -mean*gamma/sqrt(variance) + beta
    output reg finish,
    output reg[11:0] out // Data out type Q4.8
);

    wire [27:0] mul_res;
    wire [11:0] temp_out;

    assign mul_res = {{12{data_in[15]}}, data_in}*{{16'b0}, theta};
    assign temp_out = mul_res[19:8]+phi;
    assign out = (temp_out[11]) ? 12'd0 : temp_out[11:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finish <= 0;
        end else if (ready) begin
            finish <= 1;
        end
    end

endmodule