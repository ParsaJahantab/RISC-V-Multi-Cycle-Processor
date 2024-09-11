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