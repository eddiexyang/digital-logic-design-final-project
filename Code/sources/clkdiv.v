module clkdiv(
    input clk,
    input reset,
    output reg [31:0] clk_div
);

    always @(posedge clk) begin
        if (reset) begin
            clk_div <= 0;
        end else if (clk_div == 32'hffff) begin
            clk_div <= 0;
        end else begin
            clk_div <= clk_div + 1;
        end
    end

endmodule