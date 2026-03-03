import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../controllers/business_profile_provider.dart';
import '../models/business_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accNameCtrl;
  late TextEditingController _accNumCtrl;
  late TextEditingController _momoCtrl;
  late TextEditingController _termsCtrl;

  String _logoUrl = '';
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BusinessProfileProvider>(
      context,
      listen: false,
    );
    final p = provider.profile;

    // Load existing profile, or fallback to the defaults from your sample
    _nameCtrl = TextEditingController(text: p?.companyName ?? 'PEN Network');
    _addressCtrl = TextEditingController(
      text: p?.address ?? '32 MAUVE AVENUE, MILE 7',
    );
    _emailCtrl = TextEditingController(
      text: p?.email ?? 'contact@pennetwork.net',
    );
    _phoneCtrl = TextEditingController(text: p?.phone ?? '+233 20 001 2873');
    _websiteCtrl = TextEditingController(
      text: p?.website ?? 'www.pennetwork.net',
    );
    _bankNameCtrl = TextEditingController(text: p?.bankName ?? 'UMB Bank');
    _accNameCtrl = TextEditingController(
      text: p?.accountName ?? 'Ebenezer Zotoo',
    );
    _accNumCtrl = TextEditingController(text: p?.accountNumber ?? '');
    _momoCtrl = TextEditingController(
      text: p?.mobileMoneyNumber ?? '0200012873 Ebenezer Zotoo',
    );
    _termsCtrl = TextEditingController(
      text:
          p?.paymentTerms ??
          'Payment is due within 7 days from the date of invoice. Work will commence upon receiving 50% upfront. Final files handed over after full payment.',
    );

    _logoUrl = p?.logoUrl ?? '';
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      final provider = Provider.of<BusinessProfileProvider>(
        context,
        listen: false,
      );
      final url = await provider.uploadLogo(File(pickedFile.path));

      if (url != null) {
        setState(() => _logoUrl = url);
      }
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final profile = BusinessProfile(
      id: const Uuid().v4(),
      companyName: _nameCtrl.text,
      address: _addressCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      website: _websiteCtrl.text,
      logoUrl: _logoUrl,
      bankName: _bankNameCtrl.text,
      accountName: _accNameCtrl.text,
      accountNumber: _accNumCtrl.text,
      mobileMoneyNumber: _momoCtrl.text,
      paymentTerms: _termsCtrl.text,
    );

    final success = await Provider.of<BusinessProfileProvider>(
      context,
      listen: false,
    ).saveProfile(profile);
    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile Saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Logo Upload Section
            Center(
              child: GestureDetector(
                onTap: _pickAndUploadImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _logoUrl.isNotEmpty
                      ? NetworkImage(_logoUrl)
                      : null,
                  child: _isUploadingImage
                      ? const CircularProgressIndicator()
                      : (_logoUrl.isEmpty
                            ? const Icon(Icons.camera_alt, size: 30)
                            : null),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Tap to upload logo')),
            const SizedBox(height: 24),

            const Text(
              'Company Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Company Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteCtrl,
              decoration: const InputDecoration(labelText: 'Website'),
            ),

            const SizedBox(height: 24),
            const Text(
              'Payment Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankNameCtrl,
              decoration: const InputDecoration(labelText: 'Bank Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accNameCtrl,
              decoration: const InputDecoration(labelText: 'Account Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accNumCtrl,
              decoration: const InputDecoration(labelText: 'Account Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _momoCtrl,
              decoration: const InputDecoration(
                labelText: 'Mobile Money Details',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _termsCtrl,
              decoration: const InputDecoration(
                labelText: 'Standard Terms & Conditions',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
