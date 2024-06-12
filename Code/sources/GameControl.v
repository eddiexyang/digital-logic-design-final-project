module GameControl(
    input clk, // clk signal
    input rst, // Asychronous reset, active high
    input [1:0] keyboard_signal, // 00 for up, 01 for left, 10 for right, 11 for enter
    output reg [6:0] score,
    output [199:0] objects, // 1 for existing object, 0 for empty
    output [199:0] flash, // 1 for flash, 0 for no flash
    output reg [2:0] nextBlock, // See definition in the documentation
);
    // Perform clock division
    wire [31:0] div_res;
    clkdiv div_inst(.clk(clk), .reset(0), .clk_div(div_res));

    // Map two 1-d arrays to objectMatrix and flashMatrix
    // TO BE REVIEWED
    reg [19:0][11:0] objectMatrix;
    reg [19:0][11:0] flashMatrix;
    genvar i;
    generate
        for (i = 0; i < 200; i = i + 1) begin
            assign objects[i] = objectMatrix[i / 10][i % 10];
            assign flash[i] = flashMatrix[i / 10][i % 10];
        end
    endgenerate

    // Circuit connection
    // Failure check
    // TODO

    // Main Tetris logic
    always @(posedge clk) begin
        if (rst) begin
            score <= 0;
            objectMatrix <= 0;
            flash <= 0;
            nextBlock <= 0;
        end else begin
            // TODO
        end
    end

endmodule