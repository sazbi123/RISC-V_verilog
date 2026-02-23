`include "def_param.v"

module memory (
    input wire [31:0] addr,
    input wire [15:0] data_in,
    input wire clk,rw,oe,
    output wire [15:0] data_out
);
    reg [7:0] mem [0:`mem_size];

    // memに対するシミュレーション用記述
    // test.hexファイルのデータををRegのmemに入れる．
    initial begin
        $readmemh("test.hex",mem);
    end
    
    reg [15:0] internal_data_out;

    assign data_out=(oe==1'b0)?16'hzz:internal_data_out;

    // これはリトルエンディアンですか
    always @(negedge clk) begin
        // read mode
        if (rw==1'b0) begin
            internal_data_out<={mem[addr+32'd1],mem[addr]};
        end
        // write mode
        else begin
            {mem[addr+32'd1],mem[addr]}<=data_in;
        end
    end
endmodule