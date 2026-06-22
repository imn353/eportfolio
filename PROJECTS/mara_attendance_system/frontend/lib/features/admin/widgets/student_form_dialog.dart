import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/firestore/firestore_models.dart';
import '../../../core/providers/class_management_provider.dart';

class StudentFormDialog extends ConsumerStatefulWidget {
  final StudentModel? initialStudent;
  final String classGroupId;

  const StudentFormDialog({
    super.key,
    this.initialStudent,
    required this.classGroupId,
  });

  static Future<void> show(BuildContext context,
      {StudentModel? initialStudent, required String classGroupId}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StudentFormDialog(
        initialStudent: initialStudent,
        classGroupId: classGroupId,
      ),
    );
  }

  @override
  ConsumerState<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends ConsumerState<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _matricCtrl;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialStudent?.fullName ?? '');
    _matricCtrl =
        TextEditingController(text: widget.initialStudent?.matricNo ?? '');
    _isActive = widget.initialStudent?.status != 'inactive';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _matricCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isNew = widget.initialStudent == null;
      final studentId =
          isNew ? const Uuid().v4() : widget.initialStudent!.studentId;

      final model = StudentModel(
        studentId: studentId,
        fullName: _nameCtrl.text.trim(),
        matricNo: _matricCtrl.text.trim().toUpperCase(),
        classGroupId: widget.classGroupId,
        status: _isActive ? 'active' : 'inactive',
      );

      await ref.read(classManagementServiceProvider).saveStudent(model);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew
                  ? 'Student added successfully.'
                  : 'Student updated successfully.',
            ),
            backgroundColor: const Color(0xFF0F766E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialStudent == null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isNew ? 'Add Student' : 'Edit Student',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Full Name', 'e.g. Ahmad bin Ali'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matricCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration('Matric Number', 'e.g. BMA2023001'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (!isNew)
                SwitchListTile(
                  title: const Text('Active Status'),
                  subtitle: const Text('Inactive students are hidden from new attendance lists.'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeTrackColor: const Color(0xFF0F766E),
                  contentPadding: EdgeInsets.zero,
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isNew ? 'Add Student' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
      ),
    );
  }
}
