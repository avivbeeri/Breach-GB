RGBDS_ASM=rgbasm
RGBDS_LNK=rgblink
RGBDS_FIX=rgbfix

BUILD_DIR=./build

INPUT_DIRS=breach
ROMS=./$(%=%.gb)

all: build_dir breach.gb

build_dir:
	  @mkdir -p $(BUILD_DIR)

breach.gb: breach.o
	$(RGBDS_LNK) -d -t -o $(BUILD_DIR)/breach.gb $(BUILD_DIR)/breach.o
	$(RGBDS_FIX) -v $(BUILD_DIR)/breach.gb

breach.o: 
	$(RGBDS_ASM) -i ./ -o $(BUILD_DIR)/breach.o main.asm

clean:
	  rm $(BUILD_DIR)/*.o $(BUILD_DIR)/*.gb
