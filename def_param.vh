// メモリのサイズ
`define mem_size 8'hff

// Read/Writeイネーブル
`define read 1'b0
`define write 1'b1

// stateの状態
`define fetch1 6'd0
// 多分使わなくてもいい
// `define fetch2 6'd1
`define decode 6'd2

`define LUI 6'd3
`define AUIPC 6'd4
`define JAL 6'd5
`define JALR 6'd6
`define BEQ 6'd7
`define BNE 6'd8
`define BLT 6'd9
`define BGE 6'd10
`define BLTU 6'd11
`define BGEU 6'd12
`define LB 6'd13
`define LH 6'd14
`define LW 6'd15
`define LBU 6'd16
`define LHU 6'd17
`define SB 6'd18
`define SH 6'd19
`define SW 6'd20
`define ADDI 6'd21
`define SLTI 6'd22
`define SLTIU 6'd23
`define XORI 6'd24
`define ORI 6'd25
`define ANDI 6'd26
`define SLLI 6'd27
`define SRLI 6'd28
`define SRAI 6'd29
`define ADD 6'd30
`define SUB 6'd31
`define SLL 6'd32
`define SLT 6'd33
`define SLTU 6'd34
`define XOR 6'd35
`define SRL 6'd36
`define SRA 6'd37
`define OR 6'd38
`define AND 6'd39
`define FENCE 6'd40
`define ECALL 6'd41
`define EBREAK 6'd42
`define MUL 6'd43
`define MULH 6'd44
`define MULHSU 6'd45
`define MULHU 6'd46
`define DIV 6'd47
`define DIVU 6'd48
`define REM 6'd49
`define REMU 6'd50
// 何だこれM拡張にもないし他にもない
// defineを生成するときにミスったか？
// `define LW2 6'd51

// ALUのセレクト
`define equal 4'd0
`define signed_comp 4'd1
`define unsigned_comp 4'd2
`define add_alu 4'd3
`define xor_alu 4'd4
`define or_alu 4'd5
`define and_alu 4'd6
`define left_shift_alu 4'd7
`define right_logical_shift_alu 4'd8
`define right_arithmetic_shift_alu 4'd9
// singed*singedでss
`define mul_ss_alu 4'd10
// signed*unsignedでsu
`define mul_su_alu 4'd11
// unsigned*unsignedでuu
`define mul_uu_alu 4'd12
`define signed_div_rem_alu 4'd13
`define unsigned_div_rem_alu 4'd14
