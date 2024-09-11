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