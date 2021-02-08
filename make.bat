rgbasm -o ball.o ball.asm
rgbasm -o bustfree.o bustfree.asm
rgbasm -o header.o header.asm
rgbasm -o input.o input.asm
rgbasm -o oam.o oam.asm
rgbasm -o paddle.o paddle.asm
rgbasm -o sprites.o sprites.asm
rgbasm -o stage.o stage.asm
rgbasm -o tiles.o tiles.asm
rgbasm -o vblank.o vblank.asm
rgblink -d -m bustfree.map -n bustfree.sym -o bustfree.gb ball.o bustfree.o header.o input.o oam.o paddle.o sprites.o stage.o tiles.o vblank.o
rgbfix -v -p 0 bustfree.gb
