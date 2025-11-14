// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inward_outward_management/providers/auth_provider.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_logo.dart';
import 'package:inward_outward_management/widgets/rounded_textfield.dart';
import 'package:inward_outward_management/widgets/role_selector.dart';
import 'package:inward_outward_management/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  final _passwordCtr = TextEditingController();
  String _role = 'Company'; // default selection

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  /// Submit registration form
  /// - Basic validation
  /// - Calls AuthProvider.registerWithEmail which writes Firestore users doc
  /// - After success fetches cached role and navigates to appropriate dashboard
  Future<void> _submit() async {
    final name = _nameCtr.text.trim();
    final email = _emailCtr.text.trim();
    final password = _passwordCtr.text;

    if (name.isEmpty) return _showSnack('Please enter full name');
    if (!email.contains('@')) return _showSnack('Enter valid email');
    if (password.length < 6)
      return _showSnack('Password must be at least 6 chars');

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // call provider to register; provider handles role/companyId caching
    final success = await auth.registerWithEmail(
      name: name,
      email: email,
      password: password,
      role: _role,
    );

    if (!success) {
      _showSnack(auth.error ?? 'Registration failed');
      return;
    }

    // Ensure provider fetched/stored role/companyId
    // This helps RoleRouter or direct routing to work reliably.
    await auth.fetchUserRole();

    // Route user to the correct dashboard using cached role
    final userRole = auth.currentUserRole?.toLowerCase();
    if (userRole == null) {
      // fallback to roleRouter if something went wrong
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/roleRouter');
      return;
    }

    if (!mounted) return;

    switch (userRole) {
      case 'company':
        Navigator.of(context).pushReplacementNamed('/companyDashboard');
        break;
      case 'supplier':
        Navigator.of(context).pushReplacementNamed('/supplierDashboard');
        break;
      case 'customer':
        Navigator.of(context).pushReplacementNamed('/customerDashboard');
        break;
      default:
        Navigator.of(context).pushReplacementNamed('/roleRouter');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF28343A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: r.wp(6), vertical: r.hp(4)),
          child: Column(
            children: [
              AppLogo(assetPath: 'assets/images/logo.png', diameterPercent: 18),
              SizedBox(height: r.hp(3)),
              Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.sp(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: r.hp(1)),
              Text(
                'Join to streamline your business flow.',
                style: TextStyle(fontSize: r.sp(11), color: Colors.white70),
              ),
              SizedBox(height: r.hp(4)),
              RoundedTextField(
                controller: _nameCtr,
                hint: 'Full Name',
                prefixIcon: const Icon(Icons.person),
              ),
              SizedBox(height: r.hp(2)),
              RoundedTextField(
                controller: _emailCtr,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email),
              ),
              SizedBox(height: r.hp(2)),
              RoundedTextField(
                controller: _passwordCtr,
                hint: 'Password',
                obscure: true,
                prefixIcon: const Icon(Icons.lock),
              ),
              SizedBox(height: r.hp(2)),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'I am a:',
                  style: TextStyle(fontSize: r.sp(11), color: Colors.white70),
                ),
              ),
              SizedBox(height: r.hp(1)),
              // RoleSelector UI is unchanged; it calls setState on selection
              RoleSelector(
                selectedRole: _role,
                onSelected: (val) => setState(() => _role = val),
              ),
              SizedBox(height: r.hp(3)),
              if (auth.error != null) ...[
                Text(auth.error!, style: const TextStyle(color: Colors.red)),
                SizedBox(height: r.hp(1)),
              ],
              PrimaryButton(
                label: 'Register',
                onTap: _submit,
                loading: auth.loading,
              ),
              SizedBox(height: r.hp(2)),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text(
                  'Already have an account? Log In',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
