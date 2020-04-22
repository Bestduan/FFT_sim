module testbench();

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;
parameter MAIN_FRE   = 100; //unit MHz
reg                   W_clk       = 0;
reg                   R_clk       = 0;
reg                   sys_rst_n = 0;
reg [DATA_WIDTH-1:0]  data = 0;
reg   Request = 0;
always begin
    #(500/10) W_clk = ~W_clk;
end
always begin
    #(500/100) R_clk = ~R_clk;
end
always begin
    #50 sys_rst_n = 1;
	#50 Request = 1;
end

always @(posedge W_clk ) begin
	data <= data + 1;
end

// FIFO_RAM Outputs
wire  [DATA_WIDTH-1:0]  rd_data;
wire  data_vaild;
wire  data_tlast;

FIFO_RAM #(
    .RAM_DEEP         ( 32 ),
    .DATA_WIDTH       ( DATA_WIDTH   ))
 u_FIFO_RAM (
    .wr_clk                  ( W_clk        ),
    .wr_data                 ( data         ),
    .rd_clk                  ( R_clk        ),
    .rst_n                   ( sys_rst_n    ),
    .Request                 ( Request      ),

    .rd_data                 ( rd_data      ),
    .data_vaild              ( data_vaild   ),
    .data_tlast              ( data_tlast   )
);

endmodule  //TOP