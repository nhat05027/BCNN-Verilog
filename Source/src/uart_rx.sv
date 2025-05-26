// UART Receiver Module
module uart_rx #(
    parameter CLOCK_FREQ = 100_000_000, // Clock frequency in Hz
    parameter BAUD_RATE  = 115200
)(
    input        clk,
    input        rst_n,
    input        rx,
    output logic [7:0] data,
    output logic ready
);

localparam BIT_PERIOD = CLOCK_FREQ / BAUD_RATE;

typedef enum {
    IDLE,
    START_BIT,
    DATA_BITS,
    STOP_BIT
} state_t;

state_t state;
logic [15:0] cntr;
logic [2:0]  bit_idx;
logic [7:0]  data_reg;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state    <= IDLE;
        cntr     <= '0;
        bit_idx  <= '0;
        data_reg <= '0;
        ready    <= '0;
    end else begin
        ready <= '0;
        
        case (state)
            IDLE: begin
                if (!rx) begin // Start bit detected
                    state <= START_BIT;
                    cntr  <= BIT_PERIOD/2 - 1;
                end
            end

            START_BIT: begin
                if (cntr == 0) begin
                    if (!rx) begin // Valid start bit
                        state   <= DATA_BITS;
                        cntr    <= BIT_PERIOD - 1;
                        bit_idx <= '0;
                    end else begin
                        state <= IDLE;
                    end
                end else begin
                    cntr <= cntr - 1;
                end
            end

            DATA_BITS: begin
                if (cntr == 0) begin
                    data_reg[bit_idx] <= rx;
                    cntr <= BIT_PERIOD - 1;
                    
                    if (bit_idx == 7) begin
                        state <= STOP_BIT;
                    end else begin
                        bit_idx <= bit_idx + 1;
                    end
                end else begin
                    cntr <= cntr - 1;
                end
            end

            STOP_BIT: begin
                if (cntr == 0) begin
                    state <= IDLE;
                    data  <= data_reg;
                    ready <= 1'b1;
                end else begin
                    cntr <= cntr - 1;
                end
            end
        endcase
    end
end

endmodule