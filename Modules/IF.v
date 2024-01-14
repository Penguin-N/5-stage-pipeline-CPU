`include "InstructionRAM.v"

module IF(
    input [31:0] PCBranchD, PCJumpD, PCJrD,
    input Clock, lw_hazard, 
    input [2:0] PCSrcD,
    output reg [31:0] PCnormalF,
    output [31:0]  InstructionF
);

reg [31:0] PC, PCF, FETCH_ADDRESS;
wire RESET, ENABLE;

assign RESET = 0;
assign ENABLE = 1;

// We initialize PC as 0
initial begin
    PCnormalF = 0;
end

// When there is a lw_hazard, we need to re_execute the instruction.
always @(lw_hazard) begin
    if (lw_hazard) begin
        PCnormalF = PCnormalF - 4;
    end
end

// Choose the PC address in different situations
always @(PCSrcD,PCnormalF,PCBranchD, PCJrD, PCJumpD) begin
    #0.00001
    case (PCSrcD)
    3'b000: PC = PCnormalF; // a normal way
    3'b001: PC = PCBranchD; // beq/bne
    3'b010: PC = PCJumpD; // j
    3'b011: PC = PCJrD; // jr
    3'b100: PC = PCJumpD; // jal
    default: PC = PCnormalF;
    endcase     
end

// PC fetch and PC conversion
always @(posedge Clock) begin
    PCF = PC;
    PCnormalF = PCF + 4;
    FETCH_ADDRESS = PCF/4;
end

// Use Insturction RAM
InstructionRAM u_InstructionRAM(
    .CLOCK         (Clock        ),
    .RESET         (RESET         ),
    .ENABLE        (ENABLE        ),
    .FETCH_ADDRESS (FETCH_ADDRESS ),
    .DATA          (InstructionF          )
);


endmodule

module IFID_Register(
    input [31:0] PCnormalF,// PC + 4
    InstructionF,
    input Clock, lw_hazard, 
    input [2:0] PCSrcD, 
    output reg [31:0] PCnormalD, InstructionD);

reg [31:0] PCnormal, Instruction;

// Get the data from IF module.
always @(PCnormalF, InstructionF, lw_hazard) begin
    if (lw_hazard!=1) begin // When there is a lw hazard, we need re_execute the instruction behind lw
        PCnormal = PCnormalF;
        Instruction = InstructionF; 
    end
end

// Output the data in registers to ID module.
always @(posedge Clock) begin
    if (PCSrcD==3'b001 | PCSrcD==3'b010 | PCSrcD==3'b011 | PCSrcD == 3'b100) begin // branch, j, jr, jal need flush 
        PCnormal = 0;
        Instruction = 0;
    end
    PCnormalD = PCnormal;
    InstructionD = Instruction;   
end
endmodule
