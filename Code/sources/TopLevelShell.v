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
    wire left, right, down, up;
    reg [1:0] keyboard_signal;
    always @(left, right, up) begin
        if (left) begin
            keyboard_signal <= 2'b01;
        end else if (right) begin
            keyboard_signal <= 2'b10;
        end else if (up) begin
            keyboard_signal <= 2'b11;
        end else begin
            keyboard_signal <= 2'b00;
        end
    end

    // Define game signals
    wire [6:0] score;
    wire [2:0] nextBlock;
    wire [199:0] objects;
    wire fail;
    
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
        .clk          (clk          ),
        .clrn         (clrn         ),
        .nextblock    (nextBlock    ),
        .objectMatrix (objects      ),
        .flash        (200'b0       ),
        .hs           (hs           ),
        .vs           (vs           ),
        .r            (r            ),
        .g            (g            ),
        .b            (b            )
    );

    // Reset signals
    initial begin
        clrn = 1'b0;
        #100 clrn = 1'b1;
    end

endmodule