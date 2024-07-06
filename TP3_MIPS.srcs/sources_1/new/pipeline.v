`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: pipeline
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


module pipeline#(
        parameter WIDTH_PC = 32,
        parameter WIDTH_INSTRUCTION = 32,
        parameter WIDTH_DATA = 32,
        parameter WIDTH_REG = 5, 
        parameter WIDTH_ADDR = 32,
        parameter WIDTH_MEM_DEPTH = 6,
        parameter WIDTH_MEM_ADDR = 5,
        parameter WIDTH_OPCODE = 6,
        parameter WIDTH_MEM_WIDTH = 32,
        parameter WIDTH_SEL = 2
    )
    (
        input i_clock,
        input i_pc_enable,
        input i_pc_reset,
        input i_read_enable,
        input i_ID_reset,
        input i_reset_forward_stall,                            // FORWARDING UNIT
        input i_pipeline_enable,                                // DEBUG UNIT
        input i_MEM_debug_unit_flag,                            // Flag de read y addr provenientes de DEBUG UNIT
        input i_instru_mem_enable,                              // DEBUG UNIT
        input i_instru_mem_write_enable,                        // DEBUG UNIT
        input [WIDTH_MEM_WIDTH-1:0] i_instru_mem_data,          // DEBUG UNIT
        input [WIDTH_MEM_DEPTH-1:0] i_instru_mem_addr,          // DEBUG UNIT
        input i_bank_register_enable,                           // DEBUG UNIT
        input i_bank_register_read_enable,                      // DEBUG UNIT
        input [WIDTH_REG-1:0] i_bank_register_addr,             // DEBUG UNIT
        input i_mem_data_enable,                                // DEBUG UNIT
        input i_mem_data_read_enable,                           // DEBUG UNIT
        input [WIDTH_MEM_ADDR-1:0] i_mem_data_read_addr,        // DEBUG UNIT
        input i_unit_control_enable,                            // DEBUG UNIT

        output o_halt,                                          // DEBUG UNIT
        output [WIDTH_DATA-1:0] o_bank_register_data,            // DEBUG UNIT
        output [WIDTH_DATA-1:0] o_mem_data_data,                // DEBUG UNIT
        output [WIDTH_PC-1:0] o_last_pc                         // DEBUG UNIT
    );
    
    // IF to IF_ID
    wire [WIDTH_PC-1:0] IF_last_pc;
    wire [WIDTH_PC-1:0] i_IF_adder_result;
    wire [WIDTH_INSTRUCTION-1:0] i_IF_instruction;
    
    // IF_ID to ID
    wire [WIDTH_PC-1:0] o_ID_adder_result;
    wire [WIDTH_INSTRUCTION-1:0] o_ID_instruction;
    
    // ID to ID_EX
    wire ID_reg_dest;
    wire [WIDTH_OPCODE-1:0] ID_alu_op;
    wire ID_alu_src;
    wire ID_mem_read;
    wire ID_mem_write;
    wire ID_branch;
    wire ID_reg_write;
    wire ID_mem_to_reg;
    wire [WIDTH_DATA-1:0] ID_data_a;
    wire [WIDTH_DATA-1:0] ID_data_b;
    wire [WIDTH_PC-1:0] ID_immediate;
    wire [WIDTH_DATA-1:0] ID_shamt;
    wire [WIDTH_REG-1:0] ID_rt;
    wire [WIDTH_REG-1:0] ID_rd;
    wire [WIDTH_REG-1:0] ID_rs;
    wire [WIDTH_PC-1:0] ID_pc;
    wire ID_byte_enable;
    wire ID_halfword_enable;
    wire ID_word_enable;
    // from UNIT STALL
    wire ID_flush;
    wire en_IF_ID_reg;
    wire en_pc_stall;
    wire IF_flush;
    wire EX_flush;
    
    // ID to IF
    wire ID_signed;
    wire ID_jump;
    wire ID_halt;
    wire ID_jr_jalr;
    wire EX_jr_jalr;
    wire MEM_jr_jalr;
    wire [WIDTH_PC-1:0] ID_jump_addr;
    
    // ID_EX to EX
    wire EX_signed;
    wire EX_reg_dest;
    wire [WIDTH_OPCODE-1:0]        EX_alu_op;
    wire EX_alu_src;
    wire EX_mem_read;
    wire EX_mem_write;
    wire EX_branch;
    wire EX_reg_write;
    wire EX_mem_to_reg;
    wire [WIDTH_DATA-1:0] EX_data_a;
    wire [WIDTH_DATA-1:0] EX_data_b;
    wire [WIDTH_PC-1:0] EX_immediate;
    wire [WIDTH_DATA-1:0] EX_shamt;
    wire [WIDTH_REG-1:0] EX_rt;
    wire [WIDTH_REG-1:0] EX_rd;
    wire [WIDTH_REG-1:0] EX_rs;
    wire [WIDTH_PC-1:0] EX_pc;
    wire EX_byte_enable;
    wire EX_halfword_enable;
    wire EX_word_enable;
    wire EX_halt;
    wire EX_jump;
    
    // EX to EX_MEM
    wire o_EX_signed;
    wire o_EX_reg_write;     // Se les agrega el "o_" para diferenciar de
    wire o_EX_mem_to_reg;    // las se?ales de entrada, que son las mismas
    wire o_EX_mem_read;      // (declaradas en el bloque anterior)
    wire o_EX_mem_write;
    wire o_EX_branch;
    wire [WIDTH_PC-1:0] EX_branch_addr;
    wire EX_zero;
    wire [WIDTH_DATA-1:0] EX_alu_result;
    wire [WIDTH_DATA-1:0] o_EX_data_b;
    wire [WIDTH_REG-1:0] EX_selected_reg;
    wire o_EX_byte_enable;
    wire o_EX_halfword_enable;
    wire o_EX_word_enable;
    wire EX_last_register_ctrl;
    wire [WIDTH_PC-1:0] o_EX_pc;
    wire o_EX_halt;
    wire o_EX_jump;
    
    // EX_MEM to MEM
    wire MEM_signed;
    wire MEM_reg_write;
    wire MEM_mem_to_reg;
    wire MEM_mem_read;
    wire MEM_mem_write;
    wire MEM_branch;
    wire [WIDTH_PC-1:0] MEM_branch_addr;
    wire MEM_zero;
    wire [WIDTH_DATA-1:0] MEM_alu_result;
    wire [WIDTH_DATA-1:0] MEM_data_b;
    wire [WIDTH_REG-1:0] MEM_selected_reg;
    wire MEM_byte_enable;
    wire MEM_halfword_enable;
    wire MEM_word_enable;
    wire MEM_last_register_ctrl;
    wire [WIDTH_PC-1:0] MEM_pc;
    wire MEM_halt;
    wire MEM_jump;

    // MEM to MEM_WB
    wire [WIDTH_DATA-1:0] MEM_mem_data;
    wire [WIDTH_DATA-1:0] MEM_read_dm;
    wire [WIDTH_REG-1:0] o_MEM_selected_reg;
    wire [WIDTH_ADDR-1:0] o_MEM_alu_result;
    wire o_MEM_reg_write;
    wire o_MEM_mem_to_reg;
    wire o_MEM_last_register_ctrl;
    wire [WIDTH_PC-1:0] o_MEM_pc;
    wire o_MEM_halt;

    // MEM to IF
    wire [WIDTH_PC-1:0] o_MEM_branch_addr;
    wire MEM_branch_zero;

    // MEM_WB to WB
    wire WB_reg_write;
    wire WB_mem_to_reg;
    wire [WIDTH_DATA-1:0] WB_mem_data;
    wire [WIDTH_DATA-1:0] WB_alu_result;
    wire [WIDTH_REG-1:0] WB_selected_reg;
    wire WB_last_register_ctrl;
    wire [WIDTH_PC-1:0] WB_pc;

    // WB to ID
    wire o_WB_reg_write;
    wire [WIDTH_DATA-1:0] WB_selected_data;
    wire [WIDTH_REG-1:0] o_WB_selected_reg;
    wire MEM_WB_halt;
    wire WB_halt;

    // FORWADING UNIT
    wire [WIDTH_SEL-1:0] forwarding_a;
    wire [WIDTH_SEL-1:0] forwarding_b;
    wire [WIDTH_SEL-1:0] forwarding_mux;
    
    instruction_fetch instruction_fetch
    (
        .i_clock(i_clock),
        .i_branch(MEM_branch_zero),
        .i_j_jal(ID_jump),
        .i_jr_jalr(EX_jr_jalr),
        .i_pc_enable(i_pc_enable),
        .i_pc_reset(i_pc_reset),
        .i_read_enable(i_read_enable),
        .i_instru_mem_enable(i_instru_mem_enable),
        .i_write_enable(i_instru_mem_write_enable),
        .i_write_data(i_instru_mem_data),
        .i_write_addr(i_instru_mem_addr),
        .i_branch_addr(o_MEM_branch_addr),
        .i_jump_addr(ID_jump_addr),
        .i_data_last_register(EX_data_a),               // pasa por DECODE/EX PIPELINE
        .i_pc_stall(en_pc_stall),                       // STALL UNIT
        .o_last_pc(IF_last_pc),                         // DEBUG UNIT
        .o_adder_result(i_IF_adder_result),
        .o_instruction(i_IF_instruction)
    );
                        
    IF_ID IF_ID
    (
        .i_clock(i_clock),
        .i_reset(i_pc_reset),
        .i_pipeline_enable(i_pipeline_enable),
        .i_enable(en_IF_ID_reg),                    // STALL UNIT: 1 -> data hazard (stall) 0 -> !data_hazard
        .i_flush(IF_flush),                         // STALL UNIT: 1 -> control hazards     0 -> !control_hazard
        .i_adder_result(i_IF_adder_result),
        .i_instruction(i_IF_instruction),
        .o_adder_result(o_ID_adder_result),
        .o_instruction(o_ID_instruction)
    );
    
    instruction_decode instruction_decode
    (
        .i_clock(i_clock),
        .i_pipeline_enable(i_pipeline_enable),
        .i_reset(i_ID_reset),
        .i_rb_enable(i_bank_register_enable),                   // Debug Unit
        .i_rb_read_enable(i_bank_register_read_enable),         // Debug Unit
        .i_rb_read_addr(i_bank_register_addr),                  // Debug Unit
        .i_unit_control_enable(i_unit_control_enable),           // Debug Unit
        .i_inst(o_ID_instruction),
        .i_pc(o_ID_adder_result),
        .i_write_data(WB_selected_data),
        .i_write_reg(o_WB_selected_reg),
        .i_reg_write(o_WB_reg_write),
        .i_flush_unit_ctrl(ID_flush),
        .o_signed(ID_signed),
        .o_reg_dest(ID_reg_dest),
        .o_alu_op(ID_alu_op),
        .o_alu_src(ID_alu_src),
        .o_mem_read(ID_mem_read),
        .o_mem_write(ID_mem_write),
        .o_branch(ID_branch),
        .o_reg_write(ID_reg_write),
        .o_mem_to_reg(ID_mem_to_reg),
        .o_jump(ID_jump),
        .o_halt(ID_halt),
        .o_jr_jalr(ID_jr_jalr),
        .o_jump_addr(ID_jump_addr),
        .o_data_a(ID_data_a),
        .o_data_b(ID_data_b),
        .o_immediate(ID_immediate),
        .o_shamt(ID_shamt),
        .o_rt(ID_rt),
        .o_rd(ID_rd),
        .o_rs(ID_rs),
        .o_pc(ID_pc),
        .o_byte_enable(ID_byte_enable),
        .o_halfword_enable(ID_halfword_enable),
        .o_word_enable(ID_word_enable)
    );
                        
    ID_EX ID_EX
    (
        .i_clock(i_clock),
        .i_reset(i_pc_reset),
        .i_pipeline_enable(i_pipeline_enable),
        .i_signed(ID_signed),
        .i_reg_write(ID_reg_write),
        .i_mem_to_reg(ID_mem_to_reg),
        .i_mem_read(ID_mem_read),
        .i_mem_write(ID_mem_write),
        .i_branch(ID_branch),
        .i_alu_src(ID_alu_src),
        .i_reg_dest(ID_reg_dest),
        .i_alu_op(ID_alu_op),
        .i_pc(ID_pc),
        .i_data_a(ID_data_a),
        .i_data_b(ID_data_b),
        .i_immediate(ID_immediate),
        .i_shamt(ID_shamt),
        .i_rt(ID_rt),
        .i_rd(ID_rd),
        .i_rs(ID_rs),
        .i_byte_enable(ID_byte_enable),
        .i_halfword_enable(ID_halfword_enable),
        .i_word_enable(ID_word_enable),
        .i_halt(ID_halt),
        .i_jump(ID_jump),
        .i_jr_jalr(ID_jr_jalr),
        
        .o_signed(EX_signed),
        .o_reg_write(EX_reg_write),
        .o_mem_to_reg(EX_mem_to_reg),
        .o_mem_read(EX_mem_read),
        .o_mem_write(EX_mem_write),
        .o_branch(EX_branch),
        .o_alu_src(EX_alu_src),
        .o_reg_dest(EX_reg_dest),
        .o_alu_op(EX_alu_op),
        .o_pc(EX_pc),
        .o_data_a(EX_data_a),
        .o_data_b(EX_data_b),
        .o_immediate(EX_immediate),
        .o_shamt(EX_shamt),
        .o_rt(EX_rt),
        .o_rd(EX_rd),
        .o_rs(EX_rs),
        .o_byte_enable(EX_byte_enable),
        .o_halfword_enable(EX_halfword_enable),
        .o_word_enable(EX_word_enable),
        .o_halt(EX_halt),
        .o_jump(EX_jump),
        .o_jr_jalr(EX_jr_jalr)
    );
    
    execute execute
    (
        .i_data_A(EX_data_a),
        .i_data_B(EX_data_b),
        .i_op_code(EX_alu_op),
        .i_signed(EX_signed),
        .i_reg_write(EX_reg_write),
        .i_mem_to_reg(EX_mem_to_reg),
        .i_mem_read(EX_mem_read),
        .i_mem_write(EX_mem_write),
        .i_branch(EX_branch),
        .i_alu_src(EX_alu_src),
        .i_reg_dest(EX_reg_dest),
        .i_pc(EX_pc),
        .i_immediate(EX_immediate),
        .i_shamt(EX_shamt),
        .i_rt(EX_rt),
        .i_rd(EX_rd),
        .i_byte_enable(EX_byte_enable),
        .i_halfword_enable(EX_halfword_enable),
        .i_word_enable(EX_word_enable),
        .i_halt(EX_halt),
        .i_mem_fwd_data(MEM_alu_result),        // forwarded from MEM
        .i_wb_fwd_data(WB_selected_data),       // forwarded from WB
        .i_fwd_a(forwarding_a),                 // FORWARDING UNIT
        .i_fwd_b(forwarding_b),                 // FORWARDING UNIT
        .i_forwarding_mux(forwarding_mux),      // FORWARDING UNIT 
        .i_jump(EX_jump),
        
        .o_alu_result(EX_alu_result),
        .o_signed(o_EX_signed),
        .o_reg_write(o_EX_reg_write),
        .o_mem_to_reg(o_EX_mem_to_reg),
        .o_mem_read(o_EX_mem_read),
        .o_mem_write(o_EX_mem_write),
        .o_branch(o_EX_branch),
        .o_branch_addr(EX_branch_addr),
        .o_zero(EX_zero),
        .o_data_b(o_EX_data_b),
        .o_selected_reg(EX_selected_reg),
        .o_byte_enable(o_EX_byte_enable),
        .o_halfword_enable(o_EX_halfword_enable),
        .o_word_enable(o_EX_word_enable),
        .o_last_register_ctrl(EX_last_register_ctrl),
        .o_pc(o_EX_pc),
        .o_halt(o_EX_halt),
        .o_jump(o_EX_jump)
    );
                        
    EX_MEM EX_MEM
    (
        .i_clock(i_clock),
        .i_reset(i_pc_reset),
        .i_pipeline_enable(i_pipeline_enable),
        .i_flush(EX_flush),
        .i_signed(o_EX_signed),
        .i_reg_write(o_EX_reg_write),
        .i_mem_to_reg(o_EX_mem_to_reg),
        .i_mem_read(o_EX_mem_read),
        .i_mem_write(o_EX_mem_write),
        .i_branch(o_EX_branch),
        .i_branch_addr(EX_branch_addr),
        .i_zero(EX_zero),
        .i_alu_result(EX_alu_result),
        .i_data_b(o_EX_data_b),
        .i_selected_reg(EX_selected_reg),
        .i_byte_enable(o_EX_byte_enable),
        .i_halfword_enable(o_EX_halfword_enable),
        .i_word_enable(o_EX_word_enable),
        .i_last_register_ctrl(EX_last_register_ctrl),
        .i_pc(o_EX_pc),
        .i_halt(o_EX_halt),
        .i_jump(o_EX_jump),
        .i_jr_jalr(EX_jr_jalr),

        .o_signed(MEM_signed),
        .o_reg_write(MEM_reg_write),
        .o_mem_to_reg(MEM_mem_to_reg),
        .o_mem_read(MEM_mem_read),
        .o_mem_write(MEM_mem_write),
        .o_branch(MEM_branch),
        .o_branch_addr(MEM_branch_addr),
        .o_zero(MEM_zero),
        .o_alu_result(MEM_alu_result),
        .o_data_b(MEM_data_b),
        .o_selected_reg(MEM_selected_reg),
        .o_byte_enable(MEM_byte_enable),
        .o_halfword_enable(MEM_halfword_enable),
        .o_word_enable(MEM_word_enable),
        .o_last_register_ctrl(MEM_last_register_ctrl),
        .o_pc(MEM_pc),
        .o_halt(MEM_halt),
        .o_jump(MEM_jump),
        .o_jr_jalr(MEM_jr_jalr)
    );
                
    memory memory
    (
        .i_signed(MEM_signed),
        .i_complete_word(MEM_word_enable),
        .i_halfword_enable(MEM_halfword_enable),
        .i_byte_enable(MEM_byte_enable),
        .i_write_data(MEM_data_b),
        .i_clock(i_clock),
        .i_debug_unit_flag(i_MEM_debug_unit_flag),
        .i_memory_data_enable(i_mem_data_enable),               // Debug Unit
        .i_memory_data_read_enable(i_mem_data_read_enable),     // Debug Unit
        .i_memory_data_read_addr(i_mem_data_read_addr),         // Debug Unit
        .i_mem_read(MEM_mem_read),
        .i_mem_write(MEM_mem_write),
        .i_alu_result(MEM_alu_result),
        .i_branch(MEM_branch),
        .i_zero(MEM_zero),
        .i_branch_addr(MEM_branch_addr),
        .i_selected_reg(MEM_selected_reg),
        .i_reg_write(MEM_reg_write),
        .i_mem_to_reg(MEM_mem_to_reg),
        .i_last_register_ctrl(MEM_last_register_ctrl),
        .i_pc(MEM_pc),
        .i_halt(MEM_halt),
        
        .o_ctr_read_data(MEM_mem_data),
        .o_mem_read_value(MEM_read_dm),
        .o_alu_result(o_MEM_alu_result),
        .o_branch_zero(MEM_branch_zero),
        .o_branch_addr(o_MEM_branch_addr),
        .o_selected_reg(o_MEM_selected_reg),
        .o_reg_write(o_MEM_reg_write),
        .o_mem_to_reg(o_MEM_mem_to_reg),
        .o_last_register_ctrl(o_MEM_last_register_ctrl),
        .o_pc(o_MEM_pc),
        .o_halt(o_MEM_halt)
    );
                         
    MEM_WB MEM_WB
    (
        .i_clock(i_clock),
        .i_reset(i_pc_reset),
        .i_pipeline_enable(i_pipeline_enable),
        .i_reg_write(o_MEM_reg_write),
        .i_mem_to_reg(o_MEM_mem_to_reg),
        .i_mem_data(MEM_mem_data),
        .i_alu_result(o_MEM_alu_result),
        .i_selected_reg(o_MEM_selected_reg),
        .i_last_register_ctrl(o_MEM_last_register_ctrl),
        .i_pc(o_MEM_pc),
        .i_halt(MEM_halt),

        .o_reg_write(WB_reg_write),
        .o_mem_to_reg(WB_mem_to_reg),
        .o_mem_data(WB_mem_data),
        .o_alu_result(WB_alu_result),
        .o_selected_reg(WB_selected_reg),
        .o_last_register_ctrl(WB_last_register_ctrl),
        .o_pc(WB_pc),
        .o_halt(MEM_WB_halt)
    );
                          
    write_back write_back
    (
        .i_reg_write(WB_reg_write),
        .i_mem_to_reg(WB_mem_to_reg),
        .i_mem_data(WB_mem_data),
        .i_alu_result(WB_alu_result),
        .i_selected_reg(WB_selected_reg),
        .i_last_register_ctrl(WB_last_register_ctrl),
        .i_pc(WB_pc),
        .i_halt(MEM_WB_halt),
        
        .o_reg_write(o_WB_reg_write),
        .o_selected_data(WB_selected_data),
        .o_selected_reg(o_WB_selected_reg),
        .o_halt(WB_halt)
    );
  
    // Riesgos
    forwarding_unit forwarding_unit
    (
        .i_reset(i_reset_forward_stall),
        .i_EX_MEM_rd(MEM_selected_reg),
        .i_MEM_WB_rd(WB_selected_reg),
        .i_rt(EX_rt),                               // data_b
        .i_rs(EX_rs),                               // data_a
        .i_EX_mem_write(EX_mem_write),
        .i_MEM_write_reg(MEM_reg_write),
        .i_WB_write_reg(WB_reg_write),
        .o_forwarding_a(forwarding_a),              // to EX
        .o_forwarding_b(forwarding_b),              // to EX   
        .o_forwarding_mux(forwarding_mux)           // to EX   
    );  

    stall stall
    (
        .i_reset(i_reset_forward_stall),
        .i_MEM_halt(MEM_halt),
        .i_WB_halt(WB_halt),
        .i_branch_taken(MEM_branch_zero),           // from MEM
        .i_ID_EX_mem_read(EX_mem_read),
        .i_EX_jump(EX_jump || EX_jr_jalr),
        .i_MEM_jump(MEM_jump || MEM_jr_jalr),
        .i_ID_EX_rt(EX_rt),
        .i_IF_ID_rt(o_ID_instruction[20:16]),
        .i_IF_ID_rs(o_ID_instruction[25:21]),
        .o_flush_ID(ID_flush),
        .o_enable_IF_ID_reg(en_IF_ID_reg),
        .o_enable_pc(en_pc_stall),
        .o_flush_IF(IF_flush),
        .o_flush_EX(EX_flush)
    );

  assign o_bank_register_data = ID_data_a;           // to DEBUG UNIT
  assign o_mem_data_data = MEM_read_dm;             // to DEBUG UNIT
  assign o_last_pc = IF_last_pc;                    // to DEBUG UNIT
  assign o_halt = WB_halt;
    
endmodule
