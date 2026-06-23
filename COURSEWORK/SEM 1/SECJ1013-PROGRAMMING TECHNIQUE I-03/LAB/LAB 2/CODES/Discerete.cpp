#include <iostream>
using namespace std;

int main()
{
	int a;
	int function;
	
	for (a = 1 ; a <= 14 ; a++)
	{
		function = (3*a) - a;
		if (function == 0)
		{
			cout << a << "\t" << function;
		}
		else
		{
			cout << "Function does not exists\n";
		}
	
	}		
	return 0;
}


