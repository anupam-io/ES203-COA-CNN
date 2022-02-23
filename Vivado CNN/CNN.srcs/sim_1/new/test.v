`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/16/2019 03:18:06 AM
// Design Name:
// Module Name: test
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module test();
    reg clk;
    wire [9:0] A;
    initial
        clk = 0;

    always #0.08 clk = ~clk;

    CNN inst(.clk(clk), .A(A));
endmodule
