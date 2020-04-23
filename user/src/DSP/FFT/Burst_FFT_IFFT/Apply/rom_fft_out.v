module rom_fft_out #(
    parameter    ADDR_WIDTH     =   10,
    parameter    DATA_WIDTH     =   32
) (
    input   wire                        clk,
    input   wire                        rst,
    input   wire    [ADDR_WIDTH-1:0]    addr,
    output  reg     [DATA_WIDTH-1:0]    rd_data
);

localparam  DEPTH = 2**ADDR_WIDTH;

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

initial begin
    $readmemh("fft_out.dat",mem,0,DEPTH-1);
end

always @(posedge clk) begin
    rd_data <=  mem[addr];
end

endmodule
