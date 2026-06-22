#include <graphics.h>
#ifndef PLAYER_H
#define PLAYER_H

#include "../point/point.hpp"

class Point;

class Player
{
    private:
        Point position;
        int radius;

    public:
        Player(int _radius , int x , int y);
        void spawnLocation(int width, int height);
        void draw() const;
        void undraw() const;
        void move(int dx, int dy);
        void shoot();
        int getPlayerX();
        int getPlayerY();
        int getPlayerR();
};

#endif