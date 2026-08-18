`default_nettype none
`timescale 1ns/1ps
// load_unit test: every funct3 load type, every byte offset, many random words,
// checked against a reference for sign/zero extension.
module tb_load_unit;
    logic [31:0] rdata; logic [1:0] addr_lo; logic [2:0] funct3; logic [31:0] out;
    load_unit dut(.rdata(rdata), .addr_lo(addr_lo), .funct3(funct3), .out(out));
    integer errors=0, tests=0, k, off, ft;
    function [31:0] ref_load(input [31:0] d, input [1:0] a, input [2:0] f);
        logic [7:0] b; logic [15:0] h;
        case (f)
            3'b000: begin b=d[a*8+:8]; ref_load={{24{b[7]}},b}; end          // lb
            3'b100: begin b=d[a*8+:8]; ref_load={24'd0,b}; end               // lbu
            3'b001: begin h=a[1]?d[31:16]:d[15:0]; ref_load={{16{h[15]}},h}; end // lh
            3'b101: begin h=a[1]?d[31:16]:d[15:0]; ref_load={16'd0,h}; end   // lhu
            3'b010: ref_load=d;                                             // lw
            default: ref_load=d;
        endcase
    endfunction
    initial begin
        for(k=0;k<3000;k=k+1) begin
            rdata=$random;
            for(off=0;off<4;off=off+1) begin
                addr_lo=off[1:0];
                for(ft=0;ft<6;ft=ft+1) begin
                    funct3 = (ft==0)?3'b000:(ft==1)?3'b100:(ft==2)?3'b001:(ft==3)?3'b101:3'b010;
                    #1; tests=tests+1;
                    if (out !== ref_load(rdata,addr_lo,funct3)) begin errors=errors+1;
                        if(errors<=5) $display("  LD MISMATCH d=%h off=%0d f=%b got=%h exp=%h",rdata,off,funct3,out,ref_load(rdata,addr_lo,funct3)); end
                end
            end
        end
        $display("load_unit: %0d tests, %0d errors -> %s", tests, errors, errors?"FAIL":"PASS");
        $finish;
    end
endmodule
