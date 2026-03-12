`include "def_param.vh"

// コントローラから制御するBRAM
// addrはコントローラからのアドレスdata_in，data_outも同様
module sram (
    input wire [31:0] addr,
    input wire [7:0] data_in,
    input wire clk,rw,
    output wire [7:0] data_out
);
    (* ram_style = "block" *) reg [7:0] mem [0:((`mem_size+1)/4)-1];
    reg [7:0] internal_data_out;

    assign data_out=internal_data_out;

    always @(negedge clk) begin
        if (rw==`read) begin
            internal_data_out<=mem[addr];
        end
        else begin
            mem[addr]<=data_in;
        end
    end
endmodule