module GameControl(
    input clk, // clk signal
    input rst, // Asychronous reset, active high
    input [1:0] keyboard_signal, // 00 for up, 01 for left, 10 for right, 11 for enter
    output reg [6:0] score,
    output reg [19:0][11:0] objectMatrix, // 1 for existing object, 0 for empty
    output reg [19:0][11:0] flash, // 1 for flash, 0 for no flash
    output reg [2:0] nextBlock,
);

endmodule