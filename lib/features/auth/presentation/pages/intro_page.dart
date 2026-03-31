import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';

class IntroPage extends StatefulWidget {
  final VoidCallback onComplete;

  const IntroPage({super.key, required this.onComplete});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_IntroSlide> _slides = [
    _IntroSlide(
      title: 'CoDeXSdY',
      subtitle: 'Tu asistente de estudio con IA',
      description: 'Hecho para estudiantes de Costa Rica',
      icon: Icons.smart_toy,
      gradient: const [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
      iconColor: Colors.white,
      features: null,
    ),
    _IntroSlide(
      title: 'Con conexión 📶',
      subtitle: 'Potencia la IA de DeX',
      description: 'Aprovecha todo el poder de la inteligencia artificial',
      icon: Icons.wifi,
      gradient: const [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF6EE7B7)],
      iconColor: Colors.white,
      features: [
        _Feature(
          'Resúmenes inteligentes',
          Icons.summarize,
          'Genera resúmenes de cualquier tema',
        ),
        _Feature(
          'Flashcards automáticas',
          Icons.style,
          'Crea tarjetas de estudio al instante',
        ),
        _Feature(
          'Chat con DeX',
          Icons.chat_bubble,
          'Pregunta lo que necesites',
        ),
        _Feature(
          'Preguntas y respuestas',
          Icons.quiz,
          'Practica con Q&A generadas',
        ),
      ],
    ),
    _IntroSlide(
      title: 'Actualizaciones 📲',
      subtitle: 'Activa Fuentes Desconocidas',
      description: 'Necesario para instalar actualizaciones automáticas',
      icon: Icons.system_update,
      gradient: const [Color(0xFFF97316), Color(0xFFFB923C), Color(0xFFFDBA74)],
      iconColor: Colors.white,
      features: [
        _Feature(
          'Actualizaciones automáticas',
          Icons.download,
          'Recibe mejoras sin conectar al dispositivo',
        ),
        _Feature(
          'Corrección de errores',
          Icons.bug_report,
          'Arreglos rápidos en segundo plano',
        ),
        _Feature(
          'Nuevas funciones',
          Icons.add_circle,
          'Mejoras que llegan directo a tu celular',
        ),
      ],
    ),
    _IntroSlide(
      title: 'Sin conexión 📴',
      subtitle: 'Sigue estudiando offline',
      description: 'Tus datos siempre disponibles',
      icon: Icons.cloud_off,
      gradient: const [Color(0xFFFBBF24), Color(0xFFFCD34D), Color(0xFFFEF3C7)],
      iconColor: Color(0xFF78350F),
      features: [
        _Feature(
          'Estudiar archivos',
          Icons.folder,
          'Accede a documentos guardados',
        ),
        _Feature(
          'Repasar flashcards',
          Icons.style_outlined,
          'Repite tarjetas generadas',
        ),
        _Feature('Revisar resúmenes', Icons.article, 'Lee resúmenes guardados'),
        _Feature('Aprende sin internet', Icons.school, 'Continúa aprendiendo'),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  Future<void> _openUnknownSourcesSettings() async {
    try {
      final Uri uri = Uri.parse('app-settings:');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showManualInstructions();
      }
    } catch (e) {
      _showManualInstructions();
    }
  }

  void _showManualInstructions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ve a: Configuración > Apps > CoDeXSdY > Instalar apps desconocidas',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _slides[_currentPage].gradient.isNotEmpty
                  ? [
                      _slides[_currentPage].gradient[0],
                      _slides[_currentPage].gradient[1].withValues(alpha: 0.5),
                      const Color(0xFF1E1E2E),
                      const Color(0xFF0F0F1A),
                    ]
                  : [
                      const Color(0xFF6366F1),
                      const Color(0xFF1E1E2E),
                      const Color(0xFF0F0F1A),
                    ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _GradientPainter())),
              SafeArea(
                child: Column(
                  children: [
                    _buildSkipButton(),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slides.length,
                        onPageChanged: (index) =>
                            setState(() => _currentPage = index),
                        itemBuilder: (context, index) => _buildSlide(index),
                      ),
                    ),
                    _buildBottomSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: widget.onComplete,
            child: Text(
              'Saltar',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(int index) {
    final slide = _slides[index];
    final isActive = _currentPage == index;
    final isUpdateSlide = slide.title.contains('Actualizaciones');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(slide, isActive),
          const SizedBox(height: 40),
          _buildTitle(slide, isActive),
          const SizedBox(height: 12),
          _buildSubtitle(slide, isActive),
          const SizedBox(height: 24),
          _buildDescription(slide, isActive),
          if (slide.features != null) ...[
            const SizedBox(height: 32),
            _buildFeatures(slide, isActive),
          ],
          if (isUpdateSlide) ...[
            const SizedBox(height: 24),
            _buildSettingsButton(isActive),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(_IntroSlide slide, bool isActive) {
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      slide.gradient[0].withValues(alpha: 0.3),
                      slide.gradient[1].withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 600.ms,
              ),
          Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: slide.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: slide.gradient[0].withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: slide.gradient[1].withValues(alpha: 0.3),
                      blurRadius: 50,
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: Icon(slide.icon, size: 80, color: slide.iconColor),
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }

  Widget _buildTitle(_IntroSlide slide, bool isActive) {
    if (slide.title == 'CoDeXSdY') {
      return ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: slide.gradient).createShader(bounds),
            child: const Text(
              'CoDeXSdY',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                fontFamily: 'Aquire',
                color: Colors.white,
              ),
            ),
          )
          .animate(target: isActive ? 1 : 0)
          .fadeIn(delay: 150.ms)
          .slideY(begin: 0.2, end: 0, delay: 150.ms);
    }

    return Text(
          slide.title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: slide.gradient[0],
          ),
        )
        .animate(target: isActive ? 1 : 0)
        .fadeIn(delay: 150.ms)
        .slideY(begin: 0.2, end: 0, delay: 150.ms);
  }

