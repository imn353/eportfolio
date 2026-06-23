#include <iostream>
#include <iomanip>
#include <cmath>
using namespace std;

//Prototypes
void matrices();
double euclidean(int, int, int, int);

// Global Variables
int x_1 = 1, y_1 = 3, x_2 = 2, y_2 = 6, x_3 = 5, y_3 = 4;

int main()
{
	// Constructing the table
	cout << "\n";
	matrices();
	cout << "\n";
	
	// Distance AB
	double euclidean (int x_1, int x_2, int y_1, int y_2);
	cout << "\t" << "AB = " << euclidean(x_1, x_2, y_1, y_2) << "\n";
	
	// Distance AC
	double euclidean (int x_1, int x_3, int y_1, int y_3);
	cout << "\t" << "AC = " << euclidean(x_1, x_3, y_1, y_3) << "\n";
	
	// Distance BC
	double euclidean (int x_2, int x_3, int y_2, int y_3);
	cout << "\t" << "BC = " << euclidean(x_2, x_3, y_2, y_3) << "\n";
	
	return 0;
}
	
void matrices()
{
	int x [3] = {1, 2, 5};
	int y [3] = {3, 6, 4};
	char coordinate [3][3] = {"A", "B", "C"};
	
	for (int count = 0; count < 3; count++)
	{
		if (count == 0)
		{
			cout << "\t" << coordinate[count] << "(" << x[count] << "," << y[count] << ")";
		}
		else if (count == 2 )
		{
			cout << ", and " << coordinate[count] << "(" << x[count] << "," << y[count] << ")";
		}
		else
		{
			cout << ", " << coordinate[count] << "(" << x[count] << "," << y[count] << ")";
		}
	}
	
	cout << "\n";
	cout << "\n";
	
	cout << "\t" << " " << setw(9) << "x" << setw(9) << "y" << "\n";
	
	for (int count = 0; count < 3; count++)
	{
		cout << "\t" << coordinate[count] << setw(9) << x[count] << setw(9) << y[count] << "\n";
	}

}

double euclidean(int a, int b, int c, int d)
{	
	// Difference of both x and y
	int difference_x = a - b; 
	int difference_y = c - d; 
	
	// The square of the difference of x and y 
	int xpower2 = pow(difference_x,2);
	int ypower2 = pow(difference_y,2);
	
	// Square root of the sum of squares
	double distance = sqrt(xpower2 + ypower2);
	
	return distance;
}













