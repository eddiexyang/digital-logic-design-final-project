// UIDisplay Module: Handles the user interface display for a game, showing the object matrix, score, and next block information on a VGA monitor.
module UIDisplay(
    input clk,                       // Main clock for synchronizing the display updates
    input reset,                     // Active high reset signal to reset the display
    input [19:0][11:0] objectMatrix, // Object position matrix (20 rows by 12 columns)
    input [19:0][11:0] flash,        // Flash matrix (20 rows by 12 columns)
    input [6:0] score,               // Current score
    input [2:0] nextBlock,           // Type of the next block to be displayed (encoded as 0 to 3)
    output hsync,                    // Horizontal synchronization signal for VGA
    output vsync,                    // Vertical synchronization signal for VGA
    output [7:0] rgb                 // Color channel value for VGA display
);

endmodule
