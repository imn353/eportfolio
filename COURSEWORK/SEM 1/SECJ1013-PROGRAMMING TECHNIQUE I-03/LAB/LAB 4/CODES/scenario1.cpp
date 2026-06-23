#include <iostream>
#include <cstring>
#include <iomanip>
using namespace std;

double calculatekeyWordPercentage (char input[], int lengthChar, char keyword[])
{
	int inputWordLength;
	double percentage;
	double numKeyword = 0;
	
	for (int i = 0; i < lengthChar; i++)
	{
		if( i == 0 || input[i] == ' ')
		{
			inputWordLength++;
		}
	}
	
	for(int j = 0; j < lengthChar; j++)
	{
		if (strstr((input + j), keyword) == (input + j))
		{
			numKeyword++;
		}
		
		keyword[0] = toupper(keyword[0]);		
	
		if (strstr((input + j), keyword) == (input + j))
		{
			numKeyword++;
		}
		
		keyword[0] = tolower(keyword[0]);	
	}
	
	percentage = (numKeyword/inputWordLength)*100;
	
	return percentage;
}

int main()
{
	const int MAX_SIZE = 999;
	int inputLength;
	char input[MAX_SIZE];
	double percentage;
	int inputCharLength;
	
	cout << "Enter the input (up to 999 character, end with an empty line) : " << endl;
	cin.getline(input, MAX_SIZE); 
	
	for(inputCharLength = 0; inputLength < MAX_SIZE; inputCharLength++)
	{
		if(input[inputCharLength] == 0)
		{
			break;
		}
	}
	
	char keyword[] = "data";
	
	percentage = calculatekeyWordPercentage(input, inputCharLength, keyword);
	
	cout << "Input :" << endl;
	cout << input << endl;
	cout << showpoint << fixed << setprecision(2);
	cout << "Percentage of lines containing 'data' : " << percentage << "%";
	
	return 0;
}
