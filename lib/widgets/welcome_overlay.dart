import 'dart:math' as math;
import 'package:flutter/material.dart';

class WelcomeOverlay extends StatefulWidget {
  final VoidCallback onSubscribe;

  const WelcomeOverlay({
    super.key,
    required this.onSubscribe,
  });

  @override
  State<WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends State<WelcomeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _iconBounceController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shimmerAnimation;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _iconBounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _iconBounceController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _iconBounceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      widget.onSubscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    const bgColor = Colors.white;
    const cardRed = Color(0xFFE53935);
    const cardYellow = Color(0xFFFFD600);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              margin: EdgeInsets.all(isMobile ? 20 : 40),
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: cardYellow, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: cardRed.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    ..._buildFloatingIcons(),
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 24 : 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeIn,
                              child: _buildStep(isMobile),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStepIndicator(),
                          const SizedBox(height: 16),
                          _buildMainButton(isMobile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isMobile) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(isMobile);
      case 1:
        return _buildFeaturesStep(isMobile);
      case 2:
        return _buildCtaStep(isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep(bool isMobile) {
    const cardRed = Color(0xFFE53935);
    const cardYellow = Color(0xFFFFD600);
    const textDark = Color(0xFF1A1A1A);

    return Column(
      key: const ValueKey('step_welcome'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardYellow, Color(0xFFFFEA00)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: cardRed, width: 3),
              boxShadow: [
                BoxShadow(
                  color: cardYellow.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Icon(
              Icons.content_cut_rounded,
              color: cardRed,
              size: isMobile ? 44 : 52,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 20 : 28),
        AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment(_shimmerAnimation.value - 1, 0),
                  end: Alignment(_shimmerAnimation.value, 0),
                  colors: const [cardRed, cardYellow, cardRed],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(rect);
              },
              child: child!,
            );
          },
          child: Text(
            'Bienvenido a\nProgramacion JJ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cardRed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Sistema Bella Color',
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'El sistema de turnos mas completo\npara tu salon de belleza',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: textDark.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesStep(bool isMobile) {
    const cardRed = Color(0xFFE53935);
    const cardYellow = Color(0xFFFFD600);
    const textDark = Color(0xFF1A1A1A);

    return Column(
      key: const ValueKey('step_features'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Tu salon, tu estilo',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Text(
          'Es super facil de configurar',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: textDark.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: isMobile ? 24 : 32),
        _buildFeatureItem(
          icon: Icons.palette_rounded,
          title: 'Colores y marca',
          subtitle: 'Cambia colores, logo y fondo con un toque',
          accentColor: cardRed,
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _buildFeatureItem(
          icon: Icons.spa_rounded,
          title: 'Servicios y profesionales',
          subtitle: 'Configura servicios, equipo y duraciones',
          accentColor: cardYellow.withValues(alpha: 0.85),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _buildFeatureItem(
          icon: Icons.chat_rounded,
          title: 'WhatsApp integrado',
          subtitle: 'Notificaciones automaticas a tus clientes',
          accentColor: const Color(0xFF25D366),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _buildFeatureItem(
          icon: Icons.bar_chart_rounded,
          title: 'Reportes en vivo',
          subtitle: 'Estadisticas, graficos y control total',
          accentColor: cardRed,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildCtaStep(bool isMobile) {
    const cardRed = Color(0xFFE53935);
    const cardYellow = Color(0xFFFFD600);
    const textDark = Color(0xFF1A1A1A);

    return Column(
      key: const ValueKey('step_cta'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(-_bounceAnimation.value, _bounceAnimation.value),
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Icon(Icons.brush_rounded,
                        color: cardYellow.withValues(alpha: 0.7),
                        size: 32),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value.abs()),
                  child: const Icon(Icons.content_cut_rounded,
                      color: cardRed, size: 48),
                ),
                const SizedBox(width: 8),
                Transform.translate(
                  offset: Offset(_bounceAnimation.value, _bounceAnimation.value),
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Icon(Icons.brush_rounded,
                        color: cardYellow.withValues(alpha: 0.7),
                        size: 32),
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: isMobile ? 28 : 36),
        Text(
          'Estas a un clic de\ntener mas clientes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: textDark,
            height: 1.2,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF9C4), Color(0xFFFFECB3)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardYellow, width: 2),
          ),
          child: Column(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: cardRed, size: 28),
              const SizedBox(height: 8),
              Text(
                'Gratis por 15 dias',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: cardRed,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sin tarjeta, sin compromiso',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: textDark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Text(
          'Industria Nacional',
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            color: textDark.withValues(alpha: 0.35),
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_rounded,
                color: Color(0xFF25D366), size: 16),
            const SizedBox(width: 6),
            Text(
              'Apreta aca y te pasamos el link!',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: const Color(0xFF25D366),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: isMobile ? 20 : 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    const cardRed = Color(0xFFE53935);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? cardRed
                : const Color(0xFF1A1A1A).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildMainButton(bool isMobile) {
    const cardRed = Color(0xFFE53935);
    const cardYellow = Color(0xFFFFD600);
    final isLastStep = _currentStep == 2;

    return GestureDetector(
      onTap: _nextStep,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
        decoration: BoxDecoration(
          gradient: isLastStep
              ? const LinearGradient(colors: [cardRed, Color(0xFFFF5722)])
              : null,
          color: isLastStep ? null : cardYellow,
          borderRadius: BorderRadius.circular(16),
          border: isLastStep
              ? null
              : Border.all(color: cardRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLastStep)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 20),
              ),
            Text(
              isLastStep ? 'Empezar ahora' : 'Siguiente',
              style: TextStyle(
                fontSize: isMobile ? 16 : 17,
                fontWeight: isLastStep ? FontWeight.w700 : FontWeight.w600,
                color: isLastStep ? Colors.white : const Color(0xFF1A1A1A),
                letterSpacing: 0.5,
              ),
            ),
            if (!isLastStep)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    color: Color(0xFF1A1A1A), size: 18),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingIcons() {
    final icons = [
      Icons.content_cut_rounded,
      Icons.spa_rounded,
      Icons.face_rounded,
      Icons.brush_rounded,
      Icons.auto_awesome_rounded,
      Icons.favorite_rounded,
    ];

    return List.generate(icons.length, (i) {
      final random = math.Random(i * 42);
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 550;
      final size = 18.0 + random.nextDouble() * 14;
      final opacity = 0.03 + random.nextDouble() * 0.05;
      final rotationOffset = (i.isEven ? 1.0 : -1.0);

      return AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, _) {
          return Positioned(
            left: left,
            top: top + (_bounceAnimation.value * rotationOffset * 1.5),
            child: Transform.rotate(
              angle: (i * 0.5) + (_bounceAnimation.value * 0.02 * rotationOffset),
              child: Icon(
                icons[i],
                color: (i.isEven ? const Color(0xFFE53935) : const Color(0xFFFFD600))
                    .withValues(alpha: opacity),
                size: size,
              ),
            ),
          );
        },
      );
    });
  }
}
