module TopLevelShell(
    input clk,
    input ps2_clk,
    input ps2_data,

    output hs,
    output vs,
    output [3:0] r,
    output [3:0] g,
    output [3:0] b,
    output reg led,
    output fail
);  
    // Perform clock division
    reg [31:0] clk_div = 0;
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    // Handle keyboard inputs
    reg rst = 0;
    wire left, right, down, up, space;
    reg [2:0] keyboard_signal;
    always @(space, down, left, right, up) begin
        if (space) begin
            keyboard_signal <= 3'b000;
            rst <= 1;
            led = ~led;
        end else if (down) begin
            keyboard_signal <= 3'b100;
        end else if (left) begin
            keyboard_signal <= 3'b101;
        end else if (right) begin
            keyboard_signal <= 3'b110;
        end else if (up) begin
            keyboard_signal <= 3'b111;
        end else begin
            keyboard_signal <= 3'b000;
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

    initial begin
        led = 0;
    end

endmodule