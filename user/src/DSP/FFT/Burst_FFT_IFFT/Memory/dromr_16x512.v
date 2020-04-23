`timescale 1ns / 1ps
module dromr_16x512 #(
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

initial begin
    $readmemh("fft_iphase_r.dat",mem,0,DEPTH-1);
end

always @(posedge clk) begin
    rd_data <=  mem[addr];
end

endmodule

