#include <ctime>
#include "timer.hpp"

Timer::Timer(double _duration) : duration(_duration){}
double Timer::getDuration() const { return duration; }
void Timer::setDuration(double value) { duration = value; }
bool Timer::isTimeOut() const { return elapse() >= duration;}

void Timer::start() { clock_start = clock(); }
double Timer::elapse() const { return double(clock() - clock_start) / CLOCKS_PER_SEC; }
