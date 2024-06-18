module VGAdisplay(
    input clk,                  // 25MHz
    input clrn,                 // negative clear signal
    input [2:0] nextblock,      // type of nextblock 
    input [199:0] objectMatrix, // 10*20 14*14 blocks
    output rd,                  // read pixel RAM (active high)
    output hs,
  	output vs,
  	output [3:0] r,
  	output [3:0] g,
  	output [3:0] b
    );

wire rdn;                        // connect to VGAc module
wire [11:0] vgac_input;          // rrrr_gggg_bbbb input connect to VGAc module
wire [8:0] row_addr;             // row address of current scanning pixel
wire [9:0] col_addr;             // column address of current scanning pixel
wire [4:0] row;                  // block row (0-19)
wire [3:0] col;                  // block column (0-9)
wire row_nextblock;              // nextblock row (0-1)
wire [1:0] col_nextblock;        // nextblock col (0-3)
wire [2:0] index;                // index in nextblocks;
wire [8:0] row_start_addr;       // top_left_corner pixel row_addr of the current block 
wire [9:0] col_start_addr;       // top_left_corner pixel col_addr of the current block
wire [8:0] row_start_addr_next;  // similar as row_start_addr
wire [9:0] col_start_addr_next;  // similar as col_start_addr
wire [18:0] addr_background;     // ROM rom_background address according to current scanning pixel (0-307199)
wire [11:0] data_background;     // rrrr_gggg_bbbb format pixel data in addr_background
wire [18:0] addr_block;          // ROM rom_block address according to current scanning pixel (0-14^2-1)
wire [18:0] addr_nextblock;      // same as above    
wire [11:0] data_flash;          // rrrr_gggg_bbbb format pixel data if flashing
wire [11:0] data_block;          // rrrr_gggg_bbbb format pixel data if block existing
wire [11:0] data_nextblock;      // same as above
wire within_blocks;              // 1 for address within blocks
wire within_nextblocks;          // 1 for address within nextblocks
wire en_flash;                   // 1 for flash, 0 for no flash
wire en_block;                   // 1 for block, 0 for no block
wire en_nextblock;              // 1 for next_block, 0 for no next_block

assign rd = ~rdn;

assign within_blocks = (col_addr >= 208 && col_addr <= 347) && (row_addr >= 105 && row_addr <= 383);     // (207,105): top left corner pixel addr of blocks, (346,382): bottom right corner pixel addr of blocks
assign within_nextblocks = (col_addr >= 368 && col_addr <= 423) && (row_addr >= 279 && row_addr <= 306); // same as above
assign row_nextblock = (row_addr - 279) / 14;
assign col_nextblock = (col_addr - 368) / 14;
assign index = row_nextblock * 2 + col_nextblock;
assign row = (row_addr - 105) / 14;                                                                      // one single block has 12 rows with 2 frame rows
assign col = (col_addr - 208) / 14;                                                                      // one single block has 12 columns with 2 frame columns
assign row_start_addr = 105 + row * 14;
assign col_start_addr = 208 + col * 14;
assign row_start_addr_next = 279 + row_nextblock * 14;
assign col_start_addr_next = 368 + col_nextblock * 14;                                          
assign addr_background = 640 * row_addr + col_addr;
assign addr_block = addr_background;//(row_addr - row_start_addr) * 14 + (col_addr - col_start_addr);
assign addr_nextblock = addr_background;//(row_addr - row_start_addr_next) * 14 + (col_addr - col_start_addr_next);

assign en_flash = 0;//flash[row * 10 + col];
assign en_block = objectMatrix[row * 10 + col];                 
assign en_nextblock = (nextblock == 0 && (index >= 4 && index <= 7)) ||
                      (nextblock == 1 && (index == 0 || index == 1 || index == 4 || index == 5)) ||
                      (nextblock == 2 && (index == 1 || index >= 4 && index <= 6)) ||
                      (nextblock == 3 && (index == 2 || index >= 4 && index <= 6)) ||
                      (nextblock == 4 && (index == 0 || index == 1 || index == 5 || index == 6))
                      ? 1'b1 : 1'b0;

assign data_flash = 12'b1100_1100_1100;

assign vgac_input = ( within_nextblocks == 1'b1 ) ? ((en_nextblock) ? data_nextblock : data_background) :
                    ( within_blocks == 1'b0 )     ? data_background :
                    ( en_flash == 1'b1 )          ? data_flash      :
                    ( en_block == 1'b1 )          ? data_block      :
                                                    data_background ; // no blocks in the background image by default

// Instantiate rom_background IP kernel
rom_background rom0(
    .clka(clk),               // input wire clka
    .addra(addr_background),  // input wire [18:0] addra
    .douta(data_background)   // output wire [11:0] douta
);


// Instantiate rom_block IP kernel
rom_full_tetris rom1(
    .clka(clk),               // input wire clka
    .addra(addr_block),       // input wire [3:0] addra
    .douta(data_block)        // output wire [11:0] douta
);

// Instantiate rom_nextblock IP kernel
rom_full_tetris rom2(
    .clka(clk),               // input wire clka
    .addra(addr_nextblock),   // input wire [3:0] addra
    .douta(data_nextblock)    // output wire [11:0] douta
);

// Instantiate VGAc module
VGAc vgac_inst(
    .d_in(vgac_input),
    .vga_clk(clk),
    .clrn(clrn),
    .row_addr(row_addr),
    .col_addr(col_addr),
    .r(r),
    .g(g),
    .b(b),
    .rdn(rdn), 
    .hs(hs),
    .vs(vs)
);

endmodule
