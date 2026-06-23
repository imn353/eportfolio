// IMAN ABADI BIN MOHD NIZWAN (A23CS0084)
// AHMAD ADIB BIN A.MAZLAM (A23CS0205) 

#include <iostream>
using namespace std;

int main()
{
	string food [3] = {"Pizza","Burger","Sandwich"};
	int price [3] = {10,5,7};
	int num;
	
	cout << "Welcome to the Food Ordering System" << endl;
	
	for (int count = 0; count <= 2; count++)
	{
		cout << (count + 1) << ".  " << food[count] << " - $" << price[count] << endl; 
	}
	
	cout << "Enter the number of the item you want to order: ";
	cin >> num;
	
	switch (num) 
	{
		case 1:
			cout << "Your total bill is $" << price[0];
			break;
		case 2:
			cout << "Your total bill is $" << price[1];
			break;
		default:
			cout << "Your total bill is $" << price[2];
			break;
	}
	
	return 0;
}
