#ifndef RECT_H
#define RECT_H

#include "../shape/shape.hpp"

class Rect: public Shape
{
protected:
    int width, height;

public:
    Rect(int _x = 0, int _y = 0, int _width = 0, int _height=0);
    void draw() const;
    void undraw() const;
    bool getHit(int cx, int cy, int r) const;
    int onHit() const ;
};

#endif