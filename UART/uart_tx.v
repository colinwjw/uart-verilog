module uart_tx #(
    parameter DATA_BITS = 8
)(
    input wire clk, 
    input wire wr_en, 
    input wire tx_en, 
    input wire rst_n,
    input wire [DATA_BITS - 1:0] data_in,
    output reg tx,
    output wire busy
);

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    reg [DATA_BITS - 1:0] data_reg;
    reg [$clog2(DATA_BITS) - 1:0] index;
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx <= 1'b1;
            data_reg <= 0;
            index <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (wr_en) begin
                        state <= START;
                        data_reg <= data_in;
                        index <= 0;
                    end
                    else begin
                        state <= IDLE;
                    end
                end

                START: begin
                    if (tx_en) begin
                        tx <= 1'b0;
                        state <= DATA;
                    end
                    else begin
                        state <= START;
                    end
                end

                DATA: begin
                    if (tx_en) begin
                        tx  <= data_reg[index];
                        if (index == DATA_BITS - 1)
                            state <= STOP;
                        else
                            index <= index + 1'b1;
                    end
                end

                STOP: begin
                    if (tx_en) begin
                        tx <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: begin
                    tx <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    assign busy = (state != IDLE);

endmodule