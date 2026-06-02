part of '../main.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatController = TextEditingController();
  final _phoneController = TextEditingController();
  var _loading = false;
  var _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final repeated = _repeatController.text.trim();
    final phone = _phoneController.text.trim();

    if (!email.contains('@') || password.length < 6 || password != repeated) {
      _snack(context, 'Check your email and passwords.');
      return;
    }

    setState(() => _loading = true);
    try {
      User? user;
      if (FirebaseBootstrap.isReady) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        user = credential.user;
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).set(
          {
            'email': email,
            'phone': phone,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }

      if (!mounted) return;
      _snack(context, 'Sign-up details saved successfully.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _snack(context, error.message ?? 'Could not create account.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await GoogleAuthService.signIn();
      if (!mounted) return;
      _snack(context, 'Google sign-in details saved successfully.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _snack(context, error.message ?? 'Google sign-in failed.');
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      _snack(context, error.description ?? 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 92, 26, 28),
          child: Column(
            children: [
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              const Text('Sign Up', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 78),
              AppTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 22),
              AppTextField(
                controller: _passwordController,
                hint: 'Special Characters',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 22),
              AppTextField(
                controller: _repeatController,
                hint: 'Repeat Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 22),
              AppTextField(
                controller: _phoneController,
                hint: 'Mobile Number',
                icon: Icons.flag_circle,
                prefixText: '+244  ',
                keyboardType: TextInputType.phone,
              ),
              const Spacer(),
              PrimaryButton(
                label: _loading ? 'SAVING...' : 'NEXT',
                onPressed: _loading ? null : _createAccount,
              ),
              const SizedBox(height: 34),
              const Text(
                'Or Continue With',
                style: TextStyle(fontSize: 12, color: _ink),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SocialButton(icon: 'Apple', label: 'Apple'),
                  const SizedBox(width: 12),
                  SocialButton(
                    icon: 'G',
                    label: _googleLoading ? 'Signing...' : 'Google',
                    isEnabled: !_googleLoading,
                    onPressed: _signInWithGoogle,
                  ),
                  const SizedBox(width: 12),
                  const SocialButton(icon: 'f', label: 'Facebook'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
