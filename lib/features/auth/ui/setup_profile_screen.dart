import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../../categories/ui/setup_categories_screen.dart';

class SetupProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const SetupProfileScreen({super.key, required this.profile});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;
  late TextEditingController _salaryController;
  late TextEditingController _allowancesController;
  late TextEditingController _creditDateController;

  String? _selectedGender;
  DateTime? _selectedDob;
  Uint8List? _selectedImageBytes;

  final _authService = AuthService();
  bool _isLoading = false;

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
      text: widget.profile.professionalSalary > 0
          ? widget.profile.professionalSalary.toString()
          : '',
    );
    _allowancesController = TextEditingController(
      text: widget.profile.fixedAllowances > 0
          ? widget.profile.fixedAllowances.toString()
          : '',
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
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _saveAndNext() async {
    setState(() => _isLoading = true);
    try {
      String? avatarUrl;
      if (_selectedImageBytes != null) {
        avatarUrl = await _authService.uploadProfilePicture(
          _selectedImageBytes!,
          widget.profile.id,
        );
      } else {
        avatarUrl = widget.profile.avatarUrl;
      }

      await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: _selectedDob,
        jobTitle: _jobTitleController.text.trim(),
        companyName: _companyController.text.trim(),
        professionalSalary: double.tryParse(_salaryController.text) ?? 0,
        fixedAllowances: double.tryParse(_allowancesController.text) ?? 0,
        salaryCreditDate: int.tryParse(_creditDateController.text),
        professionType: 'White Collar', // Default to avoid breaking backend
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SetupCategoriesScreen()),
        );
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
        title: const Text('Setup Profile'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SetupCategoriesScreen(),
                ),
              );
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tell us about yourself',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This helps us tailor categories specific to your lifestyle.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildProfilePicSection(),
            const SizedBox(height: 32),
            _buildPersonalSection(),
            const SizedBox(height: 24),
            _buildProfessionalSection(),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAndNext,
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
                  : const Text('Next: Setup Categories'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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

  Widget _buildProfessionalSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _jobTitleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                prefixIcon: Icon(Icons.business_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Salary',
                prefixIcon: Icon(Icons.payments_outlined),
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _allowancesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fixed Allowances',
                prefixIcon: Icon(Icons.add_card_rounded),
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
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

  Widget _buildProfilePicSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: _selectedImageBytes != null
                ? MemoryImage(_selectedImageBytes!)
                : (widget.profile.avatarUrl != null
                      ? NetworkImage(widget.profile.avatarUrl!) as ImageProvider
                      : null),
            child:
                _selectedImageBytes == null && widget.profile.avatarUrl == null
                ? Icon(
                    Icons.person_outline_rounded,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
