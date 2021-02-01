rgbasm -o breakout.o breakout.asm
rgbasm -o header.o header.asm
rgbasm -o input.o input.asm
rgblink -o breakout.gb breakout.o header.o input.o
rgbfix -v -p 0 breakout.gb