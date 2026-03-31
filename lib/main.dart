import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/services/database_service.dart';
import 'core/services/logging_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/update_service.dart';
import 'core/providers/app_providers.dart';
import 'core/widgets/animated_border.dart';
import 'features/documents/presentation/pages/home_page.dart';
import 'features/ai_assistant/presentation/pages/chatbot_page.dart';
import 'features/flashcards/presentation/pages/study_page.dart';
import 'features/documents/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/intro_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await DatabaseService.instance.init();
  await LoggingService.instance.init();
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();
  await UpdateService.instance.init();

  LoggingService.instance.info('CoDeXSdY started', source: 'App');

  runApp(const ProviderScope(child: CoDeXSdYApp()));
}

class CoDeXSdYApp extends ConsumerWidget {
  const CoDeXSdYApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CoDeXSdY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashPage(),
    );
  }
}

class SplashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.3), 120, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.9), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 60, paint);

    final paint2 = Paint()
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.5), 100, paint2);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.8), 80, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutQuad),
    );
    _progressController.forward();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      _checkForUpdates();
    }
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        Container(
              width: 200,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Container(
                        width: 200 * _progressAnimation.value,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1),
                              const Color(0xFF8B5CF6),
                              const Color(0xFF22D3EE),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
            .shimmer(
              delay: 1000.ms,
              duration: 1500.ms,
              color: Colors.white.withValues(alpha: 0.3),
            ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(0),
            const SizedBox(width: 6),
            _buildDot(1),
            const SizedBox(width: 6),
            _buildDot(2),
          ],
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  Widget _buildDot(int index) {
    return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF6366F1), const Color(0xFF22D3EE)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(
          delay: Duration(milliseconds: 200 + (index * 150)),
          duration: 600.ms,
        );
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await UpdateService.instance.checkForUpdates();

    if (!mounted) return;

    if (updateInfo.type == UpdateType.shorebird) {
      _showShorebirdUpdateDialog(updateInfo);
    } else if (updateInfo.type == UpdateType.required) {
      _showRequiredUpdateDialog(updateInfo);
    } else {
      _navigateToAuth();
    }
  }

  void _showShorebirdUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: Colors.green[400]),
            const SizedBox(width: 12),
            const Text('Actualización disponible'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.message ?? 'Hay una nueva actualización disponible.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.offline_bolt, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se descargará en segundo plano. '
                      'La app se actualizará automáticamente.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAuth();
            },
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await UpdateService.instance.downloadAndApplyUpdate();
              _navigateToAuth();
            },
            child: const Text('Actualizar ahora'),
          ),
        ],
      ),
    );
  }

  void _showRequiredUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.update, color: Colors.orange[400]),
            const SizedBox(width: 12),
            const Text('Nueva versión'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.message ?? 'Hay una nueva versión disponible.'),
            const SizedBox(height: 16),
            if (info.version != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Versión: ${info.version}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[300],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta actualización es requerida. '
                      'Descarga el APK para continuar.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              if (info.downloadUrl != null) {
                final uri = Uri.parse(info.downloadUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar APK'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6366F1),
                    const Color(0xFF1E1E2E),
                    const Color(0xFF0F0F1A),
                  ],
                ),
              ),
              child: FadeTransition(opacity: animation, child: child),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
              const Color(0xFF1E1E2E),
              const Color(0xFF0F0F1A),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Stack(
            children: [
              Positioned.fill(
                child: Stack(
                  children: [
                    Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(-0.5, -0.5),
                              radius: 1.2,
                              colors: [
                                const Color(0xFF22D3EE).withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeIn(begin: 0.5, duration: 2000.ms),
                    Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0.8, 0.8),
                              radius: 1.0,
                              colors: [
                                const Color(0xFF6366F1).withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeIn(begin: 0.3, duration: 2500.ms),
                  ],
                ),
              ),
              Column(
                children: [
                  const Spacer(flex: 3),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(
                                      0xFF22D3EE,
                                    ).withValues(alpha: 0.2),
                                    const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.7, 0.7),
                              end: const Offset(1.2, 1.2),
                              duration: 1800.ms,
                            ),
                        Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.3),
                                    const Color(
                                      0xFF8B5CF6,
                                    ).withValues(alpha: 0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1.1, 1.1),
                              duration: 1500.ms,
                            ),
                        Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF6366F1),
                                    const Color(0xFF8B5CF6),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: const Color(
                                      0xFF22D3EE,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 50,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.asset(
                                  'assets/logonuevo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1, 1),
                              duration: 800.ms,
                              curve: Curves.elasticOut,
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                        'CoDeXSdY',
                        style: TextStyle(
                          fontFamily: 'Aquire',
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      )
                      .animate()
                      .fadeIn(
                        delay: 300.ms,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      )
                      .slideY(
                        begin: -0.3,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 12),
                  Text(
                    'Tu asistente de estudio con IA',
                    style: TextStyle(
                      fontFamily: 'Aquire',
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  const Spacer(flex: 2),
                  _buildLoadingIndicator(),
                  const Spacer(flex: 1),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _showIntro = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final db = DatabaseService.instance;
    final isIntroShown = db.isIntroShown;

    setState(() {
      _showIntro = !isIntroShown;
      _isInitialized = true;
    });
  }

  Future<void> _completeIntro() async {
    await DatabaseService.instance.setIntroShown(true);
    setState(() => _showIntro = false);
  }

  void _handleLogin() {
    ref.read(currentUserIdProvider.notifier).state = 'authenticated';
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationPage(isGuestMode: false),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleGuestMode() async {
    await FirebaseAuth.instance.signOut();
    final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    ref.read(currentUserIdProvider.notifier).state = guestId;
    DatabaseService.instance.setGuestUserId(guestId);
    DatabaseService.instance.setGuestSession(true);
    NotificationService.instance.showGuestReminder(daysRemaining: 5);
    NotificationService.instance.scheduleGuestReminder(daysRemaining: 4);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigationPage(isGuestMode: true),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showIntro) {
      return IntroPage(onComplete: _completeIntro);
    }

    return AuthPage(
      onLoginSuccess: _handleLogin,
      onGuestMode: _handleGuestMode,
    );
  }
}

class MainNavigationPage extends StatelessWidget {
  final bool isGuestMode;

  const MainNavigationPage({super.key, this.isGuestMode = false});

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
