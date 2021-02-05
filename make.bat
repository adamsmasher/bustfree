rgbasm -o ball.o ball.asm
rgbasm -o breakout.o breakout.asm
rgbasm -o header.o header.asm
rgbasm -o input.o input.asm
rgbasm -o oam.o oam.asm
rgbasm -o paddle.o paddle.asm
rgbasm -o sprites.o sprites.asm
rgbasm -o vblank.o vblank.asm
rgblink -d -m breakout.map -n breakout.sym -o breakout.gb ball.o breakout.o header.o input.o oam.o paddle.o sprites.o vblank.o
rgbfix -v -p 0 breakout.gb