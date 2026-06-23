#ifndef PLAYER_H
#define PLAYER_H

#include <graphics.h>

class Player
{
    private:
        int radius, x, y;

    public:
        Player();
        void spawnLocation();
        // void movePressSpace();
        // boolean hitTestBorder();
        // boolean hitTestShape();
        double areaPlayer();
        void draw() const;
        void undraw() const;
        void setRadius();
};

#endif
