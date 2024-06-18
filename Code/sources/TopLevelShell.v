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
<<<<<<< HEAD
    
=======

>>>>>>> d7b5d5584106016c8d55b07e4dc6d42c05d77d2b
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

<<<<<<< HEAD
=======
    // Handle reset signal from keyboard
>>>>>>> d7b5d5584106016c8d55b07e4dc6d42c05d77d2b
    always @(posedge down) begin
        clrn = 0;
        #100 clrn = 1;
    end
<<<<<<< HEAD
    
=======

>>>>>>> d7b5d5584106016c8d55b07e4dc6d42c05d77d2b
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