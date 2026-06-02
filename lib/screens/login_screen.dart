part of '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  var _loading = false;
  var _googleLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhoneNumber(String value) {
    final compact = value.replaceAll(RegExp(r'[\s()-]'), '');
    if (compact.startsWith('+')) return compact;

    final digits = compact.replaceAll(RegExp(r'\D'), '');
    return '+91$digits';
  }

  Future<void> _sendOtp() async {
    final phone = _normalizePhoneNumber(_phoneController.text);
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      _snack(context, 'Enter a valid phone number.');
      return;
    }

    setState(() => _loading = true);
    if (!FirebaseBootstrap.isReady) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(phoneNumber: phone, verificationId: null),
        ),
      );
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (error) {
        if (!mounted) return;
        setState(() => _loading = false);
        _snack(context, error.message ?? 'OTP verification failed.');
      },
      codeSent: (verificationId, _) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                OtpScreen(phoneNumber: phone, verificationId: verificationId),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await GoogleAuthService.signIn();
      if (!mounted) return;
      _snack(context, 'Google sign-in successful.');
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 760;
            return SingleChildScrollView(
              child: SizedBox(
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned(
                      left: -90,
                      top: -90,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD981).withValues(alpha: .35),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33FFD372),
                              blurRadius: 72,
                              spreadRadius: 40,
                            ),
                          ],
                        ),
                        child: const SizedBox.square(dimension: 150),
                      ),
                    ),
                    Positioned(
                      right: -80,
                      bottom: -80,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD981).withValues(alpha: .32),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33FFD372),
                              blurRadius: 72,
                              spreadRadius: 42,
                            ),
                          ],
                        ),
                        child: const SizedBox.square(dimension: 150),
                      ),
                    ),
                    Positioned(
                      top: 18,
                      right: 22,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: isCompact ? 46 : 58),
                            BrandLogo(size: isCompact ? 122 : 140),
                            SizedBox(height: isCompact ? 42 : 54),
                            const Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Login to continue',
                              style: TextStyle(fontSize: 21, color: _ink),
                            ),
                            SizedBox(height: isCompact ? 34 : 44),
                            SizedBox(
                              height: 64,
                              child: AppTextField(
                                controller: _phoneController,
                                hint: 'Phone Number',
                                icon: Icons.phone_android,
                                keyboardType: TextInputType.phone,
                                borderRadius: 17,
                                hintFontSize: 20,
                                iconSize: 22,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 19,
                                ),
                              ),
                            ),
                            const SizedBox(height: 38),
                            PrimaryButton(
                              label: _loading ? 'SENDING...' : 'GET OTP',
                              onPressed: _loading ? null : _sendOtp,
                              borderColor: const Color(0xFF169BFF),
                              borderWidth: 3,
                            ),
                            const Spacer(flex: 2),
                            const Text(
                              'Or Continue With',
                              style: TextStyle(fontSize: 16, color: _ink),
                            ),
                            const SizedBox(height: 34),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SocialButton(
                                  icon: 'G',
                                  assetPath: 'assets/images/icons/google.png',
                                  label: _googleLoading
                                      ? 'Signing...'
                                      : 'Google',
                                  isEnabled: !_googleLoading,
                                  onPressed: _signInWithGoogle,
                                  width: 122,
                                  height: 72,
                                  logoSize: 26,
                                  labelFontSize: 16,
                                ),
                                const SizedBox(width: 24),
                                const SocialButton(
                                  icon: 'f',
                                  assetPath: 'assets/images/icons/facebook.png',
                                  label: 'Facebook',
                                  width: 122,
                                  height: 72,
                                  logoSize: 26,
                                  labelFontSize: 16,
                                ),
                              ],
                            ),
                            const Spacer(flex: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: _muted, fontSize: 15),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'SIGN UP',
                                    style: TextStyle(
                                      color: _teal,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
