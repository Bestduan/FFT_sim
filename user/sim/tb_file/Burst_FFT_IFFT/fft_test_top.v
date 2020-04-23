module  fft_test_top
(
    input   wire    clk,
    input   wire    rstn,
    output  reg     led,
    output  reg     out_vld
);

localparam  LOOP_NUM = 6;

wire        sys_clk = clk;
wire        rst_n;
reg         fft_out_vld;
reg         fft_out_vld_r1;
reg  [10:0] out_vld_cnt;

wire    [LOOP_NUM-1:0]  led_i/* synthesis syn_keep = 1 */;
wire    [LOOP_NUM-1:0]  status_i/* synthesis syn_keep = 1 */;

pgr_rst_debounce #
(
    .DLY1_RST_WIDTH  ( 10 ), //(2**9) = 512
    .DLY2_RST_WIDTH  ( 11 ) //(2**9)*512 = 256k
)
ext_rst_debounce
(
    .sys_clk    ( sys_clk   ),
    .sys_rst_n  ( rstn      ),
    .srst_len_n ( rst_n     ) 
);

genvar i;
generate
for(i=0; i<=(LOOP_NUM-1); i=i+1)
begin: loop
    fft_rd #(
		.FFT_LENGTH        (1023),     //len = 1023+1
		.BUTTERFLY_LAT     (   1),     //
		.DATA_WIDTH        (  16),     //8~
		.TWIDDLE_WIDTH     (  16),     //8~
		.ADDR_WIDTH        (   9)      //FFT_LENGTH = 2(ADDR_WIDTH+1)
    ) u_fft_rd (
		.sys_clk       ( sys_clk ),//
		.sys_rst_n     ( rst_n   ),
		.m_axi_data    (),
		.m_axi_user    (),//index
		.m_axi_last    (),
		.m_axi_valid   (),
		.led           (led_i[i]   ),
		.status        (status_i[i])
    ) /* synthesis syn_preserve = 1 */;
end
endgenerate

always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        led <= 1'b0;
    else if(| led_i)
        led <= 1'b1;
end

always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        fft_out_vld <= 1'b0;
    else
        fft_out_vld <= (| status_i);
end

always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        fft_out_vld_r1 <= 1'b0;
    else
        fft_out_vld_r1 <= fft_out_vld;
end

always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        out_vld_cnt <= 11'b0;
    else if(~fft_out_vld_r1 & fft_out_vld)
        out_vld_cnt <= out_vld_cnt + 11'h001;
end

always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        out_vld <= 1'b0;
    else if(led)
        out_vld <= 1'b0;
    else
        out_vld <= out_vld_cnt[10];
end

endmodule