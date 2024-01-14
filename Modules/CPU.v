`include "IF.v"
`include "ID.v"
`include "EX.v"
`include "ME.v"
`include "WB.v"
`timescale 100fs/100fs
module ClockGeneration(
    input Clock);
endmodule

module CPU(input Clock);

// wire for IF
wire [2:0]PCSrcD;
wire [31:0] PCBranchD, PCnormalF, InstructionF, PCJumpD, PCJrD;

// wire for ID
wire RegDstD, ALUSrcD, ALUSrcDs, MemReadD, MemWriteD, RegWriteD, MemtoRegD, RegWriteW, lw_hazard;
wire [3:0] ALUControlD;
wire [4:0] rtD, rdD, saD, rsD, WriteRegW;
wire signed [31:0] data1D, data2D, immExtendD, PCnormalD, InstructionD, ResultW;

// wire for EX
wire [3:0] ALUControlE;
wire ALUSrcE, ALUSrcEs, RegDstE, RegWriteE, MemtoRegE, MemWriteE, BranchE, ZeroE;
wire signed [31:0] data1E, data2E, immExtendE, PCnormalE, ALUResultE, WriteDataE, PCBranchE;
wire [4:0] rtE, rdE, saE, WriteRegE, rsE;

// wire for ME
wire signed [31:0] ALUResultM, WriteDataM, ReadDataM;
wire [4:0] WriteRegM;
wire MemWriteM, BranchM, ZeroM, RegWriteM, MemtoRegM;

// wire for WB
wire [31:0] ALUResultW, ReadDataW;
wire MemtoRegW;

IF u_IF(
    .PCBranchD    (PCBranchD    ),
    .PCJumpD      (PCJumpD      ),
    .PCJrD        (PCJrD        ),
    .Clock        (Clock        ),
    .lw_hazard    (lw_hazard    ),
    .PCSrcD       (PCSrcD       ),
    .PCnormalF    (PCnormalF    ),
    .InstructionF (InstructionF )
);

IFID_Register u_IFID_Register(
    .PCnormalF    (PCnormalF    ),
    .InstructionF (InstructionF ),
    .Clock        (Clock        ),
    .lw_hazard    (lw_hazard    ),
    .PCSrcD       (PCSrcD       ),
    .PCnormalD    (PCnormalD    ),
    .InstructionD (InstructionD )
);

ID u_ID(
    .InstructionD (InstructionD ),
    .ResultW      (ResultW      ),
    .WriteRegW    (WriteRegW    ),
    .rtE          (rtE          ),
    .WriteRegE    (WriteRegE    ),
    .WriteRegM    (WriteRegM    ),
    .RegWriteW    (RegWriteW    ),
    .Clock        (Clock        ),
    .MemReadE     (MemReadE     ),
    .RegWriteE    (RegWriteE    ),
    .RegWriteM    (RegWriteM    ),
    .PCnormalD    (PCnormalD    ),
    .ALUResultE   (ALUResultE   ),
    .ReadDataM    (ReadDataM    ),
    .RegDstD      (RegDstD      ),
    .ALUSrcD      (ALUSrcD      ),
    .ALUSrcDs     (ALUSrcDs     ),
    .MemReadD     (MemReadD     ),
    .MemWriteD    (MemWriteD    ),
    .RegWriteD    (RegWriteD    ),
    .MemtoRegD    (MemtoRegD    ),
    .lw_hazard    (lw_hazard    ),
    .ALUControlD  (ALUControlD  ),
    .data1D       (data1D       ),
    .data2D       (data2D       ),
    .rtD          (rtD          ),
    .rdD          (rdD          ),
    .saD          (saD          ),
    .rsD          (rsD          ),
    .PCSrcD       (PCSrcD       ),
    .immExtendD   (immExtendD   ),
    .PCBranchD    (PCBranchD    ),
    .PCJumpD      (PCJumpD      ),
    .PCJrD        (PCJrD        )
);


