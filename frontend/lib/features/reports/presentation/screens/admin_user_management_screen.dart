import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_provider.dart';
import '../widgets/officer_web_shell.dart';
import '../screens/admin_dashboard_screen.dart' show AdminDashboardScreen;
import '../../../../core/constants/app_colors.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  String _roleFilter = 'all';
  String _searchQuery = '';

  // ── Create User Dialog ───────────────────────────────────────────────
  void _showCreateUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final countyCtrl = TextEditingController();
    String selectedRole = 'citizen';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField('Full Name', nameCtrl),
                  const SizedBox(height: 12),
                  _dialogField('Email', emailCtrl, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _dialogField('Password (min 12 chars)', passwordCtrl, obscure: true),
                  const SizedBox(height: 12),
                  _dialogField('County', countyCtrl),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: _inputDecoration('Role'),
                    items: const [
                      DropdownMenuItem(value: 'citizen', child: Text('Citizen')),
                      DropdownMenuItem(value: 'county_officer', child: Text('County Officer')),
                      DropdownMenuItem(value: 'police_officer', child: Text('Police Officer')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedRole = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty ||
                    passwordCtrl.text.isEmpty || countyCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required'), backgroundColor: AppColors.red),
                  );
                  return;
                }
                try {
                  await ref.read(adminActionProvider.notifier).createUser(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passwordCtrl.text,
                    role: selectedRole,
                    county: countyCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User created successfully'), backgroundColor: AppColors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.red),
                    );
                  }
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit User Dialog ─────────────────────────────────────────────────
  void _showEditUserDialog(dynamic user) {
    final nameCtrl = TextEditingController(text: user.name);
    final countyCtrl = TextEditingController(text: user.county);
    String selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${user.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField('Full Name', nameCtrl),
                  const SizedBox(height: 12),
                  _dialogField('County', countyCtrl),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: _inputDecoration('Role'),
                    items: const [
                      DropdownMenuItem(value: 'citizen', child: Text('Citizen')),
                      DropdownMenuItem(value: 'county_officer', child: Text('County Officer')),
                      DropdownMenuItem(value: 'police_officer', child: Text('Police Officer')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedRole = v!),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active Account', style: TextStyle(fontSize: 13)),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                    activeColor: AppColors.teal,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(adminActionProvider.notifier).updateUser(user.id, {
                    'name': nameCtrl.text.trim(),
                    'county': countyCtrl.text.trim(),
                    'role': selectedRole,
                    'is_active': isActive,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User updated successfully'), backgroundColor: AppColors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.red),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Confirmation ──────────────────────────────────────────────
  void _showDeleteUserDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.red)),
        content: Text('Are you sure you want to permanently delete ${user.name} (${user.email})? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: AppColors.white),
            onPressed: () async {
              try {
                await ref.read(adminActionProvider.notifier).deleteUser(user.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted'), backgroundColor: AppColors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _dialogField(String label, TextEditingController ctrl,
      {bool obscure = false, TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
      );

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return OfficerWebShell(
      pageTitle: 'User Management',
      pageSubtitle: 'Manage all system users and roles',
      selectedIndex: 1,
      roleBadge: 'AD',
      navItems: AdminDashboardScreen.navItems,
      child: usersAsync.when(
        data: (users) {
          final roleFiltered = _roleFilter == 'all'
              ? users
              : users.where((u) => u.role == _roleFilter).toList();
          final filtered = _searchQuery.isEmpty
              ? roleFiltered
              : roleFiltered.where((u) =>
                  u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  u.county.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['all', 'citizen', 'county_officer', 'police_officer', 'admin'].map((r) {
                            final label = {
                              'all': 'All Users', 'citizen': 'Citizens',
                              'county_officer': 'County Officers',
                              'police_officer': 'Police Officers', 'admin': 'Admins',
                            }[r]!;
                            final selected = _roleFilter == r;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _roleFilter = r),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: selected ? AppColors.teal : AppColors.lightBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(label,
                                      style: TextStyle(fontSize: 12, color: selected ? AppColors.white : AppColors.grey)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      height: 38,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grey),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.lightBg)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.lightBg)),
                          filled: true,
                          fillColor: AppColors.lightBg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateUserDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add User', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: AppColors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.5),
                    2: FixedColumnWidth(120), 3: FixedColumnWidth(90),
                    4: FixedColumnWidth(80), 5: FixedColumnWidth(120),
                  },
                  children: [
                    const TableRow(children: [
                      _H('Name'), _H('Email'), _H('Role'), _H('County'), _H('Status'), _H('Actions'),
                    ]),
                    ...filtered.map((u) => TableRow(children: [
                          _C(u.name),
                          _C(u.email),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(6)),
                                child: Text(u.role.replaceAll('_', ' '),
                                    style: const TextStyle(fontSize: 10, color: AppColors.teal)),
                              ),
                            ),
                          ),
                          _C(u.county),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: u.isActive ? AppColors.greenLight : AppColors.redLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(u.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(fontSize: 10, color: u.isActive ? AppColors.green : AppColors.red)),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.teal),
                                  onPressed: () => _showEditUserDialog(u),
                                  tooltip: 'Edit',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.red),
                                  onPressed: () => _showDeleteUserDialog(u),
                                  tooltip: 'Delete',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                          ),
                        ])),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String text;
  const _H(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
      );
}

class _C extends StatelessWidget {
  final String text;
  const _C(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.dark), overflow: TextOverflow.ellipsis),
      );
}