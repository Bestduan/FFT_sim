`timescale 1 ns/1 ps
module fft_out #(
    parameter   LEN_WIDTH           =   4, //8~
    parameter   DATA_WIDTH          =   36, //8~
    parameter   ADDR_WIDTH          =   9  //
) (
    input  wire                      clk,//
    input  wire                      rst_n,
    input  wire [LEN_WIDTH - 1 : 0]  dft_length,

    input  wire                      fft_cdone,
    output reg                       o_rd_enable,

    input  wire [DATA_WIDTH - 1 : 0] ia_rd_data,
    input  wire [DATA_WIDTH - 1 : 0] ib_rd_data,

    output reg  [DATA_WIDTH - 1 : 0] m_axi_data,
    output wire [ADDR_WIDTH : 0]     m_axi_user,//index
    output reg                       m_axi_last,
    output reg                       m_axi_valid,
    input  wire                      m_axi_ready
);

reg                       fft_o_flag;
reg                       o_rd_next;
reg                       o_rd_enable_r1;
reg                       o_rd_enable_r2;
reg                       o_rd_enable_r3;
reg  [ADDR_WIDTH : 0]     out_index;
reg  [ADDR_WIDTH - 1 : 0] out_rd_cnt;

wire                      out_rd_over;
wire                      m_axi_last_w;

always@(posedge clk or negedge rst_n)begin
    if (!rst_n)
        fft_o_flag <= 1'b0;
    else if(out_rd_over)
        fft_o_flag <= 1'b0;
    else if(fft_cdone)
        fft_o_flag <= 1'b1;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_rd_cnt <= {ADDR_WIDTH{1'b0}};
    else if(fft_cdone)
        out_rd_cnt <= {ADDR_WIDTH{1'b0}};
    else if(o_rd_enable)
        out_rd_cnt <= out_rd_cnt + { {(ADDR_WIDTH-1){1'b0}}, 1'b1 };
end

assign out_rd_over = (out_rd_cnt == dft_length[ADDR_WIDTH:1]) & o_rd_enable;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        o_rd_enable <= 1'b0;
    else if( (o_rd_next & fft_o_flag & m_axi_ready) | fft_cdone)
        o_rd_enable <= 1'b1;
    else
        o_rd_enable <= 1'b0;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        o_rd_next <= 1'b0;
    else if(o_rd_enable)
        o_rd_next <= 1'b1;
    else if(m_axi_ready)
        o_rd_next <= 1'b0;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        o_rd_enable_r1 <= 1'b0;
        o_rd_enable_r2 <= 1'b0;
        o_rd_enable_r3 <= 1'b0;
    end
    else begin
        o_rd_enable_r1 <= o_rd_enable;
        o_rd_enable_r2 <= o_rd_enable_r1;
        o_rd_enable_r3 <= o_rd_enable_r2;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        m_axi_valid <= 1'b0;
    else if(m_axi_last & m_axi_ready)
        m_axi_valid <= 1'b0;
    else if(o_rd_enable_r2)
        m_axi_valid <= 1'b1;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        m_axi_data <= {DATA_WIDTH{1'b0}};
    else if(o_rd_enable_r2)
        m_axi_data <= ia_rd_data;
    else if(o_rd_enable_r3)
        m_axi_data <= ib_rd_data;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_index <= {(ADDR_WIDTH+1){1'b0}};
    else if(m_axi_last & m_axi_ready)
        out_index <= {(ADDR_WIDTH+1){1'b0}};
    else if(m_axi_valid & m_axi_ready)
        out_index <= out_index + { {ADDR_WIDTH{1'b0}}, 1'b1 };
end

assign m_axi_last_w = (out_index[ADDR_WIDTH:0] == {dft_length[ADDR_WIDTH:1], 1'b0} ) & m_axi_valid & m_axi_ready;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        m_axi_last <= 1'b0;
    else if(m_axi_last_w)
        m_axi_last <= 1'b1;
    else if(m_axi_ready)
        m_axi_last <= 1'b0;
end

assign m_axi_user = out_index;

endmodule//fft_out