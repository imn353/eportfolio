#ifndef TRIANGLE_H
#define TRIANGLE_H
#include "../shape/shape.hpp"

class Triangle : public Shape
{
protected:
    int base, height;

public:
    Triangle(int _x = 0, int _y = 0, int _base = 100, int _height = 100);
    void draw() const;
    void undraw() const;
    bool getHit(int cx, int cy, int radius) const;
    int onHit() const;
};

#endif
