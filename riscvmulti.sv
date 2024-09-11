///////////////////////////////////////////////////////////////
// riscvmulti
//
// Multicycle RISC-V microprocessor
///////////////////////////////////////////////////////////////

module riscvmulti(input logic clk, reset,
					input logic [31:0] ReadData,
						output logic MemWrite,
						output logic [31:0] ADR, WriteData,
						output logic [31:0] PCNext,
output logic [31:0] Instr,PC,ALUResult,
output logic [31:0] ImmExt,
output logic [31:0] SrcA,
output logic [31:0] SrcB,
output logic [31:0] Result,
output logic [3:0] state
);	
logic Zero,SF;		
logic RegWrite, AdrSrc,IRWrite,PCWrite;
logic [2:0] ResultSrc,ImmSrc,ALUSrcA,ALUSrcB;
logic [2:0] ALUControl;
	controller c(clk, reset , Instr[6:0], Instr[14:12], Instr[30], Zero,SF, ImmSrc, ALUSrcA,
	ALUSrcB,ResultSrc,AdrSrc,ALUControl,IRWrite,PCWrite,RegWrite,MemWrite,state);

	datapath dp(clk, reset,ResultSrc,ALUSrcA,ALUSrcB,RegWrite,PCWrite,IRWrite,ImmSrc,
	ALUControl,AdrSrc,ReadData,Instr,ADR,
		PC,Zero,SF,ALUResult,WriteData,PCNext,ImmExt,SrcA,SrcB,Result);

endmodule
