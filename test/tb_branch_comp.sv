`default_nettype none
`timescale 1ns/1ps
// Exhaustive test of branch_comp: every funct3 against every flag combination,
// checked against an independent reference.
module tb_branch_comp;
    logic [2:0] f3; logic zero, lts, ltu, taken;
    branch_comp dut(.funct3(f3), .zero(zero), .lt_signed(lts), .lt_unsigned(ltu), .taken(taken));
    integer errors=0, tests=0; integer i, c;
    function logic ref_taken(input [2:0] ff, input z, input ls, input lu);
        case (ff)
            3'b000: ref_taken =  z;   3'b001: ref_taken = ~z;
            3'b100: ref_taken =  ls;  3'b101: ref_taken = ~ls;
            3'b110: ref_taken =  lu;  3'b111: ref_taken = ~lu;
            default: ref_taken = 1'b0;
        endcase
    endfunction
    initial begin
        for (i=0;i<8;i=i+1) for (c=0;c<8;c=c+1) begin
            f3=i[2:0]; {zero,lts,ltu}=c[2:0]; #1; tests=tests+1;
            if (taken !== ref_taken(i[2:0],c[2],c[1],c[0])) begin
                errors=errors+1;
                $display("  MISMATCH f3=%b flags=%b got=%b", f3, c[2:0], taken);
            end
        end
        $display("branch_comp: %0d tests, %0d errors -> %s", tests, errors, errors?"FAIL":"PASS");
        $finish;
    end
endmodule
