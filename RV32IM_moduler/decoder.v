`include "def_param.vh"

module decoder (
    input wire [31:0] opcode,
    output wire [5:0] next_state,
    output wire [3:0] alu_sel,
    output wire [2:0] alu_data_in_sel
);
    reg [5:0] internal_next_state;
    reg [3:0] internal_alu_sel;
    reg [2:0] internal_alu_data_in_sel;


    assign next_state=internal_next_state;
    assign alu_sel=internal_alu_sel;
    assign alu_data_in_sel=internal_alu_data_in_sel;


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
                                internal_next_state=`REM;
                                internal_alu_sel=`signed_div_rem_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // REMU
                            3'b111: begin
                                internal_next_state=`REMU;
                                internal_alu_sel=`signed_div_rem_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // DIV
                            3'b100: begin
                                internal_next_state=`DIV;
                                internal_alu_sel=`signed_div_rem_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // MULH
                            3'b001: begin
                                internal_next_state=`MULH;
                                internal_alu_sel=`mul_ss_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // MUL
                            3'b000: begin
                                internal_next_state=`MUL;
                                internal_alu_sel=`mul_ss_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // DIVU
                            3'b101: begin
                                internal_next_state=`DIVU;
                                internal_alu_sel=`signed_div_rem_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // MULHSU
                            3'b010: begin
                                internal_next_state=`MULHSU;
                                internal_alu_sel=`mul_su_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // MULHU
                            3'b011: begin
                                internal_next_state=`MULHU;
                                internal_alu_sel=`mul_uu_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            default: internal_next_state=`fetch1;
                        endcase
                    end
                    7'b0100000: begin
                        case (opcode[14:12])
                            // SRA
                            3'b101: begin
                                internal_next_state=`SRA;
                                internal_alu_sel=`right_arithmetic_shift_alu;
                                internal_alu_data_in_sel=3'd4;
                            end
                            // SUB
                            3'b000: begin
                                internal_next_state=`SUB;
                                internal_alu_sel=`add_alu;
                                internal_alu_data_in_sel=3'd3;
                            end
                            default: internal_next_state=`fetch1;
                        endcase
                    end
                    7'b0000000: begin
                        case (opcode[14:12])
                            // AND
                            3'b111: begin
                                internal_next_state=`AND;
                                internal_alu_sel=`and_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // SLL
                            3'b001: begin
                                internal_next_state=`SLL;
                                internal_alu_sel=`left_shift_alu;
                                internal_alu_data_in_sel=3'd4;
                            end
                            // XOR
                            3'b100: begin
                                internal_next_state=`XOR;
                                internal_alu_sel=`xor_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // SLTU
                            3'b011: begin
                                internal_next_state=`SLTU;
                                internal_alu_sel=`unsigned_comp;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // SRL
                            3'b101: begin
                                internal_next_state=`SRL;
                                internal_alu_sel=`right_logical_shift_alu;
                                internal_alu_data_in_sel=3'd4;
                            end
                            // OR
                            3'b110: begin
                                internal_next_state=`OR;
                                internal_alu_sel=`or_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // SLT
                            3'b010: begin
                                internal_next_state=`SLT;
                                internal_alu_sel=`signed_comp;
                                internal_alu_data_in_sel=3'd0;
                            end
                            // ADD
                            3'b000: begin
                                internal_next_state=`ADD;
                                internal_alu_sel=`add_alu;
                                internal_alu_data_in_sel=3'd0;
                            end
                            default: internal_next_state=`fetch1;
                        endcase
                    end
                    default: internal_next_state=`fetch1;
                endcase
            end
            // 9個
            // ALU使用
            7'b0010011: begin
                case (opcode[14:12])
                    // SLLI
                    3'b001: begin
                        internal_next_state=`SLLI;
                        internal_alu_sel=`left_shift_alu;
                        internal_alu_data_in_sel=3'd2;
                    end
                    // ORI
                    3'b110: begin
                        internal_next_state=`ORI;
                        internal_alu_sel=`or_alu;
                        internal_alu_data_in_sel=3'd1;
                    end
                    3'b101: begin
                        case (opcode[31:25])
                            // SRLI
                            7'b0000000: begin
                                internal_next_state=`SRLI;
                                internal_alu_sel=`right_logical_shift_alu;
                                internal_alu_data_in_sel=3'd2;
                            end
                            // SRAI
                            7'b0100000: begin
                                internal_next_state=`SRAI;
                                internal_alu_sel=`right_arithmetic_shift_alu;
                                internal_alu_data_in_sel=3'd2;
                            end
                            default: internal_next_state=`fetch1;
                        endcase
                    end
                    // ADDI
                    3'b000: begin
                        internal_next_state=`ADDI;
                        internal_alu_sel=`add_alu;
                        internal_alu_data_in_sel=3'd1;
                    end
                    // ANDI
                    3'b111: begin
                        internal_next_state=`ANDI;
                        internal_alu_sel=`and_alu;
                        internal_alu_data_in_sel=3'd1;
                    end
                    // SLTIU
                    3'b011: begin
                        internal_next_state=`SLTIU;
                        internal_alu_sel=`unsigned_comp;
                        internal_alu_data_in_sel=3'd1;
                    end
                    // XORI
                    3'b100: begin
                        internal_next_state=`XORI;
                        internal_alu_sel=`xor_alu;
                        internal_alu_data_in_sel=3'd1;
                    end
                    // SLTI
                    3'b010: begin
                        internal_next_state=`SLTI;
                        internal_alu_sel=`signed_comp;
                        internal_alu_data_in_sel=3'd1;
                    end
                    default: internal_next_state=`fetch1;
                endcase
            end
            // 6個
            // ALU使用
            7'b1100011: begin
                case (opcode[14:12])
                    // BGE
                    3'b101: begin
                        internal_next_state=`BGE;
                        internal_alu_sel=`signed_comp;
                        internal_alu_data_in_sel<=8'd0;
                    end
                    // BEQ
                    3'b000: begin
                        internal_next_state=`BEQ;
                        internal_alu_sel=`equal;
                        internal_alu_data_in_sel<=8'd0;
                    end
                    // BGEU
                    3'b111: begin
                        internal_next_state=`BGEU;
                        internal_alu_sel=`unsigned_comp;
                        internal_alu_data_in_sel<=8'd0;
                    end
                    // BLTU
                    3'b110: begin
                        internal_next_state=`BLTU;
                        internal_alu_sel=`unsigned_comp;
                        internal_alu_data_in_sel<=8'd0;
                    end
                    // BNE
                    3'b001: begin
                        internal_next_state=`BNE;
                        internal_alu_sel=`equal;
                        internal_alu_data_in_sel<=8'd0;
                    end
                    // BLT
                    3'b100: begin
                        internal_next_state=`BLT;
                        internal_alu_sel=`signed_comp;
                        internal_alu_data_in_sel<=8'd0;
                    end
                    default: internal_next_state=`fetch1;
                endcase
            end
            // 5個
            7'b0000011: begin
                case (opcode[14:12])
                    // LHU
                    3'b101: begin
                        internal_next_state=`LHU;
                    end
                    // LBU
                    3'b100: begin
                        internal_next_state=`LBU;
                    end
                    // LB
                    3'b000: begin
                        internal_next_state=`LB;
                    end
                    // LH
                    3'b001: begin
                        internal_next_state=`LH;
                    end
                    // LW
                    3'b010: begin
                        internal_next_state=`LW;
                    end
                    default: internal_next_state=`fetch1;
                endcase
            end
            // 1個
            7'b0001111: begin
                // FENCE
                internal_next_state=`FENCE;
            end
            // 1個
            7'b0010111: begin
                // AUIPC
                internal_next_state=`AUIPC;
            end
            // 3個
            7'b0100011: begin
                case (opcode[14:12])
                    // SW
                    3'b010: begin
                        internal_next_state=`SW;
                    end
                    // SB
                    3'b000: begin
                        internal_next_state=`SB;
                    end
                    // SH
                    3'b001: begin
                        internal_next_state=`SH;
                    end
                    default: internal_next_state=`fetch1;
                endcase
            end
            // 1個
            7'b0110111: begin
                // LUI
                internal_next_state=`LUI;
            end
            // 2個
            7'b1110011: begin
                case (opcode[31:20])
                    // ECALL
                    12'b000000000000: begin
                        internal_next_state=`ECALL;
                    end
                    // EBREAK
                    12'b000000000001: begin
                        internal_next_state=`EBREAK;
                    end
                    default: internal_next_state=`fetch1;
                endcase
            end
            // 1個
            7'b1100111: begin
                // JALR
                internal_next_state=`JALR;
            end
            // 1個
            7'b1101111: begin
                // JAL
                internal_next_state=`JAL;
            end
            default: internal_next_state=`fetch1;
        endcase
    end
endmodule