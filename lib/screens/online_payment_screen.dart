part of '../main.dart';

class OnlinePaymentScreen extends StatelessWidget {
  const OnlinePaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingRouteScreen(
      data: OnboardingData(
        title: 'ONLINE PAYMENT',
        copy:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pharetra quam elementum massa, viverra. Ut turpis consectetur.',
        kind: IllustrationKind.payment,
        imagePath: 'assets/images/onboarding/online_payment.png',
      ),
      nextScreen: OnlineShoppingScreen(),
    );
  }
}

class OnlineShoppingScreen extends StatelessWidget {
  const OnlineShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingRouteScreen(
      data: OnboardingData(
        title: 'ONLINE SHOPPING',
        copy:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pharetra quam elementum massa, viverra. Ut turpis consectetur.',
        kind: IllustrationKind.shopping,
        imagePath: 'assets/images/onboarding/online_shopping.png',
      ),
      nextScreen: HomeDeliverServiceScreen(),
    );
  }
}

class HomeDeliverServiceScreen extends StatelessWidget {
  const HomeDeliverServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingRouteScreen(
      data: OnboardingData(
        title: 'HOME DELIVER SERVICE',
        copy:
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pharetra quam elementum massa, viverra. Ut turpis consectetur.',
        kind: IllustrationKind.delivery,
        imagePath: 'assets/images/onboarding/delivery_service.png',
      ),
      nextScreen: LoginScreen(),
    );
  }
}

class OnboardingRouteScreen extends StatelessWidget {
  const OnboardingRouteScreen({
    super.key,
    required this.data,
    required this.nextScreen,
  });

  final OnboardingData data;
  final Widget nextScreen;

  void _continue(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Stack(
        children: [
          _OnboardingPage(data),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 336,
              padding: const EdgeInsets.fromLTRB(28, 58, 28, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
              ),
              child: Column(
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 46),
                  Text(
                    data.copy,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _muted,
                      height: 1.45,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: const Text(
                          'Skip>>',
                          style: TextStyle(
                            color: _orange,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                      CircularArrowButton(onPressed: () => _continue(context)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage(this.data);

  final OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _teal,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 92, bottom: 336),
          child: Center(
            child: FigmaStyleIllustration(
              kind: data.kind,
              imagePath: data.imagePath,
            ),
          ),
        ),
      ),
    );
  }
}
