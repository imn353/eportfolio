#include "Player.hpp"
#include <iostream>
#include <graphics.h>

Player::Player() : x(0), y(0), radius(20){}

Player::spawnLocation()
{
    int x = getmaxwidth()/2;
    int y = (getmaxheight()/4)*3;
}

void Player::draw()
{
    setcolor(YELLOW);
    circle(x,y,radius);
}

void Player::undraw()
{
    setcolor(BLACK);
    circle(x,y,radius)
}

double Player:: 

