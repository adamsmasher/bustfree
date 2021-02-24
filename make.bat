rgbasm -o ball.o ball.asm
rgbasm -o bustfree.o bustfree.asm
rgbasm -o collide.o collide.asm
rgbasm -o font.o font.asm
rgbasm -o game.o game.asm
rgbasm -o gameover.o gameover.asm
rgbasm -o game_vblank.o game_vblank.asm
rgbasm -o handlers.o handlers.asm
rgbasm -o header.o header.asm
rgbasm -o input.o input.asm
rgbasm -o oam.o oam.asm
rgbasm -o paddle.o paddle.asm
rgbasm -o s11space.o s11space.asm
rgbasm -o sprites.o sprites.asm
rgbasm -o stage.o stage.asm
rgbasm -o stat.o stat.asm
rgbasm -o status.o status.asm
rgbasm -o tiles.o tiles.asm
rgbasm -o titlescreen.o titlescreen.asm
rgbasm -o vblank.o vblank.asm
rgbasm -o AudioDriver/SoundSystem.o AudioDriver/SoundSystem.asm
rgblink -d -m bustfree.map -n bustfree.sym -o bustfree.gb ball.o bustfree.o collide.o font.o game.o gameover.o game_vblank.o handlers.o header.o input.o oam.o paddle.o s11space.o sprites.o stage.o stat.o status.o tiles.o titlescreen.o vblank.o AudioDriver/SoundSystem.o
rgbfix -v -m 1 -p 0 bustfree.gb
