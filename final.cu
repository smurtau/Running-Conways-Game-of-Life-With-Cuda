#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>

#include "cuda.h"
#include "cuda_gl_interop.h"

#define BOARD_DIM 6
#define NUM_BLOCK 1
#define NUM_THREAD BOARD_DIM*BOARD_DIM

PFNGLBINDBUFFERARBPROC glBindBuffer = NULL;
PFNGLDELETEBUFFERSARBPROC glDeleteBuffers = NULL;
PFNGLGENBUFFERSARBPROC glGenBuffers = NULL;
PFNGLBUFFERDATAARBPROC glBufferData = NULL;

GLuint bufferObj;
cudaGraphicsResource *resource;

GLint FPS = 24;
GLint window_w = 600;
GLint window_h = 600;

GLfloat left = 0.0;
GLfloat right = 1.0;
GLfloat bottom = 0.0;
GLfloat top = 1.0;
GLint game_w = BOARD_DIM;
GLint game_h = BOARD_DIM;

int board_dim1, board_dim2;
int *old_board, *new_board;
int *d_old_board, *d_new_board;

__device__ int check_up_left(int *board, int width, int position)
{
	if (board[position - width - 1] == 1) return 1;
	else return 0;
}

__device__ int check_up(int *board, int width, int position)
{
	if (board[position - width] == 1) return 1;
	else return 0;
}

__device__ int check_up_right(int *board, int width, int position)
{
	if (board[position - width + 1] == 1) return 1;
	else return 0;
}

__device__ int check_left(int *board, int width, int position)
{
	if (board[position - 1] == 1) return 1;
	else return 0;
}

__device__ int check_right(int *board, int width, int position)
{
	if (board[position + 1] == 1) return 1;
	else return 0;
}

__device__ int check_down_left(int *board, int width, int position)
{
	if (board[position + width - 1] == 1) return 1;
	else return 0;
}

__device__ int check_down(int *board, int width, int position)
{
	if (board[position + width] == 1) return 1;
	else return 0;
}

__device__ int check_down_right(int *board, int width, int position)
{
	if (board[position + width + 1] == 1) return 1;
	else return 0;
}

__global__ void update_board(int board_dimh, int board_dimw, int *o_board, int *n_board)
{
	int glb_id = blockIdx.x*blockDim.x + threadIdx.x;
	int num_alive;

	num_alive = 0;
	if (glb_id < board_dimh*board_dimw)
	{
		// look at the 8 neighboring squares
		if (glb_id == 0)                                                   // top-left corner
		{
			num_alive += check_right(o_board, board_dimw, glb_id);
			num_alive += check_down(o_board, board_dimw, glb_id);
			num_alive += check_down_right(o_board, board_dimw, glb_id);
		}
		else if (glb_id == board_dimw - 1)                                 // top-right corner
		{
			num_alive += check_left(o_board, board_dimw, glb_id);
			num_alive += check_down_left(o_board, board_dimw, glb_id);
			num_alive += check_down(o_board, board_dimw, glb_id);
		}
		else if (glb_id == board_dimw * (board_dimh - 1))                  // bottom-left corner
		{
			num_alive += check_up(o_board, board_dimw, glb_id);
			num_alive += check_up_right(o_board, board_dimw, glb_id);
			num_alive += check_right(o_board, board_dimw, glb_id);
		}
		else if (glb_id == board_dimw * board_dimh - 1)                    // bottom-right corner
		{
			num_alive += check_up_left(o_board, board_dimw, glb_id);
			num_alive += check_up(o_board, board_dimw, glb_id);
			num_alive += check_left(o_board, board_dimw, glb_id);
		}
		else if (glb_id < board_dimw)                                      // top row
		{
			num_alive += check_left(o_board, board_dimw, glb_id);
			num_alive += check_right(o_board, board_dimw, glb_id);
			num_alive += check_down_left(o_board, board_dimw, glb_id);
			num_alive += check_down(o_board, board_dimw, glb_id);
			num_alive += check_down_right(o_board, board_dimw, glb_id);
		}
		else if (glb_id > board_dimw * board_dimh - board_dimw - 1)        // bottom row
		{
			num_alive += check_up_left(o_board, board_dimw, glb_id);
			num_alive += check_up(o_board, board_dimw, glb_id);
			num_alive += check_up_right(o_board, board_dimw, glb_id);
			num_alive += check_left(o_board, board_dimw, glb_id);
			num_alive += check_right(o_board, board_dimw, glb_id);
		}
		else if (glb_id % board_dimw == 0)                                 // left column
		{
			num_alive += check_up(o_board, board_dimw, glb_id);
			num_alive += check_up_right(o_board, board_dimw, glb_id);
			num_alive += check_right(o_board, board_dimw, glb_id);
			num_alive += check_down(o_board, board_dimw, glb_id);
			num_alive += check_down_right(o_board, board_dimw, glb_id);
		}
		else if ((glb_id + 1) % board_dimw == 0)                           // right column
		{
			num_alive += check_up_left(o_board, board_dimw, glb_id);
			num_alive += check_up(o_board, board_dimw, glb_id);
			num_alive += check_left(o_board, board_dimw, glb_id);
			num_alive += check_down_left(o_board, board_dimw, glb_id);
			num_alive += check_down(o_board, board_dimw, glb_id);
		}
		else
		{
			num_alive += check_up_left(o_board, board_dimw, glb_id);
			num_alive += check_up(o_board, board_dimw, glb_id);
			num_alive += check_up_right(o_board, board_dimw, glb_id);
			num_alive += check_left(o_board, board_dimw, glb_id);
			num_alive += check_right(o_board, board_dimw, glb_id);
			num_alive += check_down_left(o_board, board_dimw, glb_id);
			num_alive += check_down(o_board, board_dimw, glb_id);
			num_alive += check_down_right(o_board, board_dimw, glb_id);
		}

		// check what happens to this square
		if (o_board[glb_id] == 1)                                        // cell alive
		{
			if (num_alive == 2 || num_alive == 3)                      // cell stays alive
				n_board[glb_id] = 1;
			else                                                       // cell dies
				n_board[glb_id] = 0;
		}
		else                                                               // cell dead
		{
			if (num_alive == 3)                                        // cell becomes alive
				n_board[glb_id] = 1;
			else                                                       // cell stays dead
				n_board[glb_id] = 0;
		}

		/*int offset = glb_id;//x + y * blockDim.x * gridDim.x;
		ptr[offset].x = n_board[glb_id] * 255;
		ptr[offset].y = n_board[glb_id] * 255;
		ptr[offset].z = n_board[glb_id] * 255;
		ptr[offset].w = 255;*/
	}
}

