module TopLevelShell(
    input clk,
    input ps2_clk,
    input ps2_data,
    output hs,
    output vs,
    output [3:0] r,
    output [3:0] g,
    output [3:0] b
);  
    // Perform clock division
    reg [31:0] clk_div = 0;
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    // Handle keyboard inputs
    reg rst = 0;
    wire left, right, down, up, space;
    always @(space) begin
        if (space) begin
            rst <= 1; 
        end else begin
            rst <= 0;
        end
    end

    // Define game signals
    wire [6:0] score;
    wire [2:0] nextBlock;
    wire [199:0] objects;
    
    // Instantiate modules
    KeyboardControl u_KeyboardControl(
        .clk      (clk      ),
        .ps2_clk  (ps2_clk  ),
        .ps2_data (ps2_data ),
        .clrn     (1        ),
        .left     (left     ),
        .right    (right    ),
        .down     (down     ),
        .up       (up       ),
        .space    (space    )
    );

    GameControl u_GameControl(
        .clk             (clk             ),
        .rst             (rst             ),
        .keyboard_signal (keyboard_signal ),
        .score           (score           ),
        .nextBlock       (nextBlock       ),
        .objects         (objects         ),
        .fail            (fail            )
    );

    VGAdisplay u_VGAdisplay(
        .clk          (clk_div[1]   ),
        .clrn         (1            ),
        .nextblock    (nextBlock    ),
        .objectMatrix (objects      ),
        .hs           (hs           ),
        .vs           (vs           ),
        .r            (r            ),
        .g            (g            ),
        .b            (b            ),
        .fail         (fail         )
    );

endmodule