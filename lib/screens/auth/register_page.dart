import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import '../../models/user_model.dart';
import '../../utils/encryption.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = UserModel(
          username: _username.text.trim(),
          email: _email.text.trim(),
          password: encryptPassword(_password.text),
        );

        await DatabaseHelper.instance.insertUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Akun berhasil dibuat! Silakan login.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 800));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Gagal membuat akun: Email sudah terdaftar'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Back Button dengan style
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header dengan sedikit aksen
              _buildHeader(),
              const SizedBox(height: 40),

              // Form dengan container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3B82F6).withOpacity(0.08),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildUsernameField(),
                      const SizedBox(height: 20),
                      _buildEmailField(),
                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      const SizedBox(height: 24),
                      _buildRegisterButton(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login Link dengan container
              _buildLoginSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icon dengan gradient
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Bergabung dengan Remedify",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Buat akun untuk mulai menggunakan",
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _username,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Username',
        labelStyle: TextStyle(color: Color(0xFF6B7280)),
        prefixIcon: Icon(Icons.person_outline, color: Color(0xFF3B82F6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFFF8FAFC),
      ),
      validator: (val) => val!.isEmpty ? 'Username tidak boleh kosong' : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: Color(0xFF6B7280)),
        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF3B82F6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFFF8FAFC),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Email tidak boleh kosong';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
          return 'Format email tidak valid';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _password,
      obscureText: _obscurePassword,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Color(0xFF6B7280)),
        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF3B82F6)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Color(0xFF6B7280),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFFF8FAFC),
      ),
      validator: (val) => val!.isEmpty ? 'Password tidak boleh kosong' : null,
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Color(0xFF3B82F6).withOpacity(0.3),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DAFTAR SEKARANG',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Sudah punya akun? ",
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              "Login Sekarang",
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
