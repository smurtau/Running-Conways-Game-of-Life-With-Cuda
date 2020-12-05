#include<stdio.h>
#include<stdlib.h>
#include<GL/gl.h>
#include<GL/glu.h>
#include<GL/glut.h>
#include<string.h>
#include <time.h>

int** board_state;
int height = 50;
int width = 50;

GLint window_w = 600;
GLint window_h = 600;

GLfloat left = 0.0;
GLfloat right = 1.0;
GLfloat bottom = 0.0;
GLfloat top = 1.0;

void initialize_board(){
    for (int i = 0; i < height; i++){
        for (int j = 0; j < width; j++){
            board_state[i][j] = rand()%2;
        }
    }
 }

 void update_board(){
    int new_state[height][width];
    for (int i = 0; i < height; i++){
        for (int j = 0; j < width; j++){
            int count = 0;
            if (i - 1 > 0 && i + 1 < height-1 && j - 1 > 0 && j + 1 < width-1){
                if (board_state[i-1][j-1] == 1) count++;
                if (board_state[i-1][j] == 1) count++;
                if (board_state[i-1][j+1] == 1) count++;
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i][j+1] == 1) count++;
                if (board_state[i+1][j-1] == 1) count++;
                if (board_state[i+1][j] == 1) count++;
                if (board_state[i+1][j+1]  == 1) count++;
            }
            else if (i == 0 && j == 0){
                if (board_state[i][j+1] == 1) count++;
                if (board_state[i+1][j+1] == 1) count++;
                if (board_state[i+1][j] == 1) count++;
            }
            else if (i == 0 && j == width-1){
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i+1][-1] == 1) count++;
                if (board_state[i+1][j+1] == 1) count++;
            }
            else if (i == height-1 && j == 0){
                if (board_state[i-1][j] == 1) count++;
                if (board_state[i-1][j+1] == 1) count++;
                if (board_state[i][j+1] == 1) count++;
            }
            else if (i == height-1 && j + 1 == width){
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i-1][j-1] == 1) count++;
                if (board_state[i-1][j] == 1) count++;
            }
            else if (i == 0){
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i][j+1] == 1) count++;
                if (board_state[i+1][j-1] == 1) count++;
                if (board_state[i+1][j] == 1) count++;
                if (board_state[i+1][j+1] == 1) count++;
            }
            else if (i == height-1) {
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i-1][j-1] == 1) count++;
                if (board_state[i-1][j] == 1) count++;
                if (board_state[i-1][j+1] == 1) count++;
                if (board_state[i][j+1] == 1) count++;
            }
            else if (j == 0) {
                if (board_state[i-1][j] == 1) count++;
                if (board_state[i-1][j+1]== 1) count++;
                if (board_state[i][j+1] == 1) count++;
                if (board_state[i+1][j] == 1) count++;
                if (board_state[i+1][j+1]== 1) count++;
            }
            else if (j == width-1) {
                if (board_state[i-1][j] == 1) count++;
                if (board_state[i-1][j-1] == 1) count++;
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i+1][j-1] == 1) count++;
                if (board_state[i+1][j] == 1) count++;
            }
            
            if (board_state[i][j] == 1 && count <= 1) new_state[i][j] = 0;
            else if (board_state[i][j] == 1 && count > 3) new_state[i][j] = 0;
            else if (board_state[i][j] == 0 && count == 3) new_state[i][j] = 1;
            else if (board_state[i][j] == 1 && (count == 2 || count == 3)) new_state[i][j] = 1;
        }
    }
    for (int i = 0; i < height; i++) memcpy(board_state[i], new_state[i],sizeof(int)*width);
}


void display(){
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();

    GLfloat xsize = (right - left) / width;

    GLfloat ysize = (top - bottom) / height;

    glBegin(GL_QUADS);
    for (GLint x = 0; x < width; x++){
        for (GLint y = 0; y < height; y++){
            if (board_state[x][y] == 1) glColor3f(0.0,0.0,0.0);
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
    update_board();
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

int main (int argc, char **argv) {
    board_state = malloc(sizeof(int*)*height);
    srand(time(NULL));
    for (int i = 0; i < height; i++) board_state[i] = malloc(sizeof(int)*width);
    initialize_board();

    glutInit(&argc,argv);
    glutInitWindowSize(window_w,window_h);
    glutCreateWindow("Life");
    glClearColor(1, 1, 1, 1);

    glutReshapeFunc(reshape);
    glutDisplayFunc(display);

    glutTimerFunc(1000,update,0);
    glutMainLoop();

    return 0;



}