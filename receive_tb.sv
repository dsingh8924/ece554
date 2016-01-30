module receive_tb();
reg clk, rst_n;
reg brg_rx_en, iocs, iorw;
reg [1:0] ioaddr;
wire [7:0] rx_buf;
reg [4:0] cnt;
reg rxd;
wire rda;

receive rcv(.clk(clk),
                .rst_n(rst_n),
                .brg_rx_en(brg_rx_en),
                .iocs(iocs),
                .iorw(iorw),
                .ioaddr(ioaddr),
                .rx_buf(rx_buf),
                .rxd(rxd),
                .rda(rda)
                );

initial begin
clk = 1'b0;
rst_n = 1'b0;
iocs = 1'b0;
iorw = 1'b1;
ioaddr = 2'b0;
cnt = 0;
rxd = 1'b0;
#10 rst_n = 1'b1;
end

always #5 clk = ~clk;

always #5120 rxd = ~rxd;//rxd should change after 16 enables, 10ns*32*16

always @(posedge clk) begin
    cnt <= cnt +1;
    if (cnt == 31)
        brg_rx_en = 1'b1;
    else 
        brg_rx_en = 1'b0;
end

endmodule
