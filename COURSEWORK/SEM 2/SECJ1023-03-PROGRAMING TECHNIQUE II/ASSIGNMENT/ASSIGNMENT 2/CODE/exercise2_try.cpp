// ? EXERCISE 2: CLASS AND OBJECT MANIPULATIONS

/// Programming Technique II

// Member 1's Name: _____________
// Member 2's Name: _____________
//
// Section: ___
// Member 1's Name: _____________    Location: ____________ (i.e. where are you currently located)
// Member 2's Name: _____________    Location: ____________

// Log the time(s) your pair programming sessions
//  Date         Time (From)   To             Duration (in minutes)
//  _________    ___________   ___________    ________
//  _________    ___________   ___________    ________

// Video link:
//   _________

#include <iostream>
#include <string>
#include <iomanip>

using namespace std;

#define MAX_SUBJECT_COUNT 10

class Subject
{
private:
	string name;
	string code;
	int score;

public:
	Subject();
	int credit() const;
	string grade() const;
	double point(string) const;
	void print() const;
	friend int readUserInput(Subject subjects[]);
	void setName();
	bool operator<(const Subject &c) const
	{
		return score < c.score;
	}
	
};

void Subject::print() const
{	 

		cout << left << setw(15) << code;
		cout << left << setw(30) << name;
		cout << left << setw(10) << credit();
		cout << left << setw(10) << score;
		cout << left << setw(10) << grade();
		cout << left << setw(10) << point(grade());
		cout << left << setw(10) << point(grade())*credit();
		cout << endl;
}

Subject lower(const Subject &a, const Subject &b);

int main()
{
	Subject subjects[MAX_SUBJECT_COUNT];
	int point, count, pointTotal, creditTotal, gpa;
	string grade;

	count = readUserInput(subjects);

	cout << endl
		 << endl
		 << "THE RESULT"
		 << endl
		 << endl;

	// Print the output table header
	cout << left << setw(15) << "Subject Code";
	cout << left << setw(30) << "Subject Name";
	cout << left << setw(10) << "Credit";
	cout << left << setw(10) << "Score";
	cout << left << setw(10) << "Grade";
	cout << left << setw(10) << "Point";
	cout << left << setw(10) << "Sub Total";
	cout << endl
		 << endl;

	for (int j = 0; j < count; j++)
	{
		subjects[j].print();
		creditTotal += subjects[j].credit();
		pointTotal += subjects[j].point(subjects[j].grade())*subjects[j].credit();
	}

	cout << endl;
	cout << "TOTAL POINT  : " << pointTotal << endl;
	cout << "TOTAL CREDIT : " << creditTotal << endl;
	cout << "GPA          : " << setprecision(3) << pointTotal/creditTotal << endl;

	Subject lowestScore = subjects[0];
	for (int k = 0; k < count; k++)
	{
		lowestScore = lower(lowestScore, subjects[k]);
	}

	cout << endl;
	cout << "LOWEST SUBJECT : " << endl;
	lowestScore.print();
	cout << endl;

	system("pause");

	return 0;
}

// The definition of the default constructor is fully given
Subject::Subject() : name(""), code(""), score(0) {}

// The definition of the getter for the 'credit()' is fully given
int Subject::credit() const { return code[7] - '0'; }

// The definition of the getter for the 'grade()' is fully given
string Subject::grade() const
{
	if (score >= 90)
		return "A+";
	if (score >= 80)
		return "A";
	if (score >= 75)
		return "A-";
	if (score >= 70)
		return "B+";
	if (score >= 65)
		return "B";
	if (score >= 60)
		return "B-";
	if (score >= 55)
		return "C+";
	if (score >= 50)
		return "C";
	if (score >= 45)
		return "C-";
	if (score >= 40)
		return "D+";
	if (score >= 35)
		return "D";
	if (score >= 30)
		return "D-";
	return "E";
}

double Subject::point(string g) const
{
	if (g == "A+")
		return 4.00;
	else if (g == "A")
		return 4.00;
	else if (g == "A-") 
		return 3.67;
	else if (g == "B+") 
		return 3.33;
	else if (g == "B")
		return 3.00;
	else if (g == "B-")
		return 2.67;
	else if (g == "C+")
		return 2.33;
	else if (g == "C") 
		return 2.00;
	else if (g == "C-") 
		return 1.67;
	else if (g == "D+") 
		return 1.33;
	else if (g == "D")
		return 1.00;
	else if (g == "D-") 
		return 0.67;
	else
		return 0.00;
}

// Define a regular function that read a list of subjects from user input
int readUserInput(Subject subjects[])
{
	int count;

	cout << "How many subjects do you want to enter? => ";
	cin >> count; 

	for (int i = 0; i < count;i++)
	{
		cout << endl << "Enter info for subject #" << i+1 << endl;
		cout << "subject code => ";
		cin >> subjects[i].code;
		cin.ignore();

		cout << "subject name => ";
		getline(cin, subjects[i].name);
		cout << "subject score => ";
		cin >> subjects[i].score;
	}

	return count;
}

// Define a regular function that determines the lower subject.
Subject lower(const Subject &a, const Subject &b)
{
	if (a < b)
		return a;
	else;
		return b;
}