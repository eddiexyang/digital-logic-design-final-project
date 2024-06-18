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
    // Define reset signals
    reg clrn;
    wire rst;
    assign rst = ~clrn;
    
    // Handle keyboard definitions
    wire left, right, down, up, space;
    reg [2:0] keyboard_signal;
    always @(left, right, up, down) begin
        if (down) begin
            keyboard_signal <= 3'b100;
        end else if (left) begin
            keyboard_signal <= 3'b101;
        end else if (right) begin
            keyboard_signal <= 3'b110;
        end else if (up) begin
            keyboard_signal <= 3'b111;
        end else begin
            keyboard_signal <= 3'b000;
        end
    end

    // Handle reset signal from keyboard
    always @(posedge clk) begin
        if (space) begin
            clrn <= 1'b0;
        end else begin
            clrn <= 1'b1;
        end
    end

    // Define game signals
    wire [6:0] score;
    wire [2:0] nextBlock;
    wire [199:0] objects;
    wire fail;
    
    // Perform clock division
    reg [31:0] clk_div = 0;
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    // Instantiate modules
    KeyboardControl u_KeyboardControl(
        .clk      (clk      ),
        .ps2_clk  (ps2_clk  ),
        .ps2_data (ps2_data ),
        .clrn     (clrn     ),
        .left     (left     ),
        .right    (right    ),
        .down     (down     ),
        .up       (up       )
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
        .b            (b            )
    );

    // Reset signals
    initial begin
        clrn = 1'b0;
    end

endmodule