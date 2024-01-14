`timescale 100fs/100fs

module RegisterFiles(
    input [4:0] rsD, rtD, WriteRegW,//read register 1, read register2, write register 
    input signed[31:0] ResultW, PCnormalD, //The data
    input RegWriteW, Clock, JalD, 
    output reg signed[31:0] data1D, data2D
    );
    reg signed[31:0] register [31:0]; //32 registers

    integer i;
    // initialize all register to 0.
    initial begin
    for(i=0;i<32;i=i+1)begin
      register[i] = 0;
    end
    end

    //write the register when the rising edge and read data then
    always @(posedge Clock) begin
      #0.00001
        if (RegWriteW & WriteRegW!=0) register[WriteRegW] = $signed(ResultW);
        data1D = register[rsD];
        data2D = register[rtD];
    end
    // When we need jal, we need to write PCPlus4 to $ra.
    always @(JalD) begin
      if (JalD) register[31] = PCnormalD;
    end

endmodule

module Control(
    input [5:0] opcode, funcode,
    output reg RegDstD,ALUSrcD,MemReadD,MemWriteD,RegWriteD,MemtoRegD,ALUSrcDs,JumpD,JrD,JalD,
    output reg [1:0]BranchD,
    output reg [3:0] ALUControlD );
always @(opcode,funcode) begin
    case (opcode)
        6'b000000:begin
          RegDstD = 1;
          ALUSrcD = 0;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 1;
          MemtoRegD = 0;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
          case (funcode)
              6'b100000: ALUControlD = 4'b0010;// add
              6'b100010: ALUControlD = 4'b0110;// sub
              6'b100100: ALUControlD = 4'b0000;// and
              6'b100101: ALUControlD = 4'b0001;// or
              6'b101010: ALUControlD = 4'b0111;// slt
              6'b100001: ALUControlD = 4'b0010;// addu
              6'b100011: ALUControlD = 4'b0110;// subu
              6'b100111: ALUControlD = 4'b1100;// nor
              6'b100110: ALUControlD = 4'b0011;// xor
              6'b000000:begin
                ALUControlD = 4'b0100;// sll
                ALUSrcDs = 1;
              end 
              6'b000100: ALUControlD = 4'b0100;// sllv
              6'b000010:begin
                ALUControlD = 4'b0101;// srl
                ALUSrcDs = 1;
              end 
              6'b000110: ALUControlD = 4'b0101;// srlv
              6'b000011:begin
                ALUControlD = 4'b1000;// sra
                ALUSrcDs = 1;
              end 
              6'b000111: ALUControlD = 4'b1000;// srav       
              6'b001000: begin
                ALUControlD = 4'b0111;// jr
                JumpD = 0;
                JrD = 1; 
              end                
              default: ALUControlD = 0;// should not happen 
          endcase
        end

        6'b001000:begin// addi
          RegDstD = 0;
          ALUSrcD = 1;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 1;
          MemtoRegD = 0;
          ALUControlD = 4'b0010;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end 

        6'b001001:begin// addiu
          RegDstD = 0;
          ALUSrcD = 1;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 1;
          MemtoRegD = 0;
          ALUControlD = 4'b0010;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end 

        6'b001100:begin// andi
          RegDstD = 0;
          ALUSrcD = 1;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 1;
          MemtoRegD = 0;
          ALUControlD = 4'b0000;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end

        6'b001101:begin// ori
          RegDstD = 0;
          ALUSrcD = 1;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 1;
          MemtoRegD = 0;
          ALUControlD = 4'b0001;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end 

        6'b001110:begin// xori
          RegDstD = 0;
          ALUSrcD = 1;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 1;
          MemtoRegD = 0;
          ALUControlD = 4'b0011;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end 

        6'b000101:begin// bne
          RegDstD = 1;
          ALUSrcD = 0;
          ALUSrcDs = 0;
          BranchD = 2'b10;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 0;
          MemtoRegD = 0;
          ALUControlD = 4'b0010;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end 

        6'b000010:begin// j
          RegDstD = 0;
          ALUSrcD = 1;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 1;
          MemtoRegD = 0;
          ALUControlD = 4'b0010;
          JumpD = 1;
          JrD = 0;
          JalD = 0;
        end 

        6'b000011:begin// jar
          RegDstD = 0;
          ALUSrcD = 1;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 1;
          MemtoRegD = 0;
          ALUControlD = 4'b0010;
          JumpD = 0;
          JrD = 0;
          JalD = 1;
        end 

        6'b100011:begin// lw
          RegDstD = 0;
          ALUSrcD = 1;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 1;
          MemWriteD = 0;
          RegWriteD = 1;
          MemtoRegD = 1;
          ALUControlD = 4'b0010;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end

        6'b101011:begin// sw
          RegDstD = 1;
          ALUSrcD = 1;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 1;
          RegWriteD = 0;
          MemtoRegD = 0;
          ALUControlD = 4'b0010;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end

        6'b000100:begin// beq
          RegDstD = 1;
          ALUSrcD = 0;
          ALUSrcDs = 0;
          BranchD = 1;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 0;
          MemtoRegD = 0;
          ALUControlD = 4'b0110;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end

        default: begin// lw_hazard
          RegDstD = 0;
          ALUSrcD = 0;
          ALUSrcDs = 0;
          BranchD = 0;
          MemReadD = 0;
          MemWriteD = 0;
          RegWriteD = 0;
          MemtoRegD = 0;
          ALUControlD = 4'b0000;
          JumpD = 0;
          JrD = 0;
          JalD = 0;
        end
    endcase
end

endmodule
