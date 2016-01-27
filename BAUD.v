module BAUD(clk, rst, DivBuff, IOaddr, rre, tre);

input clk, rst; //systm clk
input [7:0]DivBuff; //input DB from the bus
input [1:0] IOaddr; //IOaddr to determine which bit of db come in
output reg rre, tre; //recieve and transmit enables
wire [15:0]db; //division buffer
reg [15:0]BAUDcnt; //counters to divide the clk cycle
reg [7:0]hi;

//assign bit of the division buffer
assign db[15:8] = (IOaddr == 2'b11) ? DivBuff : db[15:8];
assign db[7:0] = (IOaddr == 2'b10) ? DivBuff : db[7:0];

//recieve count down timer
always@(posedge clk) begin

  if(!rst) BAUDcnt = db;
  else BAUDcnt = BAUDcnt - 16'h0001;
  if(BAUDcnt == 16'h0000) begin
    rre = 1'b1;
    tre = 1'b1;
    BAUDcnt = db;
  end else begin
    rre = 1'b0;
    tre = 1'b0;
  end
end

endmodule
