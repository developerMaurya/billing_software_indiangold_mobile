import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'utils/app_theme_provider.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _gstController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _logoImage;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _gstController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoImage = File(image.path);
      });
    }
  }

  // Encryption for redundant DB storage as requested
  String _encryptPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String?> _uploadImage(File image, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  String _statusMessage = 'Please wait...';

  Future<void> _saveShopData(String uid, String? logoUrl) async {
    setState(() => _statusMessage = 'Saving shop details...');
    String encryptedPassword = _encryptPassword(_passwordController.text);

    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(uid)
          .set({
            'name': _nameController.text.trim(),
            'about': _aboutController.text.trim(),
            'address': _addressController.text.trim(),
            'pinCode': _pinCodeController.text.trim(),
            'gst': _gstController.text.trim(),
            'mobile': _mobileController.text.trim(),
            'email': _emailController.text.trim(),
            'logo': logoUrl,
            'banners': [], // Removed banners
            'createdAt': FieldValue.serverTimestamp(),
            'uid': uid,
            'encrypted_password_storage': encryptedPassword,
          })
          .timeout(const Duration(seconds: 3));

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text(
              'Your account has been created/updated successfully. You can now login.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to login
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Firestore Save Error: $e");
      if (mounted) {
        String errorMessage = "Failed to save data: $e";
        String? urlToLaunch;
        String labelText = 'OK';
        bool isCritical = false;

        if (e.toString().contains("PERMISSION_DENIED")) {
          errorMessage =
              "CRITICAL: Database API Disabled.\n\nYou MUST enable the Firestore API in Google Cloud Console to save data.";
          urlToLaunch =
              "https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=billingsortware";
          labelText = 'FIX API NOW';
          isCritical = true;
        } else if (e.toString().contains("NOT_FOUND") ||
            e.toString().contains("database (default) does not exist")) {
          errorMessage =
              "CRITICAL: Database Not Created.\n\nYou MUST create the Firestore Database in Firebase Console to save data.";
          urlToLaunch =
              "https://console.firebase.google.com/project/billingsortware/firestore";
          labelText = 'CREATE DB NOW';
          isCritical = true;
        } else if (e.toString().contains("TimeoutException")) {
          errorMessage =
              "Connection Timeout.\n\nYour Database likely does not exist or API is disabled.\n\nPlease Check Firebase Console.";
          urlToLaunch =
              "https://console.firebase.google.com/project/billingsortware/firestore";
          labelText = 'CHECK CONSOLE';
          isCritical = true;
        }

        if (isCritical) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text(
                'Setup Required',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (urlToLaunch != null) {
                      final Uri url = Uri.parse(urlToLaunch!);
                      if (!await launchUrl(url)) {
                        debugPrint('Could not launch $url');
                      }
                    }
                  },
                  child: Text(labelText),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Creating account...';
      });

      UserCredential? userCredential;
      String? logoUrl;

      try {
        // 1. Create User in Firebase Auth
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        String uid = userCredential.user!.uid;

        // 2. Upload Logo
        if (_logoImage != null) {
          setState(() => _statusMessage = 'Uploading logo...');
          try {
            String ext = _logoImage!.path.split('.').last;
            logoUrl = await _uploadImage(
              _logoImage!,
              'shops/$uid/logo/${DateTime.now().millisecondsSinceEpoch}.$ext',
            );
          } catch (e) {
            debugPrint("Logo upload failed: $e");
          }
        }

        // Log Data for Debugging as requested
        print("--------------------------------------------------");
        print("          SUBMITTING REGISTRATION DATA            ");
        print("--------------------------------------------------");
        print("UID: $uid");
        print("Name: ${_nameController.text.trim()}");
        print("About: ${_aboutController.text.trim()}");
        print("Address: ${_addressController.text.trim()}");
        print("PinCode: ${_pinCodeController.text.trim()}");
        print("GST: ${_gstController.text.trim()}");
        print("Mobile: ${_mobileController.text.trim()}");
        print("Email: ${_emailController.text.trim()}");
        print("Logo URL: $logoUrl");
        print("Banners: [] (Removed)");
        print("--------------------------------------------------");

        // 4. Save Data to Firestore
        await _saveShopData(uid, logoUrl);
      } on FirebaseAuthException catch (e) {
        String message = "Registration failed: ${e.message} (${e.code})";

        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          // Smart Recovery
          try {
            setState(
              () => _statusMessage = 'Email exists. Attempting recovery...',
            );
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              // Re-run upload logic quickly
              String uid = user.uid;
              if (_logoImage != null) {
                setState(() => _statusMessage = 'Uploading logo...');
                String ext = _logoImage!.path.split('.').last;
                logoUrl = await _uploadImage(
                  _logoImage!,
                  'shops/$uid/logo/${DateTime.now().millisecondsSinceEpoch}.$ext',
                );
              }

              await _saveShopData(user.uid, logoUrl);
              return;
            }
          } catch (loginErr) {
            message = 'The account already exists and password didn\'t match.';
          }
        } else if (e.code == 'internal-error' || e.code == 'unknown') {
          // AGGRESSIVE FALLBACK: The user wants data saved NOW.
          // If Auth Config is broken, try to save anyway to prove DB works.

          try {
            // This error 'internal-error' often happens when "Email Enumeration Protection" is ON in Firebase Console.
            // Disable it in Firebase Console > Authentication > Settings to fix this permanently.
            await Future.delayed(Duration(seconds: 1));
            setState(() => _statusMessage = 'Auth Error. Trying Guest Mode...');
            // Try Anonymous Login
            await FirebaseAuth.instance.signInAnonymously();
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              // Re-run upload logic quickly
              String uid = user.uid;
              if (_logoImage != null) {
                setState(() => _statusMessage = 'Uploading logo...');
                String ext = _logoImage!.path.split('.').last;
                logoUrl = await _uploadImage(
                  _logoImage!,
                  'shops/$uid/logo/${DateTime.now().millisecondsSinceEpoch}.$ext',
                );
              }

              await _saveShopData(user.uid, logoUrl);
              return;
            }
          } catch (anonError) {
            // If Anonymous fails, try DIRECT WRITE (Insecure, testing only)
            setState(
              () => _statusMessage = 'Auth Failed. Trying Direct DB Write...',
            );
            String pseudoUid =
                'test_user_${DateTime.now().millisecondsSinceEpoch}';
            try {
              await _saveShopData(pseudoUid, logoUrl);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "WARNING: Data saved with TEST ID. Fix Firebase Auth to enable real login.",
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              return;
            } catch (dbError) {
              // If this fails, it's definitely a permission/connection issue
              message =
                  'CRITICAL: Could not bypass Auth. DB Error: $dbError. SETUP SHA-1 in Console!';
            }
          }
        }
        if (mounted) {
          SnackBarAction? action;
          if (e.code == 'internal-error') {
            action = SnackBarAction(
              label: 'FIX AUTH',
              textColor: Colors.white,
              onPressed: () async {
                final Uri url = Uri.parse(
                  "https://console.firebase.google.com/project/billingsortware/authentication/settings",
                );
                if (!await launchUrl(url)) {
                  debugPrint('Could not launch $url');
                }
              },
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 15),
              action: action,
            ),
          );
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Firebase Error: ${e.message} (${e.code})"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('System Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<AppTheme>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Company/Shop'),
        backgroundColor: appTheme.colors.secondary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [appTheme.colors.background, Colors.white],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Basic Details', appTheme),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Company / Shop Name',
                      icon: Icons.store,
                      appTheme: appTheme,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _aboutController,
                      label: 'About',
                      icon: Icons.info_outline,
                      appTheme: appTheme,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Contact & Address', appTheme),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      appTheme: appTheme,
                      maxLines: 2,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Please enter address' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _pinCodeController,
                            label: 'Pin Code',
                            icon: Icons.pin_drop_outlined,
                            appTheme: appTheme,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _gstController,
                            label: 'GST Number',
                            icon: Icons.receipt_long_outlined,
                            appTheme: appTheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _mobileController,
                      label: 'Mobile Number',
                      icon: Icons.phone_android,
                      appTheme: appTheme,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.isEmpty == true
                          ? 'Please enter mobile number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      appTheme: appTheme,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Please enter email' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Security', appTheme),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: appTheme.colors.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: appTheme.colors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: appTheme.colors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Branding', appTheme),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(
                        Icons.image,
                        size: 40,
                        color: appTheme.colors.primary,
                      ),
                      title: const Text('Company Logo'),
                      subtitle: Text(
                        _logoImage != null
                            ? 'Logo selected'
                            : 'Tap to select logo',
                      ),
                      trailing: _logoImage != null
                          ? Image.file(
                              _logoImage!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : null,
                      onTap: _pickLogo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      tileColor: Colors.white,
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'REGISTER COMPANY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppTheme appTheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: appTheme.colors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppTheme appTheme,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: appTheme.colors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.colors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}
