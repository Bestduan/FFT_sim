//******************************************************************
// Copyright (c) 2015 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************

`timescale 1 ns/1 ps

module fft_start #(
    parameter   DATA_WIDTH          =   16,     //8~
    parameter   ADDR_WIDTH          =   9       //FFT_LENGTH = 2(ADDR_WIDTH+1)
) (
    input  wire                     clk,//
    input  wire                     rst_n,

    input  wire                     m_axi_valid,
    input  wire                     m_axi_last,
    output reg                      fft_start
);

reg     rst_r1;
reg     rst_r2;
reg     rst_r3;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rst_r1 <= 1'b0;
        rst_r2 <= 1'b0;
        rst_r3 <= 1'b0;
    end
    else begin
        rst_r1 <= 1'b1;
        rst_r2 <= rst_r1;
        rst_r3 <= rst_r2;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        fft_start <= 1'b0;
    else if( (~rst_r3 & rst_r2) | (m_axi_valid & m_axi_last) )
        fft_start <= 1'b1;
    else
        fft_start <= 1'b0;
end

endmodule//fft_start