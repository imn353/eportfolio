#include <iostream>
#include <cstring>
#include <iomanip>
#include <fstream>
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
	int inputWordLength;
	int inputCharLength;
	
	ifstream inFile("input2.txt");
	ofstream outFile("output2.txt");

	inFile.getline(input, MAX_SIZE); 
	
	for(inputCharLength = 0; inputLength < MAX_SIZE; inputCharLength++)
	{
		if(input[inputCharLength] == 0)
		{
			break;
		}
	}
	
	char keyword[] = "data";
	
	percentage = calculatekeyWordPercentage(input, inputCharLength, keyword);
	
	outFile << "Input :" << endl;
	outFile << input << endl;
	outFile << showpoint << fixed << setprecision(2);
	outFile << "Percentage of lines containing 'data' : " << percentage << "%";
	
	inFile.close();
	outFile.close();
	
	cout << "Return written to input.txt" << endl;
	
	return 0;
}
