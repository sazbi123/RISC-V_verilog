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
    // 何も宣言しなかったらデフォルトでunsignedになるんですかね
    
    reg [31:0] regfile [0:31];

    // シミュレーション用に一応全て0に初期化
    initial begin
        $readmemh("regfile_initial.hex",regfile);
    end

    reg [63:0] result;
    reg [31:0] pc,opcode,rw_addr,internal_data_out;
    reg [5:0] state,next_state;
    reg [3:0] alu_sel;
    reg [2:0] alu_data_in_sel;
    reg internal_rw,internal_half,internal_byte;
    reg wait_count;
    reg addr_sel;
    wire [31:0] imm_U,alu_data_in;
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
    assign addr=(addr_sel==1'd0)?pc:(
                (addr_sel==1'd1)?rw_addr:32'd0);
    // これは下位5ビットしか使わないやつはALUで範囲指定できるかもしれんがとりあえず動くものを作るので余分になるかも
    // 8'd1と8'd2，8'd0と8'd4は上述の理由でまとめられる可能性あり
    assign alu_data_in=(alu_data_in_sel==3'd0)?regfile[rs2]:(
                       (alu_data_in_sel==3'd1)?{{20{imm_I[11]}},imm_I}:(
                       (alu_data_in_sel==3'd2)?{27'd0,imm_I[4:0]}:(
                       (alu_data_in_sel==3'd3)?-regfile[rs2]:(
                       (alu_data_in_sel==3'd4)?{27'd0,regfile[rs2][4:0]}:32'd0))));
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
            addr_sel<=1'd0;
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
                        addr_sel<=1'd0;
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
                    pc<=pc+{{11{imm_J[20]}},imm_J}-32'd4;
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

                    pc<=(({{20{imm_I[11]}},imm_I}+regfile[rs1])&32'hfffffffe)-32'd4;
                    state<=`fetch1;
                end
                `BEQ: begin
                    if (result[0]==1) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{{19{imm_B[12]}},imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BNE: begin
                    if (result[0]==0) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{{19{imm_B[12]}},imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BLT: begin
                    if (result[0]==1) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{{19{imm_B[12]}},imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BLTU: begin
                    if (result[0]==1) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{{19{imm_B[12]}},imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BGE: begin
                    if (result[0]==0) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{{19{imm_B[12]}},imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `BGEU: begin
                    if (result[0]==0) begin
                        // fetch1でpcを+4するためここでは-4
                        pc<=pc+{{19{imm_B[12]}},imm_B}-32'd4;
                    end

                    state<=`fetch1;
                end
                `LB: begin
                    if (wait_count==1'b0) begin
                        // rw_addrを出力
                        addr_sel<=1'd1;
                        rw_addr<=regfile[rs1]+{{20{imm_I[11]}},imm_I};
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
                            regfile[rd]<={{24{data_in[7]}},data_in[7:0]};
                        end
                        
                        wait_count<=1'b0;
                        state<=`fetch1;
                    end
                end
                `LH: begin
                    if (wait_count==1'b0) begin
                        // rw_addrを出力
                        addr_sel<=1'd1;
                        rw_addr<=regfile[rs1]+{{20{imm_I[11]}},imm_I};
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
                            regfile[rd]<={{16{data_in[15]}},data_in[15:0]};
                        end
                        
                        wait_count<=1'b0;
                        state<=`fetch1;
                    end
                end
                `LW: begin
                    if (wait_count==1'b0) begin
                        // rw_addrを出力
                        addr_sel<=1'd1;
                        rw_addr<=regfile[rs1]+{{20{imm_I[11]}},imm_I};
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
                        addr_sel<=1'd1;
                        rw_addr<=regfile[rs1]+{{20{imm_I[11]}},imm_I};
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
                        addr_sel<=1'd1;
                        rw_addr<=regfile[rs1]+{{20{imm_I[11]}},imm_I};
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
                    addr_sel<=1'd1;
                    rw_addr<=regfile[rs1]+{{20{imm_S[11]}},imm_S};
                    internal_rw<=`write;
                    {internal_byte,internal_half}<=2'b10;
                    internal_data_out<={24'd0,regfile[rs2][7:0]};
                    state<=`fetch1;
                end
                `SH: begin
                    addr_sel<=1'd1;
                    rw_addr<=regfile[rs1]+{{20{imm_S[11]}},imm_S};
                    internal_rw<=`write;
                    {internal_byte,internal_half}<=2'b01;
                    internal_data_out<={16'd0,regfile[rs2][15:0]};
                    state<=`fetch1;
                end
                `SW: begin
                    addr_sel<=1'd1;
                    rw_addr<=regfile[rs1]+{{20{imm_S[11]}},imm_S};
                    internal_rw<=`write;
                    {internal_byte,internal_half}<=2'b00;
                    internal_data_out<=regfile[rs2];
                    state<=`fetch1;
                end
                `ADDI: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SLTI: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SLTIU: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `XORI: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `ORI: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `ANDI: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                // ここから未検証（Vivadoで）
                `SLLI: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SRLI: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SRAI: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `ADD: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SUB: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SLL: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SLT: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SLTU: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `XOR: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SRL: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `SRA: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `OR: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `AND: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                // https://qiita.com/asfdrwe/items/595c871611e6603741fa ここらによく書いてあるかもしれない
                // FENCE命令はよくわからない
                // 指定したものを最適化により順序が壊れないように順序を指定する認識でいる
                // 今回パイプラインとかしていないので何もしなくていいと思っている
                `FENCE: begin
                    state<=`fetch1;
                end
                // どちらもHALT命令（何もしない）とすることにした．もしかしたらこの部分は省略するかもしれない．
                // ECALLもよくわからないので何もしない
                // 上のサイトによるとシステムコールと表記されている
                `ECALL: begin
                    state<=`ECALL;
                end
                // EBREAKも何もわからないので何もしない
                // 上のサイトによるとデバッグコールと表記されている
                `EBREAK: begin
                    state<=`EBREAK;
                end
                `MUL: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        // 下位32bit
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `MULH: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        // 下位32bit
                        regfile[rd]<=result[63:32];
                    end

                    state<=`fetch1;
                end
                `MULHSU: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        // 上位32bit
                        regfile[rd]<=result[63:32];
                    end

                    state<=`fetch1;
                end
                `MULHU: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        // 上位32bit
                        regfile[rd]<=result[63:32];
                    end

                    state<=`fetch1;
                end
                `DIV: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        // 上位32bit
                        regfile[rd]<=result[63:32];
                    end

                    state<=`fetch1;
                end
                `DIVU: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        // 上位32bit
                        regfile[rd]<=result[63:32];
                    end

                    state<=`fetch1;
                end
                `REM: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        // 下位32bit
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                `REMU: begin
                    // x0は常に0
                    if (rd==5'd0) begin
                        regfile[rd]<=32'd0;
                    end
                    else begin
                        // 下位32bit
                        regfile[rd]<=result[31:0];
                    end

                    state<=`fetch1;
                end
                default: ;
            endcase
        end
    end

    // ALU
    // 別モジュールにしてもいいかも
    // alu_selとresultとalu_data_inを使う
    // alu_data_inはセレクタ信号によりどれを使うかを命令決定時に決める
    // alu_selは命令を確定させるAlwaysで0にリセットし，resultはこのalwaysで値を確定
    // alu_selがリセットされるとこのcaseに入る値も確定するのでresultも確定させればリセットできるはず
    // ALUの入力データををWireにしてセレクタにより変えたら汎用性が上がるかも
    always @(*) begin
        case (alu_sel)
            `equal: begin
                result={32'd0,31'd0,(regfile[rs1]==alu_data_in)};
            end
            `signed_comp: begin
                result={32'd0,31'd0,($signed(regfile[rs1])<$signed(alu_data_in))};
            end
            `unsigned_comp: begin
                result={32'd0,31'd0,($unsigned(regfile[rs1])<$unsigned(alu_data_in))};
            end
            `add_alu: begin
                result=regfile[rs1]+alu_data_in;
            end
            `xor_alu: begin
                result=regfile[rs1]^alu_data_in;
            end
            `or_alu: begin
                result=regfile[rs1]|alu_data_in;
            end
            `and_alu: begin
                result=regfile[rs1]&alu_data_in;
            end
            `left_shift_alu: begin
                result=regfile[rs1]<<alu_data_in;
            end
            // 算術右シフトをsignedで明示したのでこちらはunsignedで一応明示しておく
            `right_logical_shift_alu: begin
                result=$unsigned(regfile[rs1])>>alu_data_in;
            end
            // 算術右シフトができていない
            // ↑signedにしたら動いていて良さげ
            `right_arithmetic_shift_alu: begin
                result=$signed(regfile[rs1])>>>alu_data_in;
            end
            `mul_ss_alu: begin
                result=$signed(regfile[rs1])*$signed(alu_data_in);
            end
            `mul_su_alu: begin
                result=$signed({{32{regfile[rs1][31]}},regfile[rs1]})*$unsigned({32'd0,alu_data_in});
            end
            `mul_uu_alu: begin
                result=$unsigned(regfile[rs1])*$unsigned(alu_data_in);
            end
            `signed_div_rem_alu: begin
                // 上位32bitは商，下位32bitは余り
                result[63:32]=(alu_data_in==32'd0)?32'hffffffff:(
                              ((regfile[rs1]==32'h80000000)&&(alu_data_in==32'hffffffff))?32'h80000000:$signed(regfile[rs1])/$signed(alu_data_in));
                result[31:0]=(alu_data_in==32'd0)?regfile[rs1]:(
                             ((regfile[rs1]==32'h80000000)&&(alu_data_in==32'hffffffff))?32'd0:$signed(regfile[rs1])%$signed(alu_data_in));
            end
            `unsigned_div_rem_alu: begin
                // 上位32bitは商，下位32bitは余り
                result[63:32]=(alu_data_in==32'd0)?32'hffffffff:$unsigned(regfile[rs1])/$unsigned(alu_data_in);
                result[31:0]=(alu_data_in==32'd0)?regfile[rs1]:$unsigned(regfile[rs1])%$unsigned(alu_data_in);
            end
            default: begin
                result=64'd0;
            end
        endcase
    end

    // 何命令かを確定させ次のstateを決定するモジュール
    // 別モジュールにしてもいいかもしれない
    // これは共通で使用可（opcodeしか見ていないため）
    // 後ですべてのパターンでalu_sel=0（リセット）をしないといけない
    // 後ですべてのパターンでalu_data_in_sel=0（リセット）をしないといけない
    always @(*) begin
        // 全部で48命令ある
        case (opcode[6:0])
            // 18個
            // ALU使用
            7'b0110011: begin
                case (opcode[31:25])
                    7'b0000001: begin
                        case (opcode[14:12])
                            // REM
                            3'b110: begin
                                next_state=`REM;
                                alu_sel=`signed_div_rem_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // REMU
                            3'b111: begin
                                next_state=`REMU;
                                alu_sel=`signed_div_rem_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // DIV
                            3'b100: begin
                                next_state=`DIV;
                                alu_sel=`signed_div_rem_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // MULH
                            3'b001: begin
                                next_state=`MULH;
                                alu_sel=`mul_ss_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // MUL
                            3'b000: begin
                                next_state=`MUL;
                                alu_sel=`mul_ss_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // DIVU
                            3'b101: begin
                                next_state=`DIVU;
                                alu_sel=`signed_div_rem_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // MULHSU
                            3'b010: begin
                                next_state=`MULHSU;
                                alu_sel=`mul_su_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // MULHU
                            3'b011: begin
                                next_state=`MULHU;
                                alu_sel=`mul_uu_alu;
                                alu_data_in_sel=3'd0;
                            end
                            default: next_state=`fetch1;
                        endcase
                    end
                    7'b0100000: begin
                        case (opcode[14:12])
                            // SRA
                            3'b101: begin
                                next_state=`SRA;
                                alu_sel=`right_arithmetic_shift_alu;
                                alu_data_in_sel=3'd4;
                            end
                            // SUB
                            3'b000: begin
                                next_state=`SUB;
                                alu_sel=`add_alu;
                                alu_data_in_sel=3'd3;
                            end
                            default: next_state=`fetch1;
                        endcase
                    end
                    7'b0000000: begin
                        case (opcode[14:12])
                            // AND
                            3'b111: begin
                                next_state=`AND;
                                alu_sel=`and_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // SLL
                            3'b001: begin
                                next_state=`SLL;
                                alu_sel=`left_shift_alu;
                                alu_data_in_sel=3'd4;
                            end
                            // XOR
                            3'b100: begin
                                next_state=`XOR;
                                alu_sel=`xor_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // SLTU
                            3'b011: begin
                                next_state=`SLTU;
                                alu_sel=`unsigned_comp;
                                alu_data_in_sel=3'd0;
                            end
                            // SRL
                            3'b101: begin
                                next_state=`SRL;
                                alu_sel=`right_logical_shift_alu;
                                alu_data_in_sel=3'd4;
                            end
                            // OR
                            3'b110: begin
                                next_state=`OR;
                                alu_sel=`or_alu;
                                alu_data_in_sel=3'd0;
                            end
                            // SLT
                            3'b010: begin
                                next_state=`SLT;
                                alu_sel=`signed_comp;
                                alu_data_in_sel=3'd0;
                            end
                            // ADD
                            3'b000: begin
                                next_state=`ADD;
                                alu_sel=`add_alu;
                                alu_data_in_sel=3'd0;
                            end
                            default: next_state=`fetch1;
                        endcase
                    end
                    default: next_state=`fetch1;
                endcase
            end
            // 9個
            // ALU使用
            7'b0010011: begin
                case (opcode[14:12])
                    // SLLI
                    3'b001: begin
                        next_state=`SLLI;
                        alu_sel=`left_shift_alu;
                        alu_data_in_sel=3'd2;
                    end
                    // ORI
                    3'b110: begin
                        next_state=`ORI;
                        alu_sel=`or_alu;
                        alu_data_in_sel=3'd1;
                    end
                    3'b101: begin
                        case (opcode[31:25])
                            // SRLI
                            7'b0000000: begin
                                next_state=`SRLI;
                                alu_sel=`right_logical_shift_alu;
                                alu_data_in_sel=3'd2;
                            end
                            // SRAI
                            7'b0100000: begin
                                next_state=`SRAI;
                                alu_sel=`right_arithmetic_shift_alu;
                                alu_data_in_sel=3'd2;
                            end
                            default: next_state=`fetch1;
                        endcase
                    end
                    // ADDI
                    3'b000: begin
                        next_state=`ADDI;
                        alu_sel=`add_alu;
                        alu_data_in_sel=3'd1;
                    end
                    // ANDI
                    3'b111: begin
                        next_state=`ANDI;
                        alu_sel=`and_alu;
                        alu_data_in_sel=3'd1;
                    end
                    // SLTIU
                    3'b011: begin
                        next_state=`SLTIU;
                        alu_sel=`unsigned_comp;
                        alu_data_in_sel=3'd1;
                    end
                    // XORI
                    3'b100: begin
                        next_state=`XORI;
                        alu_sel=`xor_alu;
                        alu_data_in_sel=3'd1;
                    end
                    // SLTI
                    3'b010: begin
                        next_state=`SLTI;
                        alu_sel=`signed_comp;
                        alu_data_in_sel=3'd1;
                    end
                    default: next_state=`fetch1;
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
                        alu_data_in_sel<=8'd0;
                    end
                    // BEQ
                    3'b000: begin
                        next_state=`BEQ;
                        alu_sel=`equal;
                        alu_data_in_sel<=8'd0;
                    end
                    // BGEU
                    3'b111: begin
                        next_state=`BGEU;
                        alu_sel=`unsigned_comp;
                        alu_data_in_sel<=8'd0;
                    end
                    // BLTU
                    3'b110: begin
                        next_state=`BLTU;
                        alu_sel=`unsigned_comp;
                        alu_data_in_sel<=8'd0;
                    end
                    // BNE
                    3'b001: begin
                        next_state=`BNE;
                        alu_sel=`equal;
                        alu_data_in_sel<=8'd0;
                    end
                    // BLT
                    3'b100: begin
                        next_state=`BLT;
                        alu_sel=`signed_comp;
                        alu_data_in_sel<=8'd0;
                    end
                    default: next_state=`fetch1;
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
                    default: next_state=`fetch1;
                endcase
            end
            // 1個
            7'b0001111: begin
                // FENCE
                next_state=`FENCE;
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
                    default: next_state=`fetch1;
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
                    default: next_state=`fetch1;
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
            default: next_state=`fetch1;
        endcase
    end
endmodule