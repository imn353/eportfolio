import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Student {
  final String name;
  final String matricNo;
  final String course;
  final String email;
  final String gender;

  Student({
    required this.name,
    required this.matricNo,
    required this.course,
    required this.email,
    required this.gender,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Record App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StudentPage(),
    );
  }
}

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController matricController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  final List<Student> students = [];

  void addStudent() {
    final String name = nameController.text.trim();
    final String matricNo = matricController.text.trim();
    final String course = courseController.text.trim();
    final String email = emailController.text.trim();
    final String gender = genderController.text.trim();

    if (name.isEmpty ||
        matricNo.isEmpty ||
        course.isEmpty ||
        email.isEmpty ||
        gender.isEmpty) {
      showMessage('Please fill in all fields');
      return;
    }

    final bool isDuplicated = students.any((student) => student.matricNo == matricNo);
    
    if (isDuplicated) {
      showMessage('Matric number already exists');
      return;
    }

    setState(() {
      students.add(
        Student(
          name: name,
          matricNo: matricNo,
          course: course,
          email: email,
          gender: gender,
        ),
      );
    });

    clearFields();
    showMessage('Student added successfully');
  }

  void clearFields() {
    nameController.clear();
    matricController.clear();
    courseController.clear();
    emailController.clear();
    genderController.clear();
  }

  void deleteStudent(int index) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Student'),
          content: const Text('Are you sure you want to delete this student?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  students.removeAt(index);
                });
                Navigator.of(context).pop();
                showMessage('Student deleted');
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    nameController.dispose();
    matricController.dispose();
    courseController.dispose();
    super.dispose();
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget buildStudentCard(Student student, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(student.name),
        subtitle: Text(
          'Matric No: ${student.matricNo}\nCourse: ${student.course}\nEmail: ${student.email}\nGender: ${student.gender}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => deleteStudent(index),
        ),
      ),
    );
  }

  final List<String> genderOptions = <String>['Male', 'Female'];
  String selectedGender = 'Male';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Record App')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildTextField(
              controller: nameController,
              label: 'Student Name',
              icon: Icons.person,
            ),
            buildTextField(
              controller: matricController,
              label: 'Matric Number',
              icon: Icons.badge,
            ),
            buildTextField(
              controller: courseController,
              label: 'Course',
              icon: Icons.school,
            ),
            buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email,
            ),
            DropdownButtonFormField<String>(
              initialValue: selectedGender,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (String? newValue) {
                setState(() {
                  genderController.text = newValue!;
                });
              },
              items: genderOptions.map<DropdownMenuItem<String>>((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      addStudent();
                    },
                    child: const Text('Add Student'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: clearFields,
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Student List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: ${students.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: students.isEmpty
                  ? const Center(
                      child: Text(
                        'No students added yet',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        return buildStudentCard(students[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
