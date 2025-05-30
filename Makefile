default: bin/maze.gb

bin/main.o: src/main.asm assets/maze.2bpp assets/player.2bpp
	mkdir -p bin
	mkdir -p assets
	rgbasm -I src/ -I include/ -o bin/main.o src/main.asm

bin/maze.gb: bin/main.o
	rgblink -o bin/maze.gb bin/main.o \
	&& rgbfix -v -p 0xFF bin/maze.gb

assets/maze.2bpp: src/assets/maze.png
	rgbgfx -o assets/maze.2bpp -O -u -T src/assets/maze.png

assets/player.2bpp: src/assets/player.png
	rgbgfx -o assets/player.2bpp -u src/assets/player.png
