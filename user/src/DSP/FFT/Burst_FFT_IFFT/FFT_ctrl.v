`timescale 1 ns/1 ps
module fft_ctrl #(
    parameter   FFT_LENGTH          =   1023, //
    parameter   LEN_WIDTH           =   16, //
    parameter   LEVEL_VALUE         =   16, //
    parameter   FFT_MODE            =   "FFT", //"FFT" or "IFFT"
    parameter   DATA_WIDTH          =   18,//8~
    parameter   ADDR_WIDTH          =   9  //
) (
    input  wire                     clk,//
    input  wire                     rst_n,

    input  wire                     cfg_valid,
    input  wire [ 23:0]             cfg_data,
    output reg                      cfg_ready,

    input  wire                     s_axi_valid,
    input  wire                     s_axi_last,
    output reg                      s_axi_ready,

    output reg                      dft_mode,
    output reg  [ LEN_WIDTH-1:0]    dft_length,
    output reg  [  3:0]             fft_lev_limit,

    input  wire                     fft_cdone,//calculate done
    input  wire                     fft_odone,//output done
    output reg                      fft_idone //input done
);

localparam  ST_IDLE  = 5'b00001;
localparam  ST_CFG   = 5'b00010;
localparam  ST_FFT_I = 5'b00100;
localparam  ST_FFT_C = 5'b01000;
localparam  ST_FFT_O = 5'b10000;

reg [  4:0]     curr_state;
reg [  4:0]     next_state;
reg             cfg_valid_r1;

wire            fft_in_last;

assign fft_in_last = s_axi_last & s_axi_ready & s_axi_valid;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fft_idone <= 1'b0;
    end
    else begin
        fft_idone <= fft_in_last;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        curr_state <= ST_IDLE;
    end
    else begin
        curr_state <= next_state;
    end
end

always@(*)
case(curr_state)
    ST_IDLE     :   if(s_axi_valid)
                        next_state = ST_FFT_I;
                    else if(cfg_valid)
                        next_state = ST_CFG;
                    else
                        next_state = ST_IDLE;

    ST_CFG      :   if(cfg_valid)
                        next_state = ST_CFG;
                    else
                        next_state = ST_IDLE;

    ST_FFT_I    :   if(fft_in_last)
                        next_state = ST_FFT_C;
                    else
                        next_state = ST_FFT_I;

    ST_FFT_C    :   if(fft_cdone)
                        next_state = ST_FFT_O;
                    else
                        next_state = ST_FFT_C;

    ST_FFT_O    :   if(fft_odone)
                        next_state = ST_IDLE;
                    else
                        next_state = ST_FFT_O;
    default     :   next_state = ST_IDLE;
endcase

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cfg_ready <= 1'b0;
    end
    else if( curr_state == ST_CFG ) begin
        cfg_ready <= 1'b1;
    end
    else begin
        cfg_ready <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axi_ready <= 1'b0;
    end
    else if((curr_state == ST_IDLE) | (~s_axi_last & (curr_state == ST_FFT_I))) begin
        s_axi_ready <= 1'b1;
    end
    else begin
        s_axi_ready <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dft_length <= FFT_LENGTH;
        dft_mode   <= FFT_MODE;
    end
    else if(cfg_valid & cfg_ready) begin
        dft_length <= cfg_data[15:0];
        dft_mode   <= cfg_data[16];
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cfg_valid_r1 <= 1'b0;
    end
    else if(cfg_valid & cfg_ready) begin
        cfg_valid_r1 <= 1'b1;
    end
    else begin
        cfg_valid_r1 <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fft_lev_limit <= LEVEL_VALUE;
    end
    else if(cfg_valid_r1)
    casex(dft_length[15:1])
        15'b1xx_xxxx_xxxx_xxxx  :   fft_lev_limit <= 4'hF;
        15'b01x_xxxx_xxxx_xxxx  :   fft_lev_limit <= 4'hE;
        15'b001_xxxx_xxxx_xxxx  :   fft_lev_limit <= 4'hD;
        15'b000_1xxx_xxxx_xxxx  :   fft_lev_limit <= 4'hC;
        15'b000_01xx_xxxx_xxxx  :   fft_lev_limit <= 4'hB;
        15'b000_001x_xxxx_xxxx  :   fft_lev_limit <= 4'hA;
        15'b000_0001_xxxx_xxxx  :   fft_lev_limit <= 4'h9;
        15'b000_0000_1xxx_xxxx  :   fft_lev_limit <= 4'h8;
        15'b000_0000_01xx_xxxx  :   fft_lev_limit <= 4'h7;
        15'b000_0000_001x_xxxx  :   fft_lev_limit <= 4'h6;
        15'b000_0000_0001_xxxx  :   fft_lev_limit <= 4'h5;
        15'b000_0000_0000_1xxx  :   fft_lev_limit <= 4'h4;
        default                 :   fft_lev_limit <= 4'h3;
    endcase
end

endmodule//fft_ctrl