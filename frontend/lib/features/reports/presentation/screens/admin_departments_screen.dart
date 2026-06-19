import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_provider.dart';
import '../widgets/officer_web_shell.dart';
import 'admin_dashboard_screen.dart' show AdminDashboardScreen;
import '../../../../core/constants/app_colors.dart';

class AdminDepartmentsScreen extends ConsumerStatefulWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  ConsumerState<AdminDepartmentsScreen> createState() => _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState extends ConsumerState<AdminDepartmentsScreen> {

  void _showCreateDepartmentDialog() {
    final nameCtrl = TextEditingController();
    final countyCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedType = 'public_works';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Department', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('Department Name', nameCtrl),
                  const SizedBox(height: 12),
                  _field('County', countyCtrl),
                  const SizedBox(height: 12),
                  _field('Contact Phone', phoneCtrl, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: _inputDec('Type'),
                    items: const [
                      DropdownMenuItem(value: 'public_works', child: Text('Public Works')),
                      DropdownMenuItem(value: 'police', child: Text('Police')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || countyCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and county are required'), backgroundColor: AppColors.red),
                  );
                  return;
                }
                try {
                  await ref.read(adminActionProvider.notifier).createDepartment({
                    'name': nameCtrl.text.trim(),
                    'county': countyCtrl.text.trim(),
                    'contact_phone': phoneCtrl.text.trim(),
                    'type': selectedType,
                    'is_active': true,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Department created'), backgroundColor: AppColors.green),
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDepartmentDialog(dynamic dept) {
    final nameCtrl = TextEditingController(text: dept.name);
    final countyCtrl = TextEditingController(text: dept.county);
    final phoneCtrl = TextEditingController(text: dept.contactPhone);
    String selectedType = dept.type;
    bool isActive = dept.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${dept.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('Department Name', nameCtrl),
                  const SizedBox(height: 12),
                  _field('County', countyCtrl),
                  const SizedBox(height: 12),
                  _field('Contact Phone', phoneCtrl, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: _inputDec('Type'),
                    items: const [
                      DropdownMenuItem(value: 'public_works', child: Text('Public Works')),
                      DropdownMenuItem(value: 'police', child: Text('Police')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active', style: TextStyle(fontSize: 13)),
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
                  await ref.read(adminActionProvider.notifier).updateDepartment(dept.id, {
                    'name': nameCtrl.text.trim(),
                    'county': countyCtrl.text.trim(),
                    'contact_phone': phoneCtrl.text.trim(),
                    'type': selectedType,
                    'is_active': isActive,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Department updated'), backgroundColor: AppColors.green),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDepartmentDialog(dynamic dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.red)),
        content: Text('Delete "${dept.name}"? Reports routed to this department may be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: AppColors.white),
            onPressed: () async {
              try {
                await ref.read(adminActionProvider.notifier).deleteDepartment(dept.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Department deleted'), backgroundColor: AppColors.green),
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

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: _inputDec(label),
      );

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(departmentsProvider);

    return OfficerWebShell(
      pageTitle: 'Departments',
      pageSubtitle: 'All departments — every county',
      selectedIndex: 2,
      roleBadge: 'AD',
      navItems: AdminDashboardScreen.navItems,
      child: deptsAsync.when(
        data: (depts) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${depts.length} departments',
                    style: const TextStyle(fontSize: 13, color: AppColors.grey)),
                SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _showCreateDepartmentDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Department', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal, foregroundColor: AppColors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FixedColumnWidth(110),
                  2: FixedColumnWidth(100),
                  3: FixedColumnWidth(120),
                  4: FixedColumnWidth(80),
                  5: FixedColumnWidth(100),
                },
                children: [
                  const TableRow(children: [
                    _H('Name'), _H('Type'), _H('County'), _H('Contact'), _H('Status'), _H('Actions'),
                  ]),
                  ...depts.map((d) => TableRow(children: [
                        _C(d.name),
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: d.type == 'police' ? AppColors.tealLight : AppColors.amberLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d.type == 'police' ? 'Police' : 'Public Works',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: d.type == 'police' ? AppColors.teal : AppColors.amber),
                              ),
                            ),
                          ),
                        ),
                        _C(d.county),
                        _C(d.contactPhone),
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: d.isActive ? AppColors.greenLight : AppColors.redLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: d.isActive ? AppColors.green : AppColors.red),
                              ),
                            ),
                          ),
                        ),
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.teal),
                                onPressed: () => _showEditDepartmentDialog(d),
                                tooltip: 'Edit',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.red),
                                onPressed: () => _showDeleteDepartmentDialog(d),
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
            ),
          ],
        ),
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
        child: Text(text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey)),
      );
}

class _C extends StatelessWidget {
  final String text;
  const _C(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.dark),
            overflow: TextOverflow.ellipsis),
      );
}