`include "def_param.vh"

module memory (
    input wire [31:0] addr,
    input wire [31:0] data_in,
    input wire clk,rw,oe,half,byte,
    output wire [31:0] data_out
);
    reg [7:0] mem [0:`mem_size];

    // iverilog&vivado用記述
    // memに対するシミュレーション用記述
    // test.hexファイルのデータををRegのmemに入れる．
    initial begin
        $readmemh("test.hex",mem);
    end
    
    reg [31:0] internal_data_out;

    assign data_out=(oe==1'b0)?32'hzzzzzzzz:internal_data_out;

    // これはリトルエンディアンですか
    always @(negedge clk) begin
        // read mode
        if (rw==1'b0) begin
            case ({byte,half})
                // 32bitのデータ
                2'b00: begin
                    internal_data_out<={mem[addr+32'd3],mem[addr+32'd2],mem[addr+32'd1],mem[addr]};
                end
                // halfが1なので16bitのデータ
                2'b01: begin
                    internal_data_out<={16'd0,mem[addr+32'd1],mem[addr]};
                end
                // byteが1なので8bitのデータ
                2'b10: begin
                    internal_data_out<={24'd0,mem[addr]};
                end
                // どちらも1はおかしいので何もしない
                default: ;
            endcase
        end
        // write mode
        else begin
            case ({byte,half})
                // 32bitのデータ
                2'b00: begin
                    {mem[addr+32'd3],mem[addr+32'd2],mem[addr+32'd1],mem[addr]}<=data_in;
                end
                // halfが1なので16bitのデータ
                2'b01: begin
                    {mem[addr+32'd1],mem[addr]}<=data_in[15:0];
                end
                // byteが1なので8bitのデータ
                2'b10: begin
                    mem[addr]<=data_in[7:0];
                end
                // どちらも1はおかしいので何もしない
                default: ;
            endcase
        end
    end
endmodule