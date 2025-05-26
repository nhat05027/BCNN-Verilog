module uart_controller (
    input        xtal_clk,          // Main clock
    input        rst_n,        // Active-low reset
    input        uart_rx,      // UART receive line
    output logic [3:0] cnn_out,
    output logic [6:0] seg_out,

    output			LCD_CLK,
	output			LCD_HYNC,
	output			LCD_SYNC,
	output			LCD_DEN,
	output	[4:0]	LCD_R,
	output	[5:0]	LCD_G,
	output	[4:0]	LCD_B
);

// UART Receiver Signals
logic clk;
logic       rx_ready;         // Data ready pulse
logic [7:0] rx_data;          // Received data
wire [7:0] data_in; // Captured data storage
wire [9:0] pos_data;

Gowin_rPLL rpll (
    .clkout(clk), 
    .clkin(xtal_clk)
);

// FSM States
typedef enum {
    IDLE,        // Waiting for command
    RECV_DATA,   // Receiving 784-byte data block
    DO_JOB,       // Processing 'd' command
    RESULT
} state_t;

state_t current_state, next_state;

// Data Counter
logic [9:0] data_cnt; // 10-bit counter (0-1023)

// Instantiate UART Receiver
uart_rx #(
    .CLOCK_FREQ(10_800_000), // Modify to match your clock
    .BAUD_RATE(9600)
) receiver (
    .clk(clk),
    .rst_n(rst_n),
    .rx(uart_rx),
    .data(rx_data),
    .ready(rx_ready)
);

assign LCD_CLK = clk;
wire [9:0] lcd_addr;
wire [7:0] image_rom;
VGA_timing lcd(
    .clk(clk),
    .rst_n(rst_n),
    .rom_addr(lcd_addr),
    .image_rom(image_rom),

    .LCD_DE(LCD_DEN),
    .LCD_HSYNC(LCD_HYNC),
    .LCD_VSYNC(LCD_SYNC),

	.LCD_B(LCD_B),
	.LCD_G(LCD_G),
	.LCD_R(LCD_R)
);

logic wre_ram;
initial wre_ram = 0;
reg [7:0] ram_buff;
Gowin_SDPB lcd_ram(
    .dout(image_rom), //output [7:0] dout
    .clka(clk), //input clka
    .cea(wre_ram), //input cea
    .reseta(~rst_n), //input reseta
    .clkb(clk), //input clkb
    .ceb(1'b1), //input ceb
    .resetb(~rst_n), //input resetb
    .oce(1'b1), //input oce
    .ada(data_cnt), //input [9:0] ada
    .din(ram_buff), //input [7:0] din
    .adb(lcd_addr) //input [9:0] adb
);

Gowin_SDPB cnn_ram(
    .dout(data_in), //output [7:0] dout
    .clka(clk), //input clka
    .cea(wre_ram), //input cea
    .reseta(~rst_n), //input reseta
    .clkb(clk), //input clkb
    .ceb(1'b1), //input ceb
    .resetb(~rst_n), //input resetb
    .oce(1'b1), //input oce
    .ada(data_cnt), //input [9:0] ada
    .din(ram_buff), //input [7:0] din
    .adb(pos_data) //input [9:0] adb
);

// Gowin_DPB lcd_ram(
//         .douta(data_in), //output [7:0] douta
//         .doutb(image_rom), //output [7:0] doutb
//         .clka(clk), //input clka
//         .ocea(1'b1), //input ocea
//         .cea(1'b1), //input cea
//         .reseta(~rst_n), //input reseta
//         .wrea(wre_ram), //input wrea
//         .clkb(clk), //input clkb
//         .oceb(1'b1), //input oceb
//         .ceb(1'b1), //input ceb
//         .resetb(~rst_n), //input resetb
//         .wreb(1'b0), //input wreb
//         .ada(data_cnt), //input [9:0] ada
//         .dina(ram_buff), //input [7:0] dina
//         .adb(lcd_addr), //input [9:0] adb
//         .dinb() //input [7:0] dinb
//     );

initial cnn_out = 0;
logic rst_cnn, en_cnn, cnn_fn;
wire [3:0] temp_cnn;
cnn dut (
    .clk(clk),
    .rst(rst_cnn),
    .en(en_cnn),
    .data_in(data_in), // Data in type 8bit
    .pos_data(pos_data),
    .finish(cnn_fn),
    .cnn_out(temp_cnn) // output
);

reg [3:0] bcd_in;
bcd_to_7seg b7s (
    .bcd_in(bcd_in),
    .seg_out(seg_out)
);

// State Machine
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        data_cnt      <= '0;
        rst_cnn <= 1;
        wre_ram <= 0;
        ram_buff <= 0;
    end else begin
        current_state <= next_state;
        en_cnn <= 1;

        case (current_state)
            IDLE: begin
                data_cnt <= '0;
                wre_ram <= 0;
            end

            RECV_DATA: begin
                rst_cnn <= 1;
                if (rx_ready) begin
                    data_cnt <= data_cnt + 1;
                    wre_ram <= 1;
                    ram_buff <= rx_data;
                end
                else wre_ram <= 0;
            end

            DO_JOB: begin
                wre_ram <= 0;
                if (!cnn_fn) begin
                    rst_cnn <= 0;
                end
            end
            RESULT: begin
                cnn_out <= ~temp_cnn;
                bcd_in <= temp_cnn;
            end
        endcase
    end
end

// Next State Logic
always_comb begin
    next_state = current_state;
    
    case (current_state)
        IDLE: begin
            if (rx_ready) begin
                if (rx_data == "g") next_state = RECV_DATA;
                else if (rx_data == "d") next_state = DO_JOB;
            end
        end

        RECV_DATA: begin
            if (data_cnt == 784) next_state = IDLE;
        end

        DO_JOB: begin
            if (cnn_fn) begin
                next_state = RESULT;
            end
        end

        RESULT: next_state = IDLE;

        default: next_state = IDLE;
    endcase
end

endmodule