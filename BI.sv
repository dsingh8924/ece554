module BI(databus, ioaddr, tx_buf, rx_buf, tbr, rda, iocs, iorw, db_low, db_high);

input tbr, rda, iocs, iorw;
inout wire [7:0] databus;
input [1:0] ioaddr;
input [7:0] rx_buf;
output [7:0] tx_buf;
output  [7:0] db_low, db_high;
wire [7:0] status_reg;

assign status_reg[7:2] = 6'b0;
assign status_reg[1] = tbr;
assign status_reg[0] = rda;

assign tx_buf = (ioaddr == 2'b00 && iorw == 1'b0) ? databus : 8'bz;
assign databus = (ioaddr == 2'b00 && iorw == 1'b1) ? rx_buf : 8'bz;
assign db_low = (ioaddr == 2'b10) ? databus : 8'bz;
assign db_high = (ioaddr == 2'b11) ? databus : 8'bz;

/*
always_comb begin
    case(ioaddr)
        2'b00: if (iorw) databus = rx_buf ;//wrong?
        2'b01: databus = status_reg;
        2'b10: db_low = databus;
        2'b11: db_high = databus;
    endcase
end

typedef enum reg [1:0] {RESET, SENDING, RECEIVING, HIGHZ} state;
state st;

always_comb begin
    case(st)
        RESET:
    endcase
end
*/
endmodule
