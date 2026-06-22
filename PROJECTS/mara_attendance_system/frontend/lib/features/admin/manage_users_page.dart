import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_schema.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_management_provider.dart';
import '../../core/widgets/unauthorized_view.dart';
import '../dashboard/widgets/app_drawer.dart';
import '../notifications/widgets/notification_bell.dart';

// ---------------------------------------------------------------------------
// ManageUsersPage — admin-only screen with Approved / Pending tabs.
// ---------------------------------------------------------------------------

class ManageUsersPage extends ConsumerStatefulWidget {
  const ManageUsersPage({super.key});

  @override
  ConsumerState<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends ConsumerState<ManageUsersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  /// null means "All roles"
  UserRole? _roleFilter;

  static const _filterRoles = [
    UserRole.lecturer,
    UserRole.hod,
    UserRole.headOfProgram,
    UserRole.deputyAcademicDean,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final usersAsync = ref.watch(managedUsersProvider);

    if (currentUser?.role != UserRole.admin) {
      return const UnauthorizedView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: const [NotificationBell()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(144),
          child: usersAsync.when(
            loading: () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleStatsRow(const {}),
                _buildTabBar(pendingCount: 0),
              ],
            ),
            error: (_, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleStatsRow(const {}),
                _buildTabBar(pendingCount: 0),
              ],
            ),
            data: (users) {
              final pendingCount = users
                  .where((u) => u.status == UserStatus.pendingApproval.value)
                  .length;
              final approved = users
                  .where((u) => u.status != UserStatus.pendingApproval.value)
                  .toList();
              final roleCounts = {
                UserRole.lecturer:
                    approved.where((u) => u.role == UserRole.lecturer).length,
                UserRole.hod:
                    approved.where((u) => u.role == UserRole.hod).length,
                UserRole.headOfProgram: approved
                    .where((u) => u.role == UserRole.headOfProgram)
                    .length,
                UserRole.deputyAcademicDean: approved
                    .where((u) => u.role == UserRole.deputyAcademicDean)
                    .length,
              };
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRoleStatsRow(roleCounts),
                  _buildTabBar(pendingCount: pendingCount),
                ],
              );
            },
          ),
        ),
      ),
      drawer: const AppDrawer(currentPage: 'manage_users'),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load users: $e')),
        data: (users) {
          final adminCount =
              users.where((u) => u.role == UserRole.admin).length;

          final approved = users
              .where((u) => u.status != UserStatus.pendingApproval.value)
              .toList();
          final pending = users
              .where((u) => u.status == UserStatus.pendingApproval.value)
              .toList();

          return Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList(
                      users: approved,
                      adminCount: adminCount,
                      currentUser: currentUser,
                      isPendingTab: false,
                    ),
                    _buildUserList(
                      users: pending,
                      adminCount: adminCount,
                      currentUser: currentUser,
                      isPendingTab: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Tab bar with pending badge ───────────────────────────────────────────

  Widget _buildTabBar({required int pendingCount}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF0F766E),
        indicatorWeight: 2.5,
        labelColor: const Color(0xFF0F766E),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          const Tab(text: 'Approved'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pending'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  _PendingBadge(count: pendingCount),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Role stats cards ──────────────────────────────────────────────────────

  Widget _buildRoleStatsRow(Map<UserRole, int> counts) {
    const specs = [
      (
        role: UserRole.lecturer,
        label: 'Lecturer',
        icon: Icons.school_outlined,
        color: Color(0xFF0EA5E9),
        bg: Color(0xFFE0F2FE),
      ),
      (
        role: UserRole.hod,
        label: 'Head of\nDepartment',
        icon: Icons.supervisor_account_outlined,
        color: Color(0xFF8B5CF6),
        bg: Color(0xFFEDE9FE),
      ),
      (
        role: UserRole.headOfProgram,
        label: 'Head of\nProgram',
        icon: Icons.account_tree_outlined,
        color: Color(0xFFF59E0B),
        bg: Color(0xFFFEF3C7),
      ),
      (
        role: UserRole.deputyAcademicDean,
        label: 'Deputy\nAcademic Dean',
        icon: Icons.workspace_premium_outlined,
        color: Color(0xFF10B981),
        bg: Color(0xFFD1FAE5),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          for (int i = 0; i < specs.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _RoleStatCard(
                label: specs[i].label,
                icon: specs[i].icon,
                count: counts[specs[i].role] ?? 0,
                iconColor: specs[i].color,
                bgColor: specs[i].bg,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Search + Role filter row ─────────────────────────────────────────────

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                  borderSide: const BorderSide(color: Color(0xFF0F766E)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Role filter button
          _RoleFilterButton(
            selected: _roleFilter,
            roles: _filterRoles,
            onChanged: (role) => setState(() => _roleFilter = role),
          ),
        ],
      ),
    );
  }

  // ── User list for a tab ──────────────────────────────────────────────────

  Widget _buildUserList({
    required List<ManagedUser> users,
    required int adminCount,
    required AppUser? currentUser,
    required bool isPendingTab,
  }) {
    final q = _query.trim().toLowerCase();

    var filtered = users.where((u) {
      final matchesSearch = q.isEmpty ||
          u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
      final matchesRole =
          _roleFilter == null || u.role == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    if (filtered.isEmpty) {
      return _EmptyState(
        isPendingTab: isPendingTab,
        hasFilters: q.isNotEmpty || _roleFilter != null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final u = filtered[index];
        final isSelf = currentUser != null && currentUser.uid == u.uid;
        return _UserCard(
          user: u,
          isSelf: isSelf,
          onEdit: isSelf ? null : () => _editUser(u, adminCount),
          onApprove: (isSelf || u.status != UserStatus.pendingApproval.value)
              ? null
              : () => _approveUser(u),
        );
      },
    );
  }

  // ── Role & Status editing flow ───────────────────────────────────────────

  Future<void> _approveUser(ManagedUser user) async {
    try {
      await ref.read(userManagementServiceProvider).approveUser(user.uid);
      if (!mounted) return;
      _toast('${user.displayName} has been approved.');
    } catch (e) {
      if (!mounted) return;
      _toast('Failed to approve user: $e', isError: true);
    }
  }

  Future<void> _editUser(ManagedUser user, int adminCount) async {
    final newRole = await _pickRole(user);
    if (newRole == null || newRole == user.role || !mounted) return;

    // Guard: never strip the last remaining admin.
    if (user.role == UserRole.admin &&
        newRole != UserRole.admin &&
        adminCount <= 1) {
      _toast(
        'Cannot change the role of the last remaining admin.',
        isError: true,
      );
      return;
    }

    final isLeavingTeaching = user.role.canHoldTeachingAssignment &&
        !newRole.canHoldTeachingAssignment;

    PromotionImpact? impact;
    if (isLeavingTeaching) {
      impact = await ref
          .read(userManagementServiceProvider)
          .getPromotionImpact(user.uid);
      if (!mounted) return;
    }

    final confirmed =
        await _confirmRoleChange(user, newRole, impact: impact) ?? false;
    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(userManagementServiceProvider)
          .changeUserRole(uid: user.uid, newRole: newRole);
      if (!mounted) return;
      _toast('${user.displayName} is now ${_roleLabel(newRole)}.');
    } catch (e) {
      if (!mounted) return;
      _toast('Failed to update role: $e', isError: true);
    }
  }

  Future<UserRole?> _pickRole(ManagedUser user) {
    UserRole selectedRole = user.role;
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return showModalBottomSheet<UserRole>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 4),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // User header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(
                              0xFF0F766E,
                            ).withValues(alpha: 0.1),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Color(0xFF0F766E),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Text(
                        'SELECT A ROLE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    // Role cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: UserRole.values
                            .map(
                              (role) => _selectableRoleCard(
                                role: role,
                                selected: role == selectedRole,
                                isCurrent: role == user.role,
                                onTap: () =>
                                    setSheetState(() => selectedRole = role),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Footer actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                foregroundColor: const Color(0xFF64748B),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: selectedRole == user.role
                                  ? null
                                  : () => Navigator.pop(ctx, selectedRole),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFFE2E8F0),
                                disabledForegroundColor:
                                    const Color(0xFF94A3B8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Review change',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _selectableRoleCard({
    required UserRole role,
    required bool selected,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    const teal = Color(0xFF0F766E);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? teal.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? teal : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (selected ? teal : const Color(0xFF64748B))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _roleIcon(role),
                  color: selected ? teal : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _roleLabel(role),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _roleDescription(role),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? teal : const Color(0xFFCBD5E1),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmRoleChange(
    ManagedUser user,
    UserRole newRole, {
    PromotionImpact? impact,
  }) {
    final isLeavingTeaching = user.role.canHoldTeachingAssignment &&
        !newRole.canHoldTeachingAssignment;
    final showImpact =
        isLeavingTeaching && impact != null && impact.hasLecturerProfile;
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.manage_accounts,
                color: Color(0xFF0F766E),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm role change',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(
                    0xFF0F766E,
                  ).withValues(alpha: 0.1),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _beforeAfterRoles(user.role, newRole),
            if (showImpact) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'What happens',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _impactLine(
                      Icons.event_busy,
                      '${impact.sessionCount} timetable session(s) will be deactivated',
                    ),
                    _impactLine(
                      Icons.cancel_schedule_send,
                      '${impact.replacementCount} pending/upcoming replacement class(es) will be cancelled',
                    ),
                    _impactLine(
                      Icons.person_off,
                      'Lecturer profile will be disabled',
                    ),
                    const Text(
                      'Past attendance records are kept.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isLeavingTeaching) ...[
              const SizedBox(height: 12),
              const Text(
                'This user has no lecturer schedule to drop.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              isLeavingTeaching
                  ? 'Confirm & drop schedule'
                  : 'Confirm change',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _beforeAfterRoles(UserRole from, UserRole to) {
    return Row(
      children: [
        Expanded(child: _bigRoleChip(from, highlighted: false)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, size: 20, color: Color(0xFF94A3B8)),
        ),
        Expanded(child: _bigRoleChip(to, highlighted: true)),
      ],
    );
  }

  Widget _bigRoleChip(UserRole role, {required bool highlighted}) {
    const teal = Color(0xFF0F766E);
    final color = highlighted ? teal : const Color(0xFF64748B);
    final bg = highlighted
        ? teal.withValues(alpha: 0.1)
        : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? teal.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(_roleIcon(role), size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            _roleLabel(role),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _impactLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role stat card
// ---------------------------------------------------------------------------

class _RoleStatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final Color iconColor;
  final Color bgColor;

  const _RoleStatCard({
    required this.label,
    required this.icon,
    required this.count,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending count badge
// ---------------------------------------------------------------------------

class _PendingBadge extends StatelessWidget {
  final int count;
  const _PendingBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role filter button + popover
// ---------------------------------------------------------------------------

class _RoleFilterButton extends StatelessWidget {
  final UserRole? selected;
  final List<UserRole> roles;
  final ValueChanged<UserRole?> onChanged;

  const _RoleFilterButton({
    required this.selected,
    required this.roles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected != null;
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0F766E).withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF0F766E)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: isActive
                  ? const Color(0xFF0F766E)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              isActive ? _shortLabel(selected!) : 'Role',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF64748B),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Color(0xFF0F766E),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortLabel(UserRole role) => switch (role) {
        UserRole.lecturer => 'Lecturer',
        UserRole.hod => 'Head of Dept.',
        UserRole.headOfProgram => 'Head of Program',
        UserRole.deputyAcademicDean => 'Deputy Dean',
        UserRole.admin => 'Admin',
      };

  Future<void> _showMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    // Wrap each choice in an _FilterChoice so we can distinguish "All Roles"
    // (value: null) from a dismissed menu (returns null from showMenu).
    final items = <PopupMenuEntry<_FilterChoice>>[
      PopupMenuItem<_FilterChoice>(
        value: const _FilterChoice(role: null),
        child: Row(
          children: [
            Text(
              'All Roles',
              style: TextStyle(
                fontWeight:
                    selected == null ? FontWeight.bold : FontWeight.normal,
                color: selected == null
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF1E293B),
              ),
            ),
            if (selected == null) ...[
              const Spacer(),
              const Icon(Icons.check, size: 16, color: Color(0xFF0F766E)),
            ],
          ],
        ),
      ),
      const PopupMenuDivider(),
      for (final role in roles)
        PopupMenuItem<_FilterChoice>(
          value: _FilterChoice(role: role),
          child: Row(
            children: [
              Text(
                _shortLabel(role),
                style: TextStyle(
                  fontWeight: selected == role
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: selected == role
                      ? const Color(0xFF0F766E)
                      : const Color(0xFF1E293B),
                ),
              ),
              if (selected == role) ...[
                const Spacer(),
                const Icon(Icons.check, size: 16, color: Color(0xFF0F766E)),
              ],
            ],
          ),
        ),
    ];

    final result = await showMenu<_FilterChoice>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      elevation: 8,
      items: items,
    );

    // null means the menu was dismissed without selection.
    if (result != null) {
      onChanged(result.role);
    }
  }
}

// ---------------------------------------------------------------------------
// Sentinel wrapper so "All Roles" (null) can be distinguished from a dismissed
// showMenu (which also returns null).
// ---------------------------------------------------------------------------

class _FilterChoice {
  final UserRole? role;
  const _FilterChoice({required this.role});
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isPendingTab;
  final bool hasFilters;

  const _EmptyState({required this.isPendingTab, required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    final icon = hasFilters
        ? Icons.search_off_rounded
        : isPendingTab
            ? Icons.check_circle_outline_rounded
            : Icons.people_outline;
    final title = hasFilters
        ? 'No results found'
        : isPendingTab
            ? 'All caught up!'
            : 'No users yet';
    final subtitle = hasFilters
        ? 'Try adjusting your search or filter.'
        : isPendingTab
            ? 'There are no users waiting for approval.'
            : 'Approved users will appear here.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: const Color(0xFF0F766E)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User row card
// ---------------------------------------------------------------------------

class _UserCard extends StatelessWidget {
  final ManagedUser user;
  final bool isSelf;
  final VoidCallback? onEdit;
  final VoidCallback? onApprove;

  const _UserCard({
    required this.user,
    required this.isSelf,
    this.onEdit,
    this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    const Color(0xFF0F766E).withValues(alpha: 0.1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0F766E,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _roleChip(user.role),
                        if (user.status.toLowerCase() !=
                            UserStatus.active.value) ...[
                          const SizedBox(width: 6),
                          _statusChip(user.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onApprove != null)
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 32),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (onEdit != null)
                const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFF94A3B8),
                )
              else
                const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

String _roleLabel(UserRole role) {
  return switch (role) {
    UserRole.admin => 'Admin',
    UserRole.lecturer => 'Lecturer',
    UserRole.hod => 'Head of Department',
    UserRole.headOfProgram => 'Head of Program',
    UserRole.deputyAcademicDean => 'Deputy Academic Dean',
  };
}

IconData _roleIcon(UserRole role) {
  return switch (role) {
    UserRole.admin => Icons.admin_panel_settings_outlined,
    UserRole.lecturer => Icons.school_outlined,
    UserRole.hod => Icons.supervisor_account_outlined,
    UserRole.headOfProgram => Icons.account_tree_outlined,
    UserRole.deputyAcademicDean => Icons.workspace_premium_outlined,
  };
}

String _roleDescription(UserRole role) {
  return switch (role) {
    UserRole.admin => 'Full system access — manage users, timetable & reports.',
    UserRole.lecturer =>
      'Teaches classes, marks attendance, books replacements.',
    UserRole.hod => 'Head of Department — reviews discipline cases & reports.',
    UserRole.headOfProgram => 'Oversees a program and reviews escalated cases.',
    UserRole.deputyAcademicDean => 'Senior academic oversight and case review.',
  };
}

Widget _roleChip(UserRole role) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      _roleLabel(role),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
      ),
    ),
  );
}

Widget _statusChip(String status) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      status.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFFB91C1C),
      ),
    ),
  );
}
