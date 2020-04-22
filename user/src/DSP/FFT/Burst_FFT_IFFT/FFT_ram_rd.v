//******************************************************************
// Copyright (c) 2015 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************

`timescale 1 ns/1 ps

module pgr_fft_ram_rd #
(
    parameter   FFT_MODE            =   "FFT", //"FFT" or "IFFT"
    parameter   FFT_LENGTH          =   1023, //
    parameter   LEN_WIDTH           =   16,//
    parameter   DATA_WIDTH          =   18,//8~
    parameter   ADDR_WIDTH          =   9  //
)
(
    input  wire                     clk,//
    input  wire                     rst_n,

    input  wire                     dft_mode,
    input  wire [ LEN_WIDTH-1:0]    dft_length,
    input  wire [  3:0]             fft_lev_limit,

    input  wire                     nature_order,
    input  wire                     o_rd_enable,
    output reg                      first_level,

    input  wire                     fft_idone,//input done
    output reg                      fft_cdone, //calculate done

    output reg                      i_rd_valid,
    output reg                      i_rd_en,
    output wire [    LEN_WIDTH-2:0] i_rd_addr,
    output reg  [    LEN_WIDTH-2:0] phase_addr
);

localparam  NUMBER_WIDTH  = LEN_WIDTH-1;//15

reg                         fft_idone_r1;
reg                         fft_i_flag;
reg                         fft_i_flag_r1;
reg  [ NUMBER_WIDTH-1:0]    number_cnt;
reg  [              3:0]    level_cnt;
reg  [ NUMBER_WIDTH-1:0]    curr_addr;
reg  [ NUMBER_WIDTH-1:0]    next_addr;

wire                        one_lev_done;
wire                        fft_cdone_w;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        fft_idone_r1 <= 1'b0;
    end
    else
    begin
        fft_idone_r1 <= fft_idone;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        fft_i_flag <= 1'b0;
    end
    else if(fft_cdone_w)
    begin
        fft_i_flag <= 1'b0;
    end
    else if(fft_idone_r1)
    begin
        fft_i_flag <= 1'b1;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        number_cnt <= {NUMBER_WIDTH{1'b0}};
    end
    else if(one_lev_done)
    begin
        number_cnt <= {NUMBER_WIDTH{1'b0}};
    end
    else if(fft_i_flag | o_rd_enable )
    begin
        number_cnt <= number_cnt + { {(NUMBER_WIDTH-1){1'b0}}, 1'b1};
    end
end

assign one_lev_done = (number_cnt == dft_length[LEN_WIDTH-1:1]) & ( fft_i_flag | o_rd_enable);

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        level_cnt <= {4{1'b0}};
    end
    else if(fft_idone | fft_cdone)
    begin
        level_cnt <= {4{1'b0}};
    end
    else if(one_lev_done)
    begin
        level_cnt <= level_cnt + { {3{1'b0}}, 1'b1};
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        first_level <= 1'b0;
    end
    else if(level_cnt == 4'h0)
    begin
        first_level <= 1'b1;
    end
    else
    begin
        first_level <= 1'b0;
    end
end

assign fft_cdone_w = (level_cnt == (fft_lev_limit - 4'h1) ) & one_lev_done;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        fft_cdone <= 1'b0;
    end
    else
    begin
        fft_cdone <= fft_cdone_w;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        curr_addr <= {NUMBER_WIDTH{1'b0}};
        next_addr <= {NUMBER_WIDTH{1'b0}};
    end
    else //if()
    case(level_cnt)
        4'h2    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:2], 1'b0, number_cnt[1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:2], 1'b1, number_cnt[1]};
                    end

        4'h3    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:3], 1'b0, number_cnt[2:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:3], 1'b1, number_cnt[2:1]};
                    end

        4'h4    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:4], 1'b0, number_cnt[3:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:4], 1'b1, number_cnt[3:1]};
                    end

        4'h5    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:5], 1'b0, number_cnt[4:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:5], 1'b1, number_cnt[4:1]};
                    end

        4'h6    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:6], 1'b0, number_cnt[5:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:6], 1'b1, number_cnt[5:1]};
                    end

        4'h7    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:7], 1'b0, number_cnt[6:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:7], 1'b1, number_cnt[6:1]};
                    end

        4'h8    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:8], 1'b0, number_cnt[7:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:8], 1'b1, number_cnt[7:1]};
                    end

        4'h9    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:9], 1'b0, number_cnt[8:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:9], 1'b1, number_cnt[8:1]};
                    end

        4'hA    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:10], 1'b0, number_cnt[9:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:10], 1'b1, number_cnt[9:1]};
                    end

        4'hB    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:11], 1'b0, number_cnt[10:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:11], 1'b1, number_cnt[10:1]};
                    end

        4'hC    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:12], 1'b0, number_cnt[11:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:12], 1'b1, number_cnt[11:1]};
                    end

        4'hD    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:13], 1'b0, number_cnt[12:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:13], 1'b1, number_cnt[12:1]};
                    end

        4'hE    :   if(number_cnt[0] == 1'b0)
                    begin
                        curr_addr <= { number_cnt[NUMBER_WIDTH-1:14], 1'b0, number_cnt[13:1]};
                        next_addr <= { number_cnt[NUMBER_WIDTH-1:14], 1'b1, number_cnt[13:1]};
                    end

        4'hF    :   begin
                        curr_addr <= { 1'b0, number_cnt[NUMBER_WIDTH-1:1] };
                        next_addr <= { 1'b1, number_cnt[NUMBER_WIDTH-1:1] };
                    end

        default :   begin
                        curr_addr <= {number_cnt[NUMBER_WIDTH-1:1], 1'b0 };
                        next_addr <= {number_cnt[NUMBER_WIDTH-1:1], 1'b1 };
                    end
    endcase
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        i_rd_en <= 1'b0;
    end
    else if(fft_i_flag | o_rd_enable )
    begin
        i_rd_en <= 1'b1;
    end
    else 
    begin
        i_rd_en <= 1'b0;
    end
end

assign i_rd_addr = number_cnt[0] ? curr_addr : next_addr;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        phase_addr <= {NUMBER_WIDTH{1'b0}};
    end
    else //if()
    case(level_cnt)
        4'h1    :   phase_addr <= {number_cnt[NUMBER_WIDTH-15:0], 14'h0000};

        4'h2    :   phase_addr <= {number_cnt[NUMBER_WIDTH-14:0], 13'h0000};

        4'h3    :   phase_addr <= {number_cnt[NUMBER_WIDTH-13:0], 12'h000};

        4'h4    :   phase_addr <= {number_cnt[NUMBER_WIDTH-12:0], 11'h000};

        4'h5    :   phase_addr <= {number_cnt[NUMBER_WIDTH-11:0], 10'h000};

        4'h6    :   phase_addr <= {number_cnt[NUMBER_WIDTH-10:0], 9'h000};

        4'h7    :   phase_addr <= {number_cnt[NUMBER_WIDTH-9:0], 8'h00};

        4'h8    :   phase_addr <= {number_cnt[NUMBER_WIDTH-8:0], 7'h00};

        4'h9    :   phase_addr <= {number_cnt[NUMBER_WIDTH-7:0], 6'h00};

        4'hA    :   phase_addr <= {number_cnt[NUMBER_WIDTH-6:0], 5'h00};

        4'hB    :   phase_addr <= {number_cnt[NUMBER_WIDTH-5:0], 4'h0};

        4'hC    :   phase_addr <= {number_cnt[NUMBER_WIDTH-4:0], 3'h0};

        4'hD    :   phase_addr <= {number_cnt[NUMBER_WIDTH-3:0], 2'h0};

        4'hE    :   phase_addr <= {number_cnt[NUMBER_WIDTH-2:0], 1'h0};

        4'hF    :   phase_addr <= number_cnt[NUMBER_WIDTH-1:0];

        default :   phase_addr <= {NUMBER_WIDTH{1'b0}};
    endcase
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        fft_i_flag_r1 <= 1'b0;
    end
    else 
    begin
        fft_i_flag_r1 <= fft_i_flag;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        i_rd_valid <= 1'b0;
    end
    else 
    begin
        i_rd_valid <= fft_i_flag_r1;
    end
end

endmodule//pgr_fft_ram_rd