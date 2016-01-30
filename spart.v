`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart(
    input clk,
    input rst,
    input iocs,
    input iorw,
    output rda,
    output tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
    );

wire [7:0] tx_buf, rx_buf, db_low, db_high;
wire brg_en;

BI bus_instance(.databus(databus),
                .ioaddr(ioaddr),
                .tx_buf(tx_buf),
                .rx_buf(rx_buf),
                .tbr(tbr),
                .rda(rda),
                .iocs(iocs),
                .iorw(iorw),
                .db_low(db_low),
                .db_high(db_high),
                .status_reg()//nothing to connect this to in the port list
                );
BAUD baud_rate_gen(.clk(clk),
                .rst_n(rst_n),
                .databus(databus),
                .ioaddr(ioaddr),
                .en(brg_en)
                );
transmit transmitter(.clk(clk),
                .rst_n(rst_n),
                .brg_tx_en(brg_tx_en),
                .iocs(iocs),
                .iorw(iorw),
                .ioaddr(ioaddr),
                .tx_buf(tx_buf),
                .txd(txd),
                .tbr(tbr)
                );
receive receiver (.clk(clk),
                .rst_n(rst_n),
                .brg_rx_en(brg_rx_en),
                .iocs(iocs),
                .iorw(iorw),
                .ioaddr(ioaddr),
                .rx_buf(rx_buf),
                .rxd(rxd),
                .rda(rda)
                );
endmodule
