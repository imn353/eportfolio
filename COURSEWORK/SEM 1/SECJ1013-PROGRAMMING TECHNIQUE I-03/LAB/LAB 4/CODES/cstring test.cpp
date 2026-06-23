#include <iostream>
#include <cstring>
using namespace std;

int main()
{
    // Take any two strings
    char s1[999];
    cout << "Enter the input (up to 999 character, end with an empty line) : " << endl;
	cin.getline(s1, 999);
    char s2[] = "data";
    char* p;
 
    // Find first occurrence of s2 in s1
    p = strstr(s1, s2);
 
    // Prints the result
   do 
   {
   		p = strstr(s1, s2);	
   		 if (p)
		{
        	cout << "String found" << endl << endl;
        	for (int i = 0; s1 != '\0'; i++)
        	{
        		s1[i] = p[i];
			}
    	}
    	
   		 else 
		{
        	continue;
    	}
   }while (s1 != 0);
   
   
    return 0;
}
