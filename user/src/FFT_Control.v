//==================================================================================================
//  Filename      : FFT_Control.v
//  Created On    : 2019-05-10 01:26:20
//  Last Modified : 2019-05-10 01:26:20
//  Author 		  : DUAN
//  Revision      : By sublime_3   
//					module version is 1.0
//  Description   : FFT模块  (基于zynq)
//					相关计算公式 : NFFT = log2(N) N : The piont size
//                                N_piont = N    N : The piont size
//                                sample_fre = (Fs*2^32)/Fc  (Fc = clk_AD)
//         			端口定义    ： clk_50m         : 吞吐时钟   (采用蝶四模式，固定速率50M)
//                                clk_AD          ：AD最大采样时钟
//         			         	  start_sig       ：FFT模块启用的开始信号(上升沿有效)
//                                sample_fre      ：采样率控制字
//                                N_piont         ：FFT运算点数 (8~65536)
//                                wave_in         ：波形数据输入
//                                fft_dout_tvaild ：FFT频谱数据输出的有信号(高电平有效)
//                                Power_dout      ：总功率数据  (被截低12位)
//                                amp_dout 		  ：频谱幅度数据
//	Note          : 本代码遵循BSD开源协议			
//==================================================================================================
module FFT_Control
(
    input          clk_Cal,
    input          clk_AD,
    input          clk_read,
    input          rst_n,
    input          start_sig,
    input  [31:0]  sample_fre,
    input  [14:0]  FFT_addr,
    input  [11:0]  wave_in,

    output         fft_done,
    output [23:0]  amp_dout
);

//Configure Channel 
wire [7:0]   s_axis_config_tdata = 8'd1;
wire         s_axis_config_tready;
wire         s_axis_config_tvalid = 1'b1;
//Data input Channel 
wire signed [11:0] FFT_data;
wire [31:0]  s_axis_data_tdata = {16'd0,{4{FFT_data[11]}},FFT_data};
wire         s_axis_data_tready;
wire         s_axis_data_tvalid;
wire         s_axis_data_tlast;
//Data output Channel 
wire [63:0]  m_axis_data_tdata;
wire         m_axis_data_tvalid;
wire         m_axis_data_tlast;
//event output Channel 
wire         event_frame_started;
wire         event_tlast_unexpected;
wire         event_tlast_missing;
wire         event_status_channel_halt;
wire         event_data_in_channel_halt;
wire         event_data_out_channel_halt;

/***************************************************/
//下抽样模块
wire signed [11:0] wave_data;
wire               clk_sample;
DownSample M_DownSample
(
    .clk_AD(clk_AD),
    .clk_sample(clk_sample),
    .rst_n(rst_n),
    .sample_fre(sample_fre),
    .data_in(wave_in),
    .data_out(wave_data)
);
/***************************************************/

/***************************************************/
//传输速率转换模块
Rate_Switch M_Rate_Switch
(
    .input_clk(clk_sample),
    .output_clk(clk_Cal),
    .rst_n(rst_n),
    .start_sig(start_sig),
    .piont_num(16'd32768),
    .din(wave_data),
    .data_vaild(s_axis_data_tvalid),
    .data_tlast(s_axis_data_tlast),
    .dout(FFT_data)
);
/***************************************************/

/***************************************************/
//FFT主IP部分
FFT FFT_inst
(
    .aclk(clk_Cal),

    .s_axis_config_tdata(s_axis_config_tdata),
    .s_axis_config_tvalid(s_axis_config_tvalid),
    .s_axis_config_tready(s_axis_config_tready),

    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tlast(s_axis_data_tlast),

    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(1'b1),
    .m_axis_data_tlast(m_axis_data_tlast),

    .event_frame_started(event_frame_started),
    .event_tlast_unexpected(event_tlast_unexpected),
    .event_tlast_missing(event_tlast_missing),
    .event_status_channel_halt(event_status_channel_halt),
    .event_data_in_channel_halt(event_data_in_channel_halt),
    .event_data_out_channel_halt(event_data_out_channel_halt)
);   
/***************************************************/

/***************************************************/
//进行取模运算
wire signed [63:0]  mult_re;
wire signed [63:0]  mult_im;
wire signed [31:0]  data_out_re = (m_axis_data_tvalid) ? m_axis_data_tdata[31:0] : 32'd0;
wire signed [31:0]  data_out_im = (m_axis_data_tvalid) ? m_axis_data_tdata[63:32] : 32'd0;
FFT_mult_gen mult_real
(
    .CLK(clk_Cal),
    .A(data_out_re),
    .B(data_out_re),
    .P(mult_re),
    .CE(m_axis_data_tvalid)
);
FFT_mult_gen mult_imge
(
    .CLK(clk_Cal),
    .A(data_out_im),
    .B(data_out_im),
    .P(mult_im),
    .CE(m_axis_data_tvalid)
);
/***************************************************/

/***************************************************/
reg  m_axis_data_tvalid_r0;
reg  m_axis_data_tvalid_r1;
reg  m_axis_data_tvalid_r2;
reg  m_axis_data_tvalid_r3;
reg  m_axis_data_tvalid_r4;
wire Out_valid;
always @(posedge clk_Cal) begin
    m_axis_data_tvalid_r0 <= m_axis_data_tvalid;
    m_axis_data_tvalid_r1 <= m_axis_data_tvalid_r0;
    m_axis_data_tvalid_r2 <= m_axis_data_tvalid_r1;
    m_axis_data_tvalid_r3 <= m_axis_data_tvalid_r2;
    m_axis_data_tvalid_r4 <= m_axis_data_tvalid_r3;
end
assign Out_valid = m_axis_data_tvalid_r4;

//根据功率开根求得对应的幅度值
wire signed [63:0]  energy = mult_re[63:1] + mult_im[63:1];//?
wire        [23:0]  amp_dout_r;
FFT_Square_Root M_FFT_Square_Root
(
    .aclk(clk_Cal),
    .s_axis_cartesian_tvalid(Out_valid),
    .s_axis_cartesian_tdata(energy[48:1]),
    .m_axis_dout_tvalid(fft_dout_tvaild),
    .m_axis_dout_tdata(amp_dout_r)
 );
/***************************************************/

/***************************************************/
reg [14:0]      data_addr = 0;

always@(posedge clk_Cal)
begin
    if (fft_dout_tvaild && data_addr <= 16'd32766)      
    begin
        data_addr <= data_addr + 15'd1;
    end
    else
    begin
        data_addr <= 15'd0;
    end
end

reg fft_dout_tvaild_buf = 0;
reg start_sig_buf = 0;
always @(posedge clk_Cal) begin
    fft_dout_tvaild_buf <= fft_dout_tvaild;
    start_sig_buf <= start_sig;
end
wire fft_tvaild_nege = fft_dout_tvaild_buf & ~fft_dout_tvaild;
wire start_sig_nege  = start_sig_buf & ~start_sig;
reg  fft_done_r = 0;
always @(posedge clk_Cal) begin
    if (fft_tvaild_nege == 1'b1) 
    begin
        fft_done_r <= 1'b1;
    end
    else if(start_sig_nege == 1'b1)
    begin
        fft_done_r <= 1'b0;
    end
end
assign fft_done = fft_done_r;

FFT_MCU M_FFT_MCU
(
    .clka(clk_Cal),
    .ena(fft_dout_tvaild),
    .wea(1'b1),
    .addra(data_addr),
    .dina(amp_dout_r),
    .clkb(clk_read),
    .addrb(FFT_addr),
    .doutb(amp_dout)
);
/***************************************************/
endmodule
