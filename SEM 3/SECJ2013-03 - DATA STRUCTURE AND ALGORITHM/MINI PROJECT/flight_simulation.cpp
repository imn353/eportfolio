// Project
// Group members (name & matric no.):
// 1. ???
// 2. ???
// 3. ???
// 4. ???

#include <iostream>
#include <string>

using namespace std;
const int size_queue = 5;

// Flight class definition and implementation. /////////////////////////////////

class Flight {
    public:
        string id;
        int fuel;
        int passenger;
        string status;

        Flight(void);
        Flight(string, int, int, string);
        void printInfo(void);
        void updateFuel(void);
        void landing(void);

        ~Flight() {
            cout << "Destroy " << id << " flight\n";
        }
};

Flight::Flight(void) {

}

Flight::Flight(string i, int f, int p, string s) {
    id = i;
    fuel = f;
    passenger = p;
    status = s;
}

void Flight::printInfo(void) {
     cout << id << " [" << fuel << ", " << passenger << ", " << status << "]\n";
}

void Flight::updateFuel(void) {
    if (fuel > 0) {
        fuel--;
    } else {
        status = "Crash";
    }
}

void Flight::landing(void) {
    if (fuel > 0) {
        if (status == "Flying") {
            status = "Change altitude";

        } else if (status == "Change altitude") {
            status = "Change direction";

        } else if (status == "Change direction") {
            status = "Landing";
        }

    } else {
        status = "Crash";
    }
}

// Queue class definition and implementation.///////////////////////////////////
class Queue {
    private:
    	int front;
    	int rear;
    	Flight* items[size_queue];

    public:
        Queue(void);
    	void enQueue(Flight*);
    	Flight* deQueue(void);
    	bool isFull(void);
    	bool isEmpty(void);

};

Queue::Queue(void) {
    front = 0;
    rear = -1;
}

void Queue::enQueue(Flight* f) {
	if (!isFull()) {
        rear++;
	    items[rear] = f;
    } 
    else {
    	cout << "Queue is full...\n\n";
    }
}

Flight* Queue::deQueue(void) {
	if (!isEmpty()) {
	    Flight* f = items[front];
	    front++;

	    return f;
   } 
   else {
   	    cout << "Queue is empty...\n";
   	    return NULL;
   }
}

bool Queue::isFull(void) {
	if (rear == (size_queue - 1)) {
	    return true;
    }
	return false;
}

bool Queue::isEmpty(void) {
	if (front > rear) {
		return true;
	}
	return false;
}

// End of class definitions and implementations ////////////////////////////////

// Function to print the info of all flights that have arrive at the airport
void arrivingFlightInfo(int f_arv[], Flight* f[], int size) {
    cout << "Arriving flights info.:\n";
    for (int i = 0; i < size; i++) {
        if (f_arv[i] > -1) {
            string f_status = f[f_arv[i]]->status;

            if (f_status != "Landing" && f_status != "Crash") {
                f[f_arv[i]]->updateFuel();
            }

            f[f_arv[i]]->printInfo();
        }
    }
    cout << endl;
}

// Main function
int main(int argc, char *argv[]) {
    const int size_arrive = 10;
    const int size_incoming = 17;

	Queue q;

    Flight* f[size_arrive] = {new Flight("MH123", 13, 100, "Flying"),
                              new Flight("FR320", 10, 120, "Flying"),
                              new Flight("SG078", 18, 120, "Flying"),
                              new Flight("FR747",  8, 250, "Flying"),
                              new Flight("MH118", 14, 150, "Flying"),
                              new Flight("AS103", 13, 200, "Flying"),
                              new Flight("FR240", 24, 100, "Flying"),
                              new Flight("MH308", 20, 150, "Flying"),
                              new Flight("SG090", 11, 220, "Flying"),
                              new Flight("AS303", 15, 120, "Flying")};

    int f_incoming[size_incoming] = { 0, -1, 1, 2, -1, -1,  3, 4, -1, -1, 5, -1, 6, 7, -1, 8, 9};

    int f_arrive[size_arrive] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};

    // Start simulation
    char c;
    int i = 0, cycle = 1;
    bool stop = false;
    Flight* f2land = NULL;

    while (!stop) {
        
        cout << "\nSIMULATION CYCLE: " << cycle << "\n";
        cout << "---------------------\n";
        cycle++;
        
        // Process incoming flight info.
        if (i < size_incoming) {
            if (f_incoming[i] == -1) {
                cout << "No incoming flight...\n\n";
            } else {
                cout << f[f_incoming[i]]->id << " flight " <<  " is coming...\n\n";
                f_arrive[f_incoming[i]] = f_incoming[i];

                cout << "Try to en-queue " << f[f_incoming[i]]->id << " flight...\n\n";
                q.enQueue(f[f_incoming[i]]);
            }
        }

        // Try to de-queue and landing flight from the queue.
        if (f2land == NULL) {
            if (!q.isEmpty()) {
                f2land = q.deQueue();
                cout << "De-queue " << f2land->id << " flight...\n\n";
            }
        }

        if (f2land != NULL) {
            string f_status = f2land->status;

            if (f_status == "Flying" ||
                f_status == "Change altitude" ||
                f_status == "Change direction") {
                f2land->landing();

            } else { // The flight may be safely landed or crashed.

                if (f_status == "Landing") {
                    cout << "Good news, " << f2land->passenger << " passengers are safely landed :-)\n\n";
                } else {
                    cout << "Soo sad, " << f2land->passenger << " passengers are dead :-(\n\n";
                }

                // Set f2land back to NULL so can do the q.deQueue() again
                // in the next cycle
                f2land = NULL;
            }
        }

        arrivingFlightInfo(f_arrive, f, size_arrive);

        cout << "Press 'c' to continue and 's' to stop: ";
        cin >> c;
        i++;

        if (c == 's') {
            stop = true;
        }
    }

    // Analyze simulation result.
    int crash = 0;
    int comfort = 0;
    int critical = 0;
    int alive = 0;
    int dead = 0;

    for (int i = 0; i < size_arrive; i++) {
	    if (f[i]->status == "Landing") {
            alive += f[i]->passenger;

			if (f[i]->fuel > 3) {
	            comfort++;
		    } else {
		        critical++;
		    }
	    } else {
	        crash++;
	        dead += f[i]->passenger;
	    }
	}

    cout << endl;
	cout << "Simulation result & statistic:\n\n";
	cout << "           Crash: " << crash << endl;
	cout << " Comfort landing: " << comfort << endl;
	cout << "Critical landing: " << critical << "\n\n";
	cout << " Passenger alive: " << alive << endl;
	cout << "  Passenger dead: " << dead << endl;
	
	system("PAUSE");

    for (int i = 0; i < size_arrive; i++) {
        delete f[i];
    }

    system("pause");
    return 0;
}
