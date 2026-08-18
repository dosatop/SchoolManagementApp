import 'package:app/features/admin/models/parents/admin_parent_child_model.dart';
import 'package:app/features/admin/models/parents/admin_parent_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminParentDetailsPage extends ConsumerStatefulWidget {
  final String parentId;

  const AdminParentDetailsPage({super.key, required this.parentId});

  @override
  ConsumerState<AdminParentDetailsPage> createState() =>
      _AdminParentDetailsPageState();
}

class _AdminParentDetailsPageState
    extends ConsumerState<AdminParentDetailsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  String get schoolName {
    final user = ref.read(authProvider).value?.user;

    if (user?.schoolName != null && user!.schoolName!.trim().isNotEmpty) {
      return user.schoolName!;
    }

    return 'My School';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(adminParentDetailsProvider(widget.parentId));

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: const Text(
          'Parent Details',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          parentState.when(
            loading: () => const SizedBox.shrink(),

            error: (_, __) => const SizedBox.shrink(),

            data: (parent) {
              return Row(
                children: [
                  // ==========================================================
                  // EDIT
                  // ==========================================================
                  IconButton(
                    tooltip: 'Edit Parent',
                    onPressed: _isDeleting
                        ? null
                        : () {
                            _startEditing(parent);
                          },
                    icon: const Icon(Icons.edit_outlined, color: textDark),
                  ),

                  // ==========================================================
                  // DELETE
                  // ==========================================================
                  IconButton(
                    tooltip: 'Delete Parent',
                    onPressed: _isDeleting
                        ? null
                        : () {
                            _confirmDelete(parent);
                          },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),

                  const SizedBox(width: 6),
                ],
              );
            },
          ),
        ],
      ),

      body: parentState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: primary)),

        error: (error, stackTrace) {
          return _errorState();
        },

        data: (parent) {
          if (!_isEditing) {
            return _detailsView(parent);
          }

          return _editView(parent);
        },
      ),
    );
  }

  // ================================================================
  // DETAILS VIEW
  // ================================================================

  Widget _detailsView(AdminParentDetailModel parent) {
    return RefreshIndicator(
      color: primary,

      onRefresh: () async {
        ref.invalidate(adminParentDetailsProvider(widget.parentId));

        await ref.read(adminParentDetailsProvider(widget.parentId).future);
      },

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),

        padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ========================================================
            // PARENT HEADER
            // ========================================================
            _parentHeader(parent),

            const SizedBox(height: 25),

            // ========================================================
            // CONTACT INFORMATION
            // ========================================================
            const Text(
              'Contact Information',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _informationCard(
              icon: Icons.email_outlined,
              label: 'Email',
              value: parent.email,
              color: Colors.blue,
            ),

            _informationCard(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: parent.phoneNumber.isEmpty
                  ? 'Not provided'
                  : parent.phoneNumber,
              color: Colors.green,
            ),

            _informationCard(
              icon: Icons.school_outlined,
              label: 'School',
              value: schoolName,
              color: Colors.orange,
            ),

            const SizedBox(height: 25),

            // ========================================================
            // CHILDREN
            // ========================================================
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Children',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${parent.children.length}',
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              parent.children.isEmpty
                  ? 'No children are currently linked to this parent.'
                  : 'Students linked to this parent.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 13),

            if (parent.children.isEmpty)
              _emptyChildrenCard()
            else
              ...parent.children.map((child) => _childCard(child)),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // PARENT HEADER
  // ================================================================

  Widget _parentHeader(AdminParentDetailModel parent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.family_restroom,
              color: Colors.white,
              size: 34,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Parent',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(height: 4),

                Text(
                  parent.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${parent.children.length} '
                  '${parent.children.length == 1 ? 'child' : 'children'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INFORMATION CARD
  // ================================================================

  Widget _informationCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,

            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: color, size: 21),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CHILD CARD
  // ================================================================

  Widget _childCard(AdminParentChildModel child) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,

                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(.09),
                  borderRadius: BorderRadius.circular(13),
                ),

                child: const Icon(Icons.school_outlined, color: Colors.purple),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      child.studentName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      child.className.isEmpty
                          ? 'Class not assigned'
                          : child.className,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Divider(height: 1),

          const SizedBox(height: 13),

          _childDetail(
            Icons.badge_outlined,
            'Student Number',
            child.studentNumber,
          ),

          const SizedBox(height: 9),

          _childDetail(Icons.email_outlined, 'Email', child.email),

          const SizedBox(height: 9),

          _childDetail(
            Icons.class_outlined,
            'Class',
            child.className.isEmpty ? 'Not assigned' : child.className,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CHILD DETAIL
  // ================================================================

  Widget _childDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade500),

        const SizedBox(width: 9),

        Text(
          '$label:',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY CHILDREN
  // ================================================================

  Widget _emptyChildrenCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          Icon(
            Icons.family_restroom_outlined,
            size: 45,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 10),

          const Text(
            'No Children Linked',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'This parent does not currently have any '
            'students linked to their account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EDIT VIEW
  // ================================================================

  Widget _editView(AdminParentDetailModel parent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Edit Parent',
            style: TextStyle(
              color: textDark,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Update the parent account information.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 25),

          _inputField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 15),

          _inputField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 15),

          _inputField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _isEditing = false;
                          });
                        },
                  child: const Text('Cancel'),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveParent(parent),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INPUT FIELD
  // ================================================================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  // ================================================================
  // START EDITING
  // ================================================================

  void _startEditing(AdminParentDetailModel parent) {
    _fullNameController.text = parent.fullName;
    _emailController.text = parent.email;
    _phoneController.text = parent.phoneNumber;

    setState(() {
      _isEditing = true;
    });
  }

  // ================================================================
  // SAVE
  // ================================================================

  Future<void> _saveParent(AdminParentDetailModel parent) async {
    if (_fullNameController.text.trim().isEmpty) {
      _showMessage('Full name is required.');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showMessage('Email is required.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedParent = await ref
        .read(adminDashboardProvider.notifier)
        .updateParent(
          parentId: parent.parentId,
          data: {
            'fullName': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
          },
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (updatedParent == null) {
      _showMessage('Unable to update parent.');
      return;
    }

    setState(() {
      _isEditing = false;
    });

    ref.invalidate(adminParentDetailsProvider(widget.parentId));

    _showMessage('Parent updated successfully.');
  }

  // ================================================================
  // DELETE CONFIRMATION
  // ================================================================

  Future<void> _confirmDelete(AdminParentDetailModel parent) async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Parent'),

          content: Text(
            'Are you sure you want to delete '
            '${parent.fullName}?\n\n'
            'This action cannot be undone.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _deleteParent(parent);
  }

  // ================================================================
  // DELETE PARENT
  // ================================================================

  Future<void> _deleteParent(AdminParentDetailModel parent) async {
    setState(() {
      _isDeleting = true;
    });

    final deleted = await ref
        .read(adminDashboardProvider.notifier)
        .deleteParent(parentId: parent.parentId);

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
    });

    if (!deleted) {
      _showMessage('Unable to delete parent.');
      return;
    }

    _showMessage('Parent deleted successfully.');

    context.pop();
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),

            const SizedBox(height: 12),

            const Text(
              'Unable to load parent details.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textDark, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                ref.invalidate(adminParentDetailsProvider(widget.parentId));
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),

              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // MESSAGE
  // ================================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
