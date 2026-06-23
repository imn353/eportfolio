// Lab 2 - SECJ2013 - 23241 (Lab2.cpp)
// Group Members:
// 1. Iman Abadi Bin Mohd Nizwan A23CS0084
// 2. Muhammad Naim Bin Abdullah A23CS0134

#include <iostream>
#include <string>

using namespace std;

void printStar(int n){
    if (n > 1){
        printStar(n-1);
    }

    cout << "*";
}

void printNum(int n){

    if (n > 1){
        printNum(n-1);
    }

    cout << n << "-";
    printStar(n);
    cout << endl;   
}

int totalOdd(int list [], int n){
    int total = 0;

    if (n > 1){
        total += totalOdd(list, n-1);
    }
  
    if (list[n-1] % 2 != 0){
        cout << list[n-1] << " ";
        total += list[n-1];
    }
     
    return total;
}

// Main function
int main(int argc, char *argv[])
{
    printNum(6);

    cout << "\n\n";

    int num[6] = {0, 1, 2, 3, 4, 5};
    int result = totalOdd(num, 6);
    cout << "= " << result << endl;

    system("pause");

    return 0;
}

