///////////////////////////////////////////////////////////////
// testbench
//
// Expect simulator to print "Simulation succeeded"
// when the value 25 (0x19) is written to address 100 (0x64)
///////////////////////////////////////////////////////////////
module testbench();

  logic        clk;
  logic        reset;
  logic [31:0] PC;
  logic [31:0] Instr;
  logic [3:0] state;
  logic [31:0] SrcA;
  logic [31:0] SrcB;
  logic [31:0] ALUResult;
  logic [31:0] DataAdr;
  logic [31:0] WriteData;
  logic        MemWrite;
  logic [31:0] PCNext;
  logic [31:0] ImmExt;
  logic [31:0] Result;
  logic [31:0] hash;
  // instantiate device to be tested
  top dut(clk, reset, WriteData, DataAdr, MemWrite,PCNext,Instr,PC,ALUResult,ImmExt,SrcA,SrcB,Result,state);
  
  // initialize test
  initial
    begin
      hash <= 0;
      reset <= 1; # 22; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always @(negedge clk)
    begin
      if(MemWrite) begin
        if(DataAdr === 100 & WriteData === 25) begin
          $display("Simulation succeeded");
 	   	  $display("hash = %h", hash);
          $stop;
        end else if (DataAdr !== 96) begin
          $display("Simulation failed");
          $stop;
        end
      end
    end

  // Make 32-bit hash of instruction, PC, ALU
  always @(negedge clk)
    if (~reset) begin
      hash = hash ^ dut.rvmulti.dp.Instr ^ dut.rvmulti.dp.PC;
      if (MemWrite) hash = hash ^ WriteData;
      hash = {hash[30:0], hash[9] ^ hash[29] ^ hash[30] ^ hash[31]};
    end

endmodule