#include <iostream>
#include <string>

using namespace std;

// List class definition
class List {
    private:
        Student *head, *last;
        
    public:
        List() { 
            cout << "Create list...\n";
            head = NULL; last = NULL;
        }
        
        void insertNode(Student *newStud) {
        	cout << "Insert " << newStud->getName() << "\n";

            if (head == NULL || newStud->getName() < head->getName())
            {
                 newStud->setNext(head);
                 head = newStud;
                 if (last == NULL)
                 {
                   last = head; 
                 }
            }
            else 
            {
                Student *temp = head;
                while (temp->getNext() != NULL && newStud->getName() > temp->getNext()->getName())
                {
                    temp = temp->getNext();
                }
                newStud->setNext(temp->getNext());
                temp->setNext(newStud);
                if (newStud->getNext() == NULL)
                {
                    last = newStud;
                }
            }

        }
        
        Student *findNode(string name) {
           
            Student *temp = head;

            while (temp != NULL )
            {
                if (name == temp->getName())
                return temp;
                else
                temp = temp->getNext();
            }
            
            return NULL;
        }
        
        void deleteNode(string name) {
            Student *stud, *prev;
			stud = head;

            while (stud != NULL )
            {
                if (name == stud->getName())
                {
                    if (stud == head)
                    {
                        head = stud->getNext();
                    }
                    else if (stud == last)
                    {
                        prev->setNext(NULL);
                        last = prev;
                    }
                    else
                    {
                        prev->setNext(stud->getNext());
                    }
                    delete stud;
                    return;
                }
                else
                prev = stud;
                stud = stud->getNext();
            }
        }
        
        void displayList() {
        	Student *stud = head;
        	
        	while (stud != NULL) {
        		stud->printResult();
        		stud = stud->getNext();
			}
        }
        
        Student *getHead() { return head; }
        Student *getLast() { return last; }
        
        ~List() {
        	Student *stud = head;
        	cout << "Destroy list...\n";
        	while (stud != NULL) {
        		Student *prevStud = stud;
        		stud = stud->getNext();
        		delete prevStud;
			}
		}
};
