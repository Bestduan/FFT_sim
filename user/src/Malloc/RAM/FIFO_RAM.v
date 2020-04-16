module FIFO_RAM #(
	parameter RAM_DEEP   = 2048,
	parameter DATA_WIDTH = 12
) (
    input                   wr_clk,
    input  [DATA_WIDTH-1:0] wr_data,
    input                   rd_clk,
    output [DATA_WIDTH-1:0] rd_data,

    input                	rst_n,
    input                	Request,
    output               	data_vaild,
    output               	data_tlast
);

reg        wr_clk_buf = 0;
reg        Request_buf = 0;
reg        Request_buf1 = 0;
reg        wr_cnt_busy = 0;
wire       wr_en;
wire       wr_done;
reg        wr_done_buf = 0;
reg        wr_done_buf1 = 0;
reg        wr_done_buf2 = 0;
reg        wr_done_buf3 = 0;
wire       rd_done;
reg        rd_cnt_busy = 0;
wire       rd_en;
reg [16:0] wr_cnt = 0;
reg [16:0] rd_cnt = 0;
wire       wr_clk_pose = ~wr_clk_buf & wr_clk;
wire       Request_pose = ~Request_buf1 & Request_buf;

always@(posedge rd_clk) begin
    wr_clk_buf <= wr_clk;
    Request_buf1 <= Request_buf;
	if(wr_clk_pose)
        Request_buf <= Request;
end

/*wr_en && wr_cnt     control*/
always@(posedge rd_clk) begin
    if(!rst_n)
        wr_cnt_busy <= 1'b0;
    else if(Request_pose)
        wr_cnt_busy <= 1'b1;
    else if(wr_cnt == RAM_DEEP+1 && wr_clk_pose)
        wr_cnt_busy <= 1'b0;
end

always@(posedge rd_clk) begin
    if(!rst_n)
        wr_cnt <= 14'd0;
    else if(wr_cnt == RAM_DEEP+1 && wr_clk_pose)
        wr_cnt <= 14'd0;
    else if(wr_cnt_busy && wr_clk_pose)
        wr_cnt <= wr_cnt + 14'd1;
end

assign wr_en = (wr_cnt >=1 && wr_cnt <=RAM_DEEP+1) ? 1'b1 : 1'b0;
assign wr_done = (wr_cnt == RAM_DEEP+1  && wr_clk_pose) ? 1'b1 : 1'b0;
/*rd_en && rd_cnt     control*/
always@(posedge rd_clk) begin
    wr_done_buf <= wr_done;
    wr_done_buf1 <= wr_done_buf;
    wr_done_buf2 <= wr_done_buf1;
    wr_done_buf3 <= wr_done_buf2;
end

always@(posedge rd_clk) begin
    if(!rst_n)
        rd_cnt_busy <= 1'b0;
    else if(wr_done_buf3)
        rd_cnt_busy <= 1'b1;
    else if(rd_cnt == RAM_DEEP+1)
        rd_cnt_busy <= 1'b0;
end

always@(posedge rd_clk) begin
    if(!rst_n)
        rd_cnt <= 14'd0;
    else if(rd_cnt == RAM_DEEP+1)
        rd_cnt <= 14'd0;
    else if(rd_cnt_busy)
        rd_cnt <= rd_cnt + 14'd1;
end

assign rd_en = (rd_cnt>=1 && rd_cnt<=RAM_DEEP+1) ? 1'b1 : 1'b0;
assign rd_done = (rd_cnt == RAM_DEEP+1) ? 1'b1 : 1'b0;
assign data_vaild = (rd_cnt >= 2 && rd_cnt <= RAM_DEEP+1) ? 1'b1 : 1'b0;
assign data_tlast = rd_done;

reg [DATA_WIDTH-1:0] mem[RAM_DEEP-1:0];

integer i;
initial begin
   for (i = 0; i<RAM_DEEP; i=i+1) begin
		mem[i] = 0;
	end
end

always @(posedge wr_clk) begin
	if(wr_en)
		mem[wr_cnt] <= wr_data;
	else begin
		mem[wr_cnt] <= mem[wr_cnt];
	end
end

reg [DATA_WIDTH-1:0] rd_data_r = 0;
always @(posedge rd_clk) begin
	if(rd_en)
		rd_data_r <= mem[rd_cnt];
	else
		rd_data_r <= rd_data_r;
end
assign rd_data = rd_data_r;

endmodule
