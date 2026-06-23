#include <iostream>
#include <vector>
using namespace std;

int main()
{
    int list[100];

    for (int i = 0; i < 100; i++)
    {
        int n = rand()%10;
        list[i] = n;
    }

    int count [10] = { };

    for (int n : list)
    {
        count[n]++ ;
    }

    for (int i = 0 ; i < 10 ; i++)
    {
        cout << count[i] << endl;
    }

    system("pause");
    return 0;
}


