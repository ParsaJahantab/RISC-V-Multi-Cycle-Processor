
///////////////////////////////////////////////////////////////
// top
//
// Instantiates multicycle RISC-V processor and memory
///////////////////////////////////////////////////////////////
module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite,
						output logic [31:0] PCNext,
output logic [31:0] Instr,PC,ALUResult,
output logic [31:0] ImmExt,
output logic [31:0] SrcA,
output logic [31:0] SrcB,
output logic [31:0] Result,
output logic [3:0] state
);

  logic [31:0] ReadData;
  
  // instantiate processor and memories
  riscvmulti rvmulti(clk, reset,ReadData,MemWrite,DataAdr, WriteData,PCNext,Instr,PC,ALUResult,ImmExt,SrcA,SrcB,Result,state);
  mem mem(clk, MemWrite, DataAdr, WriteData, ReadData);
endmodule