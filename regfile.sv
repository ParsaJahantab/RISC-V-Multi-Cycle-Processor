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