import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ppkd_attendance_app/data/repositories/auth_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthRepository repo = AuthRepository();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  File? selectedImage;
  String? profilePhotoUrl;
  final ImagePicker picker = ImagePicker();
  bool isLoading = false;

  Future<void> loadProfile() async {
    setState(() => isLoading = true);

    try {
      final res = await repo.getProfile();
      final data = res['data'];

      nameController.text = data['name'] ?? '';
      phoneController.text = data['phone'] ?? data['no_hp'] ?? '';
      emailController.text = data['email'] ?? '';
      profilePhotoUrl =
          data['profile_photo_url'] ??
          (data['profile_photo'] != null
              ? "https://appabsensi.mobileprojp.com/public/${data['profile_photo']}"
              : null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal load profile')));
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() {
      selectedImage = File(image.path);
    });

    await uploadImage();
  }

  Future<void> uploadImage() async {
    if (selectedImage == null) return;

    setState(() => isLoading = true);

    try {
      final bytes = await selectedImage!.readAsBytes();
      String base64Image = base64Encode(bytes);

      // IMPORTANT: format sesuai API
      base64Image = "data:image/png;base64,$base64Image";

      final res = await repo.updatePhoto(base64Image);

      if (mounted) {
        setState(() {
          profilePhotoUrl = res['data']['profile_photo'];
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload foto gagal')));
    }

    setState(() => isLoading = false);
  }

  void showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Kamera"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Galeri"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> handleUpdate() async {
    setState(() => isLoading = true);

    try {
      final res = await repo.updateProfile(
        nameController.text,
        emailController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Profile updated')),
        );
        Navigator.pop(context, true); // return true biar profile page refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal update profile')));
      }
    }

    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4ED26),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ── Background layers ──────────────────────────────
                Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.25,
                      color: const Color(0xFF5B8DEF),
                    ),
                    Expanded(child: Container(color: const Color(0xFFD4ED26))),
                  ],
                ),

                ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.55,
                    color: const Color(0xFF2D3250),
                  ),
                ),

                // ── Content ────────────────────────────────────────
                SafeArea(
                  child: Column(
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Avatar
                      GestureDetector(
                        onTap: showImagePicker,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5C518),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: selectedImage != null
                                ? Image.file(selectedImage!, fit: BoxFit.cover)
                                : (profilePhotoUrl != null &&
                                      profilePhotoUrl!.isNotEmpty)
                                ? Image.network(
                                    profilePhotoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF2D3250),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Form card
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama
                                _buildTextField(
                                  controller: nameController,
                                  label: 'Nama',
                                ),

                                const SizedBox(height: 16),

                                // Email (disabled, read-only)
                                _buildTextField(
                                  controller: emailController,
                                  label: 'Email',
                                  enabled: false,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                const SizedBox(height: 24),

                                // Done button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : handleUpdate,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5B8DEF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Done',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF5B8DEF)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.95,
      size.width,
      size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}
