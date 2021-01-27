rgbasm -o breakout.o breakout.asm
rgblink -o breakout.gb breakout.o
rgbfix -v -p 0 breakout.gb