void display(){
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();

    GLfloat xsize = (right - left) / game_w;

    GLfloat ysize = (top - bottom) / game_h;

    glBegin(GL_QUADS);
    for (GLint x = 0; x < game_w; x++){
        for (GLint y = 0; y < game_h; y++){
            if (new_board[x*game_w + y] == 1) glColor3f(0.0,0.0,0.0);
            else glColor3f(1.0,1.0,1.0);

            glVertex2f(x*xsize+left, y*ysize+bottom);
            glVertex2f((x+1)*xsize+left, y*ysize+bottom);
            glVertex2f((x+1)*xsize+left,(y+1)*ysize+bottom);
            glVertex2f(x*xsize+left,(y+1)*ysize+bottom);
        }
    }
    glEnd();

    glFlush();
    glutSwapBuffers();
}

void update(int value) {
    //update_board(board_state,width,height);
    	cudaMemcpy(d_old_board, old_board, board_dim1*board_dim2*sizeof(int), cudaMemcpyHostToDevice);

	update_board<<<NUM_BLOCK, NUM_THREAD>>>(board_dim1, board_dim2, d_old_board, d_new_board);
 	glutPostRedisplay();

	cudaMemcpy(new_board, d_new_board, board_dim1*board_dim2*sizeof(int), cudaMemcpyDeviceToHost);
	memcpy(old_board, new_board, board_dim1*board_dim2*sizeof(int));

    	glutTimerFunc(1000/FPS,update,0);
}

void reshape(int width, int height){
    window_w = width;
    window_h = height;

    glViewport(0,0,window_w,window_h);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluOrtho2D(left, right, bottom, top);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    glutPostRedisplay();
}

//==========================================================
int main(int argc, char **argv)
{
	srand(time(NULL));

  
/*	cudaDeviceProp prop;
	int dev;

	memset(&prop, 0, sizeof(cudaDeviceProp));
	prop.major = 1;
	prop.minor = 0;
	cudaChooseDevice(&dev, &prop);
*/
        glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA);
        glutInitWindowSize(window_w,window_h);
     	glutCreateWindow("Life");
    	glClearColor(1, 1, 1, 1);

/*	glBindBuffer    = (PFNGLBINDBUFFERARBPROC)GET_PROC_ADDRESS("glBindBuffer");
    	glDeleteBuffers = (PFNGLDELETEBUFFERSARBPROC)GET_PROC_ADDRESS("glDeleteBuffers");
    	glGenBuffers    = (PFNGLGENBUFFERSARBPROC)GET_PROC_ADDRESS("glGenBuffers");
    	glBufferData    = (PFNGLBUFFERDATAARBPROC)GET_PROC_ADDRESS("glBufferData");	

	glGenBuffers(1, &bufferObj);
	glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, bufferObj);
	glBufferData(GL_PIXEL_UNPACK_BUFFER_ARB, window_w*window_h, NULL, GL_DYNAMIC_DRAW_ARB);

	cudaGraphicsGLRegisterBuffer(&resource, bufferObj, cudaGraphicsMapFlagsNone);

	cudaGraphicsMapResources(1, &resource, NULL);
	
	uchar4 *devPtr;
	size_t size;
	cudaGraphicsResourceGetMappedPointer((void **)&devPtr, &size, resource);
*/
	// host variables
	board_dim1 = BOARD_DIM;
	board_dim2 = board_dim1;
	old_board = (int *)calloc(board_dim1*board_dim2, sizeof(int));
	new_board = (int *)calloc(board_dim1*board_dim2, sizeof(int));

	// initialize board
	for (int i = 0; i < board_dim1*board_dim2; i++)
	{
		old_board[i] = rand() % 2;
	}

	// setup device memory
	cudaMalloc((void **)&d_old_board, board_dim1*board_dim2*sizeof(int));
	cudaMalloc((void **)&d_new_board, board_dim1*board_dim2*sizeof(int));
	
	cudaMemcpy(d_old_board, old_board, board_dim1*board_dim2*sizeof(int), cudaMemcpyHostToDevice);


	cudaMemcpy(new_board, d_new_board, board_dim1*board_dim2*sizeof(int), cudaMemcpyDeviceToHost);

	// replace the old board with the new board
	memcpy(old_board, new_board, board_dim1*board_dim2*sizeof(int));
	
    	glutReshapeFunc(reshape);
    	glutDisplayFunc(display);
    	glutMainLoop();

	return 0;
}



