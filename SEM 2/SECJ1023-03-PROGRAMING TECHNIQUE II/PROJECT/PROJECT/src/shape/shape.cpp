#include "shape.hpp"
#include "../point/point.hpp"

Shape::Shape(int x, int y) : position(x, y) {}

int Shape ::  getPositionX() const
    {
        return position.getX();
    }

 int Shape :: getPositionY() const
    {
        return position.getY();
    }

 void Shape :: setPosition(int x , int y)
    {
        position.setPoints(x,y);
    }