IDEX_Register u_IDEX_Register(
    .Clock       (Clock       ),
    .RegDstD     (RegDstD     ),
    .ALUSrcD     (ALUSrcD     ),
    .ALUSrcDs    (ALUSrcDs    ),
    .MemReadD    (MemReadD    ),
    .MemWriteD   (MemWriteD   ),
    .RegWriteD   (RegWriteD   ),
    .MemtoRegD   (MemtoRegD   ),
    .ALUControlD (ALUControlD ),
    .data1D      (data1D      ),
    .data2D      (data2D      ),
    .immExtendD  (immExtendD  ),
    .rtD         (rtD         ),
    .rdD         (rdD         ),
    .saD         (saD         ),
    .rsD         (rsD         ),
    .RegDstE     (RegDstE     ),
    .ALUSrcE     (ALUSrcE     ),
    .ALUSrcEs    (ALUSrcEs    ),
    .MemReadE    (MemReadE    ),
    .MemWriteE   (MemWriteE   ),
    .RegWriteE   (RegWriteE   ),
    .MemtoRegE   (MemtoRegE   ),
    .ALUControlE (ALUControlE ),
    .data1E      (data1E      ),
    .data2E      (data2E      ),
    .immExtendE  (immExtendE  ),
    .rtE         (rtE         ),
    .rdE         (rdE         ),
    .saE         (saE         ),
    .rsE         (rsE         )
);

EX u_EX(
    .ALUControlE (ALUControlE ),
    .ALUSrcE     (ALUSrcE     ),
    .ALUSrcEs    (ALUSrcEs    ),
    .RegDstE     (RegDstE     ),
    .RegWriteM   (RegWriteM   ),
    .RegWriteW   (RegWriteW   ),
    .data1E      (data1E      ),
    .data2E      (data2E      ),
    .immExtendE  (immExtendE  ),
    .ALUResultM  (ALUResultM  ),
    .ResultW     (ResultW     ),
    .rtE         (rtE         ),
    .rdE         (rdE         ),
    .saE         (saE         ),
    .rsE         (rsE         ),
    .WriteRegM   (WriteRegM   ),
    .WriteRegW   (WriteRegW   ),
    .ALUResultE  (ALUResultE  ),
    .WriteDataE  (WriteDataE  ),
    .WriteRegE   (WriteRegE   )
);

EXME_Register u_EXME_Register(
    .Clock      (Clock      ),
    .RegWriteE  (RegWriteE  ),
    .MemtoRegE  (MemtoRegE  ),
    .MemWriteE  (MemWriteE  ),
    .ALUResultE (ALUResultE ),
    .WriteDataE (WriteDataE ),
    .WriteRegE  (WriteRegE  ),
    .RegWriteM  (RegWriteM  ),
    .MemtoRegM  (MemtoRegM  ),
    .MemWriteM  (MemWriteM  ),
    .ALUResultM (ALUResultM ),
    .WriteDataM (WriteDataM ),
    .WriteRegM  (WriteRegM  )
);

ME u_ME(
    .ALUResultM (ALUResultM ),
    .WriteDataM (WriteDataM ),
    .MemWriteM  (MemWriteM  ),
    .BranchM    (BranchM    ),
    .Clock      (Clock      ),
    .ReadDataM  (ReadDataM  )
);

MEWB_Register u_MEWB_Register(
    .Clock      (Clock      ),
    .RegWriteM  (RegWriteM  ),
    .MemtoRegM  (MemtoRegM  ),
    .ALUResultM (ALUResultM ),
    .ReadDataM  (ReadDataM  ),
    .WriteRegM  (WriteRegM  ),
    .RegWriteW  (RegWriteW  ),
    .MemtoRegW  (MemtoRegW  ),
    .ALUResultW (ALUResultW ),
    .ReadDataW  (ReadDataW  ),
    .WriteRegW  (WriteRegW  )
);

WB u_WB(
    .Clock      (Clock      ),
    .RegWriteW  (RegWriteW  ),
    .MemtoRegW  (MemtoRegW  ),
    .ALUResultW (ALUResultW ),
    .ReadDataW  (ReadDataW  ),
    .WriteRegW  (WriteRegW  ),
    .ResultW (ResultW)
);

integer o, fd, Clock_Number=0;
// Record the Clock number
always @(posedge Clock) begin
    Clock_Number = Clock_Number + 1;
end

// When instruction code is ffff_ffff, we exit and write main memory data to RAM_Output.txt file.
always @(InstructionF) begin
    if (InstructionF == 32'b11111111111111111111111111111111) begin
    #8
    $display("Clock Number: ", Clock_Number);
    fd = $fopen("RAM_Output.txt","w");
    for (o = 0; o<512; o=o+1 ) begin
        $fdisplay(fd, "%b", u_CPU.u_ME.u_MainMemory.DATA_RAM[o]); 
    end
    $fclose(fd);
    $finish;  
    end
    
end

endmodule
