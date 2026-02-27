// メモリのサイズ
`define mem_size 8'hff

// Read/Writeイネーブル
`define read 1'b0
`define write 1'b1

// stateの状態
`define fetch1 8'd0
// 多分使わなくてもいい
// `define fetch2 8'd1
`define decode 8'd2

`define LUI 8'd3
`define AUIPC 8'd4
`define JAL 8'd5
`define JALR 8'd6
`define BEQ 8'd7
`define BNE 8'd8
`define BLT 8'd9
`define BGE 8'd10
`define BLTU 8'd11
`define BGEU 8'd12
`define LB 8'd13
`define LH 8'd14
`define LW 8'd15
`define LBU 8'd16
`define LHU 8'd17
`define SB 8'd18
`define SH 8'd19
`define SW 8'd20
`define ADDI 8'd21
`define SLTI 8'd22
`define SLTIU 8'd23
`define XORI 8'd24
`define ORI 8'd25
`define ANDI 8'd26
`define SLLI 8'd27
`define SRLI 8'd28
`define SRAI 8'd29
`define ADD 8'd30
`define SUB 8'd31
`define SLL 8'd32
`define SLT 8'd33
`define SLTU 8'd34
`define XOR 8'd35
`define SRL 8'd36
`define SRA 8'd37
`define OR 8'd38
`define AND 8'd39
`define FENCE 8'd40
`define ECALL 8'd41
`define EBREAK 8'd42
`define MUL 8'd43
`define MULH 8'd44
`define MULHSU 8'd45
`define MULHU 8'd46
`define DIV 8'd47
`define DIVU 8'd48
`define REM 8'd49
`define REMU 8'd50
`define LW2 8'd51

// ALUのセレクト
`define equal 8'd0
`define signed_comp 8'd1
`define unsigned_comp 8'd2
`define add_alu 8'd3
`define xor_alu 8'd4
`define or_alu 8'd5
`define and_alu 8'd6
`define left_shift_alu 8'd7
`define right_logical_shift_alu 8'd8
`define right_arithmetic_shift_alu 8'd9
// singed*singedでss
`define mul_ss_alu 8'd10
// signed*unsignedでsu
`define mul_su_alu 8'd11