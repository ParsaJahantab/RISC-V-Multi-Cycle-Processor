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