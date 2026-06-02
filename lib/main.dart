import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

part 'screens/splash_screen.dart';
part 'screens/online_payment_screen.dart';
part 'screens/login_screen.dart';
part 'screens/otp_screen.dart';
part 'screens/signup_screen.dart';
part 'screens/home_screen.dart';

const _teal = Color(0xFF25A4B8);
const _orange = Color(0xFFFFA300);
const _ink = Color(0xFF181B24);
const _muted = Color(0xFF8C91A3);
const _line = Color(0xFFEDEEF3);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await FirebaseBootstrap.init();
  runApp(const MyApp());
}

class FirebaseBootstrap {
  static bool isReady = false;

  static Future<void> init() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (options.projectId.startsWith('REPLACE_')) {
        return;
      }
      await Firebase.initializeApp(options: options);
      isReady = true;
    } catch (_) {
      isReady = false;
    }
  }
}

class GoogleAuthService {
  static const _webClientId =
      '892513363343-pfqehe25tm698q8rno3u5pdm1c4bu1bn.apps.googleusercontent.com';
  static bool _initialized = false;

  static Future<UserCredential> signIn() async {
    if (!FirebaseBootstrap.isReady) {
      throw FirebaseException(
        plugin: 'firebase_core',
        message: 'Firebase is not configured yet.',
      );
    }

    final googleSignIn = GoogleSignIn.instance;
    if (!_initialized) {
      await googleSignIn
          .initialize(serverClientId: _webClientId)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw FirebaseAuthException(
              code: 'google-init-timeout',
              message: 'Google Sign-In setup timed out. Please try again.',
            ),
          );
      _initialized = true;
    }

    if (!googleSignIn.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'unsupported-platform',
        message: 'Google Sign-In is not supported on this platform.',
      );
    }

    final googleUser = await googleSignIn.authenticate().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw FirebaseAuthException(
        code: 'google-auth-timeout',
        message: 'Google Sign-In timed out. Please try again.',
      ),
    );
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw FirebaseAuthException(
            code: 'firebase-google-timeout',
            message: 'Firebase login timed out. Please try again.',
          ),
        );
    final user = userCredential.user;

    if (user != null) {
      unawaited(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'email': user.email,
              'name': user.displayName,
              'photoUrl': user.photoURL,
              'provider': 'google',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .catchError((_) {}),
      );
    }

    return userCredential;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LuxeLoft',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _teal),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class HomeRepository {
  Stream<HomeContent> watchHome() {
    if (!FirebaseBootstrap.isReady) {
      return Stream.value(HomeContent.sample());
    }

    final db = FirebaseFirestore.instance;
    return db
        .collection('home')
        .doc('content')
        .snapshots()
        .asyncMap((homeDoc) async {
          final categoriesSnapshot = await db.collection('categories').get();
          final productsSnapshot = await db.collection('products').get();
          return HomeContent.fromFirestore(
            homeDoc.data(),
            categoriesSnapshot.docs.map((doc) => doc.data()).toList(),
            productsSnapshot.docs.map((doc) => doc.data()).toList(),
          );
        })
        .handleError((_) => HomeContent.sample());
  }
}

class HomeContent {
  const HomeContent({
    required this.greeting,
    required this.bannerTitle,
    required this.bannerSubtitle,
    required this.categories,
    required this.products,
  });

  final String greeting;
  final String bannerTitle;
  final String bannerSubtitle;
  final List<CategoryItem> categories;
  final List<ProductItem> products;

  factory HomeContent.fromFirestore(
    Map<String, dynamic>? home,
    List<Map<String, dynamic>> categoryDocs,
    List<Map<String, dynamic>> productDocs,
  ) {
    final sample = HomeContent.sample();
    return HomeContent(
      greeting: home?['greeting'] as String? ?? sample.greeting,
      bannerTitle: home?['bannerTitle'] as String? ?? sample.bannerTitle,
      bannerSubtitle:
          home?['bannerSubtitle'] as String? ?? sample.bannerSubtitle,
      categories: categoryDocs.isEmpty
          ? sample.categories
          : categoryDocs.map(CategoryItem.fromMap).toList(),
      products: productDocs.isEmpty
          ? sample.products
          : productDocs
                .map(ProductItem.fromMap)
                .where((item) => !_hiddenProductNames.contains(item.name))
                .toList(),
    );
  }

