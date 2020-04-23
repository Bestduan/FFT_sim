//(*bram_map = "yes"*)
//(* RAM_STYLE="{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
`timescale 1ns / 1ps
module drm_32x512 #(
    parameter    ADDR_WIDTH     =   9,
    parameter    DATA_WIDTH     =   32
) (
    input   wire    [DATA_WIDTH-1:0]    wr_data  , //input write data
    input   wire    [ADDR_WIDTH-1:0]    wr_addr  , //input write address
    input   wire                        wr_en    , //input write enable
    input   wire                        wr_clk   , //input write clock
    input   wire                        wr_rst   , //input write reset

    output  reg     [DATA_WIDTH-1:0]    rd_data  , //output read data
    input   wire    [ADDR_WIDTH-1:0]    rd_addr  , //input read address
    input   wire                        rd_clk   , //input read clock
    input   wire                        rd_clk_en, //input read clock enable
    input   wire                        rd_rst     //input read reset
);

localparam  DEPTH = 2**ADDR_WIDTH;

reg [DATA_WIDTH-1:0]  mem [0:DEPTH-1];
always@(posedge wr_clk) begin
    if(wr_en)
        mem[wr_addr] <= wr_data;
end

always@(posedge rd_clk) begin
    if( rd_clk_en )
        rd_data <= mem[rd_addr];
end

endmodule
