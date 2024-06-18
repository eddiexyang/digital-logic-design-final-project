module GameControl(
    input clk,                   // clk signal
    input rst,                   // Asychronous reset, active high
    input [2:0] keyboard_signal, // 000 for idle, 100 for down, 101 for left, 110 for right, 111 for rotate
    output reg [6:0] score,
    output reg [2:0] nextBlock,  // See definition in the documentation
    output [199:0] objects,      // 1 for existing object, 0 for empty
    output reg fail              // 1 for game over
);
    // Here we use 24x10 registers to store the 20x10 game board
    // the 4 extra rows at top and 1 extra row at bottom
    // are used for block generation and landing detection
    reg objectReg [24:0][9:0];
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
    reg rotateSign = 0;
    reg moveLeftSign = 0;
    reg moveRightSign = 0;
    reg updateBlockPositionSign = 0;
    reg drawCurrentBlockSign = 0;
    reg checkBlockLandedSign = 0;
    reg eliminateRowSign = 0;
    reg blockLanded = 0;

    reg [4:0] rowSum = 0;
    reg executeFail = 0;
    integer row, coln, p, q, r;

    // Perform clock division
    reg [31:0] clk_div;
    reg clk_div_25_prev;
    reg clk_div_25_curr;
    reg clk_div_25_posedge;
    reg clk_div_22_prev;
    reg clk_div_22_curr;
    reg clk_div_22_posedge;

    always @(posedge clk) begin
        if (rst) begin
            clk_div <= 0;
        end else begin
            clk_div <= clk_div + 1;
        end

        clk_div_25_prev <= clk_div_25_curr;
        clk_div_25_curr <= clk_div[25];
        if (clk_div_25_curr == 1 && clk_div_25_prev == 0) begin
            clk_div_25_posedge <= 1;
        end else begin
            clk_div_25_posedge <= 0;
        end

        clk_div_22_prev <= clk_div_22_curr;
        clk_div_22_curr <= clk_div[22];
        if (clk_div_22_curr == 1 && clk_div_22_prev == 0) begin
            clk_div_22_posedge <= 1;
        end else begin
            clk_div_22_posedge <= 0;
        end
    end

    // #################################
    // # Main Tetris logic starts here #
    // #################################

    reg rstReg = 0;
    always @(posedge clk) begin
        // Handle reset signal
        if (rst) begin
            rstReg <= 1;
            score <= 7'b0;
            nextBlock <= 3'b0;
            maxHeight <= 0;
            fail <= 0;
            blockLanded <= 0;

            currBlockType <= 3'b0;
            currBlockState <= 2'b0;
            currBlockCenterX <= 5;
            currBlockCenterY <= 2;
            prevBlockState <= 2'b0;
            prevBlockCenterX <= 5;
            updateBlockPositionSign <= 0;

            objectReg[24][0] <= 1;
            objectReg[24][1] <= 1;
            objectReg[24][2] <= 1;
            objectReg[24][3] <= 1;
            objectReg[24][4] <= 1;
            objectReg[24][5] <= 1;
            objectReg[24][6] <= 1;
            objectReg[24][7] <= 1;
            objectReg[24][8] <= 1;
            objectReg[24][9] <= 1;

            i <= 0;
            j <= 0;
        end else if (rstReg) begin
            objectReg[i][j] <= 0;
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
        end else begin
            // Handle keyboard signal
            if (keyboard_signal == 3'b101) begin
                moveLeftSign <= 1;
            end else if (keyboard_signal == 3'b110) begin
                moveRightSign <= 1;
            end else if (keyboard_signal == 3'b111) begin
                rotateSign <= 1;
            end else begin
                // Handle block dropping            
                if (~fail && (clk_div_25_posedge || keyboard_signal == 3'b100)) begin
                    if (blockLanded) begin
                        score <= score + 1;
                        // Generate new block
                        blockLanded <= 0;
                        nextBlock <= clk_div % 5;
                        
                        currBlockType <= nextBlock;
                        currBlockState <= 2'b00;
                        currBlockCenterX <= 5;
                        currBlockCenterY <= 2;
                        prevBlockState <= 2'b00;
                        prevBlockCenterX <= 5;
                        prevBlockCenterY <= 2;

                        updateBlockPositionSign <= 1;
                    end else begin
                        // Move block down
                        prevBlockState <= currBlockState;
                        prevBlockCenterX <= currBlockCenterX;
                        prevBlockCenterY <= currBlockCenterY;
                        currBlockCenterY <= currBlockCenterY + 1;
                        updateBlockPositionSign <= 1;
                    end
                end
            
                // Handle block left-moving
                if (~fail && moveLeftSign) begin
                    moveLeftSign <= 0;
                    // Border detection
                    if (currBlockType == 3'b000 && currBlockState == 2'b00 && currBlockCenterX >= 3 ||
                        currBlockType == 3'b000 && currBlockState == 2'b01 && currBlockCenterX >= 1 ||
                        currBlockType == 3'b000 && currBlockState == 2'b10 && currBlockCenterX >= 3 ||
                        currBlockType == 3'b000 && currBlockState == 2'b11 && currBlockCenterX >= 1 ||

                        currBlockType == 3'b001 && currBlockState == 2'b00 && currBlockCenterX >= 1 ||
                        currBlockType == 3'b001 && currBlockState == 2'b01 && currBlockCenterX >= 1 ||
                        currBlockType == 3'b001 && currBlockState == 2'b10 && currBlockCenterX >= 1 ||
                        currBlockType == 3'b001 && currBlockState == 2'b11 && currBlockCenterX >= 1 ||

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
                        updateBlockPositionSign <= 1;
                    end
                end

                // Handle block right-moving
                if (~fail && moveRightSign) begin
                    moveRightSign <= 0;
                    // Border detection
                    if (currBlockType == 3'b000 && currBlockState == 2'b00 && currBlockCenterX <= 7 ||
                        currBlockType == 3'b000 && currBlockState == 2'b01 && currBlockCenterX <= 8 ||
                        currBlockType == 3'b000 && currBlockState == 2'b10 && currBlockCenterX <= 7 ||
                        currBlockType == 3'b000 && currBlockState == 2'b11 && currBlockCenterX <= 8 ||

                        currBlockType == 3'b001 && currBlockState == 2'b00 && currBlockCenterX <= 7 ||
                        currBlockType == 3'b001 && currBlockState == 2'b01 && currBlockCenterX <= 7 ||
                        currBlockType == 3'b001 && currBlockState == 2'b10 && currBlockCenterX <= 7 ||
                        currBlockType == 3'b001 && currBlockState == 2'b11 && currBlockCenterX <= 7 ||

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
                        updateBlockPositionSign <= 1;
                    end
                end

                // Handle block rotation
                if (~fail && rotateSign) begin
                    rotateSign <= 0;
                    currBlockState <= currBlockState + 1;
                    prevBlockState <= currBlockState;
                    prevBlockCenterX <= currBlockCenterX;
                    prevBlockCenterY <= currBlockCenterY;
                    updateBlockPositionSign <= 1;
                end

                // Update block position and handle block landing
                // Erase the previous block
                if (~fail && updateBlockPositionSign) begin
                    updateBlockPositionSign <= 0;
                    drawCurrentBlockSign <= 1;
                    case (currBlockType)
                        3'b000: begin
                            case (prevBlockState)
                                2'b00, 2'b10: begin
                                    objectReg[prevBlockCenterY][prevBlockCenterX - 2] <= 0;
                                    objectReg[prevBlockCenterY][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY][prevBlockCenterX + 1] <= 0;
                                end
                                2'b01, 2'b11: begin
                                    objectReg[prevBlockCenterY - 2][prevBlockCenterX] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX] <= 0;
                                end
                            endcase
                        end
                        3'b001: begin
                            objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                            objectReg[prevBlockCenterY    ][prevBlockCenterX + 1] <= 0;
                            objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                            objectReg[prevBlockCenterY    ][prevBlockCenterX + 1] <= 0;
                        end
                        3'b010: begin
                            case (prevBlockState)
                                2'b00: begin
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX + 1] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                                end
                                2'b01: begin
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX + 1] <= 0;
                                end
                                2'b10: begin
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX + 1] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX    ] <= 0;
                                end
                                2'b11: begin
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX - 1] <= 0;
                                end
                            endcase
                        end
                        3'b011: begin
                            case (prevBlockState)
                                2'b00: begin
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX + 1] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX + 1] <= 0;
                                end
                                2'b01: begin
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX + 1] <= 0;
                                end
                                2'b10: begin
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX + 1] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX - 1] <= 0;
                                end
                                2'b11: begin
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX - 1] <= 0;
                                end
                            endcase
                        end
                        3'b100: begin
                            case (prevBlockState)
                                2'b00: begin
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX + 1] <= 0;
                                end
                                2'b01: begin
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX    ] <= 0;
                                end
                                2'b10: begin
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX + 1] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                                end
                                2'b11: begin
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY    ][prevBlockCenterX - 1] <= 0;
                                    objectReg[prevBlockCenterY - 1][prevBlockCenterX    ] <= 0;
                                    objectReg[prevBlockCenterY + 1][prevBlockCenterX - 1] <= 0;
                                end
                            endcase
                        end
                    endcase
                end

                // Draw the current block
                if (~fail && drawCurrentBlockSign) begin
                    checkBlockLandedSign <= 1;
                    drawCurrentBlockSign <= 0;
                    case (currBlockType)
                        3'b000: begin
                            case(currBlockState)
                                2'b00, 2'b10: begin
                                    objectReg[currBlockCenterY][currBlockCenterX - 2] <= 1;
                                    objectReg[currBlockCenterY][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY][currBlockCenterX + 1] <= 1;
                                end
                                2'b01, 2'b11: begin
                                    objectReg[currBlockCenterY - 2][currBlockCenterX] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX] <= 1;
                                end
                            endcase
                        end
                        3'b001: begin
                            objectReg[currBlockCenterY - 1][currBlockCenterX - 1] <= 1;
                            objectReg[currBlockCenterY - 1][currBlockCenterX + 1] <= 1;
                            objectReg[currBlockCenterY    ][currBlockCenterX - 1] <= 1;
                            objectReg[currBlockCenterY    ][currBlockCenterX + 1] <= 1;
                        end
                        3'b010: begin
                            case(currBlockState)
                                2'b00: begin
                                    objectReg[currBlockCenterY    ][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX + 1] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX    ] <= 1;
                                end
                                2'b01: begin
                                    objectReg[currBlockCenterY - 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX + 1] <= 1;
                                end
                                2'b10: begin
                                    objectReg[currBlockCenterY    ][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX + 1] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX    ] <= 1;
                                end
                                2'b11: begin
                                    objectReg[currBlockCenterY - 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX - 1] <= 1;
                                end
                            endcase
                        end
                        3'b011: begin
                            case(currBlockState)
                                2'b00: begin
                                    objectReg[currBlockCenterY    ][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX + 1] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX + 1] <= 1;
                                end
                                2'b01: begin
                                    objectReg[currBlockCenterY - 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX + 1] <= 1;
                                end
                                2'b10: begin
                                    objectReg[currBlockCenterY    ][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX + 1] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX - 1] <= 1;
                                end
                                2'b11: begin
                                    objectReg[currBlockCenterY - 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX - 1] <= 1;
                                end
                            endcase
                        end
                        3'b100: begin
                            case(currBlockState)
                                2'b00: begin
                                    objectReg[currBlockCenterY    ][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX + 1] <= 1;
                                end
                                2'b01: begin
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX    ] <= 1;
                                end
                                2'b10: begin
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX + 1] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX    ] <= 1;
                                end
                                2'b11: begin
                                    objectReg[currBlockCenterY    ][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY    ][currBlockCenterX - 1] <= 1;
                                    objectReg[currBlockCenterY - 1][currBlockCenterX    ] <= 1;
                                    objectReg[currBlockCenterY + 1][currBlockCenterX - 1] <= 1;
                                end
                            endcase
                        end
                    endcase
                end

                // Check if the block has landed
                if (~fail && checkBlockLandedSign) begin
                    checkBlockLandedSign <= 0;
                    eliminateRowSign <= 1;
                    case (currBlockType)
                        3'b000: begin
                            case (currBlockState)
                                2'b00, 2'b10: begin
                                    if (objectReg[currBlockCenterY + 1][currBlockCenterX - 2] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX    ] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX + 1] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - currBlockCenterY > maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b01, 2'b11: begin
                                    if (objectReg[currBlockCenterY + 2][currBlockCenterX] == 1) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 2) > maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                            endcase
                        end
                        3'b001: begin
                            if (objectReg[currBlockCenterY + 1][currBlockCenterX    ] == 1 ||
                                objectReg[currBlockCenterY + 1][currBlockCenterX + 1] == 1
                            ) begin
                                blockLanded <= 1;
                                if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                    maxHeight <= 24 - currBlockCenterY;
                                end
                            end
                        end
                        3'b010: begin
                            case (currBlockState)
                                2'b00: begin
                                    if (objectReg[currBlockCenterY + 1][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX    ] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX + 1] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b01: begin
                                    if (objectReg[currBlockCenterY + 1][currBlockCenterX + 1] == 1 ||
                                        objectReg[currBlockCenterY + 2][currBlockCenterX    ] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b10: begin
                                    if (objectReg[currBlockCenterY + 1][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 2][currBlockCenterX    ] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX + 1] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - currBlockCenterY > maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b11: begin
                                    if (objectReg[currBlockCenterY + 1][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 2][currBlockCenterX    ] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                            endcase
                        end
                        3'b011: begin
                            case (currBlockState)
                                2'b00: begin
                                    if (objectReg[currBlockCenterY + 1][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX    ] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX + 1] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b01: begin
                                    if (objectReg[currBlockCenterY + 2][currBlockCenterX    ] == 1 ||
                                        objectReg[currBlockCenterY + 2][currBlockCenterX + 1] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b10: begin
                                    if (objectReg[currBlockCenterY + 2][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX    ] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX + 1] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - currBlockCenterY > maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b11: begin
                                    if (objectReg[currBlockCenterY    ][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 2][currBlockCenterX    ] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                            endcase
                        end
                        3'b100: begin
                            case (currBlockState)
                                2'b00: begin
                                    if (objectReg[currBlockCenterY + 1][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX    ] == 1 ||
                                        objectReg[currBlockCenterY    ][currBlockCenterX + 1] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b01: begin
                                    if (objectReg[currBlockCenterY + 1][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 2][currBlockCenterX    ] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b10: begin
                                    if (objectReg[currBlockCenterY    ][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX    ] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX + 1] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                                2'b11: begin
                                    if (objectReg[currBlockCenterY + 2][currBlockCenterX - 1] == 1 ||
                                        objectReg[currBlockCenterY + 1][currBlockCenterX    ] == 1
                                    ) begin
                                        blockLanded <= 1;
                                        if (24 - (currBlockCenterY - 1)> maxHeight) begin
                                            maxHeight <= 24 - currBlockCenterY;
                                        end
                                    end
                                end
                            endcase
                        end
                    endcase
                end

                // Eliminate the full rows
                if (~fail && eliminateRowSign) begin
                    for (row = 4; row < 24; row = row + 1) begin
                        rowSum = 0;
                        for (coln = 0; coln < 10; coln = coln + 1) begin
                            rowSum = rowSum + objectReg[row][coln];
                        end
                        if (rowSum == 10) begin
                            // Eliminate the row
                            for (p = row; p > 4; p = p - 1) begin
                                for (q = 0; q < 10; q = q + 1) begin
                                    objectReg[p][q] = objectReg[p - 1][q];
                                end
                            end
                            // Clear the top row
                            for (r = 0; r < 10; r = r + 1) begin
                                objectReg[4][r] = 0;
                            end
                            // Update the score
                            score = score + 10;
                        end
                    end
                    eliminateRowSign = 0;
                end

                // Detect game failure
                if (~fail && (executeFail || maxHeight >= 20)) begin
                    executeFail <= 1;
                    if (executeFail == 0) begin
                        row <= 23;
                        coln <= 0;
                    end else if (row == 4 && coln == 9) begin
                        objectReg[row][coln] <= 1;
                        fail <= 1;
                        executeFail <= 0;
                    end else if (coln == 9 && clk_div_22_posedge) begin
                        objectReg[row][coln] <= 1;
                        row <= row - 1;
                        coln <= 0;
                    end else if (coln != 9)begin
                        objectReg[row][coln] <= 1;
                        coln <= coln + 1;
                    end
                end // End failure animation
            end // End keyboard if
        end // End rst if
    end // End always

    // Map 2-d registers to 1-d signal lines
    genvar k;
    generate
        for (k = 0; k < 200; k = k + 1) begin: map
            assign objects[k] = objectReg[k / 10 + 4][k % 10];
        end
    endgenerate
    
endmodule