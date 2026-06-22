#include <graphics.h>
#ifndef POINT_H
#define POINT_H

class Point
{
    protected:
        int x, y;

    public:
        Point(int _x , int _y);
        void setPoints(int _x, int _y);
        int getX() const;
        int getY() const;
};

#endif