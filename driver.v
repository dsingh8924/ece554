`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    driver 
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
module driver(
    input clk,
    input rst_n,
    input [1:0] br_cfg,
    output reg iocs,
    output reg iorw,
    input rda,
    input tbr,
    output [1:0] ioaddr,
    inout [7:0] databus
    );

reg capture_data, send_data, load_db_high, load_db_low, drive_tx_rx;
reg [7:0] data_buf, databus_out;
localparam IDLE=3'h0, INIT_HIGH=3'h1, INIT_LOW=3'h2, RECEIVE=3'h3, TRANSMIT=3'h4;
reg [2:0] st, nxt_st;
//typedef enum reg [2:0] {IDLE, INIT_HIGH, INIT_LOW, RECEIVE, TRANSMIT} state;
//state st, nxt_st;

//ioaddr is controlled by the state machine
assign ioaddr = load_db_high ? 2'b11 :
                load_db_low ? 2'b10 :
                drive_tx_rx ? 2'b00 : 2'bz;

//baud rate and corresponding divisors are - 
//4800 bits/s - 0x0513
//9600 bits/s - 0x0288
//19200 bits/s - 0x0145
//38400 bits/s - 0x00A2

//assigning databus as controlled by the state machine and on-chip switches
assign databus = (load_db_high == 1'b1 && br_cfg == 2'b00) ? 8'h05 :
                 (load_db_high == 1'b1 && br_cfg == 2'b01) ? 8'h02 :
                 (load_db_high == 1'b1 && br_cfg == 2'b10) ? 8'h01 :
                 (load_db_high == 1'b1 && br_cfg == 2'b11) ? 8'h00 :
                 (load_db_low == 1'b1 && br_cfg == 2'b00) ? 8'h13 :
                 (load_db_low == 1'b1 && br_cfg == 2'b01) ? 8'h88 :
                 (load_db_low == 1'b1 && br_cfg == 2'b10) ? 8'h45 :
                 (load_db_low == 1'b1 && br_cfg == 2'b11) ? 8'hA2 :
                 (send_data) ? data_buf : 8'hz;

//buffer for storing incoming data, for transmitting back
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        data_buf <= 8'hx;
    end else begin
        if (capture_data)
            data_buf <= databus;
    end
end

//state machine logic
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        st <= IDLE;
    end else begin
        st <= nxt_st;
    end
end

always @(*) begin
load_db_high = 1'b0;
load_db_low = 1'b0;
capture_data = 1'b0;
send_data = 1'b0;
iocs = 1'b0;
iorw = 1'bz; //dont drive by default
    case (st)
        IDLE:   
            begin
                nxt_st = INIT_HIGH;
            end
		  //after reset is deasserted, DB_HIGH and DB_LOW registers and loaded with the divisor, respectively
		  //by driving ioaddr and databus to the appropriate value
        INIT_HIGH: 
            begin
                load_db_high = 1'b1;
                nxt_st = INIT_LOW;
            end
        INIT_LOW: 
            begin
                load_db_low = 1'b1;
                nxt_st = RECEIVE;
            end
        RECEIVE: 
            //after the initialization, the SM will waiting for receiving data (till rda goes high)
            begin
                drive_tx_rx = 1'b1;
                iocs = 1'b1;
                iorw = 1'b1;
                if (rda == 1'b1) begin 
                    capture_data = 1'b1;
                    nxt_st = TRANSMIT;
                end else begin
                    nxt_st = RECEIVE;
                end
            end
        TRANSMIT:
            //after receiving the first packet, it'll transmit it back and then go back the receive state
            begin
                drive_tx_rx = 1'b1;
                iocs = 1'b1;
                iorw = 1'b0;
                if (tbr == 1'b1) begin
                    nxt_st = RECEIVE;
                end else begin
                    send_data = 1'b1;
                    nxt_st = TRANSMIT;
                end
            end
    endcase
end

endmodule
