#ifndef RANDOM_H
#define RANDOM_H

namespace Random
{
    void init();

    int random();
    int between(int min, int max);
    int within (int min, int max, int length = 0);
    bool tossCoin();

};

#endif
