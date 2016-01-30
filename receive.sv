module receive(clk, rst_n, brg_rx_en, iocs, iorw, ioaddr, rx_buf, rxd, rda);

input clk, rst_n;
input iocs, iorw, brg_rx_en;
input [1:0] ioaddr;
output reg [7:0] rx_buf;
input rxd;
output reg rda;

reg rxd_d;
reg rst_cnt, inc_cnt;
reg rcv, rcv_en;
reg load_buf, clr_shift_reg;
reg clr_rda, set_rda;
reg rcv_start, clr_rcv_start;
reg [7:0] rx_shift_reg;
reg [3:0] rx_cnt;
reg [4:0] bit_cnt;

typedef enum reg {IDLE, RECEIVE} state;
state st, nxt_st;

//delaying RxD by one cycle
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        rxd_d <= 1'b0;
    end else begin
        rxd_d <= rxd;
    end
end

//detecting a 1 to 0 transition on RxD
//this flop will remain set unless explicitly cleared
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        rcv_start <= 1'b0;
    end else begin
        if (clr_rcv_start)
            rcv_start <= 1'b0;
        else if ((rxd == 1'b0) && (rxd_d == 1'b1))
            rcv_start <= 1'b1;
        //else maintain
    end
end

//once start of packet is detected
//logic for keeping track of incoming enables from BRG and
//generating receive enables every 16 BRG enables
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        rx_cnt <= 4'b0;
    end else begin
        //since the rate of enables is 16x the baud rate,
        //capturing the incoming bit at the next enable should work easily
        if(brg_rx_en && rcv_start) begin
            rx_cnt <= rx_cnt + 1;
            if(rx_cnt == 0) //a new enable is issued every time this 4-bit counter hits 0
                rcv_en = 1'b1;
        end else begin
            rx_cnt <= rx_cnt;
            rcv_en = 1'b0;
        end
    end
end

//once 8-bits of data is received, it'll be copied into a buffer
//controlled by the state machine
always @(posedge clk, negedge rst_n) begin
    if(load_buf)
        rx_buf <= rx_shift_reg;
end

//capturing incoming data into a shift reg
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        rx_shift_reg <= 8'h0;
    end else begin
        if (clr_shift_reg)
            rx_shift_reg <= 8'h0;
        if (rcv)
            //data comes in LSB first
            //enter data at MSB, so it makes its way to LSB
            rx_shift_reg <= {rxd, rx_shift_reg[7:1]}; 
    end
end

//counter for keeping track for bits according to the baud rate
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt <= 0;
    end else begin
        if (rst_cnt)
            bit_cnt <= 0;
        if (inc_cnt)
            bit_cnt <= bit_cnt +1;
    end
end

//transfer buffer ready signal
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        rda <= 1'b0;
    end else begin
        if(clr_rda)
            rda <= 1'b0;
        else if (set_rda)
            rda <= 1'b1;
        // else maintain
    end
end

//SM
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        st <= IDLE;
    end else begin
        st <= nxt_st;
    end
end

//State machine logic
always_comb begin
rst_cnt = 1'b0;
inc_cnt = 1'b0;
clr_rda = 1'b0;
set_rda = 1'b0;
load_buf = 1'b0;
clr_rcv_start = 1'b0;
clr_shift_reg = 1'b0;
rcv = 1'b0;
    case (st)
        IDLE:
            //rcv_en is generated by looking at RxD for start bit
            if (rcv_en && ioaddr == 2'b00 && iorw == 1'b1) begin
                inc_cnt = 1'b1;
                clr_rda = 1'b1;
                clr_shift_reg = 1'b1;
                nxt_st = RECEIVE;
            end else begin
                nxt_st = IDLE;
            end
        RECEIVE:
            //by the time the 2nd rcv_en arrives, the start bit would have gone by
            if (rcv_en && ioaddr == 2'b00 && iorw == 1'b1) begin
                rcv = 1'b1;
                if (bit_cnt == 9) begin //when we have 1 start bit and 8 data bits 
                    load_buf = 1'b1;
                    set_rda = 1'b1;
                    rst_cnt = 1'b1;
                    clr_rcv_start = 1'b1;
                    nxt_st = IDLE;
                end else begin
                    inc_cnt = 1'b1;
                    nxt_st = RECEIVE;
                end
            end else begin
                nxt_st = RECEIVE;
            end
    endcase
end

endmodule
