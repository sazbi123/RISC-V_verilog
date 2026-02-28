`include "core.v"
`include "decoder.v"
`include "alu.v"

module RV32IM (
    input wire [31:0] data_in,
    input wire clk,rst_n,
    output wire [31:0] data_out,addr,
    output wire rw,half,byte
);
    wire [63:0] result;
    wire [31:0] alu_data_in,alu_data_1,opcode;
    wire [5:0] next_state;
    wire [3:0] alu_sel;
    wire [2:0] alu_data_in_sel;

    core core(
        .result(result),
        .data_in(data_in),
        .next_state(next_state),
        .alu_data_in_sel(alu_data_in_sel),
        .rst_n(rst_n),
        .clk(clk),
        .data_out(data_out),
        .alu_data_in(alu_data_in),
        .addr(addr),
        .alu_data_1(alu_data_1),
        .rw(rw),
        .half(half),
        .byte(byte),
        .opcode(opcode)
    );

    decoder decoder(
        .opcode(opcode),
        .next_state(next_state),
        .alu_sel(alu_sel),
        .alu_data_in_sel(alu_data_in_sel)
    );

    alu alu(
        .alu_data_in(alu_data_in),
        .alu_data_1(alu_data_1),
        .alu_sel(alu_sel),
        .result(result)
    );
endmodule