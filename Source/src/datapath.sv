`define CROM "../mem/crom.mem"
`define FCROM "../mem/fcrom.mem"
`define THROM "../mem/throm.mem"
`define PHROM "../mem/phrom.mem"

module datapath (
    input wire clk,
    input wire rst,

    input wire [7:0] new_data,

    input wire rst_conv,
    input wire en_conv,
    output wire finish_conv,

    input wire [7:0] addr_crom,

    input wire rst_buff_bn,
    input wire wre_buff_bn,

    input wire rst_bn, 
    input wire ready_bn, 
    input wire [5:0] bn_addr,
    output wire finish_bn,

    input wire rst_mp,
    input wire end_mp, 
    output wire finish_mp,

    input wire wre_ram,
    input wire [13:0] addr_ram,

    input wire [7:0] fc_addr,
    input wire rst_fc,
    output wire [3:0] pos_fc,
    // output wire ld_w_fc,
    output wire finish_fc,
    output wire [3:0] cnn_out,

    input wire [1:0] dat_sel
);
    reg [8:0] weight_conv [243:0];
    initial $readmemb(`CROM, weight_conv);

    reg [11:0] out_ram;

    wire [15:0] out_conv;
    conv C (
        .clk(clk),
        .rst(rst_conv),
        .en_conv(en_conv),
        .data_in(out_ram), // Data in type Q4.8
        .w(weight_conv[addr_crom]),
        .finish(finish_conv),
        .out(out_conv) // Data out type Q8.8
    );

    reg [15:0] data_in_bn; // Buffer reg between conv and batchnorm *Need reset with conv reset
    initial data_in_bn =0;
    always @(posedge clk or posedge rst_buff_bn) begin
        if (rst_buff_bn) begin
            data_in_bn <= 0;
        end else begin
            if (wre_buff_bn) data_in_bn <= data_in_bn + out_conv;
        end
    end

    reg [11:0] theta_rom[39:0];
    reg [11:0] phi_rom[39:0];
    initial $readmemb(`THROM, theta_rom);
    initial $readmemb(`PHROM, phi_rom);

    wire [11:0] out_bn;
    bnorm B (
        .clk(clk),
        .rst(rst_bn),
        .ready(ready_bn),
        .data_in(data_in_bn), // Data in type Q8.8
        .theta(theta_rom[bn_addr]), // theta = gamma/sqrt(variance)
        .phi(phi_rom[bn_addr]), // phi = -mean*gamma/sqrt(variance) + beta
        .finish(finish_bn),
        .out(out_bn) // Data out type Q4.8
    );

    wire [11:0] out_mp;
    maxpool M (
        .clk(clk),
        .rst(rst_mp),
        .data_in(out_ram), // Data in type Q4.8
        .end_data(end_mp),
        .finish(finish_mp),
        .out(out_mp) // Data out type Q4.8
    );

    
    reg [11:0] data_in_ram;
    bsram R (
        .clk(clk),
        .rst(rst),
        .ce(1'b1), 
        .wre(wre_ram),
        .addr(addr_ram),
        .data_in(data_in_ram),
        .data_out(out_ram)
        );
    wire [11:0] temp_new_data;
    assign temp_new_data = {3'b0,new_data,1'b0}+12'hF01;
    assign data_in_ram = (dat_sel[1]) ? out_mp : (dat_sel[0]) ? out_bn : temp_new_data; // 1X:Maxpool, 01:Batchnorm, 00:NewData

    reg [119:0] fc_rom[15:0];
    initial begin
        $readmemb(`FCROM, fc_rom);
    end

    fullyconnect FC(
        .clk(clk),
        .rst(rst_fc),
        .data_in(out_ram), // Data in type Q4.8
        .w(fc_rom[fc_addr]), // Weight in type Q4.8
        .pos_data(pos_fc),
        // .load_weight(ld_w_fc),
        .cnn_out(cnn_out), // Data out type Q4.8
        .finish(finish_fc)
    );
    
    initial begin
    end
    //
    always @(posedge clk or posedge rst) begin
        if (rst) begin
        end else begin
        end
    end

endmodule
