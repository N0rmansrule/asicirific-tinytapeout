`default_nettype none
// Behavioral standard-SPI flash (read 0x03) and PSRAM (read 0x03, write 0x02).
// Shared sck/sd0/sd1; separate CS. Mode 0: sample sd0 on rising edge, drive sd1
// (shifted) so the master samples it on its rising edge one bit later.
module spi_flash #(parameter INIT="")(
    input wire clk, input wire cs_n, input wire sck, input wire sd0, output logic sd1
);
    logic [31:0] mem [0:1023];
    logic [7:0] cmd; logic [23:0] adr; logic [31:0] dout;
    integer bitc; logic [1:0] phase; logic sck_q;
    initial begin sd1=0; end
    always @(negedge cs_n) begin bitc=0; phase=0; cmd=0; adr=0; end
    always @(posedge sck) begin
        if (!cs_n) begin
            if (phase==0) begin cmd={cmd[6:0],sd0}; bitc=bitc+1;
                if (bitc==8) begin phase=1; bitc=0; end
            end else if (phase==1) begin adr={adr[22:0],sd0}; bitc=bitc+1;
                if (bitc==24) begin phase=2; bitc=0; dout=mem[adr[11:2]]; end
            end
        end
    end
    // drive sd1 on falling edge during data phase (MSB first)
    always @(negedge sck) begin
        if (!cs_n && phase==2) begin sd1<=dout[31]; dout<={dout[30:0],1'b0}; end
    end
endmodule

module spi_psram(
    input wire clk, input wire cs_n, input wire sck, input wire sd0, output logic sd1
);
    logic [31:0] mem [0:1023];
    logic [7:0] cmd; logic [23:0] adr; logic [31:0] dio; integer bitc; logic [1:0] phase;
    initial begin sd1=0; end
    always @(negedge cs_n) begin bitc=0; phase=0; cmd=0; adr=0; end
    always @(posedge sck) begin
        if (!cs_n) begin
            if (phase==0) begin cmd={cmd[6:0],sd0}; bitc=bitc+1;
                if (bitc==8) begin phase=1; bitc=0; end
            end else if (phase==1) begin adr={adr[22:0],sd0}; bitc=bitc+1;
                if (bitc==24) begin phase=2; bitc=0; if(cmd==8'h03) dio=mem[adr[11:2]]; end
            end else if (phase==2) begin
                if (cmd==8'h02) begin dio={dio[30:0],sd0}; bitc=bitc+1;
                    if (bitc==32) mem[adr[11:2]]=dio; end
            end
        end
    end
    always @(negedge sck) begin
        if (!cs_n && phase==2 && cmd==8'h03) begin sd1<=dio[31]; dio<={dio[30:0],1'b0}; end
    end
endmodule
