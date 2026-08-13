import 'package:app/features/super_admin/presentation/create_school_admin_page.dart';
import 'package:app/features/super_admin/provider/school_admins_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SchoolAdminsPage extends ConsumerWidget {
  final String schoolId;
  final String schoolName;

  const SchoolAdminsPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolAdminsProvider(schoolId));

    return Scaffold(
      appBar: AppBar(title: const Text('School Admins')),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateSchoolAdminPage(
                schoolId: schoolId,
                schoolName: schoolName,
              ),
            ),
          );

          // Refresh admins after returning
          ref.invalidate(schoolAdminsProvider(schoolId));
        },
        child: const Icon(Icons.add),
      ),

      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),

        data: (admins) {
          if (admins.isEmpty) {
            return const Center(child: Text('No school admins found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: admins.length,

            itemBuilder: (context, index) {
              final admin = admins[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),

                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      admin.fullName.isNotEmpty
                          ? admin.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),

                  title: Text(
                    admin.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (admin.email != null && admin.email!.isNotEmpty)
                        Text(admin.email!),

                      if (admin.phoneNumber != null &&
                          admin.phoneNumber!.isNotEmpty)
                        Text(admin.phoneNumber!),
                    ],
                  ),

                  trailing: const Icon(Icons.admin_panel_settings),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
