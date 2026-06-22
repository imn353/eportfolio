#ifndef GAME_H
#define GAME_H

#include "timer.hpp"
#include "../player/player.hpp"
#include "../triangle/triangle.hpp"
#include "../shape/shape.hpp"
#include "../rectangle/rect.hpp"
#include "../bomb/bomb.hpp"

class Game
{
private:
    int width;
    int height;
    bool running;

    Timer* timer;
    Player* player;
    Triangle* triangle;
    Rect* rectangle;
    Bomb* bomb;
    Shape* shapes[6];

    void doDrawing() const;
    void drawPlayer(int width, int height);
    void drawShapes();
    
    void playerMove(int distance);

    void doKeyboardPress();
    void doMouseClick();
    void doHitTest(Player &player);

    void doTimer();

public:
    
    Game(int _width, int _height);
    void init();
    int run(int width, int height);
    void end();
    void win();
};

#endif