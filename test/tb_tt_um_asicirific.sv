`default_nettype none
`timescale 1ns/1ps
module tb_tt_um_asicirific;
    logic clk=0, rst_n=0, ena=1; always #5 clk=~clk;
    logic [7:0] ui_in=0; wire [7:0] uo_out, uio_out, uio_oe; logic [7:0] uio_in=0;
    tt_um_asicirific dut(.ui_in(ui_in),.uo_out(uo_out),.uio_in(uio_in),
        .uio_out(uio_out),.uio_oe(uio_oe),.ena(ena),.clk(clk),.rst_n(rst_n));
    wire sck=uio_out[4], sd0=uio_out[0], csf=uio_out[5], csr=uio_out[6];
    wire sd1_f, sd1_r;
    always @(*) uio_in[1] = (!csf)?sd1_f : (!csr)?sd1_r : 1'b0;
    spi_flash flash(.clk(clk),.cs_n(csf),.sck(sck),.sd0(sd0),.sd1(sd1_f));
    spi_psram psram(.clk(clk),.cs_n(csr),.sck(sck),.sd0(sd0),.sd1(sd1_r));

    integer k; logic done;
    initial begin
        flash.mem[0]=32'h02000237; // lui x4,0x02000
        flash.mem[1]=32'h00422283; // lw x5,4(x4)     ; buttons
        flash.mem[2]=32'h0012f313; // andi x6,x5,1
        flash.mem[3]=32'h00030863; // beq x6,x0,+16 -> mem[7]
        flash.mem[4]=32'h0ff00393; // addi x7,x0,255
        flash.mem[5]=32'h00722023; // sw x7,0(x4)
        flash.mem[6]=32'hfe5ff06f; // j back to mem[1]
        flash.mem[7]=32'h00100393; // addi x7,x0,1
        flash.mem[8]=32'h00722023; // sw x7,0(x4)
        flash.mem[9]=32'hfddff06f; // j back to mem[1]
        repeat(5) @(posedge clk); rst_n=1;

        ui_in=8'h00; done=0;
        for(k=0;k<400000 && !done;k=k+1) begin @(posedge clk);
            if(uo_out==8'h01) begin done=1; $display("  ok: button released -> LED 0x01"); end end
        if(!done) begin $display("tt_um_asicirific: FAIL (released state)"); $finish; end

        ui_in=8'h01; done=0;
        for(k=0;k<400000 && !done;k=k+1) begin @(posedge clk);
            if(uo_out==8'hFF) begin done=1; $display("  ok: button pressed -> LED 0xFF"); end end
        if(!done) begin $display("tt_um_asicirific: FAIL (pressed state)"); $finish; end

        $display("tt_um_asicirific: PASS (button-to-LED end to end from flash)");
        $finish;
    end
endmodule
