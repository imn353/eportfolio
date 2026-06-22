#include <graphics.h>
#include <cmath>

#include "../shape/shape.hpp"
#include "triangle.hpp"

Triangle::Triangle(int _x, int _y, int _base, int _height) : base(_base), height(_height), Shape(_x, _y) {}

void Triangle::draw() const
{
    setcolor(WHITE);
    int points[] = {getPositionX(), getPositionY(), getPositionX() + base, getPositionY(), getPositionX() + base / 2, getPositionY() - height, getPositionX(), getPositionY()};
    drawpoly(4, points);
}
void Triangle::undraw() const
{
    setcolor(BLACK);
    int points[] = {getPositionX(), getPositionY(), getPositionX() + base, getPositionY(), getPositionX() + base / 2, getPositionY() - height, getPositionX(), getPositionY()};
    drawpoly(4, points);
}

bool Triangle::getHit(int cx, int cy, int r) const
{
    int nearX = cx - getPositionX();
    int nearY = cy - getPositionY();
    int nearSquared = nearX * nearX + nearY + nearY;
    int totalRadius = base + r;

    if (nearSquared <= (totalRadius * totalRadius))
    {
        return false;
    }
    else
    {
        return true;
    }
}

int Triangle :: onHit() const
{
    undraw();
    return 1;
}
