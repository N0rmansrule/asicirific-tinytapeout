// spi_mem.sv — standard-SPI memory controller for external flash and PSRAM.
// Turns the core's word memory requests into SPI transactions on a shared bus:
// program and constants come from a QSPI NOR flash (read 0x03), and data reads
// and writes go to a QSPI PSRAM (read 0x03, write 0x02). Both chips share sck,
// sd0 (chip data in), and sd1 (chip data out); each has its own chip select.
// Standard single-bit SPI is used so the parts work straight out of reset with
// no quad-enable step. Sub-word writes become a read-modify-write so byte and
// half stores are correct. The core waits on ready while a transaction runs.
`default_nettype none

module spi_mem (
    input  wire logic        clk,
    input  wire logic        rst,

    // core side (word requests, ready handshake)
    input  wire logic [31:0] addr,
    input  wire logic        re,
    input  wire logic        we,
    input  wire logic [31:0] wdata,
    input  wire logic [3:0]  be,
    output logic [31:0]      rdata,
    output logic             ready,

    // SPI pins (single-bit mode)
    output logic             sck,
    output logic             sd0,        // chip data in  (we drive)
    input  wire logic        sd1,        // chip data out (chip drives)
    output logic             cs_flash_n,
    output logic             cs_ram_n
);
    // 0x00xxxxxx -> flash (read only), 0x01xxxxxx -> PSRAM (read/write)
    wire sel_ram = addr[24];
    wire [23:0] byte_addr = {addr[23:2], 2'b00};   // word-aligned byte address

    // ---- state ----
    typedef enum logic [2:0] {
        S_IDLE, S_SHIFT, S_TURN, S_RMWGAP, S_DONE
    } st_t;
    st_t st;

    // phase within a transaction
    typedef enum logic [1:0] {P_CMDADDR, P_RDATA, P_WDATA} ph_t;
    ph_t ph;

    logic [31:0] sh_out;    // shifts out MSB-first on sd0
    logic [31:0] sh_in;     // shifts in from sd1
    logic [5:0]  bits;      // bits left in this phase
    logic        rmw;       // 1 while doing the read half of a sub-word write
    logic [31:0] wsave;     // write data held across the RMW
    logic [3:0]  besave;    // byte enables held across the RMW
    logic        for_ram;   // this transaction targets the PSRAM

    assign sd0        = sh_out[31];
    assign cs_flash_n = (st == S_IDLE) || (st == S_RMWGAP) || for_ram;
    assign cs_ram_n   = (st == S_IDLE) || (st == S_RMWGAP) || !for_ram;
    assign rdata      = sh_in;
    assign ready      = (st == S_DONE);

    // merge the read word with the bytes being written (for sub-word stores)
    logic [31:0] merged;
    always_comb begin
        merged = sh_in;
        if (besave[0]) merged[7:0]   = wsave[7:0];
        if (besave[1]) merged[15:8]  = wsave[15:8];
        if (besave[2]) merged[23:16] = wsave[23:16];
        if (besave[3]) merged[31:24] = wsave[31:24];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            st      <= S_IDLE;
            sck     <= 1'b0;
            sh_out  <= 32'd0;
            sh_in   <= 32'd0;
            for_ram <= 1'b0;
            rmw     <= 1'b0;
        end else begin
            unique case (st)
                // wait for a request, then launch the command + address
                S_IDLE: begin
                    sck <= 1'b0;
                    if (re) begin
                        for_ram <= sel_ram;
                        rmw     <= 1'b0;
                        sh_out  <= {8'h03, byte_addr};   // read
                        bits    <= 6'd32;
                        ph      <= P_CMDADDR;
                        st      <= S_SHIFT;
                    end else if (we) begin
                        for_ram <= 1'b1;                 // writes only go to RAM
                        wsave   <= wdata;
                        besave  <= be;
                        if (be == 4'b1111) begin
                            rmw    <= 1'b0;
                            sh_out <= {8'h02, byte_addr}; // full-word write
                            bits   <= 6'd32;
                            ph     <= P_CMDADDR;
                        end else begin
                            rmw    <= 1'b1;               // read first, then write
                            sh_out <= {8'h03, byte_addr};
                            bits   <= 6'd32;
                            ph     <= P_CMDADDR;
                        end
                        st <= S_SHIFT;
                    end
                end

                // one SPI bit per two clocks: rise samples sd1, fall advances
                S_SHIFT: begin
                    if (sck == 1'b0) begin
                        sck   <= 1'b1;
                        sh_in <= {sh_in[30:0], sd1};
                    end else begin
                        sck    <= 1'b0;
                        sh_out <= {sh_out[30:0], 1'b0};
                        bits   <= bits - 6'd1;
                        if (bits == 6'd1) st <= S_TURN;
                    end
                end

                // decide what comes after the phase that just finished
                S_TURN: begin
                    unique case (ph)
                        // command+address done: read data, or start writing
                        P_CMDADDR: begin
                            if (we && !rmw) begin
                                sh_out <= wsave;
                                bits   <= 6'd32;
                                ph     <= P_WDATA;
                                st     <= S_SHIFT;
                            end else begin
                                bits <= 6'd32;
                                ph   <= P_RDATA;
                                st   <= S_SHIFT;
                            end
                        end
                        // read data done
                        P_RDATA: begin
                            if (rmw) begin
                                // finished the read half; deselect, then write back
                                wsave <= merged;
                                st    <= S_RMWGAP;
                            end else begin
                                st <= S_DONE;
                            end
                        end
                        // write data done
                        P_WDATA: st <= S_DONE;
                        default: st <= S_DONE;
                    endcase
                end

                // deselect between the RMW read and write, then start the write
                S_RMWGAP: begin
                    sh_out <= {8'h02, byte_addr};
                    bits   <= 6'd32;
                    ph     <= P_CMDADDR;
                    rmw    <= 1'b0;
                    st     <= S_SHIFT;
                end

                // one ready cycle, then back to idle
                S_DONE: st <= S_IDLE;

                default: st <= S_IDLE;
            endcase
        end
    end

endmodule : spi_mem
