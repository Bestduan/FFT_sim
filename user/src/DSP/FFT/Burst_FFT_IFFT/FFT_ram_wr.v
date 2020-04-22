//******************************************************************
// Copyright (c) 2015 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************

`timescale 1 ns/1 ps

module pgr_fft_ram_wr #
(
    parameter   LEN_WIDTH           =   16,//
    parameter   ADDR_WIDTH          =   16,//
    parameter   DATA_WIDTH          =   18 //8~
)
(
    input  wire                     clk,//
    input  wire                     rst_n,

    input  wire                     fft_odone,
    input  wire [ LEN_WIDTH-1:0]    dft_length,
    input  wire [  3:0]             fft_lev_limit,

    input  wire                     s_axi_valid,
    input  wire                     s_axi_last,
    input  wire [   DATA_WIDTH-1:0] s_axi_data,
    input  wire                     s_axi_ready,

    input  wire                     o_wr_valid,
    input  wire [   ADDR_WIDTH-1:0] o_wr_index,
    input  wire [   DATA_WIDTH-1:0] ao_wr_data,
    input  wire [   DATA_WIDTH-1:0] bo_wr_data,

    output reg                      a_wr_en,
    output reg  [   DATA_WIDTH-1:0] a_wr_data,
//    output reg  [    LEN_WIDTH-2:0] a_wr_addr,
    output reg                      b_wr_en,
    output reg  [   DATA_WIDTH-1:0] b_wr_data,
    output reg  [    LEN_WIDTH-2:0] b_wr_addr
);

reg  [    LEN_WIDTH-1:0]    wr_dat_cnt;
reg                         mem_select;

wire                        fft_in_state;
wire                        one_lev_done;

assign fft_in_state = s_axi_valid & s_axi_ready;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        wr_dat_cnt <= {LEN_WIDTH{1'b0}};
    end
    else if( (s_axi_last & s_axi_ready) | one_lev_done | fft_odone  )
    begin
        wr_dat_cnt <= {LEN_WIDTH{1'b0}};
    end
    else if(fft_in_state | o_wr_valid)
    begin
        wr_dat_cnt <= wr_dat_cnt + { {(LEN_WIDTH-1){1'b0}}, 1'b1};
    end
end

assign one_lev_done = (wr_dat_cnt == dft_length[LEN_WIDTH-1:1] ) & o_wr_valid;

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        mem_select <= 1'b0;
    end
    else if(~fft_in_state)
    begin
        mem_select <= 1'b0;
    end
    else if(wr_dat_cnt == dft_length[LEN_WIDTH-1:1] )
    begin
        mem_select <= 1'b1;
    end
end

//always@(posedge clk or negedge rst_n)
//begin
//    if (!rst_n)
//    begin
//        a_wr_addr <= {(LEN_WIDTH-1){1'b0}};
//    end
//    else if(fft_in_state)
//        case(fft_lev_limit)
//            4'h4    :   a_wr_addr <= { {(LEN_WIDTH-4 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2] };
//            4'h5    :   a_wr_addr <= { {(LEN_WIDTH-5 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3] };
//            4'h6    :   a_wr_addr <= { {(LEN_WIDTH-6 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4] };
//            4'h7    :   a_wr_addr <= { {(LEN_WIDTH-7 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5] };
//            4'h8    :   a_wr_addr <= { {(LEN_WIDTH-8 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6] };
//            4'h9    :   a_wr_addr <= { {(LEN_WIDTH-9 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7] };
//            4'hA    :   a_wr_addr <= { {(LEN_WIDTH-10){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8] };
//            4'hB    :   a_wr_addr <= { {(LEN_WIDTH-11){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9] };
//            4'hC    :   a_wr_addr <= { {(LEN_WIDTH-12){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9], wr_dat_cnt[10] };
//            4'hD    :   a_wr_addr <= { {(LEN_WIDTH-13){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9], wr_dat_cnt[10], wr_dat_cnt[11] };
//            4'hE    :   a_wr_addr <= { {(LEN_WIDTH-14){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9], wr_dat_cnt[10], wr_dat_cnt[11], wr_dat_cnt[12] };
//            4'hF    :   a_wr_addr <= { {(LEN_WIDTH-15){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9], wr_dat_cnt[10], wr_dat_cnt[11], wr_dat_cnt[12], wr_dat_cnt[13] };
//            default :   a_wr_addr <= { {(LEN_WIDTH-3 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1] };
//        endcase
//    else
//    begin
////        a_wr_addr <= wr_dat_cnt[LEN_WIDTH-2:0];
//        a_wr_addr <= { {(LEN_WIDTH-1-ADDR_WIDTH){1'b0}}, o_wr_index};
//    end
//end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        b_wr_addr <= {(LEN_WIDTH-1){1'b0}};
    end
    else if(fft_in_state)
        case(fft_lev_limit)
            4'h4    :   b_wr_addr <= { {(LEN_WIDTH-4 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2] };
            4'h5    :   b_wr_addr <= { {(LEN_WIDTH-5 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3] };
            4'h6    :   b_wr_addr <= { {(LEN_WIDTH-6 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4] };
            4'h7    :   b_wr_addr <= { {(LEN_WIDTH-7 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5] };
            4'h8    :   b_wr_addr <= { {(LEN_WIDTH-8 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6] };
            4'h9    :   b_wr_addr <= { {(LEN_WIDTH-9 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7] };
            4'hA    :   b_wr_addr <= { {(LEN_WIDTH-10){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8] };
            4'hB    :   b_wr_addr <= { {(LEN_WIDTH-11){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9] };
            4'hC    :   b_wr_addr <= { {(LEN_WIDTH-12){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9], wr_dat_cnt[10] };
            4'hD    :   b_wr_addr <= { {(LEN_WIDTH-13){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9], wr_dat_cnt[10], wr_dat_cnt[11] };
            4'hE    :   b_wr_addr <= { {(LEN_WIDTH-14){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9], wr_dat_cnt[10], wr_dat_cnt[11], wr_dat_cnt[12] };
            4'hF    :   b_wr_addr <= { {(LEN_WIDTH-15){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1], wr_dat_cnt[2], wr_dat_cnt[3], wr_dat_cnt[4], wr_dat_cnt[5], wr_dat_cnt[6], wr_dat_cnt[7], wr_dat_cnt[8], wr_dat_cnt[9], wr_dat_cnt[10], wr_dat_cnt[11], wr_dat_cnt[12], wr_dat_cnt[13] };
            default :   b_wr_addr <= { {(LEN_WIDTH-3 ){1'b0}}, wr_dat_cnt[0], wr_dat_cnt[1] };
        endcase
    else
    begin
//        b_wr_addr <= wr_dat_cnt[LEN_WIDTH-2:0];
        b_wr_addr <= { {(LEN_WIDTH-1-ADDR_WIDTH){1'b0}}, o_wr_index};
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        a_wr_data <= {DATA_WIDTH{1'b0}};
    end
    else if( fft_in_state )
    begin
        a_wr_data <= s_axi_data;
    end
    else if( o_wr_valid )
    begin
        a_wr_data <= ao_wr_data;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        a_wr_en <= 1'b0;
    end
    else if( (~mem_select & fft_in_state) | o_wr_valid)
    begin
        a_wr_en <= 1'b1;
    end
    else
    begin
        a_wr_en <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        b_wr_data <= {DATA_WIDTH{1'b0}};
    end
    else if( fft_in_state )
    begin
        b_wr_data <= s_axi_data;
    end
    else if( o_wr_valid )
    begin
        b_wr_data <= bo_wr_data;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        b_wr_en <= 1'b0;
    end
    else if( (mem_select & fft_in_state) | o_wr_valid)
    begin
        b_wr_en <= 1'b1;
    end
    else
    begin
        b_wr_en <= 1'b0;
    end
end

endmodule//pgr_fft_ram_wr