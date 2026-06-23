//? EXERCISE 4: ASSOCIATION

// Programming Technique II

// Member 1's Name: _____________
// Member 2's Name: _____________

// Log the time(s) your pair programming sessions
//  Date         Time (From)   To             Duration (in minutes)
//  _________    ___________   ___________    ________
//  _________    ___________   ___________    ________

// Video link:
//   _________


#include <iostream>
#include <cmath>
using namespace std;

const int size = 10;

class Term
{
private:
    int coef;
    int exp;

public:
    Term(int c = 0, int e = 0);
    void set(int c, int e);
    int evaluate(int x) const;
    int exponent() const;
    int coefficient() const;
};

class Polynomial
{
private:
    int numTerms;
    Term terms[size];
public:
    Polynomial();
    void input();
    int evaluate(int x) const;
};

//----------------------------------------------------------------------------

int main()
{
    Polynomial equation;

    equation.input();
    cout << endl;

    cout << " x  \t\tPolynomial value" << endl;
    cout << "----\t\t----------------" << endl;

    for (int x = 0; x <= 5; x++)
        cout << x << "  \t\t" << equation.evaluate(x) << endl;

    cout << endl;

    system("pause");
    return 0;
}

//----------------------------------------------------------------------------
// class Term

// The constructor is given

Term::Term(int c, int e) : coef(c), exp(e) {}

// Implement the other methods
void Term::set(int c, int e) {coef = c; exp = e;}
int Term::exponent() const {return exp;}
int Term::coefficient() const {return coef;}
int Term::evaluate(int x) const {return coef*pow(x,exp);}
//----------------------------------------------------------------------------

// class Polynomial

// Implement the constructor and the other methods of the class Polynomial
Polynomial::Polynomial(){numTerms = 0;}

void Polynomial::input()
{
    cout << "Enter a polynomial:" << endl;
    cout << "\t How many terms? => ";
    cin >> numTerms;

    int c, e;

    for (int i = 0; i < numTerms; i++)
    {
        cout << "\tEnter term #" << i+1 << " (coef and exp) => ";
        cin >> c >> e;

        terms[i].set(c,e);
    }
}

int Polynomial::evaluate(int x) const
{
    int sum = 0;
    
    for (int i = 0; i < numTerms; i++)
    {
        sum += terms[i].evaluate(x);
    }

    return sum;
}
