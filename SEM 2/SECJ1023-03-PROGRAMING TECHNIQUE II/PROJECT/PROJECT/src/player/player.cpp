#include "player.hpp"
#include "../point/point.hpp"
#include <graphics.h>

Player::Player(int _radius , int x , int y): radius(_radius), position(x,y){}

void Player::spawnLocation(int width, int height)
{
    int _x = width/2;
    int _y = 7*(height/8);
    position.setPoints(_x,_y);
}

void Player::draw() const
{
    setcolor(YELLOW);
    circle(position.getX(),position.getY(),radius);
}

void Player::undraw() const
{
    setcolor(BLACK);
    circle(position.getX(),position.getY(),radius);
}

void Player::move(int dx, int dy)
{
    undraw();
    position.setPoints(position.getX() + dx, position.getY() + dy);
    draw();
    delay(0.5);
}

void Player::shoot()
{
    bool running = true;

    while (running)
    {
        move(0,-50);
        delay(50);
        if (position.getY() < 0) running = false;
    }
    undraw();
}

int Player::getPlayerX(){return position.getX();}
int Player::getPlayerY(){return position.getY();}
int Player::getPlayerR(){return radius;}
