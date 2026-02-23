`include "def_param.v"

// uartなし（現状）
// CPUからみてinかoutかで命名
// RV32IMって割り込みあるんですかね
// 2クロックでフェッチデータが確定
// https://risc-v-cpu-visualizer.vercel.app/assemblerでデバッグ中
// https://risc-v-cpu-visualizer.vercel.app/converterこっちのほうがいいかもしない
module RV32IM (
    input wire clk,rst_n,
    input wire [15:0] data_in,
    output wire rw,
    output wire [15:0] data_out,
    output wire [8:0] uart,
    output wire [31:0] addr
);
    reg [31:0] regfile [0:31];
    reg [31:0] pc,opcode,result,rw_addr;
    // 暫定のビット幅
    reg [7:0] state;
    // 暫定のビット幅
    reg [7:0] next_state;
    // 暫定のビット幅
    reg [7:0] addr_sel;
    // 暫定のビット幅
    reg [7:0] alu_sel;
    reg internal_rw;
    reg wait_count;

    assign rw=internal_rw;
    assign addr=(addr_sel==8'd0)?pc:(
                (addr_sel==8'd1)?rw_addr:32'd0);

    always @(posedge clk) begin
        if (rst_n==1'b0) begin
            pc<=32'hfffffffe;
            rw_addr<=32'd0;
            opcode<=32'd0;
            state<=`fetch1;
            internal_rw=`read;
            wait_count<=1'b0;
            addr_sel<=8'd0;
            // x0は常に0
            regfile[0]<=32'd0;
        end
        else begin
            case (state)
                `fetch1: begin
                    if (wait_count==1'b0) begin
                        addr_sel<=8'd0;
                        pc<=pc+32'd2;
                        internal_rw<=`read;
                        wait_count<=1'b1;
                    end
                    else begin
                        opcode<={16'd0,data_in};
                        wait_count<=1'b0;
                        state<=`fetch2;
                    end
                end
                `fetch2: begin
                    if (wait_count==1'b0) begin
                        addr_sel<=8'd0;
                        pc<=pc+32'd2;
                        internal_rw<=`read;
                        wait_count<=1'b1;
                    end
                    else begin
                        opcode<={data_in,opcode[15:0]};
                        wait_count<=1'b0;
                        state<=`decode;
                    end
                end
                `decode: begin
                    state<=next_state;
                end
                `LUI: begin
                    // x0は常に0
                    if (opcode[11:7]==5'd0) begin
                        regfile[opcode[11:7]]<=32'd0;
                        state<=`fetch1;
                    end
                    else begin
                        regfile[opcode[11:7]]<={opcode[31:12],12'd0};
                        state<=`fetch1;
                    end
                end
                `AUIPC: begin
                    // x0は常に0
                    if (opcode[11:7]==5'd0) begin
                        regfile[opcode[11:7]]<=32'd0;
                        state<=`fetch1;
                    end
                    else begin
                        // AUIPC命令がある先頭アドレス
                        // フェッチで2回+2しているがfetch1のインクリメントした値が命令の先頭バイトになるため，実質+2しかしていない．そのため先頭アドレスの算出のために引く量は-2となる．
                        regfile[opcode[11:7]]<={opcode[31:12],12'd0}+pc-32'd2;
                        state<=`fetch1;
                    end
                end
                `JAL: begin
                    // x0は常に0
                    if (opcode[11:7]==5'd0) begin
                        regfile[opcode[11:7]]<=32'd0;
                        // fetch1で+2するため調整
                        // 命令の先頭アドレス+オフセットをしたい
                        // pc-2(命令の先頭アドレス)+オフセット-2(Fetchで正しい値にするための調整) => pc+offset-4
                        pc<=pc+{(opcode[31])?11'h7ff:11'd0,opcode[31],opcode[19:12],opcode[20],opcode[30:21],1'b0}-32'd4;
                        state<=`fetch1;
                    end
                    else begin
                        // JAL命令の先頭アドレス+4
                        // AUIPCと同様に-2すれば今の命令の先頭アドレスを取得でき，そこから+4するのでまとめると+2すればいい
                        regfile[opcode[11:7]]<=pc+32'd2;
                        // fetch1で+2するため調整
                        // 命令の先頭アドレス+オフセットをしたい
                        // pc-2(命令の先頭アドレス)+オフセット-2(Fetchで正しい値にするための調整) => pc+offset-4
                        pc<=pc+{(opcode[31])?11'h7ff:11'd0,opcode[31],opcode[19:12],opcode[20],opcode[30:21],1'b0}-32'd4;
                        state<=`fetch1;
                    end
                end
                // pc+4をRdに入れる
                // 符号拡張即値をrs1と足してビット0を0にしたものが次のアドレスになる
                `JALR: begin
                    // x0は常に0
                    if (opcode[11:7]==5'd0) begin
                        regfile[opcode[11:7]]<=32'd0;
                        // rs1+immから−2（fetch1のつじつま合わせ）
                        // bit[0]を0にするための&32'hfffffffe
                        pc<=(({(opcode[31])?20'hfffff:20'd0,opcode[31:20]}+regfile[opcode[19:15]])&32'hfffffffe)-32'd2;
                        state<=`fetch1;
                    end
                    else begin
                        // JALR命令の先頭アドレス+4
                        // AUIPCと同様に-2すれば今の命令の先頭アドレスを取得でき，そこから+4するのでまとめると+2すればいい
                        regfile[opcode[11:7]]<=pc+32'd2;
                        // rs1+immから−2（fetch1のつじつま合わせ）
                        // bit[0]を0にするための&32'hfffffffe
                        pc<=(({(opcode[31])?20'hfffff:20'd0,opcode[31:20]}+regfile[opcode[19:15]])&32'hfffffffe)-32'd2;
                        state<=`fetch1;
                    end
                end
                `BEQ: begin
                    // if (regfile[opcode[24:20]]==regfile[opcode[19:15]]) begin
                    if (result==32'd0) begin
                        // BEQ命令の先頭ドレスなので−2
                        // fetch1の調整としてさらに−2なので合計−4する必要がある
                        pc<=pc+{(opcode[31])?19'h7ffff:19'd0,opcode[31],opcode[7],opcode[30:25],opcode[11:8],1'b0}-32'd4;
                        state<=`fetch1;
                    end
                    else begin
                        pc<=pc;
                        state<=`fetch1;
                    end
                end
                `BNE: begin
                    // if (regfile[opcode[24:20]]!=regfile[opcode[19:15]]) begin
                    if (result!=32'd0) begin
                        // BNE命令の先頭ドレスなので−2
                        // fetch1の調整としてさらに−2なので合計−4する必要がある
                        pc<=pc+{(opcode[31])?19'h7ffff:19'd0,opcode[31],opcode[7],opcode[30:25],opcode[11:8],1'b0}-32'd4;
                        state<=`fetch1;
                    end
                    else begin
                        pc<=pc;
                        state<=`fetch1;
                    end
                end
                `BLT: begin
                    if (result[0]==1'b1) begin
                        // BLT命令の先頭ドレスなので−2
                        // fetch1の調整としてさらに−2なので合計−4する必要がある
                        pc<=pc+{(opcode[31])?19'h7ffff:19'd0,opcode[31],opcode[7],opcode[30:25],opcode[11:8],1'b0}-32'd4;
                        state<=`fetch1;
                    end
                    else begin
                        pc<=pc;
                        state<=`fetch1;
                    end
                end
                `BGE: begin
                    if (result[0]==1'b0) begin
                        // BGE命令の先頭ドレスなので−2
                        // fetch1の調整としてさらに−2なので合計−4する必要がある
                        pc<=pc+{(opcode[31])?19'h7ffff:19'd0,opcode[31],opcode[7],opcode[30:25],opcode[11:8],1'b0}-32'd4;
                        state<=`fetch1;
                    end
                    else begin
                        pc<=pc;
                        state<=`fetch1;
                    end
                end
                `BLTU: begin
                    if (result[0]==1'b1) begin
                        // BLTU命令の先頭ドレスなので−2
                        // fetch1の調整としてさらに−2なので合計−4する必要がある
                        pc<=pc+{(opcode[31])?19'h7ffff:19'd0,opcode[31],opcode[7],opcode[30:25],opcode[11:8],1'b0}-32'd4;
                        state<=`fetch1;
                    end
                    else begin
                        pc<=pc;
                        state<=`fetch1;
                    end
                end
                `BGEU: begin
                    if (result[0]==1'b0) begin
                        // BGEU命令の先頭ドレスなので−2
                        // fetch1の調整としてさらに−2なので合計−4する必要がある
                        pc<=pc+{(opcode[31])?19'h7ffff:19'd0,opcode[31],opcode[7],opcode[30:25],opcode[11:8],1'b0}-32'd4;
                        state<=`fetch1;
                    end
                    else begin
                        pc<=pc;
                        state<=`fetch1;
                    end
                end
                `LB: begin
                    if (wait_count==1'b0) begin
                        addr_sel<=8'd1;
                        rw_addr<=regfile[opcode[19:15]]+{(opcode[31])?20'hfffff:20'd0,opcode[31:20]};
                        internal_rw<=`read;
                        wait_count<=1'b1;
                    end
                    else begin
                        if (opcode[11:7]==5'd0) begin
                            regfile[opcode[11:7]]<=32'd0;
                            wait_count<=1'b0;
                            state<=`fetch1;
                        end
                        else begin
                            regfile[opcode[11:7]]<={(data_in[7])?24'hffffff:24'd0,data_in[7:0]};
                            wait_count<=1'b0;
                            state<=`fetch1;
                        end
                    end
                end
                `LH: begin
                    if (wait_count==1'b0) begin
                        addr_sel<=8'd1;
                        rw_addr<=regfile[opcode[19:15]]+{(opcode[31])?20'hfffff:20'd0,opcode[31:20]};
                        internal_rw<=`read;
                        wait_count<=1'b1;
                    end
                    else begin
                        if (opcode[11:7]==5'd0) begin
                            regfile[opcode[11:7]]<=32'd0;
                            wait_count<=1'b0;
                            state<=`fetch1;
                        end
                        else begin
                            regfile[opcode[11:7]]<={(data_in[15])?16'hffff:16'd0,data_in};
                            wait_count<=1'b0;
                            state<=`fetch1;
                        end
                    end
                end
                `LW: begin
                    if (wait_count==1'b0) begin
                        addr_sel<=8'd1;
                        rw_addr<=regfile[opcode[19:15]]+{(opcode[31])?20'hfffff:20'd0,opcode[31:20]};
                        internal_rw<=`read;
                        wait_count<=1'b1;
                    end
                    else begin
                        if (opcode[11:7]==5'd0) begin
                            regfile[opcode[11:7]]<=32'd0;
                            wait_count<=1'b0;
                            state<=`LW2;
                        end
                        else begin
                            regfile[opcode[11:7]]<={16'd0,data_in};
                            wait_count<=1'b0;
                            state<=`LW2;
                        end
                    end
                end
                `LW2: begin
                    if (wait_count==1'b0) begin
                        addr_sel<=8'd1;
                        rw_addr<=rw_addr+32'd2;
                        internal_rw<=`read;
                        wait_count<=1'b1;
                    end
                    else begin
                        if (opcode[11:7]==5'd0) begin
                            regfile[opcode[11:7]]<=32'd0;
                            wait_count<=1'b0;
                            state<=`fetch1;
                        end
                        else begin
                            regfile[opcode[11:7]][31:16]<=data_in;
                            wait_count<=1'b0;
                            state<=`fetch1;
                        end
                    end
                end
                default: ;
            endcase
        end
    end

    // 今は比較のみだがいずれALUみたいな動作をしたい
    always @(*) begin
        case (alu_sel)
            `equal: begin
                // rs2は2の補数で表現し減算
                result=regfile[opcode[19:15]]+(~regfile[opcode[24:20]])+32'd1;
            end
            `signed_comp: begin
                result={31'd0,($signed(regfile[opcode[19:15]])<$signed(regfile[opcode[24:20]]))};
            end
            `unsigned_comp: begin
                result={31'd0,($unsigned(regfile[opcode[19:15]])<$unsigned(regfile[opcode[24:20]]))};
            end
            default: result=32'd0;
        endcase
    end

    // 何命令かを確定させ次のstateを決定するモジュール
    always @(*) begin
        // 全部で48命令ある
        case (opcode[6:0])
            // 5個
            7'b0000011: begin
                case (opcode[14:12])
                    // LHU
                    3'b101: begin
                        next_state=`LHU;
                    end
                    // LBU
                    3'b100: begin
                        next_state=`LBU;
                    end
                    // LB
                    3'b000: begin
                        next_state=`LB;
                    end
                    // LH
                    3'b001: begin
                        next_state=`LH;
                    end
                    // LW
                    3'b010: begin
                        next_state=`LW;
                    end
                    default: next_state=8'd0;
                endcase
            end
            // 18個
            7'b0110011: begin
                case (opcode[31:25])
                    7'b0000001: begin
                        case (opcode[14:12])
                            // REM
                            3'b110: begin
                                next_state=`REM;
                            end
                            // REMU
                            3'b111: begin
                                next_state=`REMU;
                            end
                            // DIV
                            3'b100: begin
                                next_state=`DIV;
                            end
                            // MULH
                            3'b001: begin
                                next_state=`MULH;
                            end
                            // MUL
                            3'b000: begin
                                next_state=`MUL;
                            end
                            // DIVU
                            3'b101: begin
                                next_state=`DIVU;
                            end
                            // MULHSU
                            3'b010: begin
                                next_state=`MULHSU;
                            end
                            // MULHU
                            3'b011: begin
                                next_state=`MULHU;
                            end
                            default: next_state=8'd0;
                        endcase
                    end
                    7'b0100000: begin
                        case (opcode[14:12])
                            // SRA
                            3'b101: begin
                                next_state=`SRA;
                            end
                            // SUB
                            3'b000: begin
                                next_state=`SUB;
                            end
                            default: next_state=8'd0;
                        endcase
                    end
                    7'b0000000: begin
                        case (opcode[14:12])
                            // AND
                            3'b111: begin
                                next_state=`AND;
                            end
                            // SLL
                            3'b001: begin
                                next_state=`SLL;
                            end
                            // XOR
                            3'b100: begin
                                next_state=`XOR;
                            end
                            // SLTU
                            3'b011: begin
                                next_state=`SLTU;
                            end
                            // SRL
                            3'b101: begin
                                next_state=`SRL;
                            end
                            // OR
                            3'b110: begin
                                next_state=`OR;
                            end
                            // SLT
                            3'b010: begin
                                next_state=`SLT;
                            end
                            // ADD
                            3'b000: begin
                                next_state=`ADD;
                            end
                            default: next_state=8'd0;
                        endcase
                    end
                    default: next_state=8'd0;
                endcase
            end
            // 6個
            // ALU使用
            7'b1100011: begin
                case (opcode[14:12])
                    // BGE
                    3'b101: begin
                        next_state=`BGE;
                        alu_sel=`signed_comp;
                    end
                    // BEQ
                    3'b000: begin
                        next_state=`BEQ;
                        alu_sel=`equal;
                    end
                    // BGEU
                    3'b111: begin
                        next_state=`BGEU;
                        alu_sel=`unsigned_comp;
                    end
                    // BLTU
                    3'b110: begin
                        next_state=`BLTU;
                        alu_sel=`unsigned_comp;
                    end
                    // BNE
                    3'b001: begin
                        next_state=`BNE;
                        alu_sel=`equal;
                    end
                    // BLT
                    3'b100: begin
                        next_state=`BLT;
                        alu_sel=`signed_comp;
                    end
                    default: next_state=8'd0;
                endcase
            end
            // 1個
            7'b0001111: begin
                // FENCE
                next_state=`FENCE;
            end
            // 9個
            7'b0010011: begin
                case (opcode[14:12])
                    // SLLI
                    3'b001: begin
                        next_state=`SLLI;
                    end
                    // ORI
                    3'b110: begin
                        next_state=`ORI;
                    end
                    3'b101: begin
                        case (opcode[31:25])
                            // SRLI
                            7'b0000000: begin
                                next_state=`SRLI;
                            end
                            // SRAI
                            7'b0100000: begin
                                next_state=`SRAI;
                            end
                            default: next_state=8'd0;
                        endcase
                    end
                    // ADDI
                    3'b000: begin
                        next_state=`ADDI;
                    end
                    // ANDI
                    3'b111: begin
                        next_state=`ANDI;
                    end
                    // SLTIU
                    3'b011: begin
                        next_state=`SLTIU;
                    end
                    // XORI
                    3'b100: begin
                        next_state=`XORI;
                    end
                    // SLTI
                    3'b010: begin
                        next_state=`SLTI;
                    end
                    default: next_state=8'd0;
                endcase
            end
            // 1個
            7'b0010111: begin
                // AUIPC
                next_state=`AUIPC;
            end
            // 3個
            7'b0100011: begin
                case (opcode[14:12])
                    // SW
                    3'b010: begin
                        next_state=`SW;
                    end
                    // SB
                    3'b000: begin
                        next_state=`SB;
                    end
                    // SH
                    3'b001: begin
                        next_state=`SH;
                    end
                    default: next_state=8'd0;
                endcase
            end
            // 1個
            7'b0110111: begin
                // LUI
                next_state=`LUI;
            end
            // 2個
            7'b1110011: begin
                case (opcode[31:20])
                    // ECALL
                    12'b000000000000: begin
                        next_state=`ECALL;
                    end
                    // EBREAK
                    12'b000000000001: begin
                        next_state=`EBREAK;
                    end
                    default: next_state=8'd0;
                endcase
            end
            // 1個
            7'b1100111: begin
                // JALR
                next_state=`JALR;
            end
            // 1個
            7'b1101111: begin
                // JAL
                next_state=`JAL;
            end
            default: next_state=8'd0;
        endcase
    end
endmodule