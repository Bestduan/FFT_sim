//******************************************************************
// Copyright (c) 2015 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************

`timescale 1 ns/1 ps

module pgr_fft_start#
   (
    parameter   DATA_WIDTH          =   16,     //8~
    parameter   ADDR_WIDTH          =   9       //FFT_LENGTH = 2(ADDR_WIDTH+1)
   )
   (
    input  wire                     clk,//
    input  wire                     rst_n,

    input  wire                     m_axi_valid,
    input  wire                     m_axi_last,
//    input  wire [ 2*DATA_WIDTH-1:0] m_axi_data,
//    input  wire [   ADDR_WIDTH  :0] m_axi_user,//index
//
//    output reg                      fft_o_zero,
    output reg                      fft_start
);


reg     rst_r1;
reg     rst_r2;
reg     rst_r3;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        rst_r1 <= 1'b0;
        rst_r2 <= 1'b0;
        rst_r3 <= 1'b0;
    end
    else
    begin
        rst_r1 <= 1'b1;
        rst_r2 <= rst_r1;
        rst_r3 <= rst_r2;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        fft_start <= 1'b0;
    end
    else if( (~rst_r3 & rst_r2) | (m_axi_valid & m_axi_last) )
    begin
        fft_start <= 1'b1;
    end
    else
    begin
        fft_start <= 1'b0;
    end
end

//reg     axi_d_zero;
//always@(posedge clk or negedge rst_n)
//begin
//    if (!rst_n)
//    begin
//        axi_d_zero <= 1'b0;
//    end
//    else if( m_axi_data == {(2*DATA_WIDTH){1'b0}} )
//    begin
//        axi_d_zero <= 1'b1;
//    end
//    else
//    begin
//        axi_d_zero <= 1'b0;
//    end
//end
//
//reg     axi_u_zero;
//always@(posedge clk or negedge rst_n)
//begin
//    if (!rst_n)
//    begin
//        axi_u_zero <= 1'b0;
//    end
//    else if( m_axi_user == {(ADDR_WIDTH+1){1'b0}} )
//    begin
//        axi_u_zero <= 1'b1;
//    end
//    else
//    begin
//        axi_u_zero <= 1'b0;
//    end
//end
//
//always@(posedge clk or negedge rst_n)
//begin
//    if (!rst_n)
//    begin
//        fft_o_zero <= 1'b0;
//    end
//    else
//    begin
//        fft_o_zero <= axi_u_zero & axi_d_zero;
//    end
//end

endmodule//pgr_fft_start