#ifndef CIRCLE_H
#define CIRCLE_H

#include "../shape/shape.hpp"

class Bomb: public Shape
{
protected:
    int radius;

public:
    Bomb(int _x = 0, int _y = 0, int _radius = 0);
    void draw() const;
	void undraw() const;
    bool getHit(int cx, int cy, int r) const;
    int onHit() const;
};

#endif