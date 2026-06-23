import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Student {
  String name;
  String matricNo;
  String course;
  String gender;

  Student({
    required this.name,
    required this.matricNo,
    required this.course,
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
  final TextEditingController searchController = TextEditingController();

  final List<String> genderOptions = ['Male', 'Female'];
  String selectedGender = 'Male';

  final List<Student> students = [];
  String searchQuery = '';

  bool isEditing = false;
  int editingIndex = -1;

  void addOrUpdateStudent() {
    final String name = nameController.text.trim();
    final String matricNo = matricController.text.trim();
    final String course = courseController.text.trim();
    final String gender = selectedGender;

    if (name.isEmpty || matricNo.isEmpty || course.isEmpty) {
      showMessage('Please fill in all fields');
      return;
    }

    if (matricNo.length < 5) {
      showMessage('Matric number must be at least 5 characters');
      return;
    }

    if (RegExp(r'^[0-9]*$').hasMatch(course)) {
      showMessage('Course cannot contain any numbers');
      return;
    }

    final isDuplicated = students.any((student) {
      final isSameMatric = student.matricNo == matricNo;
      final isOtherStudent = isEditing ? students.indexOf(student) != editingIndex : true;
      return isSameMatric && isOtherStudent;
    });

    if (isDuplicated) {
      showMessage('Matric number already exists');
      return;
    }

    if (isEditing) {
      updateStudent(name, matricNo, course, gender);
    } else {
      addStudent(name, matricNo, course, gender);
    }
  }

  void addStudent(String name, String matricNo, String course, String gender) {
    setState(() {
      students.add(Student(
        name: name,
        matricNo: matricNo,
        course: course,
        gender: gender,
      ));
    });

    clearFields();
    showMessage('Student added successfully');
  }

  void editStudent(int index) {
    final Student student = students[index];

    setState(() {
      nameController.text = student.name;
      matricController.text = student.matricNo;
      courseController.text = student.course;
      selectedGender = student.gender;

      isEditing = true;
      editingIndex = index;
    });
  }

  void updateStudent(String name, String matricNo, String course, String gender) {
    if (editingIndex < 0 || editingIndex >= students.length) {
      showMessage('Invalid student selected');
      return;
    }

    setState(() {
      students[editingIndex].name = name;
      students[editingIndex].matricNo = matricNo;
      students[editingIndex].course = course;
      students[editingIndex].gender = gender;

      isEditing = false;
      editingIndex = -1;
    });

    clearFields();
    showMessage('Student updated successfully');
  }

  void cancelEdit() {
    setState(() {
      isEditing = false;
      editingIndex = -1;
    });

    clearFields();
  }

  void clearFields() {
    nameController.clear();
    matricController.clear();
    courseController.clear();
    selectedGender = 'Male';
  }

  List<Student> get filteredStudents {
    if (searchQuery.isEmpty) {
      return students;
    }

    final query = searchQuery.toLowerCase();
    return students.where((student) {
      return student.name.toLowerCase().contains(query) ||
          student.matricNo.toLowerCase().contains(query);
    }).toList();
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

                  if (isEditing && editingIndex == index) {
                    isEditing = false;
                    editingIndex = -1;
                    clearFields();
                  } else if (isEditing && editingIndex > index) {
                    editingIndex--;
                  }
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
    searchController.dispose();
    super.dispose();
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
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
          'Matric No: ${student.matricNo}\nCourse: ${student.course}\nGender: ${student.gender}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => editStudent(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteStudent(index),
            ),
          ],
        ),
      ),
    );
  }

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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person),
                ),
                items: genderOptions
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedGender = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: addOrUpdateStudent,
                    child: Text(isEditing ? 'Update Student' : 'Add Student'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isEditing ? cancelEdit : clearFields,
                    child: Text(isEditing ? 'Cancel Edit' : 'Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            buildTextField(
              controller: searchController,
              label: 'Search by name or matric no',
              icon: Icons.search,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Student List (${filteredStudents.length}/${students.length})',
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
                  : filteredStudents.isEmpty
                  ? const Center(
                      child: Text(
                        'No students match your search',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        final originalIndex = students.indexOf(student);
                        return buildStudentCard(student, originalIndex);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
