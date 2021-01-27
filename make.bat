rgbasm -o breakout.o breakout.asm
rgbasm -o header.o header.asm
rgblink -o breakout.gb breakout.o header.o
rgbfix -v -p 0 breakout.gb