`include "RV32IM.v"
`include "memory.v"

module RV32IM_tb ();
    reg clk,rst_n;
    wire [31:0] data_in;
    wire rw;
    wire [31:0] data_out;
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

    always begin
        clk=1'b0;
        #1;
        clk=1'b1;
        #1;
    end

    initial begin
        rst_n=1'b1;
        #10;
        rst_n=1'b0;
        #10;
        rst_n=1'b1;
        #100;
        $finish;
    end

    integer i;

    initial begin
        $dumpfile("RV32IM.vcd");
        $dumpvars(0, RV32IM_tb);
        // メモリ配列を全部ダンプ
        for (i = 0; i < 3; i = i + 1) begin
            $dumpvars(0, RV32IM.regfile[i]);
        end
    end
endmodule
