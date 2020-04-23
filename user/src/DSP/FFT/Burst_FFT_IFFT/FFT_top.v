//******************************************************************
// Copyright (c) 2015 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************

`timescale 1 ns/1 ps

module fft_top #(
    parameter   FFT_LENGTH          =   63,   //len = 1023+1
    parameter   BUTTERFLY_LAT       =   1,      //
    parameter   FFT_MODE            =   0,      //0:"FFT"; 1:"IFFT"
    parameter   SIG_MODE            =   1,      //1:signed; 0:unsigned
    parameter   DATA_WIDTH          =   16,     //8~
    parameter   TWIDDLE_WIDTH       =   16,     //8~
    parameter   ADDR_WIDTH          =   9       //FFT_LENGTH = 2(ADDR_WIDTH+1)
) (
	input  wire                     clk,//
	input  wire                     rst_n,

	input  wire                     cfg_valid,
	input  wire [ 23:0]             cfg_data,
	output wire                     cfg_ready,

	input  wire                     s_axi_valid,
	input  wire                     s_axi_last,
	input  wire [ 2*DATA_WIDTH-1:0] s_axi_data,
	output wire                     s_axi_ready,

	output wire [ 2*DATA_WIDTH-1:0] m_axi_data,
	output wire [   ADDR_WIDTH  :0] m_axi_user,//index
	output wire                     m_axi_last,
	output wire                     m_axi_valid,
	input  wire                     m_axi_ready
);

localparam  LEN_WIDTH    = 16;
localparam  LEVEL_VALUE  = log2(FFT_LENGTH);

//	port
wire                        dft_mode;
wire [  LEN_WIDTH-1:0]      dft_length;
wire [  3:0]                fft_lev_limit;
wire                        fft_cdone;//calculate done
wire                        fft_odone;//output done
wire                        fft_idone; //input done
wire                        o_wr_valid;
wire [ 2*DATA_WIDTH-1:0]    ao_wr_data;
wire [ 2*DATA_WIDTH-1:0]    bo_wr_data;
wire                        a_wr_en;
wire [ 2*DATA_WIDTH-1:0]    a_wr_data;
//wire [    LEN_WIDTH-2:0]    a_wr_addr;
wire                        b_wr_en;
wire [ 2*DATA_WIDTH-1:0]    b_wr_data;
wire [    LEN_WIDTH-2:0]    b_wr_addr;
wire                        nature_order;
wire                        o_rd_enable;
wire                        first_level;
wire                        i_rd_valid;
wire                        i_rd_en;
wire [ 2*DATA_WIDTH-1:0]    ia_rd_data;
wire [ 2*DATA_WIDTH-1:0]    ib_rd_data;
wire [    LEN_WIDTH-2:0]    i_rd_addr;
wire [    LEN_WIDTH-2:0]    phase_addr;
wire [   ADDR_WIDTH-1:0]    a_wr_adr;
wire [   ADDR_WIDTH-1:0]    b_wr_adr ;
wire [   ADDR_WIDTH-1:0]    s_rd_addr;
wire [   ADDR_WIDTH-1:0]    p_rd_addr;
wire [   ADDR_WIDTH-1:0]    fft_i_index;
wire [   ADDR_WIDTH-1:0]    fft_o_index;
wire [   ADDR_WIDTH-1:0]    o_wr_index;
wire                        butterfly_vld;
wire [ 2*DATA_WIDTH-1:0]    butterfly_ain;
wire [ 2*DATA_WIDTH-1:0]    butterfly_bin;
wire [2*TWIDDLE_WIDTH-1:0]  twiddle_data;
wire [2*TWIDDLE_WIDTH-1:0]  twiddle_in;
wire [TWIDDLE_WIDTH-1:0]    twiddle_dr;
wire [TWIDDLE_WIDTH-1:0]    twiddle_di;
wire                        a_signed;
wire                        b_signed;
wire [TWIDDLE_WIDTH-1:0]    twiddle_re;
wire [TWIDDLE_WIDTH-1:0]    twiddle_im;
wire [   DATA_WIDTH-1:0]    dat_ain_re;
wire [   DATA_WIDTH-1:0]    dat_ain_im;
wire [   DATA_WIDTH-1:0]    dat_bin_re;
wire [   DATA_WIDTH-1:0]    dat_bin_im;
wire                        dat_out_vld;
wire [   DATA_WIDTH-1:0]    dat_aout_re;
wire [   DATA_WIDTH-1:0]    dat_aout_im;
wire [   DATA_WIDTH-1:0]    dat_bout_re;
wire [   DATA_WIDTH-1:0]    dat_bout_im;
wire                        first_lev_s;
wire                        first_lev_b;
wire                        bf_o_valid;
wire [ 2*DATA_WIDTH-1:0]    bf_a_data;
wire [ 2*DATA_WIDTH-1:0]    bf_b_data;

//	instance
assign nature_order = 1'b1;

pgr_fft_ctrl #(
	.FFT_LENGTH  ( FFT_LENGTH    ),
	.LEVEL_VALUE ( LEVEL_VALUE   ),
	.LEN_WIDTH   ( LEN_WIDTH     ),
	.FFT_MODE    ( FFT_MODE      ),
	.DATA_WIDTH  ( 2*DATA_WIDTH  ),
	.ADDR_WIDTH  ( ADDR_WIDTH    )
) pgr_fft_ctrl (
	.clk           ( clk           ),
	.rst_n         ( rst_n         ),
	.cfg_valid     ( cfg_valid     ),
	.cfg_data      ( cfg_data      ),
	.cfg_ready     ( cfg_ready     ),
	.s_axi_valid   ( s_axi_valid   ),
	.s_axi_last    ( s_axi_last    ),
	.s_axi_ready   ( s_axi_ready   ),
	.dft_mode      ( dft_mode      ),
	.dft_length    ( dft_length    ),
	.fft_lev_limit ( fft_lev_limit ),
	.fft_cdone     ( fft_cdone     ),
	.fft_odone     ( fft_odone     ),
	.fft_idone     ( fft_idone     )
);
    
assign fft_odone = m_axi_last & m_axi_ready;

pgr_fft_ram_wr #(
	.DATA_WIDTH ( 2*DATA_WIDTH ),
	.ADDR_WIDTH ( ADDR_WIDTH   ),
	.LEN_WIDTH  ( LEN_WIDTH    )
) pgr_fft_ram_wr (
	.clk            ( clk           ),
	.rst_n          ( rst_n         ),
	.fft_odone      ( fft_odone     ),
	.dft_length     ( dft_length    ),
	.fft_lev_limit  ( fft_lev_limit ),
	.s_axi_valid    ( s_axi_valid   ),
	.s_axi_last     ( s_axi_last    ),
	.s_axi_data     ( s_axi_data    ),
	.s_axi_ready    ( s_axi_ready   ),
	.o_wr_valid     ( o_wr_valid    ),
	.o_wr_index     ( o_wr_index    ),
	.ao_wr_data     ( ao_wr_data    ),
	.bo_wr_data     ( bo_wr_data    ),
	.a_wr_en        ( a_wr_en       ),
	.a_wr_data      ( a_wr_data     ),
//    .a_wr_addr      ( a_wr_addr     ),
	.b_wr_en        ( b_wr_en       ),
	.b_wr_data      ( b_wr_data     ),
	.b_wr_addr      ( b_wr_addr     )
);

assign a_wr_adr  = b_wr_addr[ADDR_WIDTH-1:0];
assign b_wr_adr  = b_wr_addr[ADDR_WIDTH-1:0];
assign s_rd_addr = i_rd_addr[ADDR_WIDTH-1:0];

drm_32x512 a_src_32x512 (
    .wr_data        ( a_wr_data  ),
    .wr_addr        ( a_wr_adr   ),
    .wr_en          ( a_wr_en    ),
    .wr_clk         ( clk        ),
    .wr_rst         ( ~rst_n     ),
    .rd_data        ( ia_rd_data ),
    .rd_addr        ( s_rd_addr  ),
    .rd_clk         ( clk        ),
    .rd_clk_en      ( i_rd_en    ),
    .rd_rst         ( ~rst_n     )
);

drm_32x512 b_src_32x512 (
    .wr_data        ( b_wr_data  ),
    .wr_addr        ( b_wr_adr   ),
    .wr_en          ( b_wr_en    ),
    .wr_clk         ( clk        ),
    .wr_rst         ( ~rst_n     ),
    .rd_data        ( ib_rd_data ),
    .rd_addr        ( s_rd_addr  ),
    .rd_clk         ( clk        ),
    .rd_clk_en      ( i_rd_en    ),
    .rd_rst         ( ~rst_n     )
);

assign p_rd_addr = phase_addr[LEN_WIDTH-2:LEN_WIDTH-ADDR_WIDTH-1];

dromi_16x512 dromi_16x512(
    .addr        ( p_rd_addr  ),
    .rd_data     ( twiddle_di ),
    .clk         ( clk        ),
    .clk_en      ( i_rd_en    ),
    .rst         ( ~rst_n     )
);

dromr_16x512 dromr_16x512(
    .addr        ( p_rd_addr  ),
    .rd_data     ( twiddle_dr ),
    .clk         ( clk        ),
    .clk_en      ( i_rd_en    ),
    .rst         ( ~rst_n     )
);

assign twiddle_data = {twiddle_di, twiddle_dr};

pgr_fft_ram_rd #(
	.FFT_MODE    ( FFT_MODE       ),
	.FFT_LENGTH  ( FFT_LENGTH     ),
	.LEN_WIDTH   ( LEN_WIDTH      ),
	.DATA_WIDTH  ( DATA_WIDTH     ),
	.ADDR_WIDTH  ( ADDR_WIDTH     )
) pgr_fft_ram_rd (
	.clk           ( clk           ),
	.rst_n         ( rst_n         ),
	.dft_mode      ( dft_mode      ),
	.dft_length    ( dft_length    ),
	.fft_lev_limit ( fft_lev_limit ),
	.nature_order  ( nature_order  ),
	.o_rd_enable   ( o_rd_enable   ),
	.first_level   ( first_level   ),
	.fft_idone     ( fft_idone     ),
	.fft_cdone     ( fft_cdone     ),
	.i_rd_valid    ( i_rd_valid    ),
	.i_rd_en       ( i_rd_en       ),
	.i_rd_addr     ( i_rd_addr     ),
	.phase_addr    ( phase_addr    )
);

fft_i_switch #(
	.DATA_WIDTH    (2*DATA_WIDTH    ),
	.ADDR_WIDTH    ( ADDR_WIDTH     ),
	.TWIDDLE_WIDTH (2*TWIDDLE_WIDTH )
) fft_i_switch_u (
	.clk           ( clk           ),
	.rst_n         ( rst_n         ),
	.first_level   ( first_level   ),
	.i_rd_addr     ( s_rd_addr     ),
	.i_rd_valid    ( i_rd_valid    ),
	.ia_rd_data    ( ia_rd_data    ),
	.ib_rd_data    ( ib_rd_data    ),
	.twiddle_data  ( twiddle_data  ),
	.first_lev_s   ( first_lev_s   ),
	.addr_index    ( fft_i_index   ),
	.butterfly_vld ( butterfly_vld ),
	.butterfly_ain ( butterfly_ain ),
	.butterfly_bin ( butterfly_bin ),
	.twiddle_in    ( twiddle_in    )
);

assign a_signed   = SIG_MODE;
assign b_signed   = SIG_MODE;
assign twiddle_re = twiddle_in[DATA_WIDTH-1:0];
assign twiddle_im = twiddle_in[2*DATA_WIDTH-1:DATA_WIDTH];
assign dat_ain_re = butterfly_ain[DATA_WIDTH-1:0];
assign dat_ain_im = butterfly_ain[2*DATA_WIDTH-1:DATA_WIDTH];
assign dat_bin_re = butterfly_bin[DATA_WIDTH-1:0];
assign dat_bin_im = butterfly_bin[2*DATA_WIDTH-1:DATA_WIDTH];

pgr_butterfly #(
	.ADDR_WIDTH    ( ADDR_WIDTH    ),
	.DATA_WIDTH    ( DATA_WIDTH    ),
	.TWIDDLE_WIDTH ( TWIDDLE_WIDTH ),
	.BUTTERFLY_LAT ( BUTTERFLY_LAT )
) pgr_butterfly (
	.clk         ( clk          ),
	.rst_n       ( rst_n        ),
	.mult_en     ( butterfly_vld),
	.first_lev_s ( first_lev_s  ),
	.fft_i_index ( fft_i_index  ),
	.a_signed    ( a_signed     ),
	.b_signed    ( b_signed     ),
	.twiddle_re  ( twiddle_re   ),
	.twiddle_im  ( twiddle_im   ),
	.dat_ain_re  ( dat_ain_re   ),
	.dat_ain_im  ( dat_ain_im   ),
	.dat_bin_re  ( dat_bin_re   ),
	.dat_bin_im  ( dat_bin_im   ),
	.dat_out_vld ( dat_out_vld  ),
	.first_lev_b ( first_lev_b  ),
	.fft_o_index ( fft_o_index  ),
	.dat_aout_re ( dat_aout_re  ),
	.dat_aout_im ( dat_aout_im  ),
	.dat_bout_re ( dat_bout_re  ),
	.dat_bout_im ( dat_bout_im  )
);

assign bf_o_valid = dat_out_vld;
assign bf_a_data = {dat_aout_im, dat_aout_re};
assign bf_b_data = {dat_bout_im, dat_bout_re};

fft_o_switch #(
	.DATA_WIDTH    (2*DATA_WIDTH ),
	.ADDR_WIDTH    ( ADDR_WIDTH  )
) fft_o_switch_u (
	.clk           ( clk           ),
	.rst_n         ( rst_n         ),
	.first_level   ( first_lev_b   ),
	.i_rd_addr     ( fft_o_index   ),
	.i_rd_valid    ( bf_o_valid    ),
	.ia_rd_data    ( bf_a_data     ),
	.ib_rd_data    ( bf_b_data     ),
	.addr_index    ( o_wr_index    ),
	.butterfly_vld ( o_wr_valid    ),
	.butterfly_ain ( ao_wr_data    ),
	.butterfly_bin ( bo_wr_data    )
);

pgr_fft_out #(
	.LEN_WIDTH  ( LEN_WIDTH    ),
	.DATA_WIDTH ( 2*DATA_WIDTH ),
	.ADDR_WIDTH ( ADDR_WIDTH   )
) pgr_fft_out (
	.clk          ( clk          ),
	.rst_n        ( rst_n        ),
	.dft_length   ( dft_length   ),
	.fft_cdone    ( fft_cdone    ),
	.o_rd_enable  ( o_rd_enable  ),
	.ia_rd_data   ( ia_rd_data   ),
	.ib_rd_data   ( ib_rd_data   ),
	.m_axi_data   ( m_axi_data   ),
	.m_axi_user   ( m_axi_user   ),
	.m_axi_last   ( m_axi_last   ),
	.m_axi_valid  ( m_axi_valid  ),
	.m_axi_ready  ( m_axi_ready  )
);

// Log 2
function integer log2;
    input integer dep; begin
        log2 = 0;
        while (dep >= 1) begin
            dep  = dep >> 1;
            log2 = log2 + 1;
        end
    end
endfunction

endmodule//pgr_fft_top