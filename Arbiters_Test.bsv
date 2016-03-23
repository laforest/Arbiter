
// testbench for arbiters

package Test;

import Arbiters::*;

typedef     Bit#(5)         TestType;
TestType    test_limit      = '1;       // max unsigned int
TestType    init_req        = 'b10110;  // initial requests for round robin test

// ---------------------------------------------

module mkArbiter_Priority_Test ();
    Arbiter#(TestType) arb_pri <- mkArbiter_Priority;
    Reg#(TestType)     in      <- mkReg(0);

    rule run;
        let out = arb_pri.grant(in);
        $display ("in:%b -> priority out:%b", in, out);
        in <= in + 1;
        if (in == test_limit) $finish(0);
    endrule
endmodule

// ---------------------------------------------

module mkThermometer_Mask_Test ();
    Arbiter#(TestType) thermo <- mkThermometer_Mask;
    Reg#(TestType)     in     <- mkReg(0);

    rule run;
        let out = thermo.grant(in);
        $display ("in:%b -> thermo out:%b", in, out);
        in <= in + 1;
        if (in == test_limit) $finish(0);
    endrule

endmodule

// ---------------------------------------------

module mkArbiter_RoundRobin_Test ();
    Reg#(TestType)              in       <- mkReg(init_req);
    Arbiter_Stateful#(TestType) arb_rr   <- mkArbiter_RoundRobin;

    rule start;
        let out <- arb_rr.grant(in);
        $display ("in:%b -> round_robin out:%b", in, out);
        in <= in & ~out;    // drop granted request
        if (in == 0 &&  out == 0)
        begin
            $write("All requests serviced.");
            $finish(0);
        end
    endrule

endmodule

// ---------------------------------------------

module test ();

    // let arb_pri <- mkArbiter_Priority_Test;
    // let thermo  <- mkThermometer_Mask_Test;
    let arb_rr  <- mkArbiter_RoundRobin_Test;

endmodule

endpackage

