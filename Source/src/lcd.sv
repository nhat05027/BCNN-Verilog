module VGA_timing
(
    input                   clk,
    input                   rst_n,
    output reg [9:0] rom_addr,
    input wire [7:0] image_rom,

    output                  LCD_DE,
    output                  LCD_HSYNC,
    output                  LCD_VSYNC,

	output          [4:0]   LCD_B,
	output          [5:0]   LCD_G,
	output          [4:0]   LCD_R
);
	
    // Horizen count to Hsync, then next Horizen line.

    parameter       H_Pixel_Valid    = 16'd480; 
    parameter       H_FrontPorch     = 16'd50;
    parameter       H_BackPorch      = 16'd30;  

    parameter       PixelForHS       = H_Pixel_Valid + H_FrontPorch + H_BackPorch;

    parameter       V_Pixel_Valid    = 16'd272; 
    parameter       V_FrontPorch     = 16'd20;  
    parameter       V_BackPorch      = 16'd5;    

    parameter       PixelForVS       = V_Pixel_Valid + V_FrontPorch + V_BackPorch;

    // Horizen pixel count

    reg         [15:0]  H_PixelCount;
    reg         [15:0]  V_PixelCount;
    reg [3:0] scale_cnt;
    reg [3:0] scale_cnt1;
    reg [4:0] im_counth;
    reg [4:0] im_countv;

    always @(  posedge clk or negedge rst_n)begin
        if( !rst_n ) begin
            V_PixelCount      <=  16'b0;    
            H_PixelCount      <=  16'b0;
            rom_addr <= 10'd0;
            im_countv <= 5'd0;
            im_counth <= 5'd0;
            scale_cnt <= 4'd0;
            scale_cnt1 <= 4'd0;
        end

        else if(  H_PixelCount == PixelForHS ) begin
            V_PixelCount      <=  V_PixelCount + 1'b1;
            H_PixelCount      <=  16'b0;
            scale_cnt1 <= scale_cnt1 + 1'b1;
            im_counth <= 5'd0;
            if (scale_cnt1[3] && im_countv < 28) begin
                scale_cnt1 <= 4'd0;
                im_countv <= im_countv+1;
            end
        end
        else if(  V_PixelCount == PixelForVS ) begin
            V_PixelCount      <=  16'b0;
            H_PixelCount      <=  16'b0;
            rom_addr <= 10'd0;
            im_countv <= 5'd0;
            im_counth <= 5'd0;
            scale_cnt <= 4'd0;
            scale_cnt1 <= 4'd0;
        end
        else begin
            V_PixelCount      <=  V_PixelCount ;
            H_PixelCount      <=  H_PixelCount + 1'b1;
            if (H_PixelCount > 63) scale_cnt <= scale_cnt + 1'b1;
            if (scale_cnt[3] && (im_counth < 28)) begin
                scale_cnt <= 4'd0;
                im_counth <= im_counth +1'b1;
            end
            rom_addr <= im_countv*28+im_counth;
        end
    end

    // SYNC-DE MODE
    
    assign  LCD_HSYNC = H_PixelCount <= (PixelForHS-H_FrontPorch) ? 1'b0 : 1'b1;
    
	assign  LCD_VSYNC = V_PixelCount  <= (PixelForVS-0)  ? 1'b0 : 1'b1;

    assign  LCD_DE =    ( H_PixelCount >= H_BackPorch ) && ( H_PixelCount <= H_Pixel_Valid + H_BackPorch ) &&
                        ( V_PixelCount >= V_BackPorch ) && ( V_PixelCount <= V_Pixel_Valid + V_BackPorch ) && clk;


    // wire [7:0] image_rom; // 28*28 = 784
    // testdata_pROM  p1(
    //         .dout(image_rom), //output [7:0] dout
    //         .clk(PixelClk), //input clk
    //         .oce(1'b1), //input oce
    //         .ce(1'b1), //input ce
    //         .reset(!nRST), //input reset
    //         .ad(rom_addr) //input [13:0] ad
    //     );


    // Convert 8-bit Grayscale to RGB565
    assign  LCD_R   = image_rom[7:3];   // 5-bit red (MSBs)
    assign  LCD_G = image_rom[7:2];   // 6-bit green (MSBs)
    assign  LCD_B  = image_rom[7:3];   // 5-bit blue (MSBs)

endmodule