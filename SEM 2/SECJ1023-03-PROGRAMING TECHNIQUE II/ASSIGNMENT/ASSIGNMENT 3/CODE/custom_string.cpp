// Programming Technique II

//? EXERCISE 3: STRING MANIPULATIONS
//? file: custom_string.cpp

//!----------------------------------------------------------------------------------------
//! This is the only file that you will need to modify in this exercise.
//! Also, you will submit only this file.
//! This file is the implementation for the class CustomString.
//!----------------------------------------------------------------------------------------


// Member 1's Name: IMAN ABADI BIN MOHD NIZWAN
// Member 2's Name: AHMAD ADIB ZIKRI BIN A.MAZLAM

// Video Link:
// https://drive.google.com/drive/folders/1buH_94WPttb3HyS97E6p45tPEtcqWcg6?usp=sharing


#include <iostream>
#include <string>
using namespace std;

#include "custom_string.hpp"

//?----------------------------------------------------------------------------------------
//? The following methods are fully given: a constructor, getData() and setData()
//?----------------------------------------------------------------------------------------

CustomString::CustomString(const string &_data) : data(_data) {}
string CustomString::getData() const { return data; }
void CustomString::setData(const string &_data) { data = _data; }

//! Task 1: Complete the implementation of the following mutator methods:
//!        (a) pushFront()
//!        (b) pushBack()
//!        (c) pop()
//!        (d) popFront()
//!        (e) popBack()

void CustomString::pushFront(const string &s)
{
    data.insert(0, s);
}

void CustomString::pushBack(const string &s)
{
    data.insert(data.length(), s);
}

string CustomString::pop(int index, int count)
{
    string substring;
    substring = data.substr(index, count);
    data.erase(index, count);
    return substring;
}

string CustomString::popFront(int count)
{
    string substring;
    substring = data.substr(0, count);
    data.erase(0, count);
    return substring;
}

string CustomString::popBack(int count)
{
    string substring;
    substring = data.substr(data.length() - count);
    data.erase(data.length() - count);
    return substring;
}

//! Task 2: Complete the implementation of the following overloaded operators:
//!        (a) operator !
//!        (b) operator *

CustomString CustomString::operator!() const
{
    string _data;
    _data = string(data.rbegin(), data.rend());
    return CustomString (_data);
}

CustomString CustomString::operator*(int count) const
{
    string duplicate = data;
    for (int i=1; i<count; i++)
    {
        duplicate += data;
    }
    return CustomString (duplicate);
}

//! Task 3: Complete the implementation of the following conversion methods:
//!        (a) toDouble()
//!        (b) toUpper()

double CustomString::toDouble() const
{

    return stod(data);
}

CustomString CustomString::toUpper() const
{
    string upperCase;
    for (char c : data)
    {
       upperCase += toupper(c);
    }
    return CustomString(upperCase);
  
}