import os
import linecache

head = '''
timescale 1ns / 1ps
module dromi_16x512 #(
    parameter    ADDR_WIDTH     =   9,
    parameter    DATA_WIDTH     =   16
) (
    input   wire    [ADDR_WIDTH-1:0]    addr    ,
    output  reg     [DATA_WIDTH-1:0]    rd_data ,
    input   wire                        clk     ,
     
    input   wire                        clk_en  ,
    input   wire                        rst
);

localparam  DEPTH = 2**ADDR_WIDTH;

reg [DATA_WIDTH-1:0]  mem [0:DEPTH-1];

always @(posedge clk) begin
'''

end = '''
end

endmodule
'''

def main():
	file = open('./dromi_16x512.v','w')
	file.write(head)
	for i in range(1,512):
		data = linecache.getline("./fft_iphase_i.dat",i)
		file.write("	rd_data <= %s;\n"  % data)
	file.write(end)
	file.close()