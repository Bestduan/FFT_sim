//******************************************************************
// Copyright (c) 2014 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************
`timescale 1ns/1ns
module fft_test_top_tb();

reg         clk;
reg         rstn;
wire        led;

initial clk = 1'b0;
always #5 clk = ~clk;

initial begin
    #0 
    $dumpfile("fft_test_top.vcd");
    $dumpvars(0,fft_test_top_tb.clk);
    $dumpvars(0,fft_test_top_tb.rstn);
    $dumpvars(0,fft_test_top_tb.led);
    rstn = 1'b0;
    #55 rstn = 1'b1;
    
end


//
//GTP_GRS GRS_INST(
//    .GRS_N()
//);

fft_test_top DUT(
    .clk     (clk    ),
    .rstn   (rstn   ),

    .led     (led    )
);
endmodule //tb_test

