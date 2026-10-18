`timescale 1ns/1ps

module uart_tb;

    // parameters
    localparam CLK_FREQ = 3200;
    localparam BAUD = 100;
    localparam DATA_BITS = 8;
    localparam OVERSAMPLE = 16;
    localparam CLKS_PER_BITS = CLK_FREQ / BAUD;
    // frame = start + data + stop; allow 3x that before declaring a hang
    localparam TIMEOUT_CLKS = 3 * (DATA_BITS + 2) * CLKS_PER_BITS;

    // signals
    reg clk = 0;
    reg rst_n = 0;
    reg wr_en = 0;
    reg [DATA_BITS - 1:0] data_in = 0;
    reg rdy_clr = 0;
    wire line;
    wire busy;
    wire rdy;
    wire [DATA_BITS - 1:0] data_out;

    integer errors = 0;
    integer passed = 0;
    integer i;

    // clock
    always #5 clk = ~clk;

    // dut
    uart_top #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD (BAUD),
        .DATA_BITS (DATA_BITS),
        .OVERSAMPLE (OVERSAMPLE)
    ) dut (
        .clk (clk),
        .rst_n (rst_n),
        .rx (line),
        .tx (line),
        .wr_en (wr_en),
        .data_in (data_in),
        .busy (busy),
        .rdy_clr (rdy_clr),
        .rdy (rdy),
        .data_out (data_out)
    );

    task send_byte (input [DATA_BITS - 1:0] b);
        integer cycles;
        begin
            wait (!busy);

            // one-clock write pulse with the data valid
            @(posedge clk);
            data_in <= b;
            wr_en <= 1'b1;
            @(posedge clk);
            wr_en <= 1'b0;

            // waits for receiver to flag a byte
            cycles = 0;
            while (!rdy && cycles < TIMEOUT_CLKS) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            // check result
            if (!rdy) begin
                $display ("FAIL: timeout waiting for rdy (sent %h)", b);
                errors = errors + 1;
            end else if (data_out !== b) begin
                $display ("FAIL: sent %h, received %h", b, data_out);
                errors = errors + 1;
            end else begin
                passed = passed + 1;
            end

            // acknowledge so receiver can flag next byte
            @(posedge clk);
            rdy_clr <= 1'b1;
            @(posedge clk);
            rdy_clr <= 1'b0;
        end
    endtask

    initial begin
        $dumpfile ("uart_tb.vcd");
        $dumpvars (0, uart_tb);

        // reset for a few clocks then release
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        // line must idle high
        if (line !== 1'b1) begin
            $display ("FAIL: line not idle-high after reset");
            errors = errors + 1;
        end

        // directed tests
        send_byte (8'hA5);
        send_byte (8'h00);
        send_byte (8'hFF);
        send_byte (8'h3C);
        send_byte (8'h55);
        send_byte (8'hAA);
        send_byte (8'h01);
        send_byte (8'h80);

        // random tests
        for (i = 0; i < 20; i = i + 1)
            send_byte ($random);

        // report
        $display ("%0d bytes passed, %0d bytes failed",  passed, errors);
        if (errors == 0) $display ("PASS");
        else $display  ("FAIL");
        $finish;
    end

    initial begin
        #2_000_000;
        $display ("TIMEOUT: simulation hung");
        $finish;
    end

endmodule
