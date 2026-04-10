import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/services/database_service.dart';
import 'core/services/logging_service.dart';
import 'core/services/notification_service.dart';
import 'core/providers/app_providers.dart';
import 'features/documents/presentation/pages/home_page.dart';
import 'features/ai_assistant/presentation/pages/chatbot_page.dart';
import 'features/flashcards/presentation/pages/study_page.dart';
import 'features/documents/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/intro_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await DatabaseService.instance.init();
  await LoggingService.instance.init();
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  LoggingService.instance.info('CoDeXSdY started (Local Mode)', source: 'App');

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
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      _navigateToAuth();
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
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                              Color(0xFF22D3EE),
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
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

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF1E1E2E),
                    Color(0xFF0F0F1A),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFF1E1E2E),
              Color(0xFF0F0F1A),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
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
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
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
                    'Tu asistente de estudio con IA (Local)',
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
    final userId = 'local_user_${DateTime.now().millisecondsSinceEpoch}';
    ref.read(currentUserIdProvider.notifier).state = userId;
    DatabaseService.instance.setCurrentUserId(userId);
    DatabaseService.instance.setGuestSession(false);

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

  void _handleGuestMode() {
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
