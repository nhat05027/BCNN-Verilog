module maxpool (
    input wire clk,
    input wire rst,
    input wire[11:0] data_in, // Data in type Q4.8
    input wire end_data,
    output reg finish,
    output reg[11:0] out // Data out type Q4.8
);
    reg sync;
    initial sync = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finish <= 0;
            sync <=0;
            out <= 0;
        end else if (end_data) begin
            finish <= 1;
        end
        else begin
            if(sync) out <= (data_in > out) ? data_in : out;
            else sync <=1;
        end
    end
endmodule
