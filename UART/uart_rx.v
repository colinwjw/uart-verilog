module uart_rx #(
    parameter DATA_BITS = 8,
    parameter OVERSAMPLE = 16
)(
    input wire clk,
    input wire rst_n,
    input wire rdy_clr,
    input wire rx_en,
    input wire rx,
    output reg rdy,
    output reg [DATA_BITS - 1:0] data_out
);
    
    localparam START = 2'b00;
    localparam DATA = 2'b01;
    localparam STOP = 2'b10;

    localparam LAST = OVERSAMPLE - 1;
    localparam MID = OVERSAMPLE / 2;

    reg [1:0] state;
    reg [$clog2(OVERSAMPLE) - 1:0] sample;
    reg [$clog2(DATA_BITS) - 1:0] index;
    reg [DATA_BITS - 1:0] temp_reg;
    reg rx_sync1, rx_sync2;

    // two-flop synchronisers for the asynchronous rx line
    always @(posedge clk or negedge  rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= START;
            sample <= 0;
            index <= 0;
            temp_reg <= 0;
            data_out <= 0;
            rdy <= 1'b0;
        end else begin
            if (rdy_clr)
                rdy <= 1'b0;

            if (rx_en) begin
                case (state)
                    START: begin
                        if (sample == 0) begin
                            if (!rx_sync2)
                                sample <= 1;
                        end else if (sample == LAST) begin
                            state <= DATA;
                            sample <= 0;
                            index <= 0;
                        end else begin
                            sample <= sample + 1'b1;
                        end
                    end

                    DATA: begin
                        if (sample == MID)
                            temp_reg[index] <= rx_sync2;
                        if (sample == LAST) begin
                            sample <= 0;
                            if (index == DATA_BITS - 1)
                                state <= STOP;
                            else
                                index <= index + 1'b1;
                        end else begin
                            sample <= sample + 1'b1;
                        end
                    end

                    STOP: begin
                        if (sample == MID) begin
                            state <= START;
                            sample <= 0;
                            data_out <= temp_reg;
                            rdy <= 1'b1;
                        end else begin
                            sample <= sample + 1'b1;
                        end
                    end

                    default: state <= START;
                endcase
            end
        end
    end
endmodule