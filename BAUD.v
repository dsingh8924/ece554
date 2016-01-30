`timescale 1ns / 1ps
module BAUD(clk, rst_n, databus, ioaddr, en);

input clk, rst_n; //systm clk
input [7:0] databus; //input DB from the bus
input [1:0] ioaddr; //ioaddr to determine which bit of db come in
output reg en; //recieve and transmit enables
reg [15:0]db; //division buffer
reg [15:0]BAUDcnt; //counters to divide the clk cycle
reg [7:0]hi;

//assign bit of the division buffer
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        db <= 16'b0;
    end else begin
        if (ioaddr == 2'b11)
            db[15:8] <= databus;
        if (ioaddr == 2'b10)
            db[7:0] <= databus;
    end
end

//count down to send enables
always@(posedge clk, negedge rst_n) begin
  if(!rst_n) begin
    BAUDcnt <= 16'b0000;
    en <= 1'b0;
  end else if(BAUDcnt == 16'h0000) begin
    BAUDcnt <= db;
    en <= 1'b1;
  end else begin
    BAUDcnt <= BAUDcnt - 16'h0001;
    en <= 1'b0;
  end
end

endmodule
