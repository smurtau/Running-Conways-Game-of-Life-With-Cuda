There are two code files: to compile Life.c (Life on the CPU):

gcc Life.c -o Life -lGl -lGLU -lglut

Then to execute the CPU version:

./Life

to compile final.cu (Life on the GPU):

nvcc final.cu -o Final -lGl -lGLU -lglut

Then to execute the GPU version:

./Final

To modify parameters of the game:
For the CPU (Life.c):
height - the number of cells in one dimension of the game grid
width - the number of cells in the other dimension of the game grid
window_w - the width of the display window
window_h - the height of the display window

For the GPU (final.cu):
BOARD_DIM - the game of life board will be a square grid with dimensions BOARD_DIMxBOARD_DIM
NUM_BLOCKS - the number of blocks the CUDA kernel will launch
NUM_THREAD - the number of threads on each block
WIN_W - the width of the display window
WIN_H - the height of the display window

After running the execution commands, an openGL window will appear that you can
watch the game being played in.
