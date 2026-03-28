import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/theme/app_theme.dart';
import 'core/services/database_service.dart';
import 'core/services/tts_service.dart';
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

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await LoggingService.instance.init();
  await DatabaseService.instance.init();
  await TTSService.instance.init();
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

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
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      _checkForUpdates();
    }
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
          return FadeTransition(opacity: animation, child: child);
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E1B4B),
              const Color(0xFF312E81),
              Colors.black,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              CircularAnimatedBorder(
                    size: 130,
                    color1: const Color(0xFF007AFF),
                    color2: const Color(0xFF6F42C1),
                    child: Image.asset(
                      'assets/logonuevo.png',
                      fit: BoxFit.contain,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 24),
              Text(
                    'CoDeXSdY',
                    style: TextStyle(
                      fontFamily: 'Aquire',
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: 200.ms,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: -0.3,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 8),
              Text(
                'Tu asistente de estudio',
                style: TextStyle(
                  fontFamily: 'Aquire',
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const Spacer(flex: 1),
              SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) {
                    return Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              const SizedBox(height: 60),
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
      MaterialPageRoute(
        builder: (_) => const MainNavigationPage(isGuestMode: false),
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
      MaterialPageRoute(builder: (_) => MainNavigationPage(isGuestMode: true)),
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

class MainNavigationPage extends StatefulWidget {
  final bool isGuestMode;

  const MainNavigationPage({super.key, this.isGuestMode = false});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final _pages = const [HomePage(), StudyPage(), ChatbotPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Estudiar',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'CoDy',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
