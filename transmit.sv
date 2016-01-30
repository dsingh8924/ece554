module transmit(clk, rst_n, brg_tx_en, iocs, iorw, ioaddr, tx_buf, txd, tbr);

input clk, rst_n;
input iocs, iorw, brg_tx_en;
input [1:0] ioaddr;
input [7:0] tx_buf;
output reg txd;
output reg tbr;

reg rst_cnt, inc_cnt;
reg start_bit, stop_bit, xmit, xmit_en;
reg load_reg;
reg clr_tbr, set_tbr;
reg [7:0] tx_shift_reg;
reg [3:0] tx_cnt;
reg [4:0] bit_cnt;

typedef enum reg {IDLE, TRANSMIT} state;
state st, nxt_st;

//logic for keeping track of incoming enables from BRG and 
//generating transmit enables every 16 BRG enables
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        tx_cnt <= 4'b0;
    end else begin
        if(brg_tx_en) begin
            tx_cnt <= tx_cnt + 1;
            if(tx_cnt == 0) //a new enable is issued every time this 4-bit counter hits 0
                xmit_en = 1'b1;
        end else begin
            tx_cnt <= tx_cnt;
            xmit_en = 1'b0;
        end
    end
end

//shift register with functionality for loading data
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg <= 8'h0;
    end else begin
        if (load_reg)
            tx_shift_reg <= tx_buf;
        if (xmit)
            tx_shift_reg <= tx_shift_reg >> 1;
    end
end

//TxD output, controlled by state machine
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        txd <= 1'b1;
    end else begin
        if (start_bit)
            txd <= 1'b0;
        else if (stop_bit)
            txd <= 1'b1;
        else if (xmit)
            txd <= tx_shift_reg[0];
        //else remember
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
        tbr <= 1'b0;
    end else begin
        if(clr_tbr)
            tbr <= 1'b0;
        else if (set_tbr)
            tbr <= 1'b1;
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
clr_tbr = 1'b0;
set_tbr = 1'b0;
load_reg = 1'b0;
start_bit = 1'b0;
stop_bit = 1'b0;
xmit = 1'b0;
//shift = 1'b0;
    case (st)
        IDLE: 
            //xmit_en goes high according to the baud rate
            //once it goes high we load the contents of tx_buf to the shift register,
            //clear the bit counter & TBR register and start shifting
            //TBR will be set only for 1 cycle, processor should poll
            if (xmit_en == 1'b1 && ioaddr == 2'b00 && iorw == 1'b0) begin
                start_bit = 1'b1;
                load_reg = 1'b1;
                inc_cnt = 1'b1;
                clr_tbr = 1'b1;
                nxt_st = TRANSMIT;
            end else begin
                clr_tbr = 1'b1;
                stop_bit = 1'b1;
                nxt_st = IDLE;
            end
        TRANSMIT: 
            //transmission is done at the baud rate
            //first we transmit one start bit (0) and then 8 bits of data
            //then set TBR and transition to IDLE state
            if (xmit_en == 1'b1 && ioaddr == 2'b00 && iorw == 1'b0) begin
                xmit = 1'b1;
                if (bit_cnt == 9) begin //1 start bit and 8 data bits
                    set_tbr = 1'b1;
                    rst_cnt = 1'b1;
                    nxt_st = IDLE;
                end else begin
                    inc_cnt = 1'b1;
                    nxt_st = TRANSMIT;
                end
            end else begin
                nxt_st = TRANSMIT;
            end
    endcase
end

endmodule
