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