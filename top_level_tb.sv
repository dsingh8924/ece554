`timescale 1ns / 1ps
module top_level_tb();

reg clk, rst, rxd;
reg [1:0] br_cfg;
wire txd;

top_level top(.clk(clk),
                .rst(rst),
                .txd(txd),
                .rxd(rxd),
                .br_cfg(br_cfg)
                );

initial begin
clk = 0;
rst = 0;
br_cfg = 2'b01;
rxd = 0;
#10 rst=1;
end

always begin
#104000 rxd = ~rxd;//time between 2 enables is about 6.5us, this has to be 16x of that
#208000;
end

always #5 clk=~clk;

endmodule
