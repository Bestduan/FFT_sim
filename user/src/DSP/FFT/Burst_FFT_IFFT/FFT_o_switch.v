`timescale 1 ns/1 ps
module fft_o_switch #(
    parameter   ADDR_WIDTH          =   18, //8~
    parameter   DATA_WIDTH          =   18 //8~
) (
    input  wire                      clk,
    input  wire                      rst_n,

    input  wire                      first_level,
    input  wire [ADDR_WIDTH - 1 : 0] i_rd_addr,
    input  wire                      i_rd_valid,
    input  wire [DATA_WIDTH - 1 : 0] ia_rd_data,
    input  wire [DATA_WIDTH - 1 : 0] ib_rd_data,

    output reg  [ADDR_WIDTH - 1 : 0] addr_index,
    output reg                       butterfly_vld,
    output reg  [DATA_WIDTH - 1 : 0] butterfly_ain,
    output reg  [DATA_WIDTH - 1 : 0] butterfly_bin
);

reg                         i_rd_valid_r1;
reg                         first_level_r1;
reg                         first_level_r2;
reg  [ADDR_WIDTH - 1 : 0]   i_rd_addr_r1;
reg  [DATA_WIDTH - 1 : 0]   ia_rd_data_r1;
reg  [DATA_WIDTH - 1 : 0]   ib_rd_data_r1;
reg  [DATA_WIDTH - 1 : 0]   butterfly_btemp;
reg                         i_rcv_enable;
reg                         i_rcv_enable_r1;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ia_rd_data_r1 <= {DATA_WIDTH{1'b0}};
    else if(i_rd_valid)
        ia_rd_data_r1 <= ia_rd_data;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ib_rd_data_r1 <= {DATA_WIDTH{1'b0}};
    else if(i_rd_valid)
        ib_rd_data_r1 <= ib_rd_data;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        i_rd_valid_r1 <= 1'b0;
    else
        i_rd_valid_r1 <= i_rd_valid;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        first_level_r1 <= 1'b0;
        first_level_r2 <= 1'b0;
    end
    else begin
        first_level_r1 <= first_level;
        first_level_r2 <= first_level_r1;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        i_rcv_enable <= 1'b0;
    else if( (~i_rd_valid_r1 & i_rd_valid) | i_rcv_enable_r1)
        i_rcv_enable <= 1'b1;
    else if( ~i_rd_valid | i_rcv_enable)
        i_rcv_enable <= 1'b0;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        i_rcv_enable_r1 <= 1'b0;
    else
        i_rcv_enable_r1 <= i_rcv_enable;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        butterfly_btemp <= {DATA_WIDTH{1'b0}};
    else if(i_rcv_enable)
        butterfly_btemp <= ib_rd_data_r1;
end


always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        butterfly_ain <= {DATA_WIDTH{1'b0}};
        butterfly_bin <= {DATA_WIDTH{1'b0}};
    end
    else if(first_level_r2) begin
        butterfly_ain <= ia_rd_data_r1;
        butterfly_bin <= ib_rd_data_r1;
    end
    else if(i_rcv_enable_r1) begin
        butterfly_ain <= butterfly_btemp;
        butterfly_bin <= ib_rd_data_r1;
    end
    else if(i_rcv_enable) begin
        butterfly_ain <= ia_rd_data_r1;
        butterfly_bin <= ia_rd_data;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        butterfly_vld <= 1'b0;
    else
        butterfly_vld <= i_rd_valid_r1;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        i_rd_addr_r1 <= {ADDR_WIDTH{1'b0}};
    else
        i_rd_addr_r1 <= i_rd_addr;
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        addr_index <= {ADDR_WIDTH{1'b0}};
    else if(i_rd_valid_r1)
        addr_index <= i_rd_addr_r1;
end

endmodule//fft_o_switch