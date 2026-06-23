import 'package:flutter/material.dart';
import '../models/lecturer.dart';

class AddLecturerPage extends StatefulWidget {
  const AddLecturerPage({super.key});

  @override
  State<AddLecturerPage> createState() => _AddLecturerPageState();
}

class _AddLecturerPageState extends State<AddLecturerPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lecturerIdController = TextEditingController();

  void saveLecturer() {
    final String name = nameController.text.trim();
    final String lecturerId = lecturerIdController.text.trim();

    if (name.isEmpty || lecturerId.isEmpty) {
      showMessage('Please fill in all fields');
      return;
    }

    final Lecturer newLecturer = Lecturer(name: name, lecturerId: lecturerId);

    Navigator.pop(context, newLecturer);
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
    lecturerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Lecturer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildTextField(
              controller: nameController,
              label: 'Lecturer Name',
              icon: Icons.person,
            ),
            buildTextField(
              controller: lecturerIdController,
              label: 'Lecturer ID',
              icon: Icons.badge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveLecturer,
                child: const Text('Save Lecturer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
