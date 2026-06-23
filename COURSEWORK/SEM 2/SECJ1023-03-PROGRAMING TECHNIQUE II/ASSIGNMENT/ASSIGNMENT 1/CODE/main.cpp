// ? EXERCISE 1: INTRODUCTION TO CLASSES AND OBJECTS

// Programming Technique II

// Member 1's Name: Ahmad Adib Zikri bin A.Mazlam
// Member 2's Name: Iman Abadi bin Mohd Nizwan
//
// Section: 03
// Member 1's Name: Ahmad Adib Zikri bin A.Mazlam    Location: Terengganu (Home)
// Member 2's Name: Iman Abadi bin Mohd Nizwan   Location: Johor Bahru (Home)

// Log the time(s) your pair programming sessions
//  Date         Time (From)   To             Duration (in minutes)
//  14/4/2024	 5.50		   6.30			  40 
//  14/4/2024    11.20 		   11.50		  30
//	14/4/2024    11.50         12.20		  30
//	15/4/2024	 12.20         12.30		  10
//	15/4/2024	 1.22          1.30			  8

// Video link:
// https://drive.google.com/drive/folders/1NAlsD4DjUNkl97uejYQyjPUg4uN-CbRE?usp=sharing



#include <iostream>
#include <string>

using namespace std;

class Student{
	private:
		string name, code;
		int score;

	public:
	
		Student(){
            	name = "/0"; 
				code = "/0";
            	score = 0;
		}

		Student(string a, string b, int c)
		{
			name = a;
			code = b;
			score = c;
		}

		string getCode(){
			return code;
		}

		string getName(){
			return name;
		}

		int getScore(){
			return score;
		}
		
		void setName(string Name){
			name = Name;
		}
		
		void setCode(string Code){
			code = Code;
		}

		void setScore(int Score){
			score = Score;
		}

		string Grade(int);
		
		double Point(string);

		int Pointer(int point, int creditH){
			return point*creditH;
		}

};

string Student::Grade(int score){
	if (score>100 || score<0){
		return"Invalid input";

	}
	if (score<=100 || score>=90){
		return "A+";
	}else if (score<=89 || score>=80){
		return "A";
	}else if (score<=79 || score>=75){
		return "A-";
	}else if (score<=74 || score>=70){
		return "B+";
	}else if (score<=69 || score>=65){
		return "B";
	}else if (score<=64 || score>=60){
		return "B-";
	}else if (score<=59 || score>=55){
		return "C+";
	}else if (score<=54 || score>=50){
		return "C";
	}else if (score<=49 || score>=45){
		return "C-";
	}else if (score<=44 || score>=40){
		return "D+";
	}else if (score<=39 || score>=35){
		return "D";
	}else if (score<=34 || score>=30){
		return "D-";
	}else{
		return"E";
	}
}

double Student::Point(string grade){
	if (grade=="A+" || grade=="A"){
		return 4.00;
	}else if (grade=="A-"){
		return 3.67;
	}else if (grade=="B+"){
		return 3.33;
	}else if (grade=="B"){
		return 3.00;
	}else if (grade=="B-"){
		return 2.67;
	}else if (grade=="C+"){
		return 2.33;
	}else if (grade=="C"){
		return 2.00;
	}else if (grade=="C-"){
		return 1.67;
	}else if (grade=="D+"){
		return 1.33;
	}else if (grade=="D"){
		return 1.00;
	}else if (grade=="D-"){
		return 0.67;
	}else {
		return 0.00;
	}
}



int main()
{

	Student a;
	string name, code, grade;
	int score, creditH;
	double point;

	cout << "Enter the following data: " << endl;
	cout << "  Subject name => ";
	getline(cin, name);
	a.setName(name);

	cout << endl;

	cout << "  Subject code => ";
	getline(cin, code);
	a.setCode(code);

	cout << endl;

	cout << "  Score earned => ";
	cin >> score;
	a.setScore(score);
	

	cout << endl
		 << endl;

	cout << "THE RESULT" << endl
		 << endl;

	cout << "Subject Code : " << a.getCode() << endl;
	cout << "Subject Name : " << a.getName() << endl;
	cout << "Credit Hour  : ";
	cin >> creditH;
	cout << "Score Earned : " << a.getScore() << endl;
	grade =  a.Grade(score);
	cout << "Grade Earned : " << grade << endl;
	point = a.Point(grade);
	cout << "Grade Point  : " << point << endl;
	cout << "Point Earned : " << a.Pointer(point, creditH)<<endl;
	cout << endl;

	

	system("pause");
	cin.ignore();

	return 0;
}
