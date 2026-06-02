part of '../main.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  final String phoneNumber;
  final String? verificationId;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _otpLength = 6;

  final _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  var _loading = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controllers.map((e) => e.text).join();
    if (code.length != _otpLength) {
      _snack(context, 'Enter the 6-digit verification code.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (FirebaseBootstrap.isReady && widget.verificationId != null) {
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId!,
          smsCode: code,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _snack(context, error.message ?? 'Could not verify OTP.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 42, 28, 0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton(
                  icon: Icons.chevron_left,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 56),
              const Text(
                'OTP Verification',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              const Text(
                'Enter the verification code we just sent to your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8D9AAD), fontSize: 14),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _otpLength,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 42,
                      height: 54,
                      child: Focus(
                        onKeyEvent: (_, event) {
                          if (event is! KeyDownEvent ||
                              event.logicalKey !=
                                  LogicalKeyboardKey.backspace ||
                              _controllers[index].text.isNotEmpty ||
                              index == 0) {
                            return KeyEventResult.ignored;
                          }

                          _focusNodes[index - 1].requestFocus();
                          _controllers[index - 1].clear();
                          return KeyEventResult.handled;
                        },
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          decoration: _otpInputDecoration(),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < _otpLength - 1) {
                              _focusNodes[index + 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              PrimaryButton(
                label: _loading ? 'VERIFYING...' : 'VERIFY',
                onPressed: _loading ? null : _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _otpInputDecoration() {
  return InputDecoration(
    counterText: '',
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.zero,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _teal, width: 1.4),
    ),
  );
}
