`include "def_param.vh"

// regfile[rs1]をalu_data_1にしてCOREの方でこの線にregfile[rs1]のデータを流してもらうようにする
module alu (
    input wire [31:0] alu_data_in,alu_data_1,
    input wire [3:0] alu_sel,
    output wire [63:0] result
);
    reg [63:0] internal_result;

    assign result=internal_result;

    always @(*) begin
        case (alu_sel)
            `equal: begin
                internal_result={32'd0,31'd0,(alu_data_1==alu_data_in)};
            end
            `signed_comp: begin
                internal_result={32'd0,31'd0,($signed(alu_data_1)<$signed(alu_data_in))};
            end
            `unsigned_comp: begin
                internal_result={32'd0,31'd0,($unsigned(alu_data_1)<$unsigned(alu_data_in))};
            end
            `add_alu: begin
                internal_result=alu_data_1+alu_data_in;
            end
            `xor_alu: begin
                internal_result=alu_data_1^alu_data_in;
            end
            `or_alu: begin
                internal_result=alu_data_1|alu_data_in;
            end
            `and_alu: begin
                internal_result=alu_data_1&alu_data_in;
            end
            `left_shift_alu: begin
                internal_result=alu_data_1<<alu_data_in;
            end
            // 算術右シフトをsignedで明示したのでこちらはunsignedで一応明示しておく
            `right_logical_shift_alu: begin
                internal_result=$unsigned(alu_data_1)>>alu_data_in;
            end
            // 算術右シフトができていない
            // ↑signedにしたら動いていて良さげ
            `right_arithmetic_shift_alu: begin
                internal_result=$signed(alu_data_1)>>>alu_data_in;
            end
            `mul_ss_alu: begin
                internal_result=$signed(alu_data_1)*$signed(alu_data_in);
            end
            `mul_su_alu: begin
                internal_result=$signed({{32{alu_data_1[31]}},alu_data_1})*$unsigned({32'd0,alu_data_in});
            end
            `mul_uu_alu: begin
                internal_result=$unsigned(alu_data_1)*$unsigned(alu_data_in);
            end
            `signed_div_rem_alu: begin
                // 上位32bitは商，下位32bitは余り
                internal_result[63:32]=(alu_data_in==32'd0)?32'hffffffff:(
                              ((alu_data_1==32'h80000000)&&(alu_data_in==32'hffffffff))?32'h80000000:$signed(alu_data_1)/$signed(alu_data_in));
                internal_result[31:0]=(alu_data_in==32'd0)?alu_data_1:(
                             ((alu_data_1==32'h80000000)&&(alu_data_in==32'hffffffff))?32'd0:$signed(alu_data_1)%$signed(alu_data_in));
            end
            `unsigned_div_rem_alu: begin
                // 上位32bitは商，下位32bitは余り
                internal_result[63:32]=(alu_data_in==32'd0)?32'hffffffff:$unsigned(alu_data_1)/$unsigned(alu_data_in);
                internal_result[31:0]=(alu_data_in==32'd0)?alu_data_1:$unsigned(alu_data_1)%$unsigned(alu_data_in);
            end
            default: begin
                internal_result=64'd0;
            end
        endcase
    end
endmodule