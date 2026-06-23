#include <graphics.h>

#include "shape.hpp"
#include "rect.hpp"

Rect::Rect(int _x, int _y, int _width, int _height) : width(_width), height(_height), Shape(_x,_y) {}

void Rect::draw() const
{
    setcolor(selected ? YELLOW : WHITE);
    rectangle(x,y, x + width, y + height);
}

void Rect::undraw() const
{
    setcolor(BLACK);
    rectangle(x,y, x + width, y + height);
}

void Rect::resize(double scale)
{
    undraw();
    width *= scale;
    height *= scale;
    draw();
}

bool Rect::isMouseClicked(int mx, int my) const
{
    if ((mx >= x && mx <= (x + width)) && (my >= y && my <= (y + height)))
        return true;
    else 
        return false;
}