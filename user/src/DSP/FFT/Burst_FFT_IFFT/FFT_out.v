//******************************************************************
// Copyright (c) 2015 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************

`timescale 1 ns/1 ps

module pgr_fft_out #
(
    parameter   LEN_WIDTH           =   4, //8~
    parameter   DATA_WIDTH          =   36, //8~
    parameter   ADDR_WIDTH          =   9  //
)
(
    input  wire                     clk,//
    input  wire                     rst_n,
    input  wire [ LEN_WIDTH-1:0]    dft_length,

    input  wire                     fft_cdone,
    output reg                      o_rd_enable,

    input  wire [   DATA_WIDTH-1:0] ia_rd_data,
    input  wire [   DATA_WIDTH-1:0] ib_rd_data,

    output reg  [   DATA_WIDTH-1:0] m_axi_data,
    output wire [   ADDR_WIDTH  :0] m_axi_user,//index
    output reg                      m_axi_last,
    output reg                      m_axi_valid,
    input  wire                     m_axi_ready
);

reg                         fft_o_flag;
reg                         o_rd_next;
reg                         o_rd_enable_r1;
reg                         o_rd_enable_r2;
reg                         o_rd_enable_r3;
//reg  [   DATA_WIDTH-1:0]    ia_rd_data_r1;
//reg  [   DATA_WIDTH-1:0]    ib_rd_data_r1;
reg  [   ADDR_WIDTH-1:0]    out_rd_cnt;
reg  [   ADDR_WIDTH  :0]    out_index;

wire                        out_rd_over;
wire                        m_axi_last_w;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        fft_o_flag <= 1'b0;
    end
    else if(out_rd_over)
    begin
        fft_o_flag <= 1'b0;
    end
    else if(fft_cdone)
    begin
        fft_o_flag <= 1'b1;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        out_rd_cnt <= {ADDR_WIDTH{1'b0}};
    end
    else if(fft_cdone)
    begin
        out_rd_cnt <= {ADDR_WIDTH{1'b0}};
    end
    else if(o_rd_enable)
    begin
        out_rd_cnt <= out_rd_cnt + { {(ADDR_WIDTH-1){1'b0}}, 1'b1 };
    end
end

assign out_rd_over = (out_rd_cnt == dft_length[ADDR_WIDTH:1]) & o_rd_enable;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        o_rd_enable <= 1'b0;
    end
    else if( (o_rd_next & fft_o_flag & m_axi_ready) | fft_cdone)
    begin
        o_rd_enable <= 1'b1;
    end
    else
    begin
        o_rd_enable <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        o_rd_next <= 1'b0;
    end
    else if(o_rd_enable)
    begin
        o_rd_next <= 1'b1;
    end
    else if(m_axi_ready)
    begin
        o_rd_next <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        o_rd_enable_r1 <= 1'b0;
        o_rd_enable_r2 <= 1'b0;
        o_rd_enable_r3 <= 1'b0;
    end
    else
    begin
        o_rd_enable_r1 <= o_rd_enable;
        o_rd_enable_r2 <= o_rd_enable_r1;
        o_rd_enable_r3 <= o_rd_enable_r2;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        m_axi_valid <= 1'b0;
    end
    else if(m_axi_last & m_axi_ready)
    begin
        m_axi_valid <= 1'b0;
    end
    else if(o_rd_enable_r2)
    begin
        m_axi_valid <= 1'b1;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        m_axi_data <= {DATA_WIDTH{1'b0}};
    end
    else if(o_rd_enable_r2)
    begin
        m_axi_data <= ia_rd_data;
    end
    else if(o_rd_enable_r3)
    begin
        m_axi_data <= ib_rd_data;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        out_index <= {(ADDR_WIDTH+1){1'b0}};
    end
    else if(m_axi_last & m_axi_ready)
    begin
        out_index <= {(ADDR_WIDTH+1){1'b0}};
    end
    else if(m_axi_valid & m_axi_ready)
    begin
        out_index <= out_index + { {ADDR_WIDTH{1'b0}}, 1'b1 };
    end
end

assign m_axi_last_w = (out_index[ADDR_WIDTH:0] == {dft_length[ADDR_WIDTH:1], 1'b0} ) & m_axi_valid & m_axi_ready;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        m_axi_last <= 1'b0;
    end
    else if(m_axi_last_w)
    begin
        m_axi_last <= 1'b1;
    end
    else if(m_axi_ready)
    begin
        m_axi_last <= 1'b0;
    end
end

assign m_axi_user = out_index;

endmodule//pgr_fft_out