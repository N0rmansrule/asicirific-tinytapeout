`default_nettype none
`timescale 1ns/1ps
// imm_gen test: random instruction words for each immediate type, checked
// against an independent decoder.
module tb_imm_gen;
    import asicirific_pkg::*;
    logic [31:0] inst; imm_sel_t sel; logic [31:0] imm;
    imm_gen dut(.inst(inst), .sel(sel), .imm(imm));
    integer errors=0, tests=0, k, m;
    function [31:0] ref_imm(input [31:0] w, input [2:0] s);
        case (s)
            3'd0: ref_imm = {{21{w[31]}}, w[30:20]};                              // I
            3'd1: ref_imm = {{21{w[31]}}, w[30:25], w[11:7]};                     // S
            3'd2: ref_imm = {{20{w[31]}}, w[7], w[30:25], w[11:8], 1'b0};         // B
            3'd3: ref_imm = {w[31:12], 12'd0};                                   // U
            3'd4: ref_imm = {{12{w[31]}}, w[19:12], w[20], w[30:21], 1'b0};       // J
            default: ref_imm = 0;
        endcase
    endfunction
    initial begin
        for(k=0;k<5000;k=k+1) begin
            inst=$random; m=k%5;
            case(m) 0:sel=IMM_I; 1:sel=IMM_S; 2:sel=IMM_B; 3:sel=IMM_U; default:sel=IMM_J; endcase
            #1; tests=tests+1;
            if (imm !== ref_imm(inst,m[2:0])) begin errors=errors+1;
                if(errors<=5) $display("  IMM MISMATCH inst=%h sel=%0d got=%h exp=%h",inst,m,imm,ref_imm(inst,m[2:0])); end
        end
        $display("imm_gen: %0d tests, %0d errors -> %s", tests, errors, errors?"FAIL":"PASS");
        $finish;
    end
endmodule