  factory HomeContent.sample() => const HomeContent(
    greeting: 'Hi, Andrea',
    bannerTitle: 'JUST FOR you',
    bannerSubtitle: '30% OFF',
    categories: [
      CategoryItem(
        'Beauty',
        Icons.brush,
        imagePath: 'assets/images/categories/beauty.png',
      ),
      CategoryItem(
        'Offers',
        Icons.local_offer,
        imagePath: 'assets/images/categories/offers.png',
      ),
      CategoryItem(
        'Fashion',
        Icons.checkroom,
        imagePath: 'assets/images/categories/fashion.png',
      ),
      CategoryItem(
        'Home',
        Icons.chair,
        imagePath: 'assets/images/categories/home.png',
      ),
      CategoryItem(
        'Shirt',
        Icons.dry_cleaning,
        imagePath: 'assets/images/categories/shirt.png',
      ),
      CategoryItem(
        'Woman Bag',
        Icons.shopping_bag,
        imagePath: 'assets/images/categories/woman_bag.png',
      ),
      CategoryItem(
        'Dress',
        Icons.woman,
        imagePath: 'assets/images/categories/dress.png',
      ),
      CategoryItem(
        'Mobiles',
        Icons.phone_iphone,
        imagePath: 'assets/images/categories/mobiles.png',
      ),
    ],
    products: [
      ProductItem(
        'Multi Kit',
        500,
        4.6,
        86,
        Icons.spa,
        imagePath: 'assets/images/products/multi_kit.png',
        cardImagePath: 'assets/images/products/multi_kit.png',
      ),
      ProductItem(
        'Lipstick',
        400,
        4.6,
        86,
        Icons.colorize,
        imagePath: 'assets/images/products/lipstick.png',
        cardImagePath: 'assets/images/products/lipstick.png',
      ),
    ],
  );
}

const _hiddenProductNames = {'Skin Care', 'Hand Bag'};

class CategoryItem {
  const CategoryItem(this.name, this.icon, {this.imagePath});

  final String name;
  final IconData icon;
  final String? imagePath;

  factory CategoryItem.fromMap(Map<String, dynamic> data) {
    return CategoryItem(
      data['name'] as String? ?? 'Category',
      _iconFor(data['icon'] as String?),
      imagePath: data['imagePath'] as String?,
    );
  }
}

class ProductItem {
  const ProductItem(
    this.name,
    this.price,
    this.rating,
    this.reviews,
    this.icon, {
    this.imagePath,
    this.cardImagePath,
  });

  final String name;
  final num price;
  final num rating;
  final int reviews;
  final IconData icon;
  final String? imagePath;
  final String? cardImagePath;

  factory ProductItem.fromMap(Map<String, dynamic> data) {
    return ProductItem(
      data['name'] as String? ?? 'Product',
      data['price'] as num? ?? 0,
      data['rating'] as num? ?? 4.6,
      data['reviews'] as int? ?? 0,
      _iconFor(data['icon'] as String?),
      imagePath: data['imagePath'] as String?,
      cardImagePath: data['cardImagePath'] as String?,
    );
  }
}

IconData _iconFor(String? value) {
  switch (value) {
    case 'offer':
      return Icons.local_offer;
    case 'fashion':
      return Icons.checkroom;
    case 'home':
      return Icons.chair;
    case 'bag':
      return Icons.shopping_bag;
    case 'phone':
      return Icons.phone_iphone;
    case 'lipstick':
      return Icons.colorize;
    case 'beauty':
    default:
      return Icons.brush;
  }
}

class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: child,
        ),
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

enum IllustrationKind { payment, shopping, delivery }

class OnboardingData {
  const OnboardingData({
    required this.title,
    required this.copy,
    required this.kind,
    this.imagePath,
  });

  final String title;
  final String copy;
  final IllustrationKind kind;
  final String? imagePath;
}

class FigmaStyleIllustration extends StatelessWidget {
  const FigmaStyleIllustration({super.key, required this.kind, this.imagePath});

  final IllustrationKind kind;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final assetPath = imagePath;
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: 300,
        height: 260,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _PaintedIllustration(kind: kind),
      );
    }

    return _PaintedIllustration(kind: kind);
  }
}

class _PaintedIllustration extends StatelessWidget {
  const _PaintedIllustration({required this.kind});

  final IllustrationKind kind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 260,
      child: CustomPaint(painter: _IllustrationPainter(kind)),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter(this.kind);

