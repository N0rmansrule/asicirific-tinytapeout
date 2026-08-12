// bus_fabric.sv — main-domain MMIO decode per PROJECT_PLAN memory map.
//   0x1000_0000 SRAM (handled outside; this fabric covers 0x2000_xxxx)
//   0x2000_0000 UART   0x2000_1000 GPIO   0x2000_2000 SPI
//   0x2000_3000 I2C    0x2000_4000 I2S
`default_nettype none
module bus_fabric (
    input  wire logic [31:0] addr,
    output logic [4:0]       sel     // one-hot: uart,gpio,spi,i2c,i2s
);
    always_comb begin
        sel = 5'b00000;
        if (addr[31:16] == 16'h2000) begin
            unique case (addr[15:12])
                4'h0: sel = 5'b00001;
                4'h1: sel = 5'b00010;
                4'h2: sel = 5'b00100;
                4'h3: sel = 5'b01000;
                4'h4: sel = 5'b10000;
                default: sel = 5'b00000;
            endcase
        end
    end
endmodule : bus_fabric
