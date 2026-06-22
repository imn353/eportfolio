import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/providers/class_management_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/class_form_dialog.dart';
import 'widgets/student_form_dialog.dart';

class ClassDetailPage extends ConsumerWidget {
  final ClassGroupModel classGroup;

  const ClassDetailPage({super.key, required this.classGroup});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync =
        ref.watch(classStudentsStreamProvider(classGroup.classGroupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(classGroup.name),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Class Info',
            onPressed: () => ClassFormDialog.show(
              context,
              initialClass: classGroup,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ClassInfoCard(classGroup: classGroup),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'Students',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          studentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.group_off_outlined,
                            size: 64,
                            color: AppColors.textSoft,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Students Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add students to this class to get started.',
                            style: TextStyle(color: AppColors.textSoft),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => StudentFormDialog.show(
                              context,
                              classGroupId: classGroup.classGroupId,
                            ),
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('Add Student'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final student = students[index];
                      return _StudentCard(
                        student: student,
                        onEdit: () => StudentFormDialog.show(
                          context,
                          initialStudent: student,
                          classGroupId: classGroup.classGroupId,
                        ),
                      );
                    },
                    childCount: students.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => StudentFormDialog.show(
          context,
          classGroupId: classGroup.classGroupId,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Student', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ClassInfoCard extends StatelessWidget {
  final ClassGroupModel classGroup;

  const _ClassInfoCard({required this.classGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  classGroup.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: classGroup.status == 'active'
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  classGroup.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: classGroup.status == 'active'
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.school_outlined, text: classGroup.programName),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.date_range_outlined, text: classGroup.intake),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSoft),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onEdit;

  const _StudentCard({required this.student, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.matricNo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (student.status == 'inactive')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'INACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSoft),
            ],
          ),
        ),
      ),
    );
  }
}
