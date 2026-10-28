import 'package:flutter/material.dart';
import '../../models/emergency_contact.dart';
import '../../services/local_storage_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final _storageService = LocalStorageService();
  late Future<List<EmergencyContact>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _refreshContacts();
  }

  void _refreshContacts() {
    setState(() {
      _contactsFuture = _storageService.loadContacts();
    });
  }

  void _showContactDialog({EmergencyContact? contact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ContactFormSheet(
        contact: contact,
        onSaved: () {
          _refreshContacts();
        },
      ),
    );
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: const Text('Remove Contact', style: TextStyle(color: AppConstants.textLight)),
        content: Text(
          'Are you sure you want to remove "${contact.name}" from your emergency contacts list?',
          style: const TextStyle(color: AppConstants.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppConstants.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.emergencyRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteContact(contact.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${contact.name} removed from local storage')),
        );
        _refreshContacts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload from JSON',
            onPressed: _refreshContacts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryViolet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Contact'),
        onPressed: () => _showContactDialog(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner explaining local JSON persistence
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppTheme.glassCardDecoration(
                  borderColor: AppConstants.primaryViolet.withOpacity(0.3),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryViolet.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.folder_shared_rounded, color: AppConstants.primaryLight, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Local JSON Persistence',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textLight,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Contacts are saved on-device in JSON format and sync with Firebase Realtime Database.',
                            style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // FutureBuilder reading from local JSON file
              Expanded(
                child: FutureBuilder<List<EmergencyContact>>(
                  future: _contactsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppConstants.primaryViolet),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppConstants.emergencyRed, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Error loading contacts: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppConstants.textMuted),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshContacts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final contacts = snapshot.data ?? [];

                    if (contacts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppConstants.bgCardLight.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.people_outline,
                                color: AppConstants.textMuted,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Emergency Contacts Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add trusted contacts who should receive your Safe-Walk timer escalation SMS alerts.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Contact'),
                              onPressed: () => _showContactDialog(),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: contacts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return _buildContactCard(contact);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Container(
      decoration: AppTheme.glassCardDecoration(
        borderColor: contact.isPrimary
            ? AppConstants.primaryViolet.withOpacity(0.6)
            : const Color(0xFF334155),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary
              ? AppConstants.primaryViolet
              : AppConstants.bgCardLight,
          foregroundColor: Colors.white,
          radius: 24,
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                contact.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textLight,
                ),
              ),
            ),
            if (contact.isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.primaryViolet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.primaryLight, width: 0.8),
                ),
                child: const Text(
                  'PRIMARY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryLight,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: AppConstants.textMuted),
                const SizedBox(width: 4),
                Text(
                  contact.phoneNumber,
                  style: const TextStyle(color: AppConstants.textLight, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.family_restroom_outlined, size: 14, color: AppConstants.primaryLight),
                const SizedBox(width: 4),
                Text(
                  contact.relationship,
                  style: const TextStyle(color: AppConstants.primaryLight, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppConstants.textMuted, size: 20),
              tooltip: 'Edit',
              onPressed: () => _showContactDialog(contact: contact),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppConstants.emergencyRed, size: 20),
              tooltip: 'Delete',
              onPressed: () => _deleteContact(contact),
            ),
          ],
        ),
      ),
    );
  }
}

/// Form sheet to Add or Edit Emergency Contact (Syllabus: Form + Validators + Dropdown + Checkbox)
class _ContactFormSheet extends StatefulWidget {
  final EmergencyContact? contact;
  final VoidCallback onSaved;

  const _ContactFormSheet({
    this.contact,
    required this.onSaved,
  });

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = LocalStorageService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _relationship;
  late bool _isPrimary;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phoneNumber ?? '');
    _relationship = widget.contact?.relationship ?? EmergencyContact.relationshipOptions.first;
    _isPrimary = widget.contact?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final contact = EmergencyContact(
      id: widget.contact?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      relationship: _relationship,
      isPrimary: _isPrimary,
      createdAt: widget.contact?.createdAt ?? DateTime.now(),
    );

    await _storageService.saveContact(contact);

    if (mounted) {
      widget.onSaved();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.contact == null ? 'Contact added successfully' : 'Contact updated successfully',
          ),
          backgroundColor: AppConstants.safeGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.contact == null ? 'Add Emergency Contact' : 'Edit Contact',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textLight,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppConstants.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Please enter a name (at least 2 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+1234567890 or 9876543210',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required for SMS escalations';
                  }
                  final phoneRegex = RegExp(r'^\+?[0-9\s\-]{7,15}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Enter a valid phone number (digits only)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Relationship Dropdown (Syllabus Requirement)
              DropdownButtonFormField<String>(
                initialValue: _relationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                dropdownColor: AppConstants.bgCard,
                items: EmergencyContact.relationshipOptions.map((rel) {
                  return DropdownMenuItem<String>(
                    value: rel,
                    child: Text(rel, style: const TextStyle(color: AppConstants.textLight)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _relationship = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              // Primary Contact Checkbox (Syllabus Requirement)
              Container(
                decoration: AppTheme.glassCardDecoration(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Set as Primary Contact',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textLight),
                  ),
                  subtitle: const Text(
                    'First recipient for automatic emergency SMS escalation',
                    style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
                  ),
                  value: _isPrimary,
                  activeColor: AppConstants.primaryViolet,
                  onChanged: (val) {
                    setState(() => _isPrimary = val ?? false);
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(widget.contact == null ? 'Save Contact' : 'Update Contact'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
