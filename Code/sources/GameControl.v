module GameControl(
    input clk,                   // clk signal
    input rst,                   // Sychronous reset, active high
    input [1:0] keyboard_signal, // 00 for idle, 01 for left, 10 for right, 11 for rotate
    output reg [6:0] score,
    output reg [2:0] nextBlock,  // See definition in the documentation
    output [199:0] objects,      // 1 for existing object, 0 for empty
    output [199:0] flash         // 1 for flash, 0 for no flash
);
    // Here we use 24x10 registers to store the 20x10 game board
    // the 4 extra rows are used for block generation
    reg objectReg [23:0][9:0];
    reg flashReg [23:0][9:0];
    reg [4:0] maxHeight;

    reg [2:0] currBlockType;
    reg [1:0] currBlockState;
    reg [3:0] currBlockCenterX;
    reg [4:0] currBlockCenterY;
    reg [1:0] prevBlockState;
    reg [3:0] prevBlockCenterX;
    reg [4:0] prevBlockCenterY;

    reg [4:0] i = 0;
    reg [3:0] j = 0;
    reg flashSign = 0;
    reg rotateSign = 0;
    reg moveLeftSign = 0;
    reg moveRightSign = 0;
    reg updateBlockPositionSign = 0;
    reg blockLanded = 0;

    // Perform clock division
    wire [31:0] clk_div;
    clkdiv u_clkdiv(
        .clk     (clk     ),
        .reset   (0       ),
        .clk_div (clk_div  )
    );

    // Handle reset signal
    reg rstReg;
    always @(posedge rst) begin
        rstReg <= 1;
        i <= 0;
        j <= 0;
    end
    always @(posedge clk) begin
        if (rstReg) begin
            score <= 7'b0;
            nextBlock <= 3'b0;
            objectReg[i][j] <= 0;
            flashReg[i][j] <= 0;
            currBlockType <= 3'b0;
            currBlockState <= 2'b0;
            currBlockCenterX <= 5;
            currBlockCenterY <= 2;
            maxHeight <= 0;
            if (i == 23 && j == 9) begin
                i <= 0;
                j <= 0;
                rstReg <= 0;
            end else if (j == 9) begin
                i <= i + 1;
                j <= 0;
            end else begin
                j <= j + 1;
            end
        end
    end

    // #################################
    // # Main Tetris logic starts here #
    // #################################

    // Handle keyboard signal
    always @(posedge clk_div[20]) begin
        // Handle keyboard signal
        case (keyboard_signal) 
            2'b01: moveLeftSign <= 1;
            2'b10: moveRightSign <= 1;
            2'b11: rotateSign <= 1;
            default: begin
                moveLeftSign <= 0;
                moveRightSign <= 0;
                rotateSign <= 0;
            end
        endcase
    end

    // Handle block dropping
    always @(posedge clk_div[25]) begin
        if (blockLanded) begin
            // Generate new block
            blockLanded <= 0;
            nextBlock <= $urandom % 5;
            
            currBlockType <= nextBlock;
            currBlockState <= 2'b00;
            currBlockCenterX <= 5;
            currBlockCenterY <= 2;
            prevBlockState <= 2'b00;
            prevBlockCenterX <= 5;
            prevBlockCenterY <= 2;

            updateBlockPositionSign = 1;
        end else begin
            // Move block down
            prevBlockState <= currBlockState;
            prevBlockCenterX <= currBlockCenterX;
            prevBlockCenterY <= currBlockCenterY;
            currBlockCenterY <= currBlockCenterY + 1;
            updateBlockPositionSign = 1;
        end
    end
    
    // Handle block left-moving
    always @(posedge moveLeftSign) begin
        // Border detection
        if (currBlockType == 3'b000 && currBlockState == 2'b00 && currBlockCenterX >= 3 ||
            currBlockType == 3'b000 && currBlockState == 2'b01 && currBlockCenterX >= 1 ||

            currBlockType == 3'b001 && currBlockState == 2'b00 && currBlockCenterX >= 1 ||
            
            currBlockType == 3'b010 && currBlockState == 2'b00 && currBlockCenterX >= 2 ||
            currBlockType == 3'b010 && currBlockState == 2'b01 && currBlockCenterX >= 1 ||
            currBlockType == 3'b010 && currBlockState == 2'b10 && currBlockCenterX >= 2 ||
            currBlockType == 3'b010 && currBlockState == 2'b11 && currBlockCenterX >= 2 ||
            
            currBlockType == 3'b011 && currBlockState == 2'b00 && currBlockCenterX >= 2 ||
            currBlockType == 3'b011 && currBlockState == 2'b01 && currBlockCenterX >= 1 ||
            currBlockType == 3'b011 && currBlockState == 2'b10 && currBlockCenterX >= 2 ||
            currBlockType == 3'b011 && currBlockState == 2'b11 && currBlockCenterX >= 2 ||
            
            currBlockType == 3'b100 && currBlockState == 2'b00 && currBlockCenterX >= 2 ||
            currBlockType == 3'b100 && currBlockState == 2'b01 && currBlockCenterX >= 2 ||
            currBlockType == 3'b100 && currBlockState == 2'b10 && currBlockCenterX >= 2 ||
            currBlockType == 3'b100 && currBlockState == 2'b11 && currBlockCenterX >= 2 
        ) begin
            currBlockCenterX <= currBlockCenterX - 1;
            prevBlockCenterX <= currBlockCenterX;
            prevBlockCenterY <= currBlockCenterY;
            prevBlockState <= currBlockState;
            updateBlockPositionSign = 1;
        end
        moveLeftSign <= 0;
    end

    // Handle block right-moving
    always @(posedge moveRightSign) begin
        // Border detection
        if (currBlockType == 3'b000 && currBlockState == 2'b00 && currBlockCenterX <= 7 ||
            currBlockType == 3'b000 && currBlockState == 2'b01 && currBlockCenterX <= 8 ||
            
            currBlockType == 3'b001 && currBlockState == 2'b00 && currBlockCenterX <= 7 ||
            
            currBlockType == 3'b010 && currBlockState == 2'b00 && currBlockCenterX <= 7 ||
            currBlockType == 3'b010 && currBlockState == 2'b01 && currBlockCenterX <= 7 ||
            currBlockType == 3'b010 && currBlockState == 2'b10 && currBlockCenterX <= 7 ||
            currBlockType == 3'b010 && currBlockState == 2'b11 && currBlockCenterX <= 8 ||
            
            currBlockType == 3'b011 && currBlockState == 2'b00 && currBlockCenterX <= 7 ||
            currBlockType == 3'b011 && currBlockState == 2'b01 && currBlockCenterX <= 7 ||
            currBlockType == 3'b011 && currBlockState == 2'b10 && currBlockCenterX <= 7 ||
            currBlockType == 3'b011 && currBlockState == 2'b11 && currBlockCenterX <= 8 ||
            
            currBlockType == 3'b100 && currBlockState == 2'b00 && currBlockCenterX <= 7 ||
            currBlockType == 3'b100 && currBlockState == 2'b01 && currBlockCenterX <= 8 ||
            currBlockType == 3'b100 && currBlockState == 2'b10 && currBlockCenterX <= 7 ||
            currBlockType == 3'b100 && currBlockState == 2'b11 && currBlockCenterX <= 8 
        ) begin
            currBlockCenterX <= currBlockCenterX + 1;
            prevBlockCenterX <= currBlockCenterX;
            prevBlockCenterY <= currBlockCenterY;
            prevBlockState <= currBlockState;
            updateBlockPositionSign = 1;
        end
        moveRightSign <= 0;
    end

    // Handle block rotation
    always @(posedge rotateSign) begin
        rotateSign <= 0;
        currBlockState <= currBlockState + 1;
        prevBlockState <= currBlockState;
        prevBlockCenterX <= currBlockCenterX;
        prevBlockCenterX <= currBlockCenterY;
        updateBlockPositionSign = 1;
    end

    // Update block position and handle block landing
    always @(posedge updateBlockPositionSign) begin
        // TODO
    end

    // Map 2-d registers to 1-d signal lines
    // TODO
    
endmodule