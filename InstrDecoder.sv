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