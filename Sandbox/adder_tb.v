`timescale 1ns / 100ps

module Adder_tb();
    reg [31:0] in;
    reg clk;
    reg rst;
    wire  [31:0] out;

    adder adderU (.clk(clk), .rst(rst), .in(in), .out(out));
    integer PASSED, FAILED;

    initial begin
        clk = 0;
        forever
            #5 clk = ~clk;
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, Adder_tb);
    end

    initial begin
        PASSED = 0;
        FAILED = 0;
        rst = 1;
        # 16
        rst = 0;
        in = 32'd1;
        #1
        if (out == 32'd1)   PASSED = PASSED + 1;
        else                FAILED = FAILED + 1;
        #9
        in = 32'd2;
        #1
        if(out == 32'd3)    PASSED = PASSED + 1;
        else                FAILED = FAILED + 1;
        #9
        in = 32'd5;
        #1
        if(out == 32'd8)    PASSED = PASSED + 1;
        else                FAILED = FAILED + 1;
        $display("PASSED: %d, FAILED: %d", PASSED, FAILED);
        $finish();
    end

endmodule