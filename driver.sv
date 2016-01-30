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
    output reg [1:0] ioaddr,
    inout [7:0] databus
    );

reg capture_data, send_data, load_db_high, load_db_low, drive_tx_rx;
reg [7:0] data_buf, databus_out;
typedef enum reg [2:0] {IDLE, INIT_HIGH, INIT_LOW, RECEIVE, TRANSMIT} state;
state st, nxt_st;


assign ioaddr = load_db_high ? 2'b11 :
                load_db_low ? 2'b10 :
                drive_tx_rx ? 2'b00 : 2'bz;

//baud rate and corresponding divisors are - 
//4800 bits/s - 0x0515
//9600 bits/s - 0x028A - Verified, gives frequency of 153.6kHz
//19200 bits/s - 0x0145
//38400 bits/s - 0x00A2

assign databus = (load_db_high == 1'b1 && br_cfg == 2'b00) ? 8'h05 :
                 (load_db_high == 1'b1 && br_cfg == 2'b01) ? 8'h02 :
                 (load_db_high == 1'b1 && br_cfg == 2'b10) ? 8'h01 :
                 (load_db_high == 1'b1 && br_cfg == 2'b11) ? 8'h00 :
                 (load_db_low == 1'b1 && br_cfg == 2'b00) ? 8'h15 :
                 (load_db_low == 1'b1 && br_cfg == 2'b01) ? 8'h8A :
                 (load_db_low == 1'b1 && br_cfg == 2'b10) ? 8'h45 :
                 (load_db_low == 1'b1 && br_cfg == 2'b11) ? 8'hA2 :
                 (send_data) ? data_buf : 8'hz;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        data_buf <= 8'hx;
    end else begin
        if (capture_data)
            data_buf <= databus;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        st <= IDLE;
    end else begin
        st <= nxt_st;
    end
end

always_comb begin
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
            //after the initialization, the SM will waiting for receiving
            begin
                drive_tx_rx = 1'b1;
                iocs = 1'b1;
                iorw = 1'b1;
                if (rda == 1'b1) begin //TODO - rda is not cleared till the next packet comes in
                    capture_data = 1'b1;
                    nxt_st = TRANSMIT;
                end else begin
                    nxt_st = RECEIVE;
                end
            end
        TRANSMIT:
            //after receiving the first packet, it'll transmit it back and then wait for receiving again
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
