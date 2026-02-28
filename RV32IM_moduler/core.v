`include "def_param.vh"

module core (
    input wire [63:0] result,
    input wire [31:0] data_in,
    input wire [5:0] next_state,
    input wire [2:0] alu_data_in_sel,
    input wire rst_n,clk,
    output wire [31:0] data_out,alu_data_in,opcode,
    output wire [31:0] addr,alu_data_1,
    output wire rw,
    output wire half,byte
);
    reg [31:0] regfile [0:31];

    // // シミュレーション用に一応全て0に初期化
    // initial begin
    //     $readmemh("regfile_initial.hex",regfile);
    // end
    
    reg [31:0] pc,rw_addr,internal_data_out,internal_opcode;
    reg [5:0] state;
    reg internal_rw,addr_sel,internal_half,internal_byte;
    reg wait_count;
    wire [31:0] imm_U;
    wire [20:0] imm_J;
    wire [12:0] imm_B;
    wire [11:0] imm_I,imm_S;
    wire [6:0] funct7;
    wire [4:0] rd,rs1,rs2;
    wire [2:0] funct3;

    assign opcode=internal_opcode;
    assign alu_data_1=regfile[rs1];
    assign half=internal_half;
    assign byte=internal_byte;
    assign data_out=internal_data_out;
    assign rw=internal_rw;
    assign addr=(addr_sel==1'd0)?pc:(
                (addr_sel==1'd1)?rw_addr:32'd0);
    assign rd=internal_opcode[11:7];
    assign funct3=internal_opcode[14:12];
    assign rs1=internal_opcode[19:15];
    assign rs2=internal_opcode[24:20];
    assign funct7=internal_opcode[31:25];
    assign imm_I=internal_opcode[31:20];
    assign imm_S={internal_opcode[31:25],internal_opcode[11:7]};
    assign imm_B={internal_opcode[31],internal_opcode[7],internal_opcode[30:25],internal_opcode[11:8],1'b0};
    assign imm_U={internal_opcode[31:12],12'd0};
    assign imm_J={internal_opcode[31],internal_opcode[19:12],internal_opcode[20],internal_opcode[30:21],1'b0};
    assign alu_data_in=(alu_data_in_sel==3'd0)?regfile[rs2]:(
                       (alu_data_in_sel==3'd1)?{{20{imm_I[11]}},imm_I}:(
                       (alu_data_in_sel==3'd2)?{27'd0,imm_I[4:0]}:(
                       (alu_data_in_sel==3'd3)?-regfile[rs2]:(
                       (alu_data_in_sel==3'd4)?{27'd0,regfile[rs2][4:0]}:32'd0))));

    always @(posedge clk) begin
        if (rst_n==1'b0) begin
            state<=`fetch1;
            addr_sel<=1'd0;
            pc<=32'hfffffffc;
            internal_rw<=`read;
            internal_data_out<=32'd0;
            {internal_byte,internal_half}<=2'b00;
            wait_count<=1'b0;
            internal_opcode<=32'd0;
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
                        internal_opcode<=data_in;
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
endmodule