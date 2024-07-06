`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: alu_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`define RTYPE_OPCODE    6'b000000
// Loads
`define LB_OPCODE       6'b100000
`define LH_OPCODE       6'b100001
`define LHU_OPCODE      6'b100010
`define LW_OPCODE       6'b100011
`define LWU_OPCODE      6'b100100
`define LBU_OPCODE      6'b100101
// Stores
`define SB_OPCODE       6'b101000
`define SH_OPCODE       6'b101001
`define SW_OPCODE       6'b101011

`define ADDI_OPCODE     6'b001000
`define ANDI_OPCODE     6'b001100
`define ORI_OPCODE      6'b001101
`define XORI_OPCODE     6'b001110
`define BEQ_OPCODE      6'b000100

`define BNE_OPCODE      6'b000101
`define SLTI_OPCODE     6'b001010
`define LUI_OPCODE      6'b001111
`define JAL_OPCODE      6'b000011
// Function codes
`define SLL_FCODE       6'b000000
`define SRL_FCODE       6'b000010
`define SRA_FCODE       6'b000011
`define SLLV_FCODE      6'b000100
`define SRLV_FCODE      6'b000110
`define SRAV_FCODE      6'b000111
`define JALR_FCODE      6'b001001
`define ADD_FCODE       6'b100000
`define ADDU_FCODE      6'b100001
`define SUB_FCODE       6'b100010
`define SUBU_FCODE      6'b100011
`define AND_FCODE       6'b100100
`define OR_FCODE        6'b100101
`define XOR_FCODE       6'b100110
`define NOR_FCODE       6'b100111
`define SLT_FCODE       6'b101010





module alu_control#(
        parameter WIDTH_FCODE = 6,
        parameter WIDTH_OPCODE = 6,
        parameter WIDTH_ALU_CTRLI = 4
        
    )
    (
        input [WIDTH_FCODE-1 : 0] i_funct_code,         // Codigo de funcion para instrucciones tipo R
        input [WIDTH_OPCODE-1 : 0] i_op_code,           // opcode
        output reg [WIDTH_ALU_CTRLI-1 : 0] o_alu_ctrl,   // Senial que indica a la ALU que tipo de operacion ejecutar
        output reg o_shamt_ctrl,                        // 0 -> shamt  1 -> data_a
        output reg o_last_register_ctrl                 // Senial que selecciona registro last_register para que se guarde el PC
    );
    
   
    always@(*) begin
        // Inicializacion para que no se produzca un inferred latch
        o_alu_ctrl = 4'b0000;
        o_shamt_ctrl = 1'b0;
        o_last_register_ctrl = 1'b0;

        case(i_op_code)
            `RTYPE_OPCODE: begin
                case(i_funct_code)
                        // R type
                        `SLL_FCODE   : begin
                            o_alu_ctrl = 4'b1101;
                            o_shamt_ctrl = 1'b0;            // Shamt
                            o_last_register_ctrl = 1'b0;
                        end 
                        `SRL_FCODE   : begin
                            o_alu_ctrl = 4'b1110;
                            o_shamt_ctrl = 1'b0;            // Shamt
                            o_last_register_ctrl = 1'b0;
                        end
                        `SRA_FCODE   : begin
                            o_alu_ctrl = 4'b1111;
                            o_shamt_ctrl = 1'b0;            // Shamt
                            o_last_register_ctrl = 1'b0;
                        end
                        `SLLV_FCODE  : begin
                            o_alu_ctrl = 4'b1101;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `SRLV_FCODE  : begin
                            o_alu_ctrl = 4'b1110;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `SRAV_FCODE  : begin
                            o_alu_ctrl = 4'b1111;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `ADD_FCODE   : begin
                            o_alu_ctrl = 4'b0010;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `ADDU_FCODE  : begin
                            o_alu_ctrl = 4'b0010;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `SUB_FCODE   : begin
                            o_alu_ctrl = 4'b0110;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `SUBU_FCODE  : begin
                            o_alu_ctrl = 4'b0110;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `AND_FCODE   : begin
                            o_alu_ctrl = 4'b0000;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `OR_FCODE    : begin
                            o_alu_ctrl = 4'b0001;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `XOR_FCODE   : begin
                            o_alu_ctrl = 4'b0011;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `NOR_FCODE   : begin
                            o_alu_ctrl = 4'b1100;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `SLT_FCODE   : begin
                            o_alu_ctrl = 4'b0100;
                            o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                            o_last_register_ctrl = 1'b0;
                        end
                        `JALR_FCODE  : begin
                            o_alu_ctrl = 4'b1101;             //No usa la ALU
                            o_shamt_ctrl = 1'b0;            
                            o_last_register_ctrl = 1'b1;
                        end
                        default     : begin
                            o_alu_ctrl = o_alu_ctrl;
                        end                      
                endcase
            end
            // INSTRUCCION ITYPE
            // Todos los loads
            `LB_OPCODE, `LH_OPCODE, `LW_OPCODE,
            `LWU_OPCODE, `LBU_OPCODE, `LHU_OPCODE,
            // Todos los stores
            `SB_OPCODE, `SH_OPCODE, `SW_OPCODE
                : begin
                o_alu_ctrl = 4'b0010;  
                o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                o_last_register_ctrl = 1'b0;
            end
            `ADDI_OPCODE : begin
                o_alu_ctrl = 4'b0010;
                o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                o_last_register_ctrl = 1'b0;
            end
            `ANDI_OPCODE : begin
                o_alu_ctrl = 4'b0000;
                o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                o_last_register_ctrl = 1'b0;
            end
            `ORI_OPCODE  : begin
                o_alu_ctrl = 4'b0001;
                o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                o_last_register_ctrl = 1'b0;
            end
            `XORI_OPCODE : begin
                o_alu_ctrl = 4'b0011;
                o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                o_last_register_ctrl = 1'b0;
            end
            `LUI_OPCODE  : begin
                o_alu_ctrl = 4'b1001;
                o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                o_last_register_ctrl = 1'b0;
            end
            `SLTI_OPCODE : begin
                o_alu_ctrl = 4'b0100;
                o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                o_last_register_ctrl = 1'b0;
            end
            `BEQ_OPCODE  : begin
                o_alu_ctrl = 4'b0111; // NOT EQ
                o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                o_last_register_ctrl = 1'b0;
            end
            `BNE_OPCODE  : begin
                o_alu_ctrl = 4'b1000; // EQ
                o_shamt_ctrl = 1'b1;            //Elige data_a (rs)
                o_last_register_ctrl = 1'b0;
            end
            `JAL_OPCODE  : begin
                o_alu_ctrl = 4'b1101;
                o_shamt_ctrl = 1'b1;
                o_last_register_ctrl = 1'b1;
            end
            default     : begin
                o_alu_ctrl = o_alu_ctrl;
                o_shamt_ctrl = o_shamt_ctrl;
                o_last_register_ctrl = o_last_register_ctrl;
            end
        endcase
    end
    
endmodule