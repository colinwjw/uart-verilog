// baud rate = 9600
// clk freq = 50 MHz
// oversample = 16
// clk freq / baud rate = 5208 (transmitter counter) 13 bits
// clk freq / (baud rate x oversample) = 325 (receiver counter) 10 bits

module baud_gen #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD = 9600,
    parameter OVERSAMPLE = 16
)(
    input wire clk, 
    input wire rst_n,
    output wire tx_en, 
    output wire rx_en
);
    
    localparam TX_DIV = CLK_FREQ / BAUD;
    localparam RX_DIV = CLK_FREQ / (BAUD * OVERSAMPLE);

    reg [$clog2(TX_DIV)-1:0] tx_counter;
    reg [$clog2(RX_DIV)-1:0] rx_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_counter <= 0;
        else if (tx_counter == TX_DIV - 1)
            tx_counter <= 0;
        else
            tx_counter <= tx_counter + 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_counter <= 0;
        else if (rx_counter == RX_DIV - 1)
            rx_counter <= 0;
        else
            rx_counter <= rx_counter + 1'b1;
    end

    assign tx_en = (tx_counter == 0) ? 1'b1 : 1'b0;
    assign rx_en = (rx_counter == 0) ? 1'b1 : 1'b0; 

endmodule