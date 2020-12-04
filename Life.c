#include<stdio.h>
#include<stdlib.h>

int** update_board(int** board_state, int width, int height){
    int **new_state[height][width];
    for (int i = 0; i < height; i++){
        for (int j = 0; j < width; j++){
            int count = 0;
            if (i - 1 > 0 && i + 1 < height && j - 1 > 0 && j + 1 < width){
                if (board_state[i-1][j-1] == 1) count++;
                if (board_state[i-1][j] == 1) count++;
                if (board_state[i-1][j+1] == 1) count++;
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i][j+1] == 1) count++;
                if (board_state[i+1][j-1] == 1) count++;
                if (board_state[i+1][j] == 1) count++;
                if (board_state[i+1][j+1]  == 1) count++;
            }
            else if (i - 1 < 0 && j - 1 < 0){
                if (board_state[i][j+1] == 1) count++;
                if (board_state[i+1][j+1] == 1) count++;
                if (board_state[i+1][j] == 1) count++;
            }
            else if (i - 1 < 0 && j + 1 > width){
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i+1][-1] == 1) count++;
                if (board_state[i+1][j+1] == 1) count++;
            }
            else if (i + 1 > height && j - 1 < 0){
                if (board_state[i-1][j] == 1) count++;
                if (board_state[i-1][j+1] == 1) count++;
                if (board_state[i][j+1] == 1) count++;
            }
            else if (i + 1 > height && j + 1 > width){
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i-1][j-1] == 1) count++;
                if (board_state[i-1][j] == 1) count++;
            }
            else if (i - 1 <  0){
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i][j+1] == 1) count++;
                if (board_state[i+1][j-1] == 1) count++;
                if (board_state[i+1][j] == 1) count++;
                if (board_state[i+1][j+1] == 1) count++;
            }
            else if (i + 1 > height) {
                if (board_state[i][j-1] == 1) count++;
                if (board_state[i-1][j-1] == 1) count++;
                if (board_state[i-1][j] == 1) count++;
                if (board_state[i-1][j+1] == 1) count++;
                if (board_state[i][j+1] == 1) count++;
            }
            else if (j - 1 < 0) {
                if (board_state[i-1][j] == 1) count++;
                if (board_state[i-1][j+1]== 1) count++;
                if (board_state[i][j+1] == 1) count++;
                if (board_state[i+1][j] == 1) count++;
                if (board_state[i+1][j+1]== 1) count++;
            }
            else if (j + 1 > width) {
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
    return new_state;
}

int main (void) {
    int width, height;
    //width = 5;
    //height = 5;
    int board_state [5][5] = {
                              {1,1,0,1,1},
                              {1,0,0,1,0},
                              {1,1,1,0,1},
                              {1,1,1,1,1},
                              {0,0,1,1,0}
                            };



}