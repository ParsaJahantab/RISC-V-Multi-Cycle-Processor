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

///////////////////////////////////////////////////////////////
// mem
//
// Single-ported RAM with read and write ports
// Initialized with machine language program
///////////////////////////////////////////////////////////////

module mem(input  logic        clk, we,
           input  logic [31:0] a, wd,
           output logic [31:0] rd);

  logic [31:0] RAM[63:0];
  
  initial
      $readmemh("riscvtest.txt",RAM);

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule

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
module MainFSM(input  logic       clk,
                  input  logic       reset,  
                  input  logic [6:0] op,
						input  logic [2:0] funct3,
                  output logic [1:0] ALUSrcA, ALUSrcB,
                  output logic [1:0] ResultSrc,ALUOp,
                  output logic       AdrSrc,
                  output logic       IRWrite,
                  output logic       RegWrite, MemWrite,PCUpdate,BranchEQ,BranchNE,BranchLT,
				  output logic [3:0] state,
				  output logic [3:0] next_state);
always @(state)
	begin
		case(state)
			4'b0000://S0:Fetch
				begin
					PCUpdate<=1'b1;
					BranchEQ<=1'b0;
					BranchNE<=1'b0;
					BranchLT<=1'b0;
					AdrSrc<=1'b0;
					MemWrite<=1'b0;
					IRWrite<=1'b1;
					RegWrite<=1'b0;
					ALUSrcA<=2'b00;
					ALUSrcB<=2'b10;
					ALUOp<=2'b00;
					ResultSrc<=2'b10;
					next_state<=4'b0001;// next state is S1:decode
				end
			4'b0001://S1: Decode
				begin
					PCUpdate<=1'b0;
					BranchEQ<=1'b0;
					BranchNE<=1'b0;
					BranchLT<=1'b0;
					AdrSrc<=1'b0;
					MemWrite<=1'b0;
					IRWrite<=1'b0;
					RegWrite<=1'b0;
					ALUOp<=2'b00;
					ResultSrc<=2'b10;
					ALUSrcA<=2'b01;
					ALUSrcB<=2'b01;
					case(op)
						7'b0000011://this is the decode state of lw 
							begin
								next_state<=4'b0010;//the next state is S2:MemAdr
							end
						7'b0100011://this is the decode state of sw
							begin
								next_state<=4'b0010;//the next state is S2:MemAdr
							end
						7'b0110011: // decode state of R-type instructions
							begin
								next_state<=4'b0110;//next state is S6:ExecuteR the case for (R-type)
							end
						7'b0010011: // decode state of I-type ALU instructions
							begin
								next_state<=4'b1000;// next state is S8:ExecuteI the case for (I-type ALU)
							end
						7'b1101111:// decode state of JAL
							begin
								next_state<=4'b1001; // next state is S9:JAL the case for JAL
							end
						7'b1100011://decode state of BEQ,BNE,BLT
							begin
								next_state<=4'b1010;//next state is S10:BEQ the case for BEQ and BNE
							end
						7'b0010111://decode state of auipc
							begin
								next_state=4'b1011;//next state is S11:U-type
							end
						7'b0110111://decode state of lui
							begin
								next_state=4'b1011;//next state is S11:U-type
							end
					endcase
				end
			4'b0010:// S2:MemAdr for lw and sw
				begin
					PCUpdate<=1'b0;
					BranchEQ<=1'b0;
					BranchNE<=1'b0;
					BranchLT<=1'b0;
					AdrSrc<=1'b1;
					MemWrite<=1'b0;
					AdrSrc<=1'b0;
					MemWrite<=1'b0;
					IRWrite<=1'b0;
					RegWrite<=1'b0;
					ALUSrcA<=2'b10;
					ALUSrcB<=2'b01;
					ALUOp<=2'b00;
					ResultSrc<=2'b00;
					case(op)
						7'b0000011:// MemAdr state of lw
							begin
								next_state<=4'b0011; //next state is S3:MemRead
							end
						7'b0100011:// MemAdr state of sw
							begin
								next_state<=4'b0101; //next state is S5:MemWrite
							end
					endcase
				end
				4'b0011://S3:MemRead
					begin
						BranchNE<=1'b0;
						BranchLT<=1'b0;
						AdrSrc<=1'b1;
						MemWrite<=1'b0;
						IRWrite<=1'b0;
						RegWrite<=1'b0;
					   ALUSrcA<=2'b00;
						ALUSrcB<=2'b00;
						ALUOp<=2'b00;
						ResultSrc<=2'b00;
						next_state<=4'b0100;// next state is S4:MemWb
					end
				4'b0100: //S4:MemWB
					begin
						PCUpdate<=1'b0;
						BranchEQ<=1'b0;
						BranchNE<=1'b0;
						BranchLT<=1'b0;
						AdrSrc<=1'b0;
						MemWrite<=1'b0;
						IRWrite<=1'b0;
						RegWrite<=1'b1;
						ALUSrcA<=2'b00;
						ALUSrcB<=2'b00;
						ALUOp<=2'b00;
						ResultSrc<=2'b01;
						next_state<=4'b0000;// next state is fetch
					end
				4'b0101://S5:MemWrite
					begin
						PCUpdate<=1'b0;
						BranchEQ<=1'b0;
						BranchNE<=1'b0;
						BranchLT<=1'b0;
						AdrSrc<=1'b1;
						MemWrite<=1'b1;
						IRWrite<=1'b0;
						RegWrite<=1'b0;
						ALUSrcA<=2'b00;
						ALUSrcB<=2'b00;
						ALUOp<=2'b00;
						ResultSrc<=2'b00;
						next_state<=4'b0000;// next state is fetch
					end
				4'b0110://S6:ExecuteR
					begin
						PCUpdate<=1'b0;
						BranchEQ<=1'b0;
						BranchNE<=1'b0;
						BranchLT<=1'b0;
						AdrSrc<=1'b0;
					   MemWrite<=1'b0;
					   IRWrite<=1'b0;
					   RegWrite<=1'b0;
						ALUSrcA<=2'b10;
						ALUSrcB<=2'b00;
						ALUOp<=2'b10;
						ResultSrc<=2'b00;
						next_state<=4'b0111;//next state is S7:ALUWB
					end
				4'b0111://S7:ALUWB
					begin
						PCUpdate<=1'b0;
						BranchEQ<=1'b0;
						BranchNE<=1'b0;
						BranchLT<=1'b0;
						AdrSrc<=1'b0;
						MemWrite<=1'b0;
						IRWrite<=1'b0;
						RegWrite<=1'b1;
						ALUSrcA<=2'b10;
						ALUSrcB<=2'b01;
						ALUOp<=2'b00;
						ResultSrc<=2'b00;
						next_state<=4'b0000;//next state is S0:Fetch
					end
				4'b1000://S8:ExecuteI
					begin
						PCUpdate<=1'b0;
						BranchEQ<=1'b0;
						BranchNE<=1'b0;
						BranchLT<=1'b0;
						AdrSrc<=1'b0;
						MemWrite<=1'b0;
						IRWrite<=1'b0;
						RegWrite<=1'b0;
						ALUSrcA<=2'b10;
						ALUSrcB<=2'b01;
						ALUOp<=2'b10;
						ResultSrc<=2'b00;
						next_state<=4'b0111;//next state is S7:ALUWB
					end
				4'b1001://S9:JAL
					begin
						PCUpdate<=1'b1;
						BranchEQ<=1'b0;
						BranchNE<=1'b0;
						BranchLT<=1'b0;
						AdrSrc<=1'b0;
						MemWrite<=1'b0;
						IRWrite<=1'b0;
						RegWrite<=1'b0;
						ALUSrcA<=2'b01;
						ALUSrcB<=2'b10;
						ALUOp<=2'b00;
						ResultSrc<=2'b00;
						next_state<=4'b0111;//next state is S7:ALUWB
					end
				4'b1010://S10:BEQ and BNE
					begin
						case(funct3)
							3'b000://BEQ
								begin
									BranchEQ<=1'b1;
									BranchNE<=1'b0;
									BranchLT<=1'b0;
								end
							3'b001://BNE
								begin
									BranchEQ<=1'b0;
									BranchNE<=1'b1;
									BranchLT<=1'b0;
								end
							3'b100://BLT
								begin
									BranchEQ<=1'b0;
									BranchNE<=1'b0;
									BranchLT<=1'b1;
								end
						endcase
					   PCUpdate<=1'b0;
						AdrSrc<=1'b0;
						MemWrite<=1'b0;
						IRWrite<=1'b0;
						RegWrite<=1'b0;
						ALUSrcA<=2'b10;
						ALUSrcB<=2'b00;
						ALUOp<=2'b01;
						ResultSrc<=2'b00;
						next_state<=4'b0000;//next state is S0:Fetch
					end
				4'b1011://S11:U-type
					begin
						PCUpdate<=1'b0;
						BranchEQ<=1'b0;
						BranchNE<=1'b0;
						BranchLT<=1'b0;
						AdrSrc<=1'b0;
						MemWrite<=1'b0;
						IRWrite<=1'b0;
						RegWrite<=1'b0;
						case(op)
							7'b0010111://auipc
								begin
									ALUSrcA<=2'b01;
								end
							7'b0110111://lui
								begin
									ALUSrcA<=2'b11;
								end
						endcase
						ALUSrcB<=2'b01;
						ALUOp<=2'b00;
						ResultSrc<=2'b00;
						next_state<=4'b0111;//next state is S7:ALUWB
					end
		endcase
	end
