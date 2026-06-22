#ifndef SHAPE_H
#define SHAPE_H
#include "../point/point.hpp"

class Shape
{
protected:
    Point position;

public:
    Shape(int _x, int _y);
    int getPositionX() const;
    int getPositionY() const;
    void setPosition(int x , int y);

    virtual void draw() const = 0;
    virtual void undraw() const = 0 ;
    virtual bool getHit(int cx, int cy, int r) const = 0 ;
    virtual int onHit() const = 0;
};

#endif