  final IllustrationKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFF243746);
    final yellow = Paint()..color = const Color(0xFFFFCB22);
    final cream = Paint()..color = const Color(0xFFFFF4BD);
    final white = Paint()..color = Colors.white;
    final shadow = Paint()..color = const Color(0x44243746);

    canvas.drawOval(
      Rect.fromLTWH(size.width * .08, size.height * .82, size.width * .84, 24),
      Paint()..color = Colors.white.withValues(alpha: .22),
    );

    if (kind == IllustrationKind.delivery) {
      canvas.drawRect(Rect.fromLTWH(164, 78, 72, 122), white);
      canvas.drawRect(Rect.fromLTWH(176, 92, 18, 28), dark);
      canvas.drawRect(Rect.fromLTWH(206, 92, 18, 28), dark);
      canvas.drawRect(Rect.fromLTWH(176, 132, 18, 28), dark);
      canvas.drawRect(Rect.fromLTWH(206, 132, 18, 28), dark);
      canvas.drawRect(Rect.fromLTWH(226, 124, 54, 76), yellow);
      canvas.drawCircle(const Offset(74, 202), 24, dark);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(58, 168, 138, 34),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFF5D7A84),
      );
      canvas.drawRect(Rect.fromLTWH(78, 136, 48, 34), yellow);
      canvas.drawCircle(const Offset(194, 202), 24, dark);
      canvas.drawCircle(const Offset(74, 202), 12, white);
      canvas.drawCircle(const Offset(194, 202), 12, white);
      canvas.drawCircle(const Offset(210, 64), 8, yellow);
      canvas.drawCircle(const Offset(248, 76), 11, yellow);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(96, 58, 76, 150),
          const Radius.circular(16),
        ),
        dark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(104, 66, 60, 134),
          const Radius.circular(10),
        ),
        cream,
      );
      canvas.drawCircle(
        Offset(134, 138),
        28,
        kind == IllustrationKind.payment ? dark : yellow,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(178, 48, 84, 160),
          const Radius.circular(16),
        ),
        dark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(186, 56, 68, 144),
          const Radius.circular(10),
        ),
        cream,
      );
      if (kind == IllustrationKind.payment) {
        canvas.drawCircle(const Offset(220, 126), 34, dark);
        _text(canvas, 'KZ', const Offset(204, 136), Colors.white, 18);
        canvas.drawCircle(const Offset(130, 114), 12, white);
        canvas.drawRect(Rect.fromLTWH(116, 152, 36, 18), yellow);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(186, 54, 84, 30),
            const Radius.circular(6),
          ),
          white,
        );
        canvas.drawRect(Rect.fromLTWH(198, 95, 20, 20), yellow);
        canvas.drawRect(Rect.fromLTWH(226, 95, 20, 20), yellow);
        canvas.drawRect(Rect.fromLTWH(198, 126, 20, 20), yellow);
        canvas.drawPath(
          Path()
            ..moveTo(152, 170)
            ..lineTo(236, 156)
            ..lineTo(226, 205)
            ..lineTo(166, 205)
            ..close(),
          Paint()
            ..color = Colors.transparent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawCircle(const Offset(76, 116), 12, dark);
      canvas.drawRect(Rect.fromLTWH(68, 128, 28, 86), yellow);
      canvas.drawCircle(
        const Offset(76, 98),
        12,
        const Color(0xFF8B4F3E).asPaint(),
      );
    }
    canvas.drawCircle(Offset(size.width * .52, size.height * .85), 5, shadow);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension on Color {
  Paint asPaint() => Paint()..color = this;
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.prefixText,
    this.borderRadius,
    this.hintFontSize,
    this.iconSize,
    this.contentPadding,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? prefixText;
  final double? borderRadius;
  final double? hintFontSize;
  final double? iconSize;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration:
          _inputDecoration(
            borderRadius: borderRadius,
            hintFontSize: hintFontSize,
            contentPadding: contentPadding,
          ).copyWith(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: iconSize ?? 18,
              color: const Color(0xFFCFD3DD),
            ),
            prefixText: prefixText,
            suffixIcon: obscureText
                ? const Icon(
                    Icons.visibility_off_outlined,
                    size: 18,
                    color: Color(0xFFCFD3DD),
                  )
                : null,
          ),
    );
  }
}

InputDecoration _inputDecoration({
  double? borderRadius,
  double? hintFontSize,
  EdgeInsetsGeometry? contentPadding,
}) {
  final radius = BorderRadius.circular(borderRadius ?? 14);
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintStyle: TextStyle(
      color: const Color(0xFFC7C9D1),
      fontSize: hintFontSize ?? 14,
    ),
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: _line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: _teal, width: 1.4),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _teal,
          disabledBackgroundColor: _teal.withValues(alpha: .55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: borderWidth > 0
                ? BorderSide(color: borderColor ?? _teal, width: borderWidth)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(backgroundColor: const Color(0xFFE9F7FA)),
        icon: Icon(icon, color: _teal, size: 28),
      ),
    );
  }
}

