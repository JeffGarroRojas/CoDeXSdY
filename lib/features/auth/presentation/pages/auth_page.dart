import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/widgets/animated_border.dart';
import '../../../../main.dart';

class AuthPage extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;
  final Future<void> Function() onGuestMode;

  const AuthPage({
    super.key,
    required this.onLoginSuccess,
    required this.onGuestMode,
  });

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre';
    if (value.trim().length < 2) return 'El nombre es muy corto';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu email';
    if (!value.contains('@') || !value.contains('.')) return 'Email inválido';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Incluye mayúscula';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Incluye número';
    return null;
  }

  int calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  String getPasswordStrengthLabel(int strength) {
    if (strength < 3) return 'Débil';
    if (strength < 5) return 'Moderada';
    return 'Fuerte';
  }

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFF1E1E2E),
              Color(0xFF0F0F1A),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _AuthGradientPainter()),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 40),
                      _buildTitle(),
                      const SizedBox(height: 32),
                      _buildGoogleButton(),
                      const SizedBox(height: 24),
                      _buildDivider(),
                      const SizedBox(height: 24),
                      _buildForm(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _buildError(),
                      ],
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 12),
                      _buildToggleButton(),
                      const SizedBox(height: 24),
                      _buildGuestModeButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestModeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            '¿No quieres registrarte ahora?',
            style: TextStyle(fontSize: 14, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            'Usa la app como invitado. Tienes 5 días para crear tu cuenta.',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    _showGuestConfirmationDialog();
                  },
            icon: const Icon(Icons.person_outline, color: Colors.orange),
            label: const Text(
              'Omitir por ahora',
              style: TextStyle(color: Colors.orange),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  void _showGuestConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Modo Invitado'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Al continuar como invitado:'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Puedes usar todas las funciones')),
              ],
            ),
            Row(
              children: [
                Icon(Icons.check, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Tus datos se guardan localmente')),
              ],
            ),
            Row(
              children: [
                Icon(Icons.check, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Necesitarás WiFi para funcionar')),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tienes 5 días para crear tu cuenta. Después se borrarán tus datos.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.onGuestMode();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuar como invitado'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.45;

    return RepaintBoundary(
      child:
          CircularAnimatedBorder(
                size: logoSize,
                color1: const Color(0xFF007AFF),
                color2: const Color(0xFF6F42C1),
                child: Image.asset(
                  'assets/logonuevo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
          ).createShader(bounds),
          child: const Text(
            'CoDeXSdY',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontFamily: 'Aquire',
              color: Colors.white,
            ),
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, delay: 150.ms),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _isLogin ? 'Inicia sesión para continuar' : 'Crea tu cuenta',
            key: ValueKey(_isLogin),
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ).animate().fadeIn(delay: 250.ms),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: Image.network(
          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
          height: 20,
          width: 20,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.g_mobiledata, size: 20),
        ),
        label: const Text(
          'Continuar con Google',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[700])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('o', style: TextStyle(color: Colors.grey[500])),
        ),
        Expanded(child: Divider(color: Colors.grey[700])),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildForm() {
    return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: !_isLogin
                    ? TextFormField(
                        key: const ValueKey('name_field'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: const Icon(Icons.person_outline),
                          errorText: _getFieldError('name'),
                        ),
                        validator: (value) {
                          final error = validateName(value);
                          if (error != null) {
                            _setFieldError('name', error);
                            return error;
                          }
                          _clearFieldError('name');
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ).animate().fadeIn().slideY(begin: -0.2)
                    : const SizedBox.shrink(key: const ValueKey('empty')),
              ),
              if (!_isLogin) const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _getFieldError('email'),
                ),
                validator: (value) {
                  final error = validateEmail(value);
                  if (error != null) {
                    _setFieldError('email', error);
                    return error;
                  }
                  _clearFieldError('email');
                  return null;
                },
                textInputAction: TextInputAction.next,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _getFieldError('password'),
                  suffixIcon: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        key: ValueKey(_obscurePassword),
                        color: Colors.grey[500],
                      ),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) {
                  final error = _isLogin
                      ? validatePassword(value)
                      : validatePasswordStrength(value);
                  if (error != null) {
                    _setFieldError('password', error);
                    return error;
                  }
                  _clearFieldError('password');
                  return null;
                },
                onChanged: (value) {
                  if (!_isLogin && value.length >= 4) {
                    _updatePasswordStrength(value);
                  }
                },
                textInputAction: TextInputAction.done,
              ).animate().fadeIn(delay: 200.ms),
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                _buildPasswordStrengthIndicator(),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 700.ms)
        .slideY(begin: 0.2)
        .scale(begin: const Offset(0.95, 0.95));
  }

  final Map<String, String?> _fieldErrors = {};

  void _setFieldError(String field, String error) {
    _fieldErrors[field] = error;
  }

  void _clearFieldError(String field) {
    _fieldErrors.remove(field);
  }

  String? _getFieldError(String field) {
    return _fieldErrors[field];
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = calculatePasswordStrength(_passwordController.text);
    final maxStrength = 7;
    final percentage = strength / maxStrength;

    Color color;
    if (strength < 3) {
      color = Colors.red;
    } else if (strength < 5) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _passwordController.text.isEmpty ? 0 : percentage,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              getPasswordStrengthLabel(strength),
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Usa mayúsculas, minúsculas, números y símbolos',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _updatePasswordStrength(String value) {
    if (value.length >= 4) {
      setState(() {});
    }
  }

  Widget _buildError() {
    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.errorColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn()
        .shake(duration: 400.ms, hz: 3)
        .then()
        .shimmer(
          duration: 1000.ms,
          color: AppTheme.errorColor.withValues(alpha: 0.3),
        );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isLoading
                  ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(
                          duration: 1000.ms,
                          color: Colors.white.withValues(alpha: 0.3),
                        )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isLogin ? Icons.login : Icons.person_add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 800.ms)
        .slideY(begin: 0.3)
        .then()
        .shimmer(
          delay: 1500.ms,
          duration: 2000.ms,
          color: Colors.white.withValues(alpha: 0.2),
        );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
          _errorMessage = null;
          _fieldErrors.clear();
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          _isLogin
              ? '¿No tienes cuenta? Regístrate'
              : '¿Ya tienes cuenta? Inicia sesión',
          key: ValueKey(_isLogin),
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 900.ms);
  }

  void _navigateToMain({bool isGuest = false}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavigationPage(isGuestMode: isGuest),
      ),
      (route) => false,
    );
  }

  Future<void> _migrateGuestDataIfNeeded(String newUserId) async {
    if (DatabaseService.instance.hasGuestData()) {
      await DatabaseService.instance.migrateGuestDataToUser(newUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tus datos fueron transferidos a tu cuenta!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    _fieldErrors.clear();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;

      if (_isLogin) {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        final user = auth.currentUser;
        if (user != null) {
          ref.read(currentUserIdProvider.notifier).state = user.uid;
          await _migrateGuestDataIfNeeded(user.uid);
          _navigateToMain();
        }
      } else {
        final credential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (credential.user != null) {
          await credential.user!.updateDisplayName(_nameController.text.trim());
          final newUserId = credential.user!.uid;
          ref.read(currentUserIdProvider.notifier).state = newUserId;
          await _migrateGuestDataIfNeeded(newUserId);
          _navigateToMain();
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        final newUserId = userCredential.user!.uid;
        ref.read(currentUserIdProvider.notifier).state = newUserId;
        await _migrateGuestDataIfNeeded(newUserId);
        _navigateToMain();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'El email ya está registrado';
      case 'invalid-email':
        return 'Email inválido';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 8 caracteres.';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión.';
      default:
        return 'Error de autenticación';
    }
  }
}

class _AuthGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.15, size.height * 0.25),
              radius: size.width * 0.8,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.25),
      size.width * 0.6,
      paint,
    );

    final paint2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Color(0xFF22D3EE).withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.85, size.height * 0.75),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.75),
      size.width * 0.5,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
