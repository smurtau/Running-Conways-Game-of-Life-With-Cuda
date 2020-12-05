#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>

/*#include "cuda.h"
#include "cuda_gl_interop.h"*/

#define BOARD_DIM 1000
#define NUM_BLOCK 5
#define NUM_THREAD 256

GLint window_w = 1000;
GLint window_h = 1000;

GLfloat left = 0.0;
GLfloat right = 1.0;
GLfloat bottom = 0.0;
GLfloat top = 1.0;
GLint game_w = BOARD_DIM;
GLint game_h = BOARD_DIM;

int board_dim1, board_dim2;
int *old_board, *new_board;
int *d_old_board, *d_new_board;
int N;

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

__global__ void update_board(int board_dimh, int board_dimw, int *o_board, int *n_board, int nblock)
{
	int gbl_id = blockIdx.x * blockDim.x + threadIdx.x;
	int num_squares = board_dimh*board_dimw;
	int num_alive;
	int stride = nblock * blockDim.x;

	for (int i = gbl_id; i < num_squares; i += stride)
	{
		num_alive = 0;
		//if (i < num_squares)
		//{
			//look at the 8 neighboring squares
			if (i == 0)                                                   // top-left corner
			{
				num_alive += check_right(o_board, board_dimw, i);
				num_alive += check_down(o_board, board_dimw, i);
				num_alive += check_down_right(o_board, board_dimw, i);
			}
			else if (i == board_dimw - 1)                                 // top-right corner
			{
				num_alive += check_left(o_board, board_dimw, i);
				num_alive += check_down_left(o_board, board_dimw, i);
				num_alive += check_down(o_board, board_dimw, i);
			}
			else if (i == board_dimw * (board_dimh - 1))                  // bottom-left corner
			{
				num_alive += check_up(o_board, board_dimw, i);
				num_alive += check_up_right(o_board, board_dimw, i);
				num_alive += check_right(o_board, board_dimw, i);
			}
			else if (i == board_dimw * board_dimh - 1)                    // bottom-right corner
			{
				num_alive += check_up_left(o_board, board_dimw, i);
				num_alive += check_up(o_board, board_dimw, i);
				num_alive += check_left(o_board, board_dimw, i);
			}
			else if (i < board_dimw)                                      // top row
			{
				num_alive += check_left(o_board, board_dimw, i);
				num_alive += check_right(o_board, board_dimw, i);
				num_alive += check_down_left(o_board, board_dimw, i);
				num_alive += check_down(o_board, board_dimw, i);
				num_alive += check_down_right(o_board, board_dimw, i);
			}
			else if (i > board_dimw * board_dimh - board_dimw - 1)        // bottom row
			{
				num_alive += check_up_left(o_board, board_dimw, i);
				num_alive += check_up(o_board, board_dimw, i);
				num_alive += check_up_right(o_board, board_dimw, i);
				num_alive += check_left(o_board, board_dimw, i);
				num_alive += check_right(o_board, board_dimw, i);
			}
			else if (i % board_dimw == 0)                                 // left column
			{
				num_alive += check_up(o_board, board_dimw, i);
				num_alive += check_up_right(o_board, board_dimw, i);
				num_alive += check_right(o_board, board_dimw, i);
				num_alive += check_down(o_board, board_dimw, i);
				num_alive += check_down_right(o_board, board_dimw, i);
			}
			else if ((i + 1) % board_dimw == 0)                           // right column
			{
				num_alive += check_up_left(o_board, board_dimw, i);
				num_alive += check_up(o_board, board_dimw, i);
				num_alive += check_left(o_board, board_dimw, i);
				num_alive += check_down_left(o_board, board_dimw, i);
				num_alive += check_down(o_board, board_dimw, i);
			}
			else
			{
				num_alive += check_up_left(o_board, board_dimw, i);
				num_alive += check_up(o_board, board_dimw, i);
				num_alive += check_up_right(o_board, board_dimw, i);
				num_alive += check_left(o_board, board_dimw, i);
				num_alive += check_right(o_board, board_dimw, i);
				num_alive += check_down_left(o_board, board_dimw, i);
				num_alive += check_down(o_board, board_dimw, i);
				num_alive += check_down_right(o_board, board_dimw, i);
			}

			//check what happens to this square
			if (o_board[i] == 1)                                        // cell alive
			{
				if (num_alive == 2 || num_alive == 3)                      // cell stays alive
					n_board[i] = 1;
				else                                                       // cell dies
					n_board[i] = 0;
			}
			else                                                               // cell dead
			{
				if (num_alive == 3)                                        // cell becomes alive
					n_board[i] = 1;
				else                                                       // cell stays dead
					n_board[i] = 0;
			}
		//}
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
            if (old_board[y*game_w + x] == 1) glColor3f(0.0,0.0,0.0);
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
		cudaMemcpy(d_old_board, old_board, board_dim1*board_dim2*sizeof(int), cudaMemcpyHostToDevice);

		update_board<<<NUM_BLOCK, NUM_THREAD>>>(board_dim1, board_dim2, d_old_board, d_new_board, N);
		cudaMemcpy(new_board, d_new_board, board_dim1*board_dim2*sizeof(int), cudaMemcpyDeviceToHost);
		cudaDeviceSynchronize();

		memcpy(old_board, new_board, board_dim1*board_dim2*sizeof(int));

		glutPostRedisplay();
    	glutTimerFunc(1000,update,0);
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

        glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA);
        glutInitWindowSize(window_w,window_h);
     	glutCreateWindow("Life");
		 glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    	glClearColor(1, 1, 1, 1);

	// host variables
	board_dim1 = BOARD_DIM;
	board_dim2 = board_dim1;
	old_board = (int *)calloc(board_dim1*board_dim2, sizeof(int));
	new_board = (int *)calloc(board_dim1*board_dim2, sizeof(int));
	N = NUM_BLOCK;

	// initialize board
	for (int i = 0; i < board_dim1*board_dim2; i++)
	{
		old_board[i] = rand() % 2;
	}

	// setup device memory
	cudaMalloc((void **)&d_old_board, board_dim1*board_dim2*sizeof(int));
	cudaMalloc((void **)&d_new_board, board_dim1*board_dim2*sizeof(int));

	cudaSetDeviceFlags(cudaDeviceScheduleBlockingSync);

	glutTimerFunc(1000, update, 0);
	glutReshapeFunc(reshape);
	glutDisplayFunc(display);
	glutMainLoop();

	return 0;
}



