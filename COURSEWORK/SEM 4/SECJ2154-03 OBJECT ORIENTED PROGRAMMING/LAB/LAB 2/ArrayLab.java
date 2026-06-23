import java.util.*;


public class ArrayLab {

    // Question 1 double gpa[] = new double(4); // Line to fix
    double[] gpa = new double[4];
    // Question 2 int[] points = new int[] {90, 85, 88}; // Line to fix
    int[] points = new int[] {90, 85, 88};
    // Question 3 public static void printTotal(String title, int... values) { // Line to fix
    static void printTotal(int[] values, String title) { 
        // ...
    }

    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);

        // 1D array for student scores
        int[] scores = new int[5];
        for (int i = 0; i < scores.length; i++) {
            System.out.print("Enter score " + (i + 1) + ": ");
            scores[i] = input.nextInt();
        }

        // 2D array for marks of 3 students and 3 subjects
        int[][] marks = {
            {85, 78, 90},
            {88, 92, 79},
            {75, 80, 85}
        };

        // ArrayList of subjects
        ArrayList<String> subjects = new ArrayList<>();
        subjects.add("Math");
        subjects.add("Science");
        subjects.add("English");

        // Array of Student objects
        Student[] students = new Student[3];
        students[0] = new Student("Ali", 20);
        students[1] = new Student("Siti", 21);
        students[2] = new Student("Raj", 19);

        // Question 4 2D array named matrix declaration
        int[][] matrix = {
            {1, 2, 3},
            {4, 5, 6},
            {7, 8, 9}
        };

        // Question 5 ArryList names grades
        ArrayList<Double> grades = new ArrayList<>();
        grades.add(85.5);
        grades.add(76.0);
        grades.add(64.5);

        // Question 6 Print average of 10, 20, 30, 40 using anonymous array
        printAverage(new int[] {10, 20, 30, 40});

        // Question 7 Finding highest score
        findHighestScore(scores);

        // Question 8 Display all student names
        printStudentInfo(students);

        // Quetion 9 Display sum of marks
        sumSubjectMarks(marks);



        input.close();
    }

    public static void printAverage(int[] values) {
        int sum = 0;
        for (int v : values) {
            sum += v;
        }
        double average = (double) sum / values.length;
        System.out.println("Average of 10, 20, 30, 40: " + average);
    }

    static void findHighestScore(int[] marks) {
        int highest = marks[0];
        for (int mark : marks) {
            if (mark > highest) {
                highest = mark;
            }
        }
        System.out.println("Highest score: " + highest);
    }

    static void printStudentInfo(Student[] arr) {
        for (Student s : arr) {
            System.out.println("Student: " + s.getName() + ", Age: " + s.getAge());
        }
    }

    static void sumSubjectMarks(int[][] marks) {
        int sum = 0;
        for (int[] row : marks) {
            for (int mark : row) {
                sum += mark;
            }
        }
        System.out.println("The sum of marks: " + sum);;
    }

}

// Student class
class Student {
    private String name;
    private int age;

    public Student(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() { return name; }
    public int getAge() { return age; }
}
