// tb.v — cocotb testbench wrapper (TinyTapeout standard shape).
// Instantiates tt_um_asicirific with the fixed pin interface and dumps a VCD.
`default_nettype none
`timescale 1ns/1ps

module tb ();
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
    end

    reg        clk;
    reg        rst_n;
    reg        ena;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    reg  [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    tt_um_asicirific user_project (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );
endmodule
