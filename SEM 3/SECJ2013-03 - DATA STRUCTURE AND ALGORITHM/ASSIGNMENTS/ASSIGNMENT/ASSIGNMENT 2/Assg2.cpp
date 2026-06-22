// Assignment 2 - SECJ2013 - 23241 (Assg2.cpp)
// Group Members:
// 1. Muhammad Naim Bin Abdullah
// 2. Muhammad Mukhritz Al Iman Bin Mohd Raffi
// 3. Iman Abadi Bin Mohd Nizwan

#include <iostream>
#include <string>
#include <fstream>
#include "Student.h"
#include "List.h"

using namespace std;

// main function
int main() {
    const int LIST_SIZE = 10;
    string name;
    string nameList[4] = {"Sarah", "Kevin", "Ahmed", "Cindy"};
    int cw, fe = 0;
	List studList;

    fstream fileIn("Marks.txt", ios::in);

    if (!fileIn) {
        cout << "File input/output error!\n";
        return 1;

    } else {
        while (fileIn >> name >> cw >> fe) {
            Student *stud = new Student(name, cw, fe);
            studList.insertNode(stud);
        }
        
        cout << "\nList all student:\n";
    	studList.displayList();
    	cout << "\n";
		
		// delete student where name stored inside the nameList array
		for (int i = 0; i < 4; i++) {
    		if (studList.findNode(nameList[i])) {
    		    cout << "Found and delete student: " << nameList[i] << "\n";
    		    studList.deleteNode(nameList[i]);
    		    
            } else {
                cout << "Can't found student with name " << nameList[i] << "\n";
            }
        }

        cout << "\nList all student:\n";
		studList.displayList();
		cout << "\n";
		
		cout << "First student: ";
        studList.getHead()->printResult();
		cout << "Last student: ";
        studList.getLast()->printResult();

        fileIn.close();
    }

    system("pause");
    return 0;
}

