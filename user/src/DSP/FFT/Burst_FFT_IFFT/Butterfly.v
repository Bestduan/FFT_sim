//******************************************************************
// Copyright (c) 2015 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************

`timescale 1 ns/1 ps

module pgr_butterfly#
(
    parameter   ADDR_WIDTH          =   18,//8~
    parameter   DATA_WIDTH          =   18,//8~
    parameter   TWIDDLE_WIDTH       =   18,//8~
    parameter   BUTTERFLY_LAT       =   1  //1~
)
(
    input  wire                     clk,//
    input  wire                     rst_n,

    input  wire                     first_lev_s,
    input  wire [   ADDR_WIDTH-1:0] fft_i_index,
    input  wire                     mult_en,
    input  wire                     a_signed,
    input  wire                     b_signed,
    input  wire [TWIDDLE_WIDTH-1:0] twiddle_re,
    input  wire [TWIDDLE_WIDTH-1:0] twiddle_im,
    input  wire [   DATA_WIDTH-1:0] dat_ain_re,
    input  wire [   DATA_WIDTH-1:0] dat_ain_im,
    input  wire [   DATA_WIDTH-1:0] dat_bin_re,
    input  wire [   DATA_WIDTH-1:0] dat_bin_im,

    output reg                      dat_out_vld,
    output reg                      first_lev_b,
    output reg  [   ADDR_WIDTH-1:0] fft_o_index,
    output reg  [   DATA_WIDTH-1:0] dat_aout_re,
    output reg  [   DATA_WIDTH-1:0] dat_aout_im,
    output reg  [   DATA_WIDTH-1:0] dat_bout_re,
    output reg  [   DATA_WIDTH-1:0] dat_bout_im
);

wire [ 2*DATA_WIDTH  :0]        bxt_real_w;
wire [ 2*DATA_WIDTH  :0]        bxt_imag_w;

localparam AXT_VLD_WIDTH = DATA_WIDTH +4;

wire [AXT_VLD_WIDTH-1:0]        bxt_real_temp;
wire [AXT_VLD_WIDTH-1:0]        bxt_imag_temp;
wire [AXT_VLD_WIDTH-1:0]        dat_a_re_temp;
wire [AXT_VLD_WIDTH-1:0]        dat_a_im_temp;
wire [AXT_VLD_WIDTH  :0]        dat0_re_temp;
wire [AXT_VLD_WIDTH  :0]        dat0_im_temp;
wire [AXT_VLD_WIDTH  :0]        dat1_re_temp;
wire [AXT_VLD_WIDTH  :0]        dat1_im_temp;
wire [   DATA_WIDTH-1:0]        out0_re_temp;
wire [   DATA_WIDTH-1:0]        out0_im_temp;
wire [   DATA_WIDTH-1:0]        out1_re_temp;
wire [   DATA_WIDTH-1:0]        out1_im_temp;


assign bxt_real_w = $signed(dat_bin_re)*$signed(twiddle_re) - $signed(dat_bin_im)*$signed(twiddle_im);
assign bxt_imag_w = $signed(dat_bin_re)*$signed(twiddle_im) + $signed(dat_bin_im)*$signed(twiddle_re);

//pg_mult_add pg_mult_add
//    ( 
//    .CE     ( mult_en    ),
//    .RST    ( ~rst_n     ),
//    .CLK    ( clk        ),
//    .A0     ( dat_bin_re ),
//    .A1     ( dat_bin_im ),
//    .B0     ( twiddle_im ),
//    .B1     ( twiddle_re ),
//    .P      ( bxt_imag_w )
//    );
//
//pg_mult_sub pg_mult_sub
//    ( 
//    .CE     ( mult_en    ),
//    .RST    ( ~rst_n     ),
//    .CLK    ( clk        ),
//    .A0     ( dat_bin_re ),
//    .A1     ( dat_bin_im ),
//    .B0     ( twiddle_re ),
//    .B1     ( twiddle_im ),
//    .P      ( bxt_real_w )
//    );


assign bxt_real_temp = bxt_real_w[2*DATA_WIDTH:DATA_WIDTH-3];
assign bxt_imag_temp = bxt_imag_w[2*DATA_WIDTH:DATA_WIDTH-3];

assign dat_a_re_temp = { {3{dat_ain_re[DATA_WIDTH-1]}}, dat_ain_re[DATA_WIDTH-1:0],1'b1};//+0.5,tuncate
assign dat_a_im_temp = { {3{dat_ain_im[DATA_WIDTH-1]}}, dat_ain_im[DATA_WIDTH-1:0],1'b1};//+0.5,tuncate

assign dat0_re_temp = $signed(dat_a_re_temp) + $signed(bxt_real_temp);
assign dat0_im_temp = $signed(dat_a_im_temp) + $signed(bxt_imag_temp);

assign dat1_re_temp = $signed(dat_a_re_temp) - $signed(bxt_real_temp);
assign dat1_im_temp = $signed(dat_a_im_temp) - $signed(bxt_imag_temp);

assign out0_re_temp  = ( (dat0_re_temp[AXT_VLD_WIDTH:AXT_VLD_WIDTH-3] == 4'h0) | (dat0_re_temp[AXT_VLD_WIDTH:AXT_VLD_WIDTH-3] == 4'hf) )
                     ?  dat0_re_temp[AXT_VLD_WIDTH-3:2]
                     : (dat0_re_temp[AXT_VLD_WIDTH] ? { 1'b1, {(DATA_WIDTH-2){1'b0}}, 1'b0 } : { 1'b0, {(DATA_WIDTH-1){1'b1}} } );

assign out0_im_temp  = ( (dat0_im_temp[AXT_VLD_WIDTH:AXT_VLD_WIDTH-3] == 4'h0) | (dat0_im_temp[AXT_VLD_WIDTH:AXT_VLD_WIDTH-3] == 4'hf) )
                     ?  dat0_im_temp[AXT_VLD_WIDTH-3:2]
                     : (dat0_im_temp[AXT_VLD_WIDTH] ? { 1'b1, {(DATA_WIDTH-2){1'b0}}, 1'b0 } : { 1'b0, {(DATA_WIDTH-1){1'b1}} } );

assign out1_re_temp  = ( (dat1_re_temp[AXT_VLD_WIDTH:AXT_VLD_WIDTH-3] == 4'h0) | (dat1_re_temp[AXT_VLD_WIDTH:AXT_VLD_WIDTH-3] == 4'hf) )
                     ?  dat1_re_temp[AXT_VLD_WIDTH-3:2]
                     : (dat1_re_temp[AXT_VLD_WIDTH] ? { 1'b1, {(DATA_WIDTH-2){1'b0}}, 1'b0 } : { 1'b0, {(DATA_WIDTH-1){1'b1}} } );

assign out1_im_temp  = ( (dat1_im_temp[AXT_VLD_WIDTH:AXT_VLD_WIDTH-3] == 4'h0) | (dat1_im_temp[AXT_VLD_WIDTH:AXT_VLD_WIDTH-3] == 4'hf) )
                     ?  dat1_im_temp[AXT_VLD_WIDTH-3:2]
                     : (dat1_im_temp[AXT_VLD_WIDTH] ? { 1'b1, {(DATA_WIDTH-2){1'b0}}, 1'b0 } : { 1'b0, {(DATA_WIDTH-1){1'b1}} } );

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        dat_aout_re <= {DATA_WIDTH{1'b0}};
    end
    else
    begin
        dat_aout_re <= out0_re_temp;
//        dat_aout_re <= dat0_re_temp[AXT_VLD_WIDTH:5];
    end
end


always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        dat_aout_im <= {DATA_WIDTH{1'b0}};
    end
    else
    begin
        dat_aout_im <= out0_im_temp;
//        dat_aout_im <= dat0_im_temp[AXT_VLD_WIDTH:5];
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        dat_bout_re <= {DATA_WIDTH{1'b0}};
    end
    else
    begin
        dat_bout_re <= out1_re_temp;
//        dat_bout_re <= dat1_re_temp[AXT_VLD_WIDTH:5];
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        dat_bout_im <= {DATA_WIDTH{1'b0}};
    end
    else
    begin
        dat_bout_im <= out1_im_temp;
//        dat_bout_im <= dat1_im_temp[AXT_VLD_WIDTH:5];
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        dat_out_vld <= 1'b0;
    end
    else
    begin
//        dat_out_vld <= mult_en_r1;
        dat_out_vld <= mult_en;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        fft_o_index <= {ADDR_WIDTH{1'b0}};
    end
    else
    begin
//        fft_o_index <= fft_i_index_r1;
        fft_o_index <= fft_i_index;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        first_lev_b <= 1'b0;
    end
    else
    begin
//        first_lev_b <= first_lev_b_r1;
        first_lev_b <= first_lev_s;
    end
end

endmodule//pgr_butterfly