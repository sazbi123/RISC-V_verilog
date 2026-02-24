// `include "RV32IM.v"
// `include "memory.v"

module top (
    input wire clk,rst_n,
    output wire [31:0] data_out
);
    wire [31:0] data_in;
    wire rw;
    wire [31:0] addr;
    wire [8:0] uart;
    wire half,byte;

    RV32IM RV32IM(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .rw(rw),
        .data_out(data_out),
        .addr(addr),
        .uart(uart),
        .half(half),
        .byte(byte)
    );

    memory memory(
        .addr(addr),
        .data_in(data_out),
        .clk(clk),
        .rw(rw),
        .oe(1'b1),
        .half(half),
        .byte(byte),
        .data_out(data_in)
    );
endmodule
