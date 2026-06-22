#include <graphics.h>

#include "../shape/shape.hpp"
#include "rect.hpp"

Rect::Rect(int _x, int _y, int _width, int _height) : width(_width), height(_height), Shape(_x,_y) {}

void Rect::draw() const
{
    setcolor(WHITE);
    rectangle(getPositionX(), getPositionY(), getPositionX() + width, getPositionY() + height);
    
}

void  Rect::undraw() const
{
    setcolor(BLACK);
    rectangle(getPositionX(), getPositionY(), getPositionX() + width, getPositionY() + height);
}



bool Rect::getHit(int cx, int cy, int r) const
{
    //nearest coordinate x and y to center of circle
    int nearX = cx - getPositionX();  //reperesent distance from circle center to nearest x at rectangle
    int nearY = cy - getPositionY();  //reperesent distance from circle center to nearest y at rectangle
    int nearSquared = nearX * nearX;
    int totalRadius = width + r;

    if (nearSquared <= (totalRadius * totalRadius))
    {
        return false;
    }
    else
    {
        return true;
    }

}

int Rect :: onHit() const
{
    undraw();
    return 1;
}