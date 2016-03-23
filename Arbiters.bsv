
// Various Arbiter designs.
// Core logic from Hacker's Delight, Chapter 2.

package Arbiters;

// --------------------------------------------
// Simple arbiters hold no internal state

interface Arbiter#(type element);
    method element grant (element request);
endinterface

// --------------------------------------------
// For arbiters whose decision depends on past inputs

interface Arbiter_Stateful#(type element);
    method ActionValue#(element) grant (element request);
endinterface

// ---------------------------------------------
// Returns LSB set, where bit 0 has highest priority.

module mkArbiter_Priority
(
    Arbiter#(element)
)
provisos 
(
    Arith#(element), 
    Bitwise#(element),
    Bits#(element, SizeOf#(element))
);
    method element grant (element request);
        return request & -request;
    endmethod
endmodule

// ---------------------------------------------
// Takes a single set bit, returns a mask which 
// masks-off that bit and all less significant ones.
// Used to mask-off requests of equal and higher priority.

module mkThermometer_Mask
(
    Arbiter#(element)
)
provisos 
(
    Arith#(element), 
    Bitwise#(element),
    Eq#(element)
);
    method element grant (element request);
        // 1's at set bit and all trailing 0's.
        // All 1's if no bit set. (e.g.: no pending requests)
        let mask = request ^ (request - 1);
        // Invert mask to instead masks-off set bit and all trailing bits
        // Don't invert mask if no pending requests 
        // else mask becomes all 0's and hides any new request.
            mask = (request == 0) ? mask : ~mask;
        // Re-add set bit
            mask = mask | request;
        return mask;
    endmethod
endmodule

// ---------------------------------------------
// Returns a single bit set from all set bits, in a round-robin order
// going from highest priority (LSB) to lowest (MSB).
// New requests of higher priority than currently granted request will wait.
// New requests of lower priority than currently granted request will get processed.

module mkArbiter_RoundRobin
(
    Arbiter_Stateful#(element)
)
provisos 
(
    Arith#(element), 
    Bitwise#(element),
    Eq#(element),
    Bits#(element, SizeOf#(element))
);
    Wire#(element)      request_current         <- mkWire();
    Reg#(element)       grant_current           <- mkReg(0);
    Arbiter#(element)   priority_arbiter_raw    <- mkArbiter_Priority;
    Arbiter#(element)   priority_arbiter_masked <- mkArbiter_Priority;
    Arbiter#(element)   mask_requests           <- mkThermometer_Mask;

    rule arbitrate;
        let grant_raw       = priority_arbiter_raw.grant(request_current);
        let mask            = mask_requests.grant(grant_current);
        let request_masked  = request_current & mask;
        let grant_masked    = priority_arbiter_masked.grant(request_masked);
        // If we run out of masked requests to service, 
        // start over at highest priority raw request
            grant_current  <= (grant_masked == 0) ? grant_raw : grant_masked; 
    endrule

    method ActionValue#(element) grant (element request);
        request_current <= request;
        return grant_current;
    endmethod
endmodule

endpackage

