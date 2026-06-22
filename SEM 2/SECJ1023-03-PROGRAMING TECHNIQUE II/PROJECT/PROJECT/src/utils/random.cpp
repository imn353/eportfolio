#include <ctime>
#include <cstdlib>

#include "random.hpp"

void Random::init() { srand(time(NULL)); }

int Random::random() { return rand(); }
int Random::between(int min, int max) { return min + (random() % (max - min + 1)); }
int Random::within(int min, int max, int length) { return between(min +length, max - length); }
bool Random::tossCoin() { return between(0, 100) > 50; }
