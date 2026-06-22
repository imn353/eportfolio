import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/providers/class_management_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui.dart';
import '../dashboard/widgets/app_drawer.dart';
import 'class_detail_page.dart';
import 'widgets/class_form_dialog.dart';

class ManageClassesPage extends ConsumerStatefulWidget {
  const ManageClassesPage({super.key});

  @override
  ConsumerState<ManageClassesPage> createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends ConsumerState<ManageClassesPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classGroupsStreamProvider);

    return AppShell(
      title: 'Manage Classes',
      drawer: const AppDrawer(currentPage: 'manage_classes'),
      actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add New Class',
            onPressed: () => ClassFormDialog.show(context),
          ),
          const SizedBox(width: 8),
      ],
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by class name, program, or intake',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSoft),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: classesAsync.when(
              data: (classes) {
                final filtered = classes.where((c) {
                  return c.name.toLowerCase().contains(_searchQuery) ||
                      c.programName.toLowerCase().contains(_searchQuery) ||
                      c.intake.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.domain_disabled_rounded,
                          size: 64,
                          color: AppColors.textSoft,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No Classes Found' : 'No matches found',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Add a new class cohort to get started.'
                              : 'Try adjusting your search filters.',
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final classGroup = filtered[index];
                    return _ClassCard(classGroup: classGroup);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ClassFormDialog.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Class', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassGroupModel classGroup;

  const _ClassCard({required this.classGroup});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ClassDetailPage(classGroup: classGroup),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (classGroup.status == 'inactive')
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
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.school_outlined, size: 16, color: AppColors.textSoft),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      classGroup.programName,
                      style: const TextStyle(fontSize: 14, color: AppColors.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.date_range_outlined, size: 16, color: AppColors.textSoft),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      classGroup.intake,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSoft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
