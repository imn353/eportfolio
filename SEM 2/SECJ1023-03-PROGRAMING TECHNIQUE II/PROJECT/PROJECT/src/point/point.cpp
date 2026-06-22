#include "point.hpp"

Point::Point(int _x = 0 , int _y = 0) : x(_x), y(_y){}

void Point::setPoints(int _x, int _y)
{
    x = _x;
    y = _y;
}

int Point::getX() const
{
    return x;
}

int Point::getY() const
{
    return y;
}
