`include "def_param.vh"

// uartなし（現状）
// CPUからみてinかoutかで命名
// RV32IMって割り込みあるんですかね
// 2クロックでフェッチデータが確定
// https://risc-v-cpu-visualizer.vercel.app/assembler でデバッグ中
// https://risc-v-cpu-visualizer.vercel.app/converter こっちのほうがいいかもしない(AUIPC, LUIは調子悪くて即値が全て0になる)
module RV32IM (
    input wire clk,rst_n,
    input wire [31:0] data_in,
    output wire rw,
    output wire [31:0] data_out,
    output wire [31:0] addr,
    output wire [8:0] uart,
    output wire half,byte
);
    reg [31:0] regfile [0:31];
    reg [31:0] pc,opcode,result,rw_addr,internal_data_out;
    // 暫定のビット幅
    reg [7:0] state;
    // 暫定のビット幅
    reg [7:0] next_state;
    // 暫定のビット幅
    reg [7:0] addr_sel;
    // 暫定のビット幅
    reg [7:0] alu_sel;
    reg internal_rw,internal_half,internal_byte;
    reg wait_count;
    wire [31:0] imm_U;
    wire [20:0] imm_J;
    wire [12:0] imm_B;
    wire [11:0] imm_I,imm_S;
    wire [6:0] funct7;
    wire [4:0] rd,rs1,rs2;
    wire [2:0] funct3;

    assign data_out=internal_data_out;
    assign rw=internal_rw;
    assign half=internal_half;
    assign byte=internal_byte;
    assign addr=(addr_sel==8'd0)?pc:(
                (addr_sel==8'd1)?rw_addr:32'd0);
    // 各命令の分けるやつ定義（rdとかimmとか）
    assign rd=opcode[11:7];
    assign funct3=opcode[14:12];
    assign rs1=opcode[19:15];
    assign rs2=opcode[24:20];
    assign funct7=opcode[31:25];
    assign imm_I=opcode[31:20];
    assign imm_S={opcode[31:25],opcode[11:7]};
    assign imm_B={opcode[31],opcode[7],opcode[30:25],opcode[11:8],1'b0};
    assign imm_U={opcode[31:12],12'd0};
    assign imm_J={opcode[31],opcode[19:12],opcode[20],opcode[30:21],1'b0};

    // fetch1でpcを+4するためPCをいじるときは-4
    always @(posedge clk) begin
        if (rst_n==1'b0) begin
            state<=`fetch1;
            addr_sel<=8'd0;
            pc<=32'hfffffffc;
            internal_rw<=`read;
            internal_data_out<=32'd0;
            {internal_byte,internal_half}<=2'b00;
            wait_count<=1'b0;
            opcode<=32'd0;
            rw_addr<=32'd0;
            // x0は常に0
            regfile[5'd0]<=32'd0;
        end
        else begin
            case (state)
                `fetch1: begin
                    if (wait_count==1'b0) begin
                        addr_sel<=8'd0;
                        pc<=pc+32'd4;
                        internal_rw<=`read;
                        {internal_byte,internal_half}<=2'b00;
                        wait_count<=1'b1;
                    end
                    else begin
                        opcode<=data_in;
                        wait_count<=1'b0;
                        state<=`decode;
                    end
                end
                `decode: begin
                    state<=next_state;
                end
                `LUI: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=imm_U;
                    end

                    state<=`fetch1;
                end
                `AUIPC: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=imm_U+pc;
                    end

                    state<=`fetch1;
                end
                `JAL: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=pc+32'd4;
                    end

                    // sign extended
                    // fetch1でpcを+4するためここでは-4
                    pc<=pc+{(imm_J[20])?11'h7ff:11'd0,imm_J}-32'd4;
                    state<=`fetch1;
                end
                `JALR: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=pc+32'd4;
                    end

                    pc<=(({(imm_I[11])?20'hfffff:20'd0,imm_I}+regfile[rs1])&32'hfffffffe)-32'd4;
                    state<=`fetch1;
                end
                `BEQ: begin
                    if (result[0]==1) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{(imm_B[12])?19'h7ffff:19'd0,imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BNE: begin
                    if (result[0]==0) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{(imm_B[12])?19'h7ffff:19'd0,imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BLT: begin
                    if (result[0]==1) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{(imm_B[12])?19'h7ffff:19'd0,imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BLTU: begin
                    if (result[0]==1) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{(imm_B[12])?19'h7ffff:19'd0,imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BGE: begin
                    if (result[0]==0) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{(imm_B[12])?19'h7ffff:19'd0,imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BGEU: begin
                    if (result[0]==0) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{(imm_B[12])?19'h7ffff:19'd0,imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `LB: begin
                    if (wait_count==1'b0) begin
                        // rw_addrを出力
                        addr_sel<=8'd1;
                        rw_addr<=regfile[rs1]+{(imm_I[11])?20'hfffff:20'd0,imm_I};
                        internal_rw<=`read;
                        {internal_byte,internal_half}<=2'b10;
                        wait_count<=1'b1;
                    end
                    else begin
                        // x0は常に0
                        if (rd==5'd0) begin
                            regfile[rd]<=32'd0;
                        end
                        else begin
                            regfile[rd]<={(data_in[7])?24'hffffff:24'd0,data_in[7:0]};
                        end
                        
                        wait_count<=1'b0;
                        state<=`fetch1;
                    end
                end
                `LH: begin
                    if (wait_count==1'b0) begin
                        // rw_addrを出力
                        addr_sel<=8'd1;
                        rw_addr<=regfile[rs1]+{(imm_I[11])?20'hfffff:20'd0,imm_I};
                        internal_rw<=`read;
                        {internal_byte,internal_half}<=2'b01;
                        wait_count<=1'b1;
                    end
                    else begin
                        // x0は常に0
                        if (rd==5'd0) begin
                            regfile[rd]<=32'd0;
                        end
                        else begin
                            regfile[rd]<={(data_in[15])?16'hffff:16'd0,data_in[15:0]};
                        end
                        
                        wait_count<=1'b0;
                        state<=`fetch1;
                    end
                end
                `LW: begin
                    if (wait_count==1'b0) begin
                        // rw_addrを出力
                        addr_sel<=8'd1;
                        rw_addr<=regfile[rs1]+{(imm_I[11])?20'hfffff:20'd0,imm_I};
                        internal_rw<=`read;
                        {internal_byte,internal_half}<=2'b00;
                        wait_count<=1'b1;
                    end
                    else begin
                        // x0は常に0
                        if (rd==5'd0) begin
                            regfile[rd]<=32'd0;
                        end
                        else begin
                            regfile[rd]<=data_in;
                        end
                        
                        wait_count<=1'b0;
                        state<=`fetch1;
                    end
                end
                `LBU: begin
                    if (wait_count==1'b0) begin
                        // rw_addrを出力
                        addr_sel<=8'd1;
                        rw_addr<=regfile[rs1]+{(imm_I[11])?20'hfffff:20'd0,imm_I};
                        internal_rw<=`read;
                        {internal_byte,internal_half}<=2'b10;
                        wait_count<=1'b1;
                    end
                    else begin
                        // x0は常に0
                        if (rd==5'd0) begin
                            regfile[rd]<=32'd0;
                        end
                        else begin
                            regfile[rd]<={24'd0,data_in[7:0]};
                        end
                        
                        wait_count<=1'b0;
                        state<=`fetch1;
                    end
                end
                `LHU: begin
                    if (wait_count==1'b0) begin
                        // rw_addrを出力
                        addr_sel<=8'd1;
                        rw_addr<=regfile[rs1]+{(imm_I[11])?20'hfffff:20'd0,imm_I};
                        internal_rw<=`read;
                        {internal_byte,internal_half}<=2'b01;
                        wait_count<=1'b1;
                    end
                    else begin
                        // x0は常に0
                        if (rd==5'd0) begin
                            regfile[rd]<=32'd0;
                        end
                        else begin
                            regfile[rd]<={16'd0,data_in[15:0]};
                        end
                        
                        wait_count<=1'b0;
                        state<=`fetch1;
                    end
                end
                `SB: begin
                    addr_sel<=8'd1;
                    rw_addr<=regfile[rs1]+{(imm_S[11])?20'hfffff:20'd0,imm_S};
                    internal_rw<=`write;
                    {internal_byte,internal_half}<=2'b10;
                    internal_data_out<={24'd0,regfile[rs2][7:0]};
                    state<=`fetch1;
                end
                `SH: begin
                    addr_sel<=8'd1;
                    rw_addr<=regfile[rs1]+{(imm_S[11])?20'hfffff:20'd0,imm_S};
                    internal_rw<=`write;
                    {internal_byte,internal_half}<=2'b01;
                    internal_data_out<={16'd0,regfile[rs2][15:0]};
                    state<=`fetch1;
                end
                `SW: begin
                    addr_sel<=8'd1;
                    rw_addr<=regfile[rs1]+{(imm_S[11])?20'hfffff:20'd0,imm_S};
                    internal_rw<=`write;
                    {internal_byte,internal_half}<=2'b00;
                    internal_data_out<=regfile[rs2];
                    state<=`fetch1;
                end
                
                default: ;
            endcase
        end
    end

    // ALU
    // alu_selとresultを使う
    // alu_selは命令を確定させるAlwaysで0にリセットし，resultはこのalwaysで値を確定
    // 後ですべてのパターンでalu_sel=0をしないといけない
    // alu_selがリセットされるとこのcaseに入る値も確定するのでresultも確定させればリセットできるはず
    always @(*) begin
        case (alu_sel)
            `equal: begin
                result={31'd0,(regfile[rs1]==regfile[rs2])};
            end
            `signed_comp: begin
                result={31'd0,($signed(regfile[rs1])<$signed(regfile[rs2]))};
            end
            `unsigned_comp: begin
                result={31'd0,($unsigned(regfile[rs1])<$unsigned(regfile[rs2]))};
            end
            default: begin
                result=32'd0;
            end
        endcase
    end

    // 何命令かを確定させ次のstateを決定するモジュール
    // これは共通で使用可（opcodeしか見ていないため）
    always @(*) begin
        // 全部で48命令ある
        case (opcode[6:0])
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