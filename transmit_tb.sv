module transmit_tb();
reg clk, rst_n;
reg brg_tx_en, iocs, iorw;
reg [1:0] ioaddr;
reg [7:0] tx_buf;
reg [4:0] cnt;
wire txd, tbr;

transmit xmit(.clk(clk),
                .rst_n(rst_n),
                .brg_tx_en(brg_tx_en),
                .iocs(iocs),
                .iorw(iorw),
                .ioaddr(ioaddr),
                .tx_buf(tx_buf),
                .txd(txd),
                .tbr(tbr)
                );

initial begin
clk = 1'b0;
rst_n = 1'b0;
iocs = 1'b0;
iorw = 1'b0;
ioaddr = 2'b0;
tx_buf = 8'hee;
cnt = 0;
#10 rst_n = 1'b1;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    cnt <= cnt +1;
    if (cnt == 31)
        brg_tx_en = 1'b1;
    else 
        brg_tx_en = 1'b0;
end

endmodule
