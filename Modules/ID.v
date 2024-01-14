`include "RegisterFiles.v"

module ID(
    input signed [31:0] InstructionD, ResultW,
    input [4:0] WriteRegW, rtE, WriteRegE, WriteRegM, 
    input RegWriteW, Clock, MemReadE, RegWriteE, RegWriteM, 
    input [31:0]  PCnormalD, ALUResultE, ReadDataM,
    output RegDstD, ALUSrcD, ALUSrcDs, MemReadD, MemWriteD, RegWriteD, MemtoRegD, lw_hazard, 
    output [3:0] ALUControlD,
    output signed [31:0] data1D, data2D,
    output [4:0] rtD, rdD, saD, rsD,
    output reg [2:0] PCSrcD,
    output reg signed[31:0] immExtendD,
    output reg [31:0] PCBranchD,
    output [31:0] PCJumpD, PCJrD
);

reg [5:0] opcode, funcode;
wire [4:0] rtD, rdD, rsD, saD;
wire signed [15:0] immD;
wire JrD, JumpD, JalD;
wire [1:0] BranchD;
wire [25:0] target;
reg [31:0] PCJrD;
reg lw_hazard;
reg [1:0] jr_hazard;
reg [2:0] beq_hazard; 
reg signed [31:0] beq_data1D, beq_data2D;
reg EqualD;

// Assign some wires and registers
always @(InstructionD,lw_hazard) begin
    opcode = InstructionD[31:26];
    funcode = InstructionD[5:0]; 
end

assign rtD = InstructionD[20:16];
assign rdD = InstructionD[15:11];
assign immD = $signed(InstructionD[15:0]);
assign saD = $signed(InstructionD[10:6]);
assign rsD = InstructionD[25:21];

// PC jump address synthesis
assign target = (InstructionD[25:0] << 2);
assign PCJumpD = {PCnormalD[31:28],target};

initial begin
    lw_hazard = 0;
end

// When there is a lw hazard, we need to insert a NOP. ( Set all signals in control to 0 )
always @(rtD, rsD, MemReadE, rtE) begin
    if (MemReadE & ((rtE==rsD)|(rtE==rtD))) begin // lw hazard test
        lw_hazard = 1;
        opcode = 6'b111111;
        funcode = 6'b111111;
    end
    else lw_hazard = 0;
end

// Connect to the control unit
Control u_Control(
    .opcode      (opcode      ),
    .funcode     (funcode     ),
    .RegDstD     (RegDstD     ),
    .ALUSrcD     (ALUSrcD     ),
    .MemReadD    (MemReadD    ),
    .MemWriteD   (MemWriteD   ),
    .RegWriteD   (RegWriteD   ),
    .MemtoRegD   (MemtoRegD   ),
    .ALUSrcDs    (ALUSrcDs    ),
    .JumpD       (JumpD       ),
    .JrD         (JrD         ),
    .JalD        (JalD        ),
    .BranchD     (BranchD     ),
    .ALUControlD (ALUControlD )
); 

// Connect to Register Files
RegisterFiles u_RegisterFiles(
    .rsD       (rsD       ),
    .rtD       (rtD       ),
    .WriteRegW (WriteRegW ),
    .ResultW   (ResultW   ),
    .PCnormalD (PCnormalD ),
    .RegWriteW (RegWriteW ),
    .Clock     (Clock     ),
    .JalD      (JalD      ),
    .data1D    (data1D    ),
    .data2D    (data2D    )
);


// Get the value of PC Src to obtain PC address in different situations
wire [5:0] PCAdd_Con = {JalD,JumpD,JrD,EqualD,BranchD};
always @(PCAdd_Con) begin
    case (PCAdd_Con)
        6'b000000: PCSrcD = 3'b000; // PCnormalD
        6'b000101: PCSrcD = 3'b001; // PCBranchD beq
        6'b000010: PCSrcD = 3'b001; // PCBranchD bne
        6'b010000: PCSrcD = 3'b010; // PCJumpD j
        6'b010100: PCSrcD = 3'b010; // PCJumpD j
        6'b001000: PCSrcD = 3'b011; // PCJrD jr
        6'b001100: PCSrcD = 3'b011; // PCJrD jr
        6'b100000: PCSrcD = 3'b100; // PCJumpD jal
        6'b100100: PCSrcD = 3'b100; // PCJumpD jal
        default: PCSrcD = 0;
    endcase
end

// Jr hazard test
always @(JrD, rsD, WriteRegE, RegWriteE, WriteRegM, RegWriteM) begin
    if ((JrD==1) & (RegWriteE==1) & (rsD==WriteRegE)) begin
        jr_hazard = 2'b01; // jr hazard for EX & ID
    end
    else if ((JrD==1) & (RegWriteM==1) & (rsD==WriteRegM)) begin
        jr_hazard = 2'b10; // jr hazard for ME & ID (lw)
    end
    else jr_hazard = 0;
end

// jr hazard solve
always @(jr_hazard, data1D, ALUResultE, ReadDataM) begin
    if (jr_hazard==2'b01) begin
        PCJrD = ALUResultE; // jr hazard for EX & ID
    end
    else if (jr_hazard==2'b10) begin
        PCJrD = ReadDataM; // jr hazard for ME & ID (lw)
    end
    else PCJrD = data1D;
end

// beq/bne hazard test
always @(rsD, rtD, WriteRegE, RegWriteE, BranchD, WriteRegM, RegWriteM) begin
    if ((RegWriteE==1) & (WriteRegE==rsD) & (BranchD!=0)) begin
        beq_hazard = 3'b001; // beq_hazard for EX & ID 
    end
    else if ((RegWriteE==1) & (WriteRegE==rtD) & (BranchD!=0)) begin
        beq_hazard = 3'b010; // beq_hazard for EX & ID
    end
    else if ((RegWriteM==1) & (WriteRegM==rsD) & (BranchD!=0)) begin
        beq_hazard = 3'b011; // beq_hazard for ME & ID
    end
    else if ((RegWriteM==1) & (WriteRegM==rtD) & (BranchD!=0)) begin
        beq_hazard = 3'b100; // beq_hazard for ME & ID
    end
    else beq_hazard = 0;
end

// beq/bne hazard solve
always @(data1D, data2D, beq_hazard, ALUResultE, ReadDataM) begin
    if (beq_hazard==0) begin
        beq_data1D = data1D;
        beq_data2D = data2D;
    end
    else if (beq_hazard==3'b001) begin // beq_hazard for EX & ID
        beq_data1D = ALUResultE; 
        beq_data2D = data2D;
    end
    else if (beq_hazard==3'b010) begin // beq_hazard for EX & ID
        beq_data1D = data1D;
        beq_data2D = ALUResultE;
    end
    else if (beq_hazard==3'b011) begin // beq_hazard for ME & ID
        beq_data1D = ReadDataM;
        beq_data2D = data2D;
    end
    else if (beq_hazard==3'b100) begin // beq_hazard for ME & ID
        beq_data1D = data1D;
        beq_data2D = ReadDataM;
    end
end

// Used to beq/bne test
always @(beq_data1D, beq_data2D) begin
    if (beq_data1D == beq_data2D) begin
        EqualD = 1;
    end
    else EqualD = 0;
end

always @(opcode,funcode,immD) begin
    if (opcode==6'b001100 | opcode==6'b001101 |opcode==6'b001110)begin // andi, ori, xori zero_extended
      immExtendD = $unsigned(immD); 
    end
    else begin
      immExtendD = $signed(immD); // others signed_extended
      PCBranchD = (immExtendD << 2) + PCnormalD;
    end
end

endmodule

module IDEX_Register(
    input Clock,
    input signed RegDstD, ALUSrcD, ALUSrcDs, MemReadD, MemWriteD, RegWriteD, MemtoRegD,
    input [3:0] ALUControlD,
    input signed [31:0] data1D, data2D, immExtendD,  
    input [4:0] rtD, rdD, saD, rsD,
    output reg RegDstE, ALUSrcE, ALUSrcEs, MemReadE, MemWriteE, RegWriteE, MemtoRegE,
    output  reg [3:0] ALUControlE,
    output  reg signed[31:0] data1E, data2E, immExtendE,
    output reg [4:0] rtE, rdE, saE, rsE
);

reg RegDst, ALUSrc, ALUSrcs, MemRead, MemWrite, RegWrite, MemtoReg;
reg [3:0] ALUControl;
reg [4:0] rt, rd, sa, rs;
reg [31:0] data1, data2, immExtend, PCnormal;


// Get the data from ID module
always @(RegDstD, ALUSrcD, ALUSrcDs, MemReadD, MemWriteD, RegWriteD, MemtoRegD, ALUControlD, data1D, data2D, immExtendD, rtD, rdD, saD) begin
    RegDst = RegDstD;
    ALUSrc = ALUSrcD;
    ALUSrcs = ALUSrcDs;
    MemRead = MemReadD;
    MemWrite = MemWriteD;
    RegWrite = RegWriteD;
    MemtoReg = MemtoRegD;
    ALUControl = ALUControlD;
    data1 = data1D;
    data2 = data2D;
    immExtend = immExtendD;
    rt = rtD;
    rd = rdD;
    sa = saD;
    rs = rsD; 
end

// Output data from registers to EX module
always @(posedge Clock) begin
    RegDstE = RegDst;
    ALUSrcE = ALUSrc;
    ALUSrcEs = ALUSrcs;
    MemReadE = MemRead;
    MemWriteE = MemWrite;
    RegWriteE = RegWrite;
    MemtoRegE = MemtoReg;
    ALUControlE = ALUControl;
    data1E = data1;
    data2E = data2;
    immExtendE = immExtend;
    rtE = rt;
    rdE = rd;
    saE = sa;
    rsE = rs;
end

endmodule