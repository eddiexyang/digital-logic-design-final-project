module GameControl(
    input clk,                   // clk signal
    input rst,                   // Asychronous reset, active high
    input left,
    input right,
    input up,
    input down,
    output reg [6:0] score,
    output reg [2:0] nextBlock,  // See definition in the documentation
    output [199:0] objects,      // 1 for existing object, 0 for empty
    output reg fail              // 1 for game over
);
    // Here we use 25x12 registers to store the 20x10 game board
    // 
    // the 4 extra rows at top are used for block generation
    //
    // 1 extra row at bottom and 2 extra columns at both sides
    // are used for collision detection
    reg objectReg [24:0][11:0];

    reg [2:0] currBlockType;
    reg [1:0] currBlockState;
    reg [3:0] currBlockCenterX;
    reg [4:0] currBlockCenterY;
    reg [1:0] prevBlockState;
    reg [3:0] prevBlockCenterX;
    reg [4:0] prevBlockCenterY;
    reg signed [7:0] coordOffsetX [4:0][3:0][2:0]; // Indices: blockType, blockState, blockNumber
    reg signed [7:0] coordOffsetY [4:0][3:0][2:0];
    
    reg gameStartSign = 0;
    reg [4:0] gameMaxHeight;
    reg ignore_keyboard_input = 0;

    reg dropSign = 0;
    reg checkPositionSign = 0;
    reg updateBlockPositionSign = 0;
    reg drawCurrentBlockSign = 0;
    reg eliminateRowSign = 0;
    reg blockLanded = 0;

    reg [4:0] rowSum = 0;
    reg executeFail = 0;
    
    integer i, j, row, coln, p, q, r;
    reg [7:0] reg_i = 0;
    reg [7:0] reg_j = 1;

    // Perform clock division
    reg [31:0] clk_div = 0;
    reg [31:0] clk_div_prev;
    wire [31:0] clk_div_posedge;
    always @(posedge clk) begin        
        clk_div <= clk_div + 1;
        clk_div_prev <= clk_div;
    end
    genvar div;
    generate
        for (div = 0; div < 32; div = div + 1) begin
            assign clk_div_posedge[div] = clk_div[div] && ~clk_div_prev[div];
        end
    endgenerate

    // Handle keyboard signal
    reg left_posedge, right_posedge, up_posedge, down_posedge;
    reg left_prev, right_prev, up_prev, down_prev;
    always @(posedge clk) begin
        left_prev <= left;
        right_prev <= right;
        up_prev <= up;
        down_prev <= down;
        if (~left_prev && left) begin
            left_posedge <= 1;
        end else begin
            left_posedge <= 0;
        end
        if (~right_prev && right) begin
            right_posedge <= 1;
        end else begin
            right_posedge <= 0;
        end
        if (~up_prev && up) begin
            up_posedge <= 1;
        end else begin
            up_posedge <= 0;
        end
        if (~down_prev && down) begin
            down_posedge <= 1;
        end else begin
            down_posedge <= 0;
        end
    end

    // Assign initial values to the game board
    initial begin
        // Fill the game board with 1s
        for (i = 0; i <= 24; i = i + 1) begin
            for (j = 0; j <= 11; j = j + 1) begin
                objectReg[i][j] = 1;
            end
        end
        // Initialize the block generation offsets
        // Block type 0, block state 0
        coordOffsetX[0][0][0] = -2; coordOffsetY[0][0][0] =  0;
        coordOffsetX[0][0][1] = -1; coordOffsetY[0][0][1] =  0;
        coordOffsetX[0][0][2] =  1; coordOffsetY[0][0][2] =  0;
        // Block type 0, block state 1
        coordOffsetX[0][1][0] =  0; coordOffsetY[0][1][0] = -2;
        coordOffsetX[0][1][1] =  0; coordOffsetY[0][1][1] = -1;
        coordOffsetX[0][1][2] =  0; coordOffsetY[0][1][2] =  1;
        // Block type 0, block state 2
        coordOffsetX[0][2][0] = -2; coordOffsetY[0][2][0] =  0;
        coordOffsetX[0][2][1] = -1; coordOffsetY[0][2][1] =  0;
        coordOffsetX[0][2][2] =  1; coordOffsetY[0][2][2] =  0;
        // Block type 0, block state 3
        coordOffsetX[0][3][0] =  0; coordOffsetY[0][3][0] = -2;
        coordOffsetX[0][3][1] =  0; coordOffsetY[0][3][1] = -1;
        coordOffsetX[0][3][2] =  0; coordOffsetY[0][3][2] =  1;
        // Block type 1, block state 0
        coordOffsetX[1][0][0] =  0; coordOffsetY[1][0][0] = -1;
        coordOffsetX[1][0][1] =  1; coordOffsetY[1][0][1] = -1;
        coordOffsetX[1][0][2] =  1; coordOffsetY[1][0][2] =  0;
        // Block type 1, block state 1
        coordOffsetX[1][0][0] =  0; coordOffsetY[1][0][0] = -1;
        coordOffsetX[1][0][1] =  1; coordOffsetY[1][0][1] = -1;
        coordOffsetX[1][0][2] =  1; coordOffsetY[1][0][2] =  0;
        // Block type 1, block state 2
        coordOffsetX[1][0][0] =  0; coordOffsetY[1][0][0] = -1;
        coordOffsetX[1][0][1] =  1; coordOffsetY[1][0][1] = -1;
        coordOffsetX[1][0][2] =  1; coordOffsetY[1][0][2] =  0;
        // Block type 1, block state 3
        coordOffsetX[1][0][0] =  0; coordOffsetY[1][0][0] = -1;
        coordOffsetX[1][0][1] =  1; coordOffsetY[1][0][1] = -1;
        coordOffsetX[1][0][2] =  1; coordOffsetY[1][0][2] =  0;
        // Block type 2, block state 0
        coordOffsetX[2][0][0] = -1; coordOffsetY[2][0][0] =  0;
        coordOffsetX[2][0][1] =  0; coordOffsetY[2][0][1] = -1;
        coordOffsetX[2][0][2] =  1; coordOffsetY[2][0][2] =  0;
        // Block type 2, block state 1
        coordOffsetX[2][1][0] =  0; coordOffsetY[2][1][0] = -1;
        coordOffsetX[2][1][1] =  1; coordOffsetY[2][1][1] =  0;
        coordOffsetX[2][1][2] =  0; coordOffsetY[2][1][2] =  1;
        // Block type 2, block state 2
        coordOffsetX[2][2][0] = -1; coordOffsetY[2][2][0] =  0;
        coordOffsetX[2][2][1] =  0; coordOffsetY[2][2][1] =  1;
        coordOffsetX[2][2][2] =  1; coordOffsetY[2][2][2] =  0;
        // Block type 2, block state 3
        coordOffsetX[2][3][0] =  0; coordOffsetY[2][3][0] = -1;
        coordOffsetX[2][3][1] = -1; coordOffsetY[2][3][1] =  0;
        coordOffsetX[2][3][2] =  0; coordOffsetY[2][3][2] =  1;
        // Block type 3, block state 0
        coordOffsetX[3][0][0] = -1; coordOffsetY[3][0][0] =  0;
        coordOffsetX[3][0][1] =  1; coordOffsetY[3][0][1] =  0;
        coordOffsetX[3][0][2] =  1; coordOffsetY[3][0][2] = -1;
        // Block type 3, block state 1
        coordOffsetX[3][1][0] =  0; coordOffsetY[3][1][0] = -1;
        coordOffsetX[3][1][1] =  0; coordOffsetY[3][1][1] =  1;
        coordOffsetX[3][1][2] =  1; coordOffsetY[3][1][2] =  1;
        // Block type 3, block state 2
        coordOffsetX[3][2][0] = -1; coordOffsetY[3][2][0] =  1;
        coordOffsetX[3][2][1] = -1; coordOffsetY[3][2][1] =  0;
        coordOffsetX[3][2][2] =  1; coordOffsetY[3][2][2] =  0;
        // Block type 3, block state 3
        coordOffsetX[3][3][0] = -1; coordOffsetY[3][3][0] = -1;
        coordOffsetX[3][3][1] =  0; coordOffsetY[3][3][1] = -1;
        coordOffsetX[3][3][2] =  0; coordOffsetY[3][3][2] =  1;
        // Block type 4, block state 0
        coordOffsetX[4][0][0] = -1; coordOffsetY[4][0][0] =  0;
        coordOffsetX[4][0][1] =  0; coordOffsetY[4][0][1] = -1;
        coordOffsetX[4][0][2] =  1; coordOffsetY[4][0][2] = -1;
        // Block type 4, block state 1
        coordOffsetX[4][1][0] = -1; coordOffsetY[4][1][0] = -1;
        coordOffsetX[4][1][1] = -1; coordOffsetY[4][1][1] =  0;
        coordOffsetX[4][1][2] =  0; coordOffsetY[4][1][2] =  1;
        // Block type 4, block state 2
        coordOffsetX[4][2][0] = -1; coordOffsetY[4][2][0] = -1;
        coordOffsetX[4][2][1] =  0; coordOffsetY[4][2][1] = -1;
        coordOffsetX[4][2][2] =  1; coordOffsetY[4][2][2] =  0;
        // Block type 4, block state 3
        coordOffsetX[4][3][0] =  0; coordOffsetY[4][3][0] = -1;
        coordOffsetX[4][3][1] = -1; coordOffsetY[4][3][1] =  0;
        coordOffsetX[4][3][2] = -1; coordOffsetY[4][3][2] =  1;
    end

    // #################################
    // # Main Tetris logic starts here #
    // #################################
    
    always @(posedge clk) begin
        // Handle reset signal
        if (rst) begin
            // Clear game board
            for (i = 0; i <= 23; i = i + 1) begin
                for (j = 1; j <= 10; j = j + 1) begin
                    objectReg[i][j] <= 0;
                end
            end

            gameStartSign = 1;
            // Clear block state
            currBlockType <= 3'b0;
            currBlockState <= 2'b0;
            currBlockCenterX <= 5;
            currBlockCenterY <= 2;
            prevBlockState <= 2'b0;
            prevBlockCenterX <= 5;
            prevBlockCenterY <= 2;
            
            // Reset signs
            checkPositionSign <= 0;
            updateBlockPositionSign <= 0;
            drawCurrentBlockSign <= 0;
            eliminateRowSign <= 0;
            blockLanded <= 0;

            // Clear game status
            score <= 7'b0;
            nextBlock <= 3'b0;
            fail <= 0;
            executeFail <= 0;
            gameMaxHeight <= 0;
        end else if (gameStartSign && ~fail) begin
            // Keyboard debounce
            if (clk_div_posedge[20]) begin
                ignore_keyboard_input <= 0;
            end

            // Handle block dropping            
            if (~executeFail && (clk_div_posedge[25] || down_posedge)) begin
                ignore_keyboard_input <= 1;
                if (blockLanded) begin
                    blockLanded <= 0;
                    score <= score + 1;
                    eliminateRowSign <= 1;
                    // Generate new block
                    nextBlock <= clk_div % 5;
                    currBlockType <= nextBlock;
                    currBlockState <= 2'b00;
                    currBlockCenterX <= 5;
                    currBlockCenterY <= 2;
                end else begin
                    // Move block down
                    dropSign <= 1;
                    checkPositionSign <= 1;
                    currBlockCenterY <= currBlockCenterY + 1;
                    prevBlockState <= currBlockState;
                    prevBlockCenterX <= currBlockCenterX;
                    prevBlockCenterY <= currBlockCenterY;
                end
            end
        
            // Handle block left-moving
            if (~executeFail && left_posedge) begin
                checkPositionSign <= 1;
                currBlockCenterX <= currBlockCenterX - 1;
                prevBlockCenterX <= currBlockCenterX;
                prevBlockCenterY <= currBlockCenterY;
                prevBlockState <= currBlockState;
            end

            // Handle block right-moving
            if (~executeFail && right_posedge) begin
                checkPositionSign <= 1;
                currBlockCenterX <= currBlockCenterX + 1;
                prevBlockCenterX <= currBlockCenterX;
                prevBlockCenterY <= currBlockCenterY;
                prevBlockState <= currBlockState;
            end

            // Handle block rotation
            if (~executeFail && up_posedge) begin
                checkPositionSign <= 1;
                currBlockState <= currBlockState + 1;
                prevBlockCenterX <= currBlockCenterX;
                prevBlockCenterY <= currBlockCenterY;
                prevBlockState <= currBlockState;
            end

            // Check block position
            if (~executeFail && checkPositionSign) begin
                checkPositionSign = 0;
                // Erase the previous block
                objectReg[prevBlockCenterY][prevBlockCenterX] = 0;
                objectReg[prevBlockCenterY + coordOffsetY[currBlockType][prevBlockState][0]][prevBlockCenterX + coordOffsetX[currBlockType][prevBlockState][0]] = 0;
                objectReg[prevBlockCenterY + coordOffsetY[currBlockType][prevBlockState][1]][prevBlockCenterX + coordOffsetX[currBlockType][prevBlockState][1]] = 0;
                objectReg[prevBlockCenterY + coordOffsetY[currBlockType][prevBlockState][2]][prevBlockCenterX + coordOffsetX[currBlockType][prevBlockState][2]] = 0;
                // Check if the block can be placed
                if (objectReg[currBlockCenterY][currBlockCenterX] ||
                    objectReg[currBlockCenterY + coordOffsetY[currBlockType][currBlockState][0]][currBlockCenterX + coordOffsetX[currBlockType][currBlockState][0]] ||
                    objectReg[currBlockCenterY + coordOffsetY[currBlockType][currBlockState][1]][currBlockCenterX + coordOffsetX[currBlockType][currBlockState][1]] ||
                    objectReg[currBlockCenterY + coordOffsetY[currBlockType][currBlockState][2]][currBlockCenterX + coordOffsetX[currBlockType][currBlockState][2]]
                ) begin
                    if (dropSign) begin
                        blockLanded <= 1;
                        dropSign <= 0;
                    end
                    // Reset block
                    currBlockCenterX = prevBlockCenterX;
                    currBlockCenterY = prevBlockCenterY;
                    currBlockState = prevBlockState;
                    objectReg[currBlockCenterY][currBlockCenterX] = 1;
                    objectReg[currBlockCenterY + coordOffsetY[currBlockType][currBlockState][0]][currBlockCenterX + coordOffsetX[currBlockType][currBlockState][0]] = 1;
                    objectReg[currBlockCenterY + coordOffsetY[currBlockType][currBlockState][1]][currBlockCenterX + coordOffsetX[currBlockType][currBlockState][1]] = 1;
                    objectReg[currBlockCenterY + coordOffsetY[currBlockType][currBlockState][2]][currBlockCenterX + coordOffsetX[currBlockType][currBlockState][2]] = 1;
                end else begin
                    objectReg[currBlockCenterY][currBlockCenterX] = 1;
                    objectReg[currBlockCenterY + coordOffsetY[currBlockType][currBlockState][0]][currBlockCenterX + coordOffsetX[currBlockType][currBlockState][0]] = 1;
                    objectReg[currBlockCenterY + coordOffsetY[currBlockType][currBlockState][1]][currBlockCenterX + coordOffsetX[currBlockType][currBlockState][1]] = 1;
                    objectReg[currBlockCenterY + coordOffsetY[currBlockType][currBlockState][2]][currBlockCenterX + coordOffsetX[currBlockType][currBlockState][2]] = 1;
                end
            end

            // Eliminate the full rows
            if (~executeFail && eliminateRowSign) begin
                for (row = 4; row < 24; row = row + 1) begin
                    rowSum = 0;
                    for (coln = 1; coln <= 10; coln = coln + 1) begin
                        rowSum = rowSum + objectReg[row][coln];   
                        if (objectReg[row][coln] == 1 && 24 - row > gameMaxHeight) begin
                             gameMaxHeight = 24 - row;
                        end
                    end
                    if (rowSum == 10) begin
                        // Eliminate the row
                        for (p = row; p > 4; p = p - 1) begin
                            for (q = 1; q <= 10; q = q + 1) begin
                                objectReg[p][q] = objectReg[p - 1][q];
                            end
                        end
                        // Clear the top row
                        for (r = 1; r <= 10; r = r + 1) begin
                            objectReg[4][r] = 0;
                        end
                        // Update the score
                        score = score + 10;
                    end
                end
                eliminateRowSign = 0;
            end

            // Detect game failure
            if (executeFail || gameMaxHeight >= 20) begin
                executeFail <= 1;
                if (executeFail == 0) begin
                    row <= 23;
                    coln <= 1;
                end else if (row == 4 && coln == 10) begin
                    objectReg[row][coln] <= 1;
                    fail <= 1;
                    executeFail <= 0;
                end else if (coln == 10) begin
                    objectReg[row][coln] <= 1;
                    if (clk_div_posedge[22]) begin
                        row <= row - 1;
                        coln <= 1;    
                    end
                end else begin
                    objectReg[row][coln] <= 1;
                    coln <= coln + 1;
                end
            end
        end
    end

    // Map 2-d registers to 1-d signal lines
    genvar k, l;
    generate
        for (k = 4; k <= 23; k = k + 1) begin: map
            for (l = 1; l <= 10; l = l + 1) begin
                assign objects[10 * (k - 4) + l - 1] = objectReg[k][l];
            end
        end
    endgenerate
    
endmodule