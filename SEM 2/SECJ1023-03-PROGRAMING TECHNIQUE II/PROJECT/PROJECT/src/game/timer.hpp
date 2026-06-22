#ifndef TIMER_H
#define TIMER_H

#include<ctime>

class Timer
{
private:
    double duration;
    clock_t clock_start;
public:
    Timer(double duration=1);
    void start();
    double elapse()const;
    
    double getDuration() const;
    void setDuration(double value);
    bool isTimeOut() const;
};

#endif