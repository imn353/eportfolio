#include <iostream>
using namespace std;

int main()
{
	string member_1, member_2, matric_1, matric_2;
	
	// Inputing names and matric number //
	cout << " Enter member 1 name: ";
	getline (cin, member_1);
	cout << " Enter member 1 matric number: ";
	getline (cin, matric_1);
	cout << " Enter member 2 name: ";
	getline (cin, member_2);
	cout << " Enter member 2 matric number: ";
	getline (cin, matric_2);
	
	// Displaying the other information and inputed values //
	cout << "\n Assingment 1\n -----------------\n";
	cout << " Course: SECJ 1013 Programming Technique 1\n";
	cout << " Section: 03\n";
	cout << " Programme: Bachelor of Computer Science (Data Engineering)\n";
	cout << " Members :\n";
	cout << " " << member_1 << "(" << matric_1 << ")\n";
	cout << " " << member_2 << "(" << matric_2 << ")\n ";
	
	return 0;
}


