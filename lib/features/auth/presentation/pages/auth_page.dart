import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_border.dart';
import '../../../../main.dart';

class AuthPage extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onGuestMode;

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
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
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
            '¿Solo quieres probar la app?',
            style: TextStyle(fontSize: 14, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            'Usa la app como invitado sin registrarte.',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _showGuestConfirmationDialog,
            icon: const Icon(Icons.person_outline, color: Colors.orange),
            label: const Text(
              'Modo Invitado',
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
                Expanded(child: Text('No necesitas registrarte')),
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
            onPressed: () {
              Navigator.pop(context);
              widget.onGuestMode();
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
                color1: const Color(0xFF6366F1),
                color2: const Color(0xFF22D3EE),
                child: Image.asset(
                  'assets/logonuevo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
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
            _isLogin ? 'Ingresa tu PIN para continuar' : 'Crea tu cuenta local',
            key: ValueKey(_isLogin),
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ).animate().fadeIn(delay: 250.ms),
      ],
    );
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
                          labelText: 'Nombre (opcional)',
                          prefixIcon: const Icon(Icons.person_outline),
                          hintText: '¿Cómo te llamas?',
                        ),
                        textInputAction: TextInputAction.next,
                      ).animate().fadeIn().slideY(begin: -0.2)
                    : const SizedBox.shrink(key: const ValueKey('empty')),
              ),
              if (!_isLogin) const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: _obscurePassword,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'PIN de 4 dígitos',
                  prefixIcon: const Icon(Icons.lock_outline),
                  counterText: '',
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
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu PIN';
                  }
                  if (value.length != 4) {
                    return 'El PIN debe tener 4 dígitos';
                  }
                  if (!_isLogin && !RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Solo números';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ).animate().fadeIn(delay: 100.ms),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePassword,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar PIN',
                    prefixIcon: Icon(Icons.lock_outline),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value != _pinController.text) {
                      return 'Los PINs no coinciden';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ).animate().fadeIn(delay: 200.ms),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 700.ms)
        .slideY(begin: 0.2)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.5)),
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
    ).animate().fadeIn().shake(duration: 400.ms, hz: 3);
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
                          _isLogin ? 'Ingresar' : 'Crear Cuenta',
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
          _pinController.clear();
          _confirmPinController.clear();
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          _isLogin
              ? '¿Primera vez? Crea tu cuenta'
              : '¿Ya tienes cuenta? Inicia sesión',
          key: ValueKey(_isLogin),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 900.ms);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();

    if (_isLogin) {
      final storedPin = _getStoredPin();
      if (storedPin != null && storedPin == _pinController.text) {
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = 'PIN incorrecto';
        });
      }
    } else {
      _savePin(_pinController.text, name.isNotEmpty ? name : 'Usuario');
      widget.onLoginSuccess();
    }

    setState(() {
      _isLoading = false;
    });
  }

  String? _getStoredPin() {
    return null;
  }

  void _savePin(String pin, String name) {}
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
              const Color(0xFF22D3EE).withValues(alpha: 0.08),
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
