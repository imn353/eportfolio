// Assignment 1 - SECJ2013 - 23241 (Assg1.cpp)
// Group Members:
// 1. Muhammad Naim Bin Abdullah A23CS0134
// 2. Iman Abadi Bin Mohd Nizwan A23CS0084
// 3. Muhammad Mukhritz Al Iman Bin Mohd Raffi A23CS0250 

#include <iostream>
#include <string>
#include <fstream>
#include "Student.h"

using namespace std;

// function headers
void listStudent(Student* [], int);
void sortName(Student* [], Student* [], int);
void sortGrade(Student* [], Student* [], int);

// main function
int main() {
    const int LIST_SIZE = 10;
    string name;
    int cw, fe, idx = 0;
    Student* studList[LIST_SIZE];
    Student* sortedName[LIST_SIZE];
    
    fstream fileIn("Marks.txt", ios::in);

    if (!fileIn) {
        cout << "File input/output error!\n";
        return 1;

    } else {
        while (fileIn >> name >> cw >> fe) {
            studList[idx] = new Student(name, cw, fe);
            idx++;
        }
        
        int opt = 0;

        while (opt != 4) {
            cout << "\n1. List results (original list)";
            cout << "\n2. List results (sort by name)";
            cout << "\n3. List results (sort by grade)";
            cout << "\n4. Exit\n\n";
            
            cout << "Enter your choice [1, 2, 3, 4]: ";
            cin >> opt;
            
            if (opt == 1) {
                listStudent(studList, idx);
            }

            if (opt == 2) {
                sortName(studList, sortedName, idx);
                listStudent(sortedName, idx);
            }

            if (opt == 3){
                sortGrade(studList, sortedName, idx);
            }
            
            if (opt != 4) system("pause");
        }

        fileIn.close();
    }

    return 0;
}


// function implementation
void listStudent(Student* sl[], int size) {
    for (int i = 0; i < size; i++) {
        sl[i]->printResult();
    }
}

// Swap function
void swap(Student *&a, Student *&b) {
    Student *temp = a;
    a = b;
    b = temp;
}

// Sort by name function
void sortName(Student* s1[], Student* s2[], int size){
    
    for (int i = 0 ; i < size ; i++)
    {
        s2[i] = s1[i];
    }
    bool sorted = false;

    for (int pass = 1; pass < size && !sorted; pass++) {
        sorted = true ;

        // compare adjacent items
        for (int x = 0; x < size - pass; x++) {

            if (s2[x]->getName() > s2[x+1]->getName()) {
                swap(s2[x], s2[x+1]);
                sorted = false;
            }
        }
    }
}

// Sort name then by grade function
void sortGrade(Student* s1[], Student* s2[], int size)
{
    sortName(s1, s2, size);
    bool sorted = false;

    for (int pass = 1; pass < size && !sorted; pass++) {
        sorted = true ;

        // compare adjacent items
        for (int x = 0; x < size - pass; x++) {

            if (s2[x]->getGrade() > s2[x+1]->getGrade() ) {
                swap(s2[x], s2[x+1]);
                sorted = false;
            }
        }
    }
    listStudent(s2, size);
}

