#include<iostream>
using namespace std;

int main() {
    // Read an integer number
    int num;
    cout << "Enter an integer number: ";
    cin >> num;

    // Initialize variables
    int product = 1;
    int digit;
    bool isMultipleOf4 = false, isMultipleOf5 = false, isMultipleOf7 = false;

    // Calculate the product of digits
    while (num != 0) {
        digit = num % 10;
        product *= digit;
        num /= 10;
    }

    // Check if the product is a multiple of 4, 5, and/or 7
    if (product % 4 == 0) {
        isMultipleOf4 = true;
    }
    if (product % 5 == 0) {
        isMultipleOf5 = true;
    }
    if (product % 7 == 0) {
        isMultipleOf7 = true;
    }

    // Display the product and whether it's a multiple of 4, 5, and/or 7
    cout << "Product of digits: " << product << endl;
    cout << "Is a multiple of 4: " << boolalpha << isMultipleOf4 << endl;
    cout << "Is a multiple of 5: " << boolalpha << isMultipleOf5 << endl;
    cout << "Is a multiple of 7: " << boolalpha << isMultipleOf7 << endl;

    return 0;
}
