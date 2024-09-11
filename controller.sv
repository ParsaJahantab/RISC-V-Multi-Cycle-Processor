///////////////////////////////////////////////////////////////
//control
module controller(input  logic       clk,
                  input  logic       reset,  
                  input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,SF,
                  output logic [2:0] ImmSrc,
                  output logic [1:0] ALUSrcA, ALUSrcB,
                  output logic [1:0] ResultSrc, 
                  output logic       AdrSrc,
                  output logic [2:0] ALUControl,
                  output logic       IRWrite, PCWrite, 
                  output logic       RegWrite, MemWrite,
				  output logic [3:0] state);
logic[1:0] ALUOp;
logic [3:0] next_state;
logic PCUpdate;
logic BranchEQ,BranchNE,BranchLT;

MainFSM MainFSM(clk,reset,op,funct3,ALUSrcA,ALUSrcB,ResultSrc,ALUOp,AdrSrc,IRWrite,RegWrite,MemWrite,PCUpdate,BranchEQ,BranchNE,BranchLT,state,next_state);
ALUDecoder aludecoder(ALUOp,op,funct3,funct7b5,ALUControl);
InstrDecoder instrdecoder(op,ImmSrc);
assign PCWrite=(PCUpdate|((BranchEQ & Zero)|(BranchNE & !Zero))|(BranchLT & SF));
endmodule