import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Student {
  String name;
  String matricNo;
  String course;
  String email;
  String phoneNo;
  String gender;

  Student({
    required this.name,
    required this.matricNo,
    required this.course,
    required this.email,
    required this.phoneNo,
    required this.gender,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student CRUD App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StudentListPage(),
    );
  }
}

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final List<Student> students = [];
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  List<Student> get filteredStudents {
    if (searchQuery.isEmpty) return students;

    return students.where((student) {
      final query = searchQuery.toLowerCase();
      return student.name.toLowerCase().contains(query) ||
          student.matricNo.toLowerCase().contains(query) ||
          student.course.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query) ||
          student.phoneNo.toLowerCase().contains(query) ||
          student.gender.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> goToAddStudentPage() async {
    final Student? newStudent = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStudentPage()),
    );

    if (newStudent != null) {
      setState(() {
        students.add(newStudent);
      });

      showMessage('Student added successfully');
    }
  }

  Future<void> goToEditStudentPage(int index) async {
    final Student student = students[index];

    final Student? updatedStudent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStudentPage(student: student),
      ),
    );

    if (updatedStudent != null) {
      setState(() {
        students[index] = updatedStudent;
      });

      showMessage('Student updated successfully');
    }
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildStudentCard(Student student, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(student.name),
        subtitle: Text(
          'Matric No: ${student.matricNo}\nCourse: ${student.course}\nEmail: ${student.email}\nPhone: ${student.phoneNo}\nGender: ${student.gender}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => goToEditStudentPage(index),
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
      appBar: AppBar(title: const Text('Student List')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: students.isEmpty
            ? const Center(
                child: Text(
                  'No students added yet',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Search students',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  searchQuery = '';
                                  searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total Students: ${filteredStudents.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  filteredStudents.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Text(
                              'No students match "$searchQuery"',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              final Student student = filteredStudents[index];
                              final int originalIndex = students.indexOf(
                                student,
                              );
                              return buildStudentCard(student, originalIndex);
                            },
                          ),
                        ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToAddStudentPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController matricController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  List<String> genderOptions = ['Male', 'Female'];
  String selectedGender = 'Male';

  void saveStudent() {
    final String name = nameController.text.trim();
    final String matricNo = matricController.text.trim();
    final String course = courseController.text.trim();
    final String email = emailController.text.trim();
    final String phoneNo = phoneController.text.trim();
    final String gender = selectedGender;

    if (name.isEmpty ||
        matricNo.isEmpty ||
        course.isEmpty ||
        email.isEmpty ||
        phoneNo.isEmpty) {
      showMessage('Please fill in all fields');
      return;
    }

    bool onlyNo = RegExp(r'^[0-9]+$').hasMatch(phoneNo);

    if (!onlyNo) {
      showMessage("Phone numbers cannot contain letters");
      return;
    }

    final Student newStudent = Student(
      name: name,
      matricNo: matricNo,
      course: course,
      email: email,
      phoneNo: phoneNo,
      gender: gender,
    );

    Navigator.pop(context, newStudent);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  void dispose() {
    nameController.dispose();
    matricController.dispose();
    courseController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
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
              icon: Icons.mail,
            ),
            buildTextField(
              controller: phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
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
                    .map(
                      (gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)),
                    )
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveStudent,
                child: const Text('Save Student'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditStudentPage extends StatefulWidget {
  final Student student;

  const EditStudentPage({super.key, required this.student});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  late TextEditingController nameController;
  late TextEditingController matricController;
  late TextEditingController courseController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  List<String> genderOptions = ['Male', 'Female'];
  late String selectedGender;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.student.name);
    matricController = TextEditingController(text: widget.student.matricNo);
    courseController = TextEditingController(text: widget.student.course);
    emailController = TextEditingController(text: widget.student.email);
    phoneController = TextEditingController(text: widget.student.phoneNo);
    selectedGender = genderOptions.contains(widget.student.gender)
        ? widget.student.gender
        : genderOptions.first;
  }

  void updateStudent() {
    final String name = nameController.text.trim();
    final String matricNo = matricController.text.trim();
    final String course = courseController.text.trim();
    final String email = emailController.text.trim();
    final String phoneNo = phoneController.text.trim();
    final String gender = selectedGender;

    if (name.isEmpty ||
        matricNo.isEmpty ||
        course.isEmpty ||
        email.isEmpty ||
        phoneNo.isEmpty) {
      showMessage('Please fill in all fields');
      return;
    }

    bool onlyNo = RegExp(r'^[0-9]+$').hasMatch(phoneNo);

    if (!onlyNo) {
      showMessage("Phone numbers cannot contain letters");
      return;
    }

    final Student updatedStudent = Student(
      name: name,
      matricNo: matricNo,
      course: course,
      email: email,
      phoneNo: phoneNo,
      gender: gender,
    );

    Navigator.pop(context, updatedStudent);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  void dispose() {
    nameController.dispose();
    matricController.dispose();
    courseController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Student')),
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
              icon: Icons.mail,
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
                    .map(
                      (gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)),
                    )
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateStudent,
                child: const Text('Update Student'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
