/* 
Iman Abadi Bin Mohd Nizwan (A23CS0084) 
Ahmad Adib Bin A.Mazlam (A23CS0205)
Section 03
Dr Nies Hui Wen
*/
#include <iostream>
#include <limits>
using namespace std;

const int MAX_OPERATIONS = 100;
int operands1[MAX_OPERATIONS] = {};
int results[MAX_OPERATIONS] = {};

void displayMainMenu();
void performMultiplication(int &);
int multiplyUsingAddition(int , int);
void displayResults(int &);

int main()
{
	int operationCount = 0;
	int choice;
	
	do
	{
		displayMainMenu();
		cout << "Enter your choice: ";
		while (true)
		{
			cin >> choice ;
		    if (!cin)
		    {
		      cout << "Please the the number according to the function displayed in the menu. Enter again " << endl;
		      cin.clear();
		      cin.ignore(numeric_limits<streamsize>::max(), '\n');
		      continue;
		    }
		    else break;
		}	
		
		cout << endl;
		
		switch (choice)
		{
			case 1:
				performMultiplication(operationCount);
				break;
			case 2:
				displayResults(operationCount);
                break;
            case 3:
                cout << "Goodbye!" << endl;
                break;		
		}		  
	}while (choice != 3);
	return 0;
}

void displayMainMenu()
{
	cout << "<<<<<Main Menu>>>>>" << endl;
	cout << "=============================" << endl;
	cout << "1. Perform Multiplication" << endl;
	cout << "2. Display Results" << endl;
	cout << "3. Quit" << endl;
}

void performMultiplication(int &operationCount)
{
	int operandNum = 0;
	int Operand = 0;
	int initialOperand = 1;
	int result = 1;
	
	cout << "Enter the number of operands for multiplication: ";
	cin >> operandNum;
	
	while (operandNum < 2)
	{
		cout << "Please enter number of operands that is at least 2: ";
		cin >> operandNum;
	}
	
	for (int i = 0; i < operandNum; i++)
	{
		cout << "Enter operand " << i+1 << ": ";
		cin >> Operand;

		initialOperand = multiplyUsingAddition(initialOperand, Operand);  
	}
	
	operands1[operationCount] = operandNum;
	results[operationCount] = initialOperand;
	operationCount++;
	cout << "\nMultiplication performed successfully!" << endl;
	cout << endl;
}

int multiplyUsingAddition(int a, int b)
{	

	int result = 0;
	
	for (int i = 0; i < b; i++)
	{
		result += a;
	}
	
	return result;
}

void displayResults(int &operationCount)
{
	cout << "Results of Mathematical Operations: " << endl;
	cout << "========================================" << endl;
	for (int i = 0; i < operationCount; i++)
	{
		cout << "Operation 1: " << results[i] << " (Operands: " << operands1[i] << ")" << endl;
	}
	
	cout << endl;
	cout << endl;
}