always @(posedge clk,posedge reset)
	begin
		if (reset)
			begin
				state<=4'b0000;//S0:Fetch
			end
		else
			begin
				state<=next_state;// changes the state
			end
	end
endmodule
module ALUDecoder(input logic [1:0] ALUOp,input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  output logic [2:0] ALUControl);
always @(ALUOp)// to set the ALUControl
	begin
		case(ALUOp)
			2'b00:
				begin
					ALUControl<=3'b000;// lw,sw Instructions (add)
				end
			2'b01:
				begin
					ALUControl<=3'b001;// beq Instruction (001)
				end
			2'b10:// R-type and I-type(ALU) Instruction
				begin
					case(funct3)
						3'b000:
							begin
								if (op[5]==1 && funct7b5==1)
									begin
										ALUControl<=3'b001;// subtract
									end
								else
									begin
										ALUControl<=3'b000;//add
									end
							end
						3'b010:
							begin
								ALUControl<=3'b101; // set less than
							end
						3'b110:
							begin
								ALUControl<=3'b011; // or
									
							end
						3'b111:
							begin
								ALUControl<=3'b010; // and
							end
						3'b100:
							begin
								ALUControl<=3'b100; // xor
							end
						3'b001:
							begin
								ALUControl<=3'b110; //SLL
							end
						3'b101:
							begin
								ALUControl<=3'b111; //SRL
							end
					endcase
				end
		endcase
	end
