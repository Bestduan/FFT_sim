module dram_16x1024 #(
    parameter    ADDR_WIDTH     =   10,
    parameter    DATA_WIDTH     =   16
) (
    input   wire    [ADDR_WIDTH-1:0]    addr,
    output  reg     [DATA_WIDTH-1:0]    rd_data,
    input   wire                        clk,
     
    input   wire                        clk_en,
    input   wire                        rst
);

localparam  DEPTH = 2**ADDR_WIDTH;

reg     [DATA_WIDTH-1:0]  mem [0:DEPTH-1];


initial begin
    $readmemh("fft_in.dat",mem,0,DEPTH-1);
end

always @(posedge clk or posedge rst) begin
    if(rst)
       rd_data <= {DATA_WIDTH{1'b0}};
    else if(clk_en)
       rd_data <=  mem[addr];
end

endmodule
