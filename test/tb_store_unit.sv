`default_nettype none
`timescale 1ns/1ps
// store_unit test: every store type and byte offset, checking the byte-enable
// mask and the placement of data into the word.
module tb_store_unit;
    logic [31:0] wdata_in; logic [1:0] addr_lo; logic [2:0] funct3;
    logic [31:0] wdata_out; logic [3:0] be;
    store_unit dut(.wdata_in(wdata_in),.addr_lo(addr_lo),.funct3(funct3),.wdata_out(wdata_out),.be(be));
    integer errors=0, tests=0, k, off, ft, bb;
    logic [7:0] want; logic [3:0] ebe;
    function [3:0] ref_be(input [1:0] a, input [2:0] f);
        case (f)
            3'b000: ref_be = 4'b0001 << a;             // sb
            3'b001: ref_be = a[1]?4'b1100:4'b0011;     // sh
            3'b010: ref_be = 4'b1111;                  // sw
            default: ref_be = 4'b0000;
        endcase
    endfunction
    initial begin
        for(k=0;k<3000;k=k+1) begin
            wdata_in=$random;
            for(off=0;off<4;off=off+1) begin
                addr_lo=off[1:0];
                for(ft=0;ft<3;ft=ft+1) begin
                    funct3=(ft==0)?3'b000:(ft==1)?3'b001:3'b010;
                    #1; tests=tests+1; ebe=ref_be(addr_lo,funct3);
                    if (be !== ebe) begin errors=errors+1;
                        if(errors<=5) $display("  ST BE MISMATCH in=%h off=%0d f=%b got_be=%b exp_be=%b",wdata_in,off,funct3,be,ref_be(addr_lo,funct3)); end
                    // check the enabled bytes carry the low bytes of wdata_in
                    for(bb=0;bb<4;bb=bb+1) if(ebe[bb]) begin
                        case(funct3)
                          3'b000: want = wdata_in[7:0];
                          3'b001: want = bb[0]? wdata_in[15:8] : wdata_in[7:0];
                          default: want = wdata_in[bb*8+:8];
                        endcase
                        if (wdata_out[bb*8+:8] !== want) begin errors=errors+1;
                          if(errors<=8) $display("  ST DATA MISMATCH byte %0d got=%h want=%h",bb,wdata_out[bb*8+:8],want); end
                    end
                end
            end
        end
        $display("store_unit: %0d tests, %0d errors -> %s", tests, errors, errors?"FAIL":"PASS");
        $finish;
    end
endmodule
