import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../widgets/student_card.dart';
import 'add_student_page.dart';
import 'edit_student_page.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final List<Student> students = [];
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  static const String studentsKey = 'students_list';

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    final List<String>? studentJsonList =
        await prefs.getStringList(studentsKey);

    if (studentJsonList != null) {
      setState(() {
        students.clear();
        students.addAll(
          studentJsonList.map((json) => Student.fromJson(json)).toList(),
        );
      });
    }
  }

  Future<void> saveStudents() async {
    final List<String> studentJsonList =
        students.map((student) => student.toJson()).toList();

    await prefs.setStringList(studentsKey, studentJsonList);
  }

  Future<void> goToAddStudentPage() async {
    final Student? newStudent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddStudentPage(),
      ),
    );

    if (newStudent != null) {
      setState(() {
        students.add(newStudent);
      });

      await saveStudents();
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

      await saveStudents();
      showMessage('Student updated successfully');
    }
  }

  Future<void> deleteStudent(int index) async {
    setState(() {
      students.removeAt(index);
    });

    await saveStudents();
    showMessage('Student deleted');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
      ),
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
                  Text(
                    'Total Students: ${students.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        return StudentCard(
                          student: students[index],
                          onEdit: () => goToEditStudentPage(index),
                          onDelete: () => deleteStudent(index),
                        );
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