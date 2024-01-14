module WB(
    input Clock, RegWriteW, MemtoRegW,
    input [31:0] ALUResultW, ReadDataW,
    input [4:0] WriteRegW,
    output reg signed[31:0] ResultW 
);

// Assign the data for ResultW, which is used to write back to Register File
always @(MemtoRegW,ALUResultW,ReadDataW) begin
    if (MemtoRegW==0) begin
        ResultW = $signed(ALUResultW);
    end
    else ResultW = $signed(ReadDataW);
end


endmodule