endmodule
module InstrDecoder(input logic [6:0] op,output logic [2:0] ImmSrc);
always @(op)
	begin
		case(op)
				7'b0000011: // lw
					begin
						ImmSrc<=3'b000;
					end
				7'b0100011: //sw 
					begin
						ImmSrc<=3'b001;
					end
				7'b0110011: // (R-type)
					begin
						ImmSrc<=3'b000;
					end
				7'b0010011: //(I-type ALU)
					begin
						ImmSrc<=3'b000;
					end
				7'b1101111:// S9:JAL the case for JAL
					begin
						ImmSrc<=3'b011;
					end
				7'b1100011://S10:BEQ the case for BEQ
					begin
						ImmSrc<=3'b010;
					end
				7'b0010111://auipc
					begin
						ImmSrc<=3'b100;
					end
				7'b0110111://lui
					begin
						ImmSrc<=3'b100;
					end
		endcase
	end
endmodule
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
//flopner
module flopenr #(parameter WIDTH = 8)
					(input logic clk, reset, en,
					input logic [WIDTH-1:0] d,
					output logic [WIDTH-1:0] q);
	
	always_ff @(posedge clk, posedge reset)
		if (reset) q <= 0;
		else if (en) q <= d;

endmodule
//doubleflopenr
module doubleflopenr #(parameter WIDTH = 8)
					(input logic clk,reset,en,
					input logic [WIDTH-1:0] d1,
					input logic [WIDTH-1:0] d2,
					output logic [WIDTH-1:0] q1,
					output logic [WIDTH-1:0] q2);
	
	always_ff @(posedge clk,posedge reset)
		if (reset)
		begin
			q1 <= 0;
			q2 <= 0;
		end
		else if (en) 
		begin 
			q1 <= d1;
			q2 <= d2;
		end
endmodule
//mux2
module mux2 #(parameter WIDTH = 8)
				(input logic [WIDTH-1:0]d0, d1,
				input logic s,
				output logic [WIDTH-1:0]y);
	assign y = s ? d1 : d0;
