// KeyboardControl Module: Interprets PS/2 keyboard inputs to control directional (up, left, right) and enter actions.
module KeyboardControl(
    input clk,           // Main clock
    input rst,           // Active high reset signal
    input ps2_clk,       // PS/2 keyboard clock signal for synchronizing data transmission
    input ps2_data,      // PS/2 keyboard data signal carrying the scan codes
    output reg up,       // Output for the up direction, set when corresponding scan code is detected
    output reg left,     // Output for the left direction, set when corresponding scan code is detected
    output reg right,    // Output for the right direction, set when corresponding scan code is detected
    output reg enter     // Output for the enter action, set when corresponding scan code is detected
);
endmodule