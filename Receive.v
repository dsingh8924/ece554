`timescale 1ns / 1ps
module Recieve(input RxD, en, clk, rst_n, IOCS, IORW, input[1:0] IOaddr, output reg[7:0] rData, output reg RDA);

reg shift, rst_cnt, dec_cnt, state, n_state;
reg [9:0] rx_shift_reg;
reg [4:0] cnt;

//state declarations
localparam IDLE = 1'b0;
localparam RECEIVE = 1'b1;

//shift in received data
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) rx_shift_reg <= 10'hxxx;
    else begin
        if (shift) rx_shift_reg <= {RxD, rx_shift_reg[8:1]};
    end
end

//counter imlementaion
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) cnt <= 4'hA;
    else begin
        if (rst_cnt) cnt <= 4'hA;
        if (dec_cnt) cnt <= cnt - 1'b1;
    end
end

//state register
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= n_state;
    end
end

//reveiver control state machine
always@(*) begin
shift = 1'b0;
rst_cnt = 1'b0;
dec_cnt = 1'b0;
RDA = 1'b0;
    case (state)
        IDLE: if ({en,IORW} == 2'b11) begin
                dec_cnt = 1'b1;
                n_state = RECEIVE;
            end
        RECEIVE: if (cnt == 0) begin
                RDA = 1'b1;
                rst_cnt = 1'b1;
                n_state = IDLE;
            end else begin
                shift = 1'b1;
                dec_cnt = 1'b1;
                n_state = RECEIVE;
            end

    endcase
end

endmodule