endmodule
//mux3
module mux3 #(parameter WIDTH = 8)
				(input logic [31:0]d0, d1, d2,
				input logic [1:0] s,
				output logic [31:0]y);
	assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule
//mux4
module mux4 #(parameter WIDTH = 8)
				(input logic [31:0]d0, d1, d2,d3,
				input logic [1:0] s,
				output logic [31:0]y);
	assign y = s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0);
endmodule
//regfile
module RegFile (input logic clk,
					input logic regwrite,
					input logic [4:0] addr1,
					input logic [4:0] addr2,
					input logic [4:0] addr3,
					input logic [31:0] wd3,
					output logic [31:0] rd1,
					output logic [31:0] rd2);
	
	logic [31:0] sram[31:0];
	initial
		begin
			sram[0]=0;
			sram[2]=0;
			sram[3]=0;
			sram[4]=0;
			sram[5]=0;
			sram[6]=0;
			sram[7]=0;
			sram[8]=0;
			sram[9]=0;
			sram[12]=0;
			sram[13]=0;
			sram[14]=0;
			sram[15]=0;
		end
	
	assign rd1 = (addr1==0) ?  0 : sram[addr1];
	assign rd2 = (addr2<0 || addr2>15) ? 0:(addr2==0) ?  0 : sram[addr2];
	
	always @(posedge clk)
	begin
		if (regwrite & addr3 != 0)
				sram[addr3] <= wd3;
	end				
					
endmodule
//extend
module Extend(input logic [31:7] Instr,
				input logic [2:0] ImmSrc,
				output logic [31:0] ImmExt);
	always_comb
		case(ImmSrc)
			// I−type
			3'b000: ImmExt = {{20{Instr[31]}}, Instr[31:20]};
			// S−type (stores)
			3'b001: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
			// B−type (branches)
			3'b010: ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25],Instr[11:8],1'b0};
			// J−type (jal)
			3'b011: ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0};
			//U-type
			3'b100:ImmExt={{12'b0,Instr[31:12]}};
			
			
			default: ImmExt = 32'bx; // undefined
		endcase
endmodule
//ALU
module ALU(input logic [31:0] SrcA,
			input logic [31:0] SrcB,
			input logic [2:0] ALUControl,
			output logic [31:0] ALUResult,
			output logic Zero,SF);
			
	always @(*)
	begin
		case (ALUControl)
			3'b000 :
			begin
				ALUResult = SrcA + SrcB;
				Zero = (ALUResult == 0)? 1 : 0;
				SF   = SrcB > SrcA;
			end
			3'b001 :
			begin
				ALUResult = SrcA - SrcB;
				Zero = (ALUResult == 0)? 1 : 0;
				SF   = SrcB > SrcA;
			end	
			3'b010 :
			begin
				ALUResult = SrcA & SrcB;
				Zero = (ALUResult == 0)? 1 : 0;
				SF   = SrcB > SrcA;
			end
			3'b011 :
			begin
				ALUResult = SrcA | SrcB;
				Zero = (ALUResult == 0)? 1 : 0;
				SF   = SrcB > SrcA;
			end
			3'b100:
				begin
					ALUResult = SrcA ^ SrcB;
					Zero = (ALUResult == 0)? 1 : 0;
					SF   = SrcB > SrcA;
				end
			3'b101 : 
			begin
				ALUResult = SrcA < SrcB;
				Zero = (ALUResult == 0)? 1 : 0;
				SF   = SrcB > SrcA;
			end
			3'b110:
				begin
					ALUResult = SrcA << SrcB;
					Zero = (ALUResult == 0)? 1 : 0;
					SF   = SrcB > SrcA;
				end
			3'b111:
				begin
					ALUResult = SrcA >> SrcB;
					Zero = (ALUResult == 0)? 1 : 0;
					SF   = SrcB > SrcA;
				end
			default : 
			begin
				ALUResult = 32'b0;
				Zero = 0;
			end
		endcase
	end
			
endmodule
///////////////////////////////////////////////////////////////

// Describe your non-leaf cells structurally
// Describe your lef cells (mux, flop, alu, etc.) behaviorally
// Exactly follow the multicycle processor diagram
// Remember to declare internal signals
// Be consistent with spelling and capitalization
// Be consistent with order of signals in module declarations and instantiations
