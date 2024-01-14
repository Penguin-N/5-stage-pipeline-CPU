module ALU(
    input signed [31:0] SrcAE, SrcBE,
    input [3:0] ALUControlE,
    output reg signed[31:0] ALUResultE
);

integer m;
// Execute different instruction according to ALUControl
always @(SrcAE, SrcBE, ALUControlE) begin
    case (ALUControlE)
        4'b0010: ALUResultE = SrcAE + SrcBE;// add, sw, lw, addu, addi, addiu
        4'b0110: begin
        ALUResultE = SrcAE - SrcBE;// sub, beq, bne, subu
        end
        4'b0000: ALUResultE = SrcAE & SrcBE;// and, andi
        4'b0001: ALUResultE = SrcAE | SrcBE;// or, ori
        4'b0111: begin  // slt
          if (SrcAE < SrcBE) begin
            ALUResultE = 1;
          end
          else ALUResultE = 0;
        end
        4'b1100: ALUResultE = ~(SrcAE | SrcBE);//nor
        4'b0011: ALUResultE = SrcAE ^ SrcBE;// xor, xori
        4'b0100: ALUResultE = SrcBE << SrcAE;// sll, sllv
        4'b0101: ALUResultE = SrcBE >> SrcAE;// srl, srlv
        4'b1000:begin // sra, srav
          ALUResultE = SrcBE >> SrcAE;
          if (SrcBE[31]==1) begin
              for (m = 0; m<SrcAE;m=m+1 ) begin
                  ALUResultE[31-m] = 1;
              end
          end
        end
        default: ALUResultE = 4'b0000;// should not happen
    endcase
end

endmodule

module EX(
    input [3:0] ALUControlE,
    input ALUSrcE, ALUSrcEs, RegDstE, RegWriteM, RegWriteW,  
    input [31:0] data1E, data2E, immExtendE,
    input signed [31:0] ALUResultM, ResultW,  
    input [4:0] rtE, rdE, saE, rsE, WriteRegM, WriteRegW, 
    output [31:0] ALUResultE, 
    output reg [31:0] WriteDataE, 
    output reg [4:0] WriteRegE
);

reg signed [31:0] SrcAE, SrcBE;
reg [31:0] data1,data2;
reg [1:0] ForwardA, ForwardB;

// MEM_to_EX hazard & WB_to_EX hazard test 
always @(rsE, rtE, WriteRegM, WriteRegW, RegWriteM, RegWriteW) begin
    if (RegWriteM & (WriteRegM==rsE) & (WriteRegM!=0)) begin
        ForwardA = 2'b10; // MEM_to_EX hazard
    end 
    else if (RegWriteW & (WriteRegW==rsE) & (WriteRegM!=0) & (~(RegWriteM & (WriteRegM==rsE) & (WriteRegM!=0)))) begin
        ForwardA = 2'b01; // WB_to_EX hazard. When both hazard happen want to use the most recent -> Let MEM forward.
    end
    else ForwardA = 2'b00;
    if (RegWriteM & (WriteRegM==rtE) & (WriteRegM!=0)) begin
        ForwardB = 2'b10;  // MEM_to_EX hazard
    end
    else if (RegWriteW & (WriteRegW==rtE) & (WriteRegM!=0) & (~(RegWriteM & (WriteRegM==rtE) & (WriteRegM!=0)))) begin
        ForwardB = 2'b01; // WB_to_EX hazard. When both hazard happen want to use the most recent -> Let MEM forward.
    end
    else ForwardB = 2'b00;
end

always @(ForwardA,ForwardB,data1E,data2E,ALUResultM,ResultW) begin
    case (ForwardA)
        2'b00: data1 = data1E;
        2'b10: data1 = ALUResultM;  // ME to EX hazard
        2'b01: data1 = ResultW;  // WB to EX hazard
        default: data1 = data1E; //should not happen
    endcase
    case (ForwardB)
        2'b00: data2 = data2E;
        2'b10: data2 = ALUResultM;  // ME to EX hazard
        2'b01: data2 = ResultW;  // WB to EX hazard
        default: data2 = data2E; //should not happen
    endcase
end

// Assign the value of ALU
always @(ALUControlE, ALUSrcE, RegDstE, data2, immExtendE, rtE, rdE, ALUSrcEs, data1, saE) begin
    if (ALUSrcEs == 0) begin
        SrcAE = $signed(data1);
    end
    else SrcAE = $signed(saE);
    if (ALUSrcE == 0) begin
        SrcBE = $signed(data2);
    end
    else SrcBE = $signed(immExtendE);
    
    if (RegDstE === 0) begin
        WriteRegE = rtE;
    end
    else WriteRegE = rdE;
    WriteDataE = data2;
end

// Connect to ALU
ALU u_ALU(
    .SrcAE       (SrcAE       ),
    .SrcBE       (SrcBE       ),
    .ALUControlE (ALUControlE ),
    .ALUResultE  (ALUResultE  )
);

endmodule

module EXME_Register(
    input Clock, RegWriteE, MemtoRegE, MemWriteE,
    input [31:0] ALUResultE, WriteDataE, 
    input [4:0] WriteRegE,
    output reg RegWriteM, MemtoRegM, MemWriteM, 
    output reg [31:0] ALUResultM, WriteDataM,
    output reg [4:0] WriteRegM
);

reg signed [31:0] ALUResult, WriteData; 
reg [4:0] WriteReg;
reg RegWrite, MemtoReg, MemWrite;

// Get the data from ID module
always @(RegWriteE, MemtoRegE, MemWriteE, ALUResultE, WriteDataE, WriteRegE) begin
    #0.00001
    RegWrite = RegWriteE;
    MemtoReg = MemtoRegE;
    MemWrite = MemWriteE;
    ALUResult = ALUResultE;
    WriteData = WriteDataE;
    WriteReg = WriteRegE;    
end

// Output data in register to ME module
always @(posedge Clock) begin
    RegWriteM = RegWrite;
    MemtoRegM = MemtoReg;
    MemWriteM = MemWrite;
    ALUResultM = ALUResult;
    WriteDataM = WriteData;
    WriteRegM = WriteReg;
end

endmodule