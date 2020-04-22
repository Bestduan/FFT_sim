//******************************************************************
// Copyright (c) 2015 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************

`timescale 1 ns/1 ps

module pgr_fft_src_in #
(
    parameter   FFT_LENGTH          =   1023, //8~
    parameter   DATA_WIDTH          =   16, //8~
    parameter   ADDR_WIDTH          =   9  //
)
(
    input  wire                     clk,//
    input  wire                     rst_n,

    input  wire                     fft_start,

    output wire                     cfg_valid,
    output wire [ 23:0]             cfg_data,
    input  wire                     cfg_ready,

    output wire [   DATA_WIDTH-1:0] s_axi_data,
    output reg                      s_axi_last,
    output reg                      s_axi_valid,
    input  wire                     s_axi_ready
);
localparam IDATA_WIDTH = DATA_WIDTH/2;

reg  [   ADDR_WIDTH   :0]   src_addr;
reg                         src_rd_en;
wire [  IDATA_WIDTH-1 :0]   src_data;
wire                        s_axi_last_w;

assign cfg_valid = 1'b0;
assign cfg_data  = 24'h0000ff;

dram_16x1024 fft_in_src(
    .addr        ( src_addr    ),
    .rd_data     ( src_data    ),
    .clk         ( clk         ),
    .clk_en      ( src_rd_en   ),
    .rst         ( ~rst_n      )
    );

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        src_rd_en <= 1'b0;
    end
    else if(fft_start)
    begin
        src_rd_en <= 1'b1;
    end
    else if(s_axi_last_w)
    begin
        src_rd_en <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        src_addr <= {(ADDR_WIDTH+1){1'b0}};
    end
    else if(s_axi_last_w)
    begin
        src_addr <= {(ADDR_WIDTH+1){1'b0}};
    end
    else if(src_rd_en)
    begin
        src_addr <= src_addr + { {ADDR_WIDTH{1'b0}}, 1'b1 };
    end
end

assign s_axi_last_w = (src_addr == FFT_LENGTH) & s_axi_ready;
assign s_axi_data  = { {16{1'b0}}, src_data};

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        s_axi_valid <= 1'b0;
    end
    else
    begin
        s_axi_valid <= src_rd_en;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        s_axi_last <= 1'b0;
    end
    else if(s_axi_ready & s_axi_last)
    begin
        s_axi_last <= 1'b0;
    end
    else if(s_axi_last_w)
    begin
        s_axi_last <= 1'b1;
    end
end

endmodule//pgr_fft_src_in