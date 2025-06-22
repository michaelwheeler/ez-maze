all: bin/web/ezmaze.gb
.PHONY: all

rom: bin/ezmaze.gb
.PHONY: rom

bin/utils.o: src/utils.asm
	rgbasm -I src/ -I include/ -o bin/utils.o src/utils.asm

bin/ezmaze.o: src/ezmaze.asm
	rgbasm -I src/ -I include/ -o bin/ezmaze.o src/ezmaze.asm

bin/title-screen.o: src/title-screen.asm assets/titlescreen.2bpp
	rgbasm -I src/ -I include/ -o bin/title-screen.o src/title-screen.asm

bin/gameplay.o: src/gameplay.asm assets/maze.2bpp assets/player.2bpp
	rgbasm -I src/ -I include/ -o bin/gameplay.o src/gameplay.asm

bin/ezmaze.gb: bin/utils.o bin/title-screen.o bin/gameplay.o bin/ezmaze.o
	rgblink -o bin/ezmaze.gb bin/ezmaze.o bin/utils.o bin/title-screen.o bin/gameplay.o

assets/titlescreen.2bpp: src/assets/titlescreen.png
	rgbgfx -o assets/titlescreen.2bpp -O -u -T src/assets/titlescreen.png

assets/maze.2bpp: src/assets/maze.png
	rgbgfx -o assets/maze.2bpp -O -u -T src/assets/maze.png

assets/player.2bpp: src/assets/player.png
	rgbgfx -o assets/player.2bpp -u src/assets/player.png


WEB_ASSETS := index.html binjgb.js binjgb.wasm LICENSE.gbstudio simple.css simple.js
WEB_ASSET_TARGETS := $(addprefix bin/web/,$(WEB_ASSETS))

$(WEB_ASSET_TARGETS): /bin/web/%: src/assets/web/%
	mkdir -p bin/web/
	cp src/assets/web/$(notdir $@) $@

bin/web/ezmaze.gb: bin/ezmaze.gb $(WEB_ASSET_TARGETS)
	mkdir -p bin/web/
	cp $< $@
