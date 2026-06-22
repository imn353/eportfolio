#include <graphics.h>
#include <stdlib.h>
#include "game.hpp"
#include "../utils/random.hpp"
#include "../utils/align.hpp"
#include "../triangle/triangle.hpp"
#include "../shape/shape.hpp"

int width;
int height;
bool running;
int decide;

Game::Game(int _width, int _height) : width(_width), height(_height) {}
void Game::init()
{
    /*you may do all setups here*/
    player = new Player(50,0,0);
    timer = new Timer(5);

    int base = 100;
    int r = 50;
    int w = 100;
    int h = 100;
    int x = 0;
    srand(time(NULL));

    for (int i = 0 ; i < 6; i++)
    {
        int random = Random::between(0,3);
        int y = Random::within(200, 6*(height/8), h);

        switch (i)
        {
        case 0:
        case 3:
            x += 200;
            shapes[i] = new Triangle(x,y,base,h);
            break;

        case 1:
        case 5:
            x += 200;
            shapes[i] = new Rect(x,y,w,h);
            break;

        case 2:
        case 4:
            x += 200;
            shapes[i] = new Bomb(x,y,r);
            break;
        
        }  
    }
}

int Game::run(int width, int height)
{
    timer->start();
    running = true;

    srand(time(NULL));
    drawPlayer(width, height);
    drawShapes();

    while (running)
    {
    
        doKeyboardPress();
    }

    return decide;
}

void Game::doKeyboardPress()
{
    if (!kbhit())
        return;

    int key = getch();
    switch (key)
    {


    case 0:
        key = getch();
        break;

    case 27:
        running = false;
        return;

    case 'a' :
    case 'A' :
        for(int i = 0 ; i < 60 ; i++ )
		player->move(-1, 0);
		break;
        
    case 'd':
    case 'D':
		for(int i = 0 ; i < 60 ; i++ )
		player->move(1, 0);
		break;

    case 'w':
    case 'W':
        player->shoot();
        doHitTest(*player);
        break;
    }
}

void Game::doTimer()
{
    // clear device for every time out
    if (!timer)
        return;

    if (!timer->isTimeOut())
        return;

    cleardevice();
    timer->start();
}

void Game::end()
{
    setfillstyle(SOLID_FILL, RED);
    setbkcolor(RED);
    setcolor(YELLOW);
    int w = 1000;
    int h = 300;
    int x = Align::center(0, width, w);
    int y = Align::center(0, height, h);
    bar(x, y, x + w, y + h);
    settextstyle(DEFAULT_FONT, HORIZ_DIR, 10);
    char message[] = "Game Over!";
    int tw = textwidth(message);
    int th = textheight(message);

    int tx = Align::center(x, x + w, tw);
    int ty = Align::center(y, y + h, th);

    outtextxy(tx, ty, message);
}

void Game::win()
{
    setfillstyle(SOLID_FILL, BLUE);
    setbkcolor(BLUE);
    setcolor(YELLOW);
    int w = 1000;
    int h = 300;
    int x = Align::center(0, width, w);
    int y = Align::center(0, height, h);
    bar(x, y, x + w, y + h);
    settextstyle(DEFAULT_FONT, HORIZ_DIR, 10);
    char message[] = "Winner!";
    int tw = textwidth(message);
    int th = textheight(message);

    int tx = Align::center(x, x + w, tw);
    int ty = Align::center(y, y + h, th);

    outtextxy(tx, ty, message);
}

void Game::drawPlayer(int width, int height)
{
    player->spawnLocation(width, height);
    player->draw();
}

void Game::drawShapes()
{
    for (int i = 0 ; i < 6 ; i++)
    {
        shapes[i]->draw();
    }
}

void Game::doHitTest(Player &player)
{
    int xPlayer = player.getPlayerX();
    int yPlayer = player.getPlayerY();
    int rPlayer = player.getPlayerR();
    
    static int sum = 0;
    for(int i = 0 ; i < 6 ; i++)
    { 
        if (!shapes[i]) continue;
        if(!shapes[i]->getHit(xPlayer,yPlayer,rPlayer))
        {
            int num = shapes[i]->onHit();
            drawPlayer(width,height);
            shapes[i] = NULL;
            if (num == 0 )
            {
                decide = 0;
                running = false;
            }
            if (num == 1 )
            {
                sum = sum + 1;
            }
            break;
        }
    } 

    if (sum == 4)
    {
        decide = 1;
        running = false;
    }
    
}




