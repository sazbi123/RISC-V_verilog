`include "def_param.vh"

// BRAM推論されない
module memory (
    input wire [31:0] addr,
    input wire [31:0] data_in,
    input wire clk,rw,oe,half,byte,
    output wire [31:0] data_out
);
    reg [31:0] internal_data_out;

    assign data_out=(oe==1'b0)?32'hzzzzzzzz:internal_data_out;

    // 基本はこれ
    // data_in
    // 31           0
    // fa |da |ba |99 
    //  3   2   1   0

    sram sram_0(
        .addr(),
        .data_in(),
        .clk(),
        .rw(rw),
        .data_out()
    );

    sram sram_1(
        .addr(),
        .data_in(),
        .clk(),
        .rw(rw),
        .data_out()
    );

    sram sram_2(
        .addr(),
        .data_in(),
        .clk(),
        .rw(rw),
        .data_out()
    );

    sram sram_3(
        .addr(),
        .data_in(),
        .clk(),
        .rw(rw),
        .data_out()
    );

    always @(*) begin
        
    end
endmodule