`include "sram.v"

module sram_tb ();
    reg [31:0] addr;
    reg [7:0] data_in;
    reg clk,rw;
    wire [7:0] data_out;

    sram sram(
        .addr(addr),
        .data_in(data_in),
        .clk(clk),
        .rw(rw),
        .data_out(data_out)
    );

    always begin
        clk=1'b0;
        #1;
        clk=1'b1;
        #1;
    end

    initial begin
        $readmemh("test.hex",sram.mem);
    end

    initial begin
        #2;
        rw=`read;
        addr=32'd0;
        #9;
        addr=addr+32'd1;
        #9;
        addr=addr+32'd1;
        #9;
        addr=addr+32'd1;
        #9;
        addr=addr+32'd1;
        #9;
        addr=addr+32'd1;
        #9;
        $finish;
    end

    initial begin
        $dumpfile("sram.vcd");
        $dumpvars(0, sram_tb);
    end
endmodule
