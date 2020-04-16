//==================================================================================================
//  Filename      : DownSample.v
//  Created On    : 2019-05-13 00:14:41
//  Last Modified : 2019-05-13 00:14:41
//  Author 		  : DUAN
//  Revision      : By sublime_3   
//					module version is 1.0
//  Description   : 下抽样模块
//					相关计算公式 : sample_fre = (Fs*2^32)/Fc  (Fc = clk_AD)
//                  
//         			端口定义    ： clk_AD          ：AD最大采样时钟
//                  			  sample_fre      ：采样率控制字
//         			         	  clk_sample      ：对应采样率下的时钟输出	
//	Note          : 本代码遵循BSD开源协议			
//==================================================================================================
module DownSample
(
    input             clk_AD,
    input             rst_n,
    input      [31:0] sample_fre,
    input      [11:0] data_in,
    output    		  clk_sample,	
    output reg [11:0] data_out
);

/***************************************************/
//欠采样时钟生成
reg    [31:0]    addr = 0;
always@(posedge clk_AD)
begin
    if(!rst_n)
        addr <= 32'd0;
    else
        addr <= addr + sample_fre;
end

assign clk_sample = (addr <= 32'd2147483647) ? 1'b0 : 1'b1;
/***************************************************/

/***************************************************/
//提取采样时钟的上升沿
reg        clk_sample_buf = 0;
wire       clk_sample_pose;
always@(posedge clk_AD)
begin
    clk_sample_buf <= clk_sample;
end

assign clk_sample_pose = ~clk_sample_buf & clk_sample;
/***************************************************/

/***************************************************/
always@(posedge clk_AD)
begin
    if(!rst_n)
    begin
        data_out <= 12'd0;
    end
	else if (clk_sample_pose)
	begin
        data_out <= data_in;
	end
end
/***************************************************/

endmodule
