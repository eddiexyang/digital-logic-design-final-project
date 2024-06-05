// VGADisplay Module: Drives a VGA display using a 25MHz clock and rgb signal 
module VGADisplay(
    input vga_clk,                    // VGA_clock with 25MHz
    input clrn,                       // Active low reset signal 
    input [11:0] d_in,                // bbbb_gggg_rrrr format rgb signal
    output reg [8:0] row_addr,        // pixel ram row address, 480 (512) lines
    output reg [9:0] col_addr,        // pixel ram col address, 640 (1024) pixels
    output reg rdn,                   // active low siganl reading pixel RAM 
    output reg [3:0] r,g,b,           // color channel value
    output reg hs, vs                 // horizontal and vertical synchronization signal
);

endmodule