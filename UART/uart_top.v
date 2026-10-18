`default_nettype none

module uart_top #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD = 9600,
    parameter DATA_BITS = 8,
    parameter OVERSAMPLE = 16
)(
    input wire clk,
    input wire rst_n,

    // serial pins
    input wire rx,
    output wire tx,

    // transmit interface
    input wire wr_en,
    input wire [DATA_BITS - 1:0] data_in,
    output wire busy,

    //receive interface
    input wire rdy_clr,
    output wire rdy,
    output wire [DATA_BITS - 1:0] data_out
);

    // internal wires
    wire tx_en;
    wire rx_en;

    baud_gen #( 
        .CLK_FREQ (CLK_FREQ),
        .BAUD (BAUD),
        .OVERSAMPLE (OVERSAMPLE)
    ) u_baud (
        .clk (clk),
        .rst_n (rst_n),
        .tx_en (tx_en),
        .rx_en (rx_en)
    );

    uart_tx #(
        .DATA_BITS (DATA_BITS)
    ) u_tx (
        .clk (clk),
        .rst_n (rst_n),
        .tx_en (tx_en),
        .wr_en (wr_en),
        .data_in (data_in),
        .tx (tx),
        .busy (busy)
    );

    uart_rx #(
        .DATA_BITS (DATA_BITS),
        .OVERSAMPLE(OVERSAMPLE)
    ) u_rx (
        .clk (clk),
        .rst_n (rst_n),
        .rx (rx),
        .rx_en (rx_en),
        .rdy_clr (rdy_clr),
        .rdy (rdy),
        .data_out (data_out)
    );

endmodule

`default_nettype wire