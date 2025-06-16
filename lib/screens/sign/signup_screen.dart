import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  final String userType;

  const SignUpScreen({super.key, required this.userType});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final companyNameController = TextEditingController();
  final officeNameController = TextEditingController();
  final officeCapacityController = TextEditingController();

  bool get areFieldsFilled {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) return false;

    if (widget.userType == 'Company') {
      return companyNameController.text.trim().isNotEmpty;
    }

    if (widget.userType == 'Office') {
      return officeNameController.text.trim().isNotEmpty &&
          officeCapacityController.text.trim().isNotEmpty;
    }

    return true;
  }

  void _addListeners() {
    final controllers = [
      fullNameController,
      emailController,
      passwordController,
      companyNameController,
      officeNameController,
      officeCapacityController,
    ];
    for (var c in controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void initState() {
    super.initState();
    _addListeners();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    companyNameController.dispose();
    officeNameController.dispose();
    officeCapacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: null,
      body: Column(
        children: [
          // AppBar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
                  color: AppColors.accent,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Card(
                          elevation: 8,
                          shadowColor: AppColors.shadow,
                          color: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Image.asset(
                                    'assets/logoo.png',
                                    height: 80,
                                  ),
                                ),
                                Text(
                                  'Create a ${widget.userType} Account',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  label: 'Full Name',
                                  icon: Icons.person,
                                  controller: fullNameController,
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                  label: 'Email',
                                  icon: Icons.email,
                                  controller: emailController,
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                  label: 'Password',
                                  icon: Icons.lock,
                                  controller: passwordController,
                                  obscure: true,
                                ),
                                const SizedBox(height: 15),

                                if (widget.userType == 'Company')
                                  _buildTextField(
                                    label: 'Company Name',
                                    icon: Icons.business,
                                    controller: companyNameController,
                                  ),

                                if (widget.userType == 'Office') ...[
                                  _buildTextField(
                                    label: 'Office Name',
                                    icon: Icons.apartment,
                                    controller: officeNameController,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildTextField(
                                    label: 'Office Capacity',
                                    icon: Icons.group,
                                    controller: officeCapacityController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],

                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          areFieldsFilled
                                              ? AppColors.accent
                                              : AppColors.primary.withOpacity(
                                                0.5,
                                              ),
                                      foregroundColor:
                                          areFieldsFilled
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SignInScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('Sign Up'),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignInScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Already have an account? Sign In',
                                    style: TextStyle(color: AppColors.accent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.accent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textPrimary),
    );
  }
}
