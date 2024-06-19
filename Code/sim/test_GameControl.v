module test_GameControl();
    reg clk;
    reg rst;
    reg [1:0] keyboard_signal;
    wire [6:0] score;
    wire [2:0] nextBlock;
    wire [199:0] objects;
    wire fail;
    
    always begin
        #5; clk <= ~clk;
    end

    initial begin
        clk = 0; rst = 0;
        #200; rst = 1;
        #5; rst = 0;
        #5000; rst = 1;
        #5 rst = 0;        
    end

    GameControl u_GameControl(
        .clk             (clk             ),
        .rst             (rst             ),
        .keyboard_signal (keyboard_signal ),
        .score           (score           ),
        .nextBlock       (nextBlock       ),
        .objects         (objects         ),
        .fail            (fail            )
    );
    

endmodule