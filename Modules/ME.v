`include "MainMemory.v"

module ME(
    input signed [31:0] ALUResultM, WriteDataM,
    input MemWriteM, BranchM, Clock,
    output signed [31:0] ReadDataM
);

wire RESET,ENABLE;
reg [64:0] EDIT_SERIAL;
wire [31:0] RealAddress;

assign RESET = 0;
assign ENABLE = 1;
assign RealAddress = (ALUResultM/4); // Real address conversion
always @(MemWriteM,ALUResultM,WriteDataM) begin // {1'b[is_edit], 32'b[write_add], 32'b[write_data]}
    EDIT_SERIAL <= {MemWriteM, RealAddress,WriteDataM}; 
end 

// Connect to Main memory
MainMemory u_MainMemory(
    .CLOCK         (Clock         ),
    .RESET         (RESET         ),
    .ENABLE        (ENABLE        ),
    .FETCH_ADDRESS (RealAddress ),
    .EDIT_SERIAL   (EDIT_SERIAL   ),
    .DATA          (ReadDataM        )
);

endmodule

module MEWB_Register(
    input Clock, RegWriteM, MemtoRegM,
    input signed [31:0] ALUResultM, ReadDataM,
    input [4:0] WriteRegM,
    output reg RegWriteW, MemtoRegW,
    output reg signed [31:0] ALUResultW, ReadDataW,
    output reg [4:0] WriteRegW    
);

reg RegWrite, MemtoReg;
reg signed [31:0] ALUResult, ReadData;
reg [4:0] WriteReg;

// Get the data from EX module
always @(RegWriteM, MemtoRegM, ALUResultM, ReadDataM, WriteRegM) begin
    #0.00001
    RegWrite = RegWriteM;
    MemtoReg = MemtoRegM;
    ALUResult = ALUResultM;
    ReadData = ReadDataM;
    WriteReg = WriteRegM;
end

// Output the data in registers to WB module
always @(posedge Clock) begin
    RegWriteW = RegWrite;
    MemtoRegW = MemtoReg;
    ALUResultW = ALUResult;
    ReadDataW = ReadData;
    WriteRegW = WriteReg;
end

endmodule