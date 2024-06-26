module test_GameControl();
    reg clk;
    reg rst;
    wire [199:0] objects;

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
        .clk       (clk       ),
        .rst       (rst       ),
        .objects   (objects   )
    );

endmodule