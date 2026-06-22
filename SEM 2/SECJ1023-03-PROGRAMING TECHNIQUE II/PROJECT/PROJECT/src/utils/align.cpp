#include "align.hpp"

int Align::center(int min, int max, int length) { return (min + max - length) / 2; }

bool Align::between(int min, int max, int value) { return (min <= value) && (value <= max); }

double Align::max(int a, int b) { return (a > b) ? a : b; }
double Align::min(int a, int b) { return (a < b) ? a : b; }
