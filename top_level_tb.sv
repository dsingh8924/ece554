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

always #5120 rxd = ~rxd;

always #5 clk=~clk;

endmodule
