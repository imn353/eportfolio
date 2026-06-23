import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Activity {
  String name;
  String details;

  Activity({required this.name, required this.details});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Activity Recorder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ActivityPage(),
    );
  }
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  final List<Activity> activities = [];

  void addActivity() {
    final String name = nameController.text.trim();
    final String details = detailsController.text.trim();

    if (name.isEmpty || details.isEmpty) {
      showMessage('Please fill in all fields');
      return;
    }

    setState(() {
      activities.add(Activity(name: name, details: details));
    });

    clearFields();
    showMessage('Activity added successfully');
  }

  void clearFields() {
    nameController.clear();
    detailsController.clear();
  }

  void deleteActivity(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: const Text('Are you sure you want to delete this activity?'),
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
                  activities.removeAt(index);
                });
                Navigator.of(context).pop();
                showMessage('Activity deleted');
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
    detailsController.dispose();
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

  Widget buildActivityCard(Activity activity, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        title: Text(
          activity.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        subtitle: Text(activity.details),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => deleteActivity(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.assignment_rounded),
        ),
        title: const Text('Daily Activity Recorder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildTextField(
              controller: nameController,
              label: 'Activity',
              icon: Icons.article_rounded,
            ),
            buildTextField(
              controller: detailsController,
              label: 'Time/Category',
              icon: Icons.av_timer_outlined,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                addActivity();
              },
              child: const Text('+ Add Activity'),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ACTIVITIES (${activities.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: activities.isEmpty
                  ? const Center(
                      child: Text(
                        'No activities added yet',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        return buildActivityCard(activities[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
