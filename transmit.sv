module transmit(clk, rst_n, transmit_en, ioaddr, tx_buf, txd, tbr);
input clk, rst_n;
input transmit_en;
input [1:0] ioaddr;
input [7:0] tx_buf;
output reg txd;
output reg tbr;

reg shift, rst_cnt, dec_cnt;
reg [7:0] tx_shift_reg;
reg [4:0] cnt;

typedef enum reg {IDLE, TRANSMIT} state;
state st, nxt_st;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg <= 8'h0;
    end else begin
        if (shift)
            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        txd <= 1'b0;
    end else begin
        txd <= tx_shift_reg[7];
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 8;
    end else begin
        if (rst_cnt)
            cnt <= 8;
        if (dec_cnt)
            cnt <= cnt -1;
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
shift = 1'b0;
rst_cnt = 1'b0;
dec_cnt = 1'b0;
tbr = 1'b0;
    case (st)
        IDLE: if (transmit_en == 1'b1) begin
                dec_cnt = 1'b1;
                nxt_st = TRANSMIT;
            end
        TRANSMIT: if (cnt == 0) begin
                tbr = 1'b1;
                rst_cnt = 1'b1;
                nxt_st = IDLE;
            end else begin
                shift = 1'b1;
                dec_cnt = 1'b1;
                nxt_st = TRANSMIT;
            end

    endcase
end

endmodule
