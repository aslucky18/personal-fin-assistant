import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/responsive.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class UserProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const UserProfileScreen({super.key, required this.profile});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;
  late TextEditingController _salaryController;
  late TextEditingController _allowancesController;
  late TextEditingController _creditDateController;

  String? _selectedGender;
  DateTime? _selectedDob;

  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageExtension;
  int _selectedSegment = 0; // 0 for Personal, 1 for Professional

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profile.fullName ?? '',
    );
    _jobTitleController = TextEditingController(
      text: widget.profile.jobTitle ?? '',
    );
    _companyController = TextEditingController(
      text: widget.profile.companyName ?? '',
    );
    _salaryController = TextEditingController(
      text: widget.profile.professionalSalary.toString(),
    );
    _allowancesController = TextEditingController(
      text: widget.profile.fixedAllowances.toString(),
    );
    _creditDateController = TextEditingController(
      text: widget.profile.salaryCreditDate?.toString() ?? '',
    );
    _selectedGender = widget.profile.gender;
    _selectedDob = widget.profile.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _salaryController.dispose();
    _allowancesController.dispose();
    _creditDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final ext = image.name.split('.').last;
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageExtension = ext.isNotEmpty ? ext : 'jpg';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;

      if (_selectedImageBytes != null && _selectedImageExtension != null) {
        avatarUrl = await _authService.uploadAvatarBytes(
          _selectedImageBytes!,
          _selectedImageExtension!,
        );
      }

      await _authService.updateProfile(
        fullName: name != widget.profile.fullName ? name : null,
        avatarUrl: avatarUrl,
        gender: _selectedGender,
        dateOfBirth: _selectedDob,
        jobTitle: _jobTitleController.text.trim(),
        companyName: _companyController.text.trim(),
        professionalSalary: double.tryParse(_salaryController.text) ?? 0,
        fixedAllowances: double.tryParse(_allowancesController.text) ?? 0,
        salaryCreditDate: int.tryParse(_creditDateController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveProfile,
            icon: const Icon(Icons.check_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveBuilder(
        mobile: _buildForm(context, isDesktop: false),
        desktop: _buildForm(context, isDesktop: true),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isDesktop}) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 24,
          vertical: 24,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 32),
              _buildSegmentedControl(),
              const SizedBox(height: 32),
              _selectedSegment == 0
                  ? _buildPersonalFields()
                  : _buildProfessionalFields(),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: _selectedImageBytes != null
                  ? MemoryImage(_selectedImageBytes!)
                  : (widget.profile.avatarUrl != null
                        ? NetworkImage(widget.profile.avatarUrl!)
                              as ImageProvider
                        : null),
              child:
                  _selectedImageBytes == null &&
                      widget.profile.avatarUrl == null
                  ? Text(
                      widget.profile.fullName != null &&
                              widget.profile.fullName!.isNotEmpty
                          ? widget.profile.fullName![0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.profile.fullName ?? 'User',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegmentTile('Personal', 0),
          _buildSegmentTile('Professional', 1),
        ],
      ),
    );
  }

  Widget _buildSegmentTile(String title, int index) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.wc_rounded),
              ),
              items: [
                'Male',
                'Female',
                'Other',
              ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _selectedGender = val),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDob ?? DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDob = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                child: Text(
                  _selectedDob == null
                      ? 'Select Date'
                      : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _jobTitleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                prefixIcon: Icon(Icons.business_rounded),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Professional Salary',
                prefixIcon: Icon(Icons.payments_outlined),
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _allowancesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fixed Allowances',
                prefixIcon: Icon(Icons.add_card_rounded),
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _creditDateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Salary Credit Date',
                hintText: 'Day of month (1-31)',
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
