`include "memory.v"

module memory_tb ();
    reg [31:0] addr;
    reg [31:0] data_in;
    reg clk,rw,oe,half,byte;
    wire [31:0] data_out;

    memory memory(
        .addr(),
        .data_in(),
        .clk(),
        .rw(),
        .oe(),
        .half(),
        .byte(),
        .data_out()
    );

    always begin
        clk=1'b0;
        #1;
        clk=1'b1;
        #1;
    end

    initial begin
        $finish;
    end

    initial begin
        $dumpfile("memory.vcd");
        $dumpvars(0, memory_tb);
    end
endmodule