class CircularArrowButton extends StatelessWidget {
  const CircularArrowButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 58,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 3),
          shadowColor: Colors.black26,
          elevation: 5,
        ),
        icon: const Icon(Icons.arrow_forward, size: 28),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.assetPath,
    this.onPressed,
    this.isEnabled = true,
    this.width = 92,
    this.height = 58,
    this.logoSize = 22,
    this.labelFontSize = 11,
  });

  final String icon;
  final String label;
  final String? assetPath;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double width;
  final double height;
  final double logoSize;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed ?? () {} : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: _line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: .10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialLogo(icon: icon, assetPath: assetPath, size: logoSize),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(color: _ink, fontSize: labelFontSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLogo extends StatelessWidget {
  const _SocialLogo({
    required this.icon,
    required this.assetPath,
    required this.size,
  });

  final String icon;
  final String? assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path != null) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _FallbackSocialLogo(icon: icon, size: size),
      );
    }

    return _FallbackSocialLogo(icon: icon, size: size);
  }
}

class _FallbackSocialLogo extends StatelessWidget {
  const _FallbackSocialLogo({required this.icon, required this.size});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (icon == 'f') {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF1877F2),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * .82,
            fontWeight: FontWeight.w900,
            height: .95,
          ),
        ),
      );
    }

    return CustomPaint(size: Size.square(size), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * .18;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -.08, 1.42, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 1.34, 1.44, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.78, 1.22, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, 4.0, 1.55, false, paint);

    final linePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * .54, size.height * .50),
      Offset(size.width * .95, size.height * .50),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * .95, size.height * .50),
      Offset(size.width * .95, size.height * .66),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PromoBanner extends StatelessWidget {
  const PromoBanner(this.title, this.subtitle, {super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      width: double.infinity,
      child: Image.asset(
        'assets/images/home/home_banner.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) =>
            _FallbackPromoBanner(title: title, subtitle: subtitle),
      ),
    );
  }
}

class _FallbackPromoBanner extends StatelessWidget {
  const _FallbackPromoBanner({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFD95A),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FOR\nONLINE\nORDER',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              top: 42,
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 40,
                  height: .88,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            Positioned(
              right: 112,
              bottom: 0,
              child: Container(
                width: 92,
                height: 162,
                decoration: const BoxDecoration(
                  color: Color(0xFF88D6D7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(46)),
                ),
              ),
            ),
            Positioned(
              right: 140,
              bottom: 86,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFFC49D),
                child: Container(
                  width: 46,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 124,
              bottom: 8,
              child: Icon(
                Icons.shopping_bag,
                size: 78,
                color: Colors.white.withValues(alpha: .85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShortcutTile extends StatelessWidget {
  const ShortcutTile(this.item, {super.key});

  final CategoryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox.square(
          dimension: 46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFFFE9B7)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _AssetOrIcon(
              imagePath: item.imagePath,
              icon: item.icon,
              iconSize: 24,
              imagePadding: 7,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(color: Color(0xFF9AA0B9), fontSize: 11),
        ),
      ],
    );
  }
}

class _AssetOrIcon extends StatelessWidget {
  const _AssetOrIcon({
    required this.imagePath,
    required this.icon,
    required this.iconSize,
    required this.imagePadding,
  });

  final String? imagePath;
  final IconData icon;
  final double iconSize;
  final double imagePadding;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && path.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.all(imagePadding),
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(icon, color: _orange, size: iconSize),
        ),
      );
    }

    return Icon(icon, color: _orange, size: iconSize);
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard(this.item, {super.key});

  final ProductItem item;

  @override
  Widget build(BuildContext context) {
    final cardImagePath = item.cardImagePath;
    if (cardImagePath != null && cardImagePath.isNotEmpty) {
      return Image.asset(
        cardImagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _GeneratedProductCard(item),
      );
    }

    return _GeneratedProductCard(item);
  }
}

class _GeneratedProductCard extends StatelessWidget {
  const _GeneratedProductCard(this.item);

  final ProductItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                const Spacer(),
                Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
              ],
            ),
            Expanded(
              child: Center(
                child: _AssetOrIcon(
                  imagePath: item.imagePath,
                  icon: item.icon,
                  iconSize: 78,
                  imagePadding: 0,
                ),
              ),
            ),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  '\$${item.price}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                SizedBox(
                  height: 26,
                  child: FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_cart, size: 13),
                    label: const Text('Add', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star, color: _orange, size: 13),
                const SizedBox(width: 4),
                Text('${item.rating}', style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 8),
                Text(
                  '${item.reviews} Reviews',
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home, 'Home'),
      (Icons.grid_view, 'Category'),
      (Icons.chat_bubble_outline, 'Message'),
      (Icons.shopping_cart_outlined, 'Cart'),
      (Icons.person_outline, 'Private'),
    ];
    return SafeArea(
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < items.length; index++)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    items[index].$1,
                    color: index == 0 ? _orange : const Color(0xFFC4C6CE),
                    size: 22,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    items[index].$2,
                    style: TextStyle(
                      color: index == 0 ? _orange : const Color(0xFFC4C6CE),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
