`timescale 1ns / 1ps
module BI(databus, ioaddr, tx_buf, rx_buf, tbr, rda, iocs, iorw, db_low, db_high, status_reg);

input tbr, rda, iocs, iorw;
inout [7:0] databus;
input [1:0] ioaddr;
input [7:0] rx_buf;
output [7:0] tx_buf;
output [7:0] db_low, db_high;
output [7:0] status_reg;

//status register logic
assign status_reg[7:2] = 6'b0;
assign status_reg[1] = tbr;
assign status_reg[0] = rda;

//transmit buffer
assign tx_buf = (ioaddr == 2'b00 && iorw == 1'b0) ? databus : 8'bz;

//databus logic
assign databus = (ioaddr == 2'b00 && iorw == 1'b1) ? rx_buf : 
                                 (ioaddr == 2'b01) ? status_reg : 8'bz;
//db registers
assign db_low = (ioaddr == 2'b10) ? databus : 8'bz;
assign db_high = (ioaddr == 2'b11) ? databus : 8'bz;

endmodule
