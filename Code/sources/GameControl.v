module GameControl(
    input clk, // clk signal
    input rst, // Sychronous reset, active high
    input [1:0] keyboard_signal, // 00 for idle, 01 for left, 10 for right, 11 for rotate
    output reg [6:0] score,
    output reg [2:0] nextBlock, // See definition in the documentation
    output [199:0] objects, // 1 for existing object, 0 for empty
    output [199:0] flash // 1 for flash, 0 for no flash
);
    // Perform clock division
    wire [31:0] divRes;
    clkdiv div_inst(.clk(clk), .reset(0), .clk_div(divRes));

    // Here we use 22x10 registers to store the 20x10 game board,
    // the two extra rows are for the blocks that are falling down
    reg objectReg [21:0][9:0];
    reg flashReg [21:0][9:0];
    reg [4:0] maxHeight;

    reg [2:0] currBlockType;
    reg [1:0] currBlockState;
    reg [3:0] currBlockCenterX;
    reg [4:0] currBlockCenterY;

    reg [31:0] clkCounter;
    reg [4:0] i = 0;
    reg [3:0] j = 0;
    reg flashSign = 0;
    reg rotateSign = 0;
    reg moveLeftSign = 0;
    reg moveRightSign = 0;
    reg dropSign = 0;
    
    // Main Tetris logic
    always @(posedge clk) begin
        if (rst) begin
            score <= 7'b0;
            nextBlock <= 3'b0;
            objectReg[i][j] <= 0;
            flashReg[i][j] <= 0;
            currBlockType <= 3'b0;
            currBlockState <= 2'b0;
            currBlockCenterX <= 5;
            currBlockCenterY <= 0;
            maxHeight <= 0;
            if (i == 19 && j == 9) begin
                i <= 0;
                j <= 0;
            end else if (j == 9) begin
                i <= i + 1;
                j <= 0;
            end else begin
                j <= j + 1;
            end
        end else begin
            // Handle keyboard signal
            case (keyboard_signal) 
                2'b01: moveLeftSign <= 1;
                2'b10: moveRightSign <= 1;
                2'b11: rotateSign <= 1;
            endcase
            // Handle block dropping
            if (clkCounter[25] == 1) begin
                dropSign <= 1;
                clkCounter <= 32'b0;
            end else begin
                clkCounter <= clkCounter + 1;
            end
        end
    end

    // Update current block display and handle collision
    always @(posedge clk) begin
        if (keyboard_signal == 2'b00) begin
            // TODO
        end
    end

    // Handle block rotation
    // TODO

    // Handle block left-moving
    // TODO

    // Handle block right-moving
    // TODO

    // Map 2-d registers to 1-d signal lines
    // TODO
    
endmodule