  Widget _buildSubtitle(_IntroSlide slide, bool isActive) {
    return Text(
          slide.subtitle,
          style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          textAlign: TextAlign.center,
        )
        .animate(target: isActive ? 1 : 0)
        .fadeIn(delay: 250.ms)
        .slideY(begin: 0.2, end: 0, delay: 250.ms);
  }

  Widget _buildDescription(_IntroSlide slide, bool isActive) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            slide.description,
            style: TextStyle(fontSize: 13, color: Colors.grey[300]),
            textAlign: TextAlign.center,
          ),
        )
        .animate(target: isActive ? 1 : 0)
        .fadeIn(delay: 300.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          delay: 300.ms,
        );
  }

  Widget _buildFeatures(_IntroSlide slide, bool isActive) {
    return Column(
      children: slide.features!.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        return RepaintBoundary(
          child:
              Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: slide.gradient[0].withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: slide.gradient[0].withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              feature.icon,
                              color: slide.gradient[0],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feature.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  feature.description,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(target: isActive ? 1 : 0)
                  .fadeIn(delay: Duration(milliseconds: 350 + (index * 75)))
                  .slideX(
                    begin: 0.15,
                    end: 0,
                    delay: Duration(milliseconds: 350 + (index * 75)),
                  ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsButton(bool isActive) {
    return TextButton.icon(
      onPressed: _openUnknownSourcesSettings,
      icon: const Icon(Icons.settings, size: 18),
      label: const Text('Abrir configuración'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        textStyle: const TextStyle(fontSize: 13),
      ),
    ).animate(target: isActive ? 1 : 0).fadeIn(delay: 500.ms);
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          _buildPageIndicator(),
          const SizedBox(height: 24),
          _buildButton(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.grey[700],
            borderRadius: BorderRadius.circular(5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildButton() {
    final isLastPage = _currentPage == _slides.length - 1;
    final slide = _slides[_currentPage];

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: slide.gradient[0].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: slide.gradient[1].withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _nextPage,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? '¡Comenzar!' : 'Siguiente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastPage ? Icons.celebration : Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15);
  }
}

class _IntroSlide {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final Color iconColor;
  final List<_Feature>? features;

  const _IntroSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.iconColor,
    this.features,
  });
}

class _GradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
            stops: const [0.0, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.2, size.height * 0.3),
              radius: size.width * 0.8,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
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
              center: Offset(size.width * 0.8, size.height * 0.7),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      size.width * 0.5,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Feature {
  final String title;
  final IconData icon;
  final String description;

  const _Feature(this.title, this.icon, this.description);
}
