import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/firestore/firestore_models.dart';
import '../../../core/providers/class_management_provider.dart';

class ClassFormDialog extends ConsumerStatefulWidget {
  final ClassGroupModel? initialClass;

  const ClassFormDialog({super.key, this.initialClass});

  static Future<void> show(BuildContext context, {ClassGroupModel? initialClass}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ClassFormDialog(initialClass: initialClass),
    );
  }

  @override
  ConsumerState<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends ConsumerState<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _programCtrl;
  late final TextEditingController _intakeCtrl;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialClass?.name ?? '');
    _programCtrl =
        TextEditingController(text: widget.initialClass?.programName ?? '');
    _intakeCtrl = TextEditingController(text: widget.initialClass?.intake ?? '');
    _isActive = widget.initialClass?.status != 'inactive';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _programCtrl.dispose();
    _intakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isNew = widget.initialClass == null;
      final classGroupId =
          isNew ? const Uuid().v4() : widget.initialClass!.classGroupId;

      final model = ClassGroupModel(
        classGroupId: classGroupId,
        name: _nameCtrl.text.trim(),
        programName: _programCtrl.text.trim(),
        intake: _intakeCtrl.text.trim(),
        status: _isActive ? 'active' : 'inactive',
      );

      await ref.read(classManagementServiceProvider).saveClassGroup(model);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew ? 'Class created successfully.' : 'Class updated successfully.',
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
    final isNew = widget.initialClass == null;

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
                    isNew ? 'New Class' : 'Edit Class',
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
                decoration: _inputDecoration('Class Name', 'e.g. DED1A'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _programCtrl,
                decoration: _inputDecoration(
                    'Program Name', 'e.g. Diploma in Electrical Engineering'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _intakeCtrl,
                decoration: _inputDecoration('Intake', 'e.g. Cohort 8 2023/2024'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (!isNew)
                SwitchListTile(
                  title: const Text('Active Status'),
                  subtitle: const Text('Inactive classes are hidden from new timetables.'),
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
                          isNew ? 'Create Class' : 'Save Changes',
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
