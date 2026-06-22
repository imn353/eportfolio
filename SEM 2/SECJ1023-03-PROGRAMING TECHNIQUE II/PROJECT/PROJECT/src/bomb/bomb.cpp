#include <graphics.h>
#include <cmath>

#include "../shape/shape.hpp"
#include "bomb.hpp"

Bomb::Bomb(int _x, int _y, int _radius): radius(_radius), Shape(_x,_y) {}

void Bomb::draw() const
{
   
    setcolor(WHITE);
    circle(getPositionX(), getPositionY(), radius);
}

void Bomb::undraw() const
{
    setcolor(BLACK);
    circle(getPositionX(), getPositionY(), radius);
}



bool Bomb::getHit(int cx, int cy, int r) const
{
    int nearX = cx - getPositionX();
    int nearY = cy - getPositionY();
    int nearSquared = nearX * nearX + nearY + nearY;
    int totalRadius = radius + r;

    if (nearSquared <= (totalRadius * totalRadius))
    {
        return false;
    }
    else
    {
        return true;
    }
}

int Bomb :: onHit() const
{
    undraw();
    return 0;
}