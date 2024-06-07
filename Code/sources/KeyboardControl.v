// KeyboardControl Module: Interprets PS/2 keyboard inputs to control directional (up, left, right) and enter actions.
module KeyboardControl(
    input clk,           // Main clock
    input rst,           // Active high reset signal
    input ps2_clk,       // PS/2 keyboard clock signal for synchronizing data transmission
    input ps2_data,      // PS/2 keyboard data signal carrying the scan codes
    output reg keyboard_signal       // 00 for up, 01 for left, 10 for right, 11 for enter
);
endmodule