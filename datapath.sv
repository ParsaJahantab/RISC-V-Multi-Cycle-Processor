//data path
module datapath(input logic clk, reset,
					input logic [1:0] ResultSrc,
					input logic [1:0]ALUSrcA,ALUSrcB,
					input logic RegWrite, PCWrite,IRWrite,
					input logic [2:0] ImmSrc,
					input logic [2:0] ALUControl,
					input logic AdrSrc,
					input logic [31:0] ReadData,
					output logic [31:0] Instr,ADR,PC,
					output logic Zero,SF,
					output logic [31:0] ALUResult, WriteData,
					output logic [31:0] PCNext, ImmExt,SrcA,SrcB,Result);
	logic [31:0] ALUOut,OldPC,Data,A,RD1,RD2,WD3;
	assign PCNext=Result;
	assign WD3=Result;
	flopenr #(32) pc_ff(clk,reset,PCWrite,PCNext,PC); // pc flip flop
	mux2 #(32) pc_mux(PC,Result,AdrSrc,ADR); // memory address mux
	doubleflopenr #(32) instr_pc_ff(clk,1'b0,IRWrite,ReadData,PC,Instr,OldPC); // memory output doubleff
	flopenr #(32) data_ff(clk,reset,1'b1,ReadData,Data);// data ff
	RegFile rf(clk,RegWrite,Instr[19:15],Instr[24:20],Instr[11:7],Result,RD1,RD2);//register file
	Extend extend(Instr[31:7],ImmSrc,ImmExt);//extend unit
	doubleflopenr #(32) reg_ff(clk,reset,1'b1,RD1,RD2,A,WriteData);// register double ff
	mux4 #(32) srcA_mux(PC,OldPC,A,0,ALUSrcA,SrcA); // alu srca mux
	mux3 #(32) srcB_mux(WriteData,ImmExt,32'd4,ALUSrcB,SrcB);//alu srcb mux
	ALU alu(SrcA,SrcB,ALUControl,ALUResult,Zero,SF); // the alu
	flopenr #(32) alu_ff(clk,reset,1'b1,ALUResult,ALUOut); // alu result ff
	mux3 #(32) result_mux(ALUOut,Data,ALUResult,ResultSrc,Result); // overall result ff
endmodule