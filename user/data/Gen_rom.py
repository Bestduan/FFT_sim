import os
import linecache

head = '''
`timescale 1ns / 1ps
module dromi_16x512 #(
    parameter    ADDR_WIDTH     =   9,
    parameter    DATA_WIDTH     =   16
) (
    input   wire                        clk,
    input   wire                        rst,
    input   wire                        clk_en,

    input   wire    [ADDR_WIDTH-1:0]    addr,
    output  reg     [DATA_WIDTH-1:0]    rd_data
);

always@(posedge clk or posedge rst) begin
    if (rst) begin
		rd_data <= 0;
	end
	else begin
		if(clk_en) begin
			case (addr)
'''

end = '''
				default : begin rd_data <= 0; end
			endcase
		end
		else begin
			rd_data <= rd_data;
		end
	end
end

endmodule
'''

def mkfile():
	f = open('./dromi_16x512.v','w')
	f.write(head)
	for i in range(1,513):
		data = linecache.getline("./fft_iphase_i.dat",i)
		if i<512 :
			f.write("\t\t\t\t%d\t: begin rd_data <= 16'h%s; end\n" % (i-1,data.replace('\n','')))
		else:
			f.write("\t\t\t\t%d\t: begin rd_data <= 16'h%s; end" % (i-1,data.replace('\n','')))
	f.write(end)
	f.close()

if __name__ == '__main__':
    mkfile()