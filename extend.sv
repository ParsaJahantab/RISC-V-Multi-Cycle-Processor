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