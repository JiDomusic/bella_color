import 'dart:math' as math;
import 'package:flutter/material.dart';

// Paleta rosas, lilas y lavandas
const _colorPrimary = Color(0xFFD97FC2);   // Rosa/lila principal
const _colorSecondary = Color(0xFFB18CFF); // Lila de apoyo
const _colorAccent = Color(0xFFB7C2FF);    // Lavanda suave
const _textDark = Color(0xFF1A1A1A);

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

  int _currentStep = 0; // 0 = welcome, 1 = features, 2 = how it works, 3 = CTA

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
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      widget.onSubscribe();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    const bgColor = Colors.white;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF4E7FF), // lavanda clara
              Color(0xFFFCE4F5), // rosa plush
              Color(0xFFEAD7FF), // lila pastel
            ],
          ),
        ),
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
              margin: EdgeInsets.all(isMobile ? 16 : 40),
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _colorAccent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _colorSecondary.withValues(alpha: 0.22),
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
                      padding: EdgeInsets.all(isMobile ? 20 : 32),
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
                          const SizedBox(height: 12),
                          _buildButtons(isMobile),
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
        return _buildHowItWorksStep(isMobile);
      case 3:
        return _buildCtaStep(isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Paso 0: Bienvenida ───
  Widget _buildWelcomeStep(bool isMobile) {
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_colorSecondary, _colorPrimary],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: _colorAccent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _colorPrimary.withValues(alpha: 0.26),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_chica.png',
                width: isMobile ? 110 : 130,
                height: isMobile ? 110 : 130,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.content_cut_rounded,
                  color: _colorPrimary,
                  size: isMobile ? 44 : 52,
                ),
              ),
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
                  colors: const [_colorPrimary, _colorAccent, _colorPrimary],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(rect);
              },
              child: child!,
            );
          },
          child: Column(
            children: [
              Text(
                'Bella Color',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 30 : 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sistema de turnos para salones de belleza',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Desarrollado por Programacion JJ en Rosario',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _colorPrimary,
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
            color: _textDark.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Organiza tu negocio, gestiona tus clientes\ny hace crecer tu salon',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: _textDark.withValues(alpha: 0.4),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ─── Paso 1: Features — qué podes hacer ───
  Widget _buildFeaturesStep(bool isMobile) {
    return SingleChildScrollView(
      key: const ValueKey('step_features'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tu salon, tu estilo',
            style: TextStyle(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            'Todo lo que necesitas para tu negocio',
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              color: _textDark.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          _buildFeatureItem(
            icon: Icons.image_rounded,
            title: 'Subi tu logo y fotos',
            subtitle: 'Logo a color, logo blanco y fondo personalizado',
            accentColor: _colorPrimary,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 10 : 14),
          _buildFeatureItem(
            icon: Icons.palette_rounded,
            title: 'Colores de tu marca',
            subtitle: 'Personaliza 4 colores para que tu salon se vea unico',
            accentColor: _colorSecondary.withValues(alpha: 0.85),
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 10 : 14),
          _buildFeatureItem(
            icon: Icons.spa_rounded,
            title: 'Servicios y precios',
            subtitle: 'Carga cortes, color, manicura, pestanas y mas',
            accentColor: _colorAccent.withValues(alpha: 0.9),
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 10 : 14),
          _buildFeatureItem(
            icon: Icons.people_rounded,
            title: 'Profesionales',
            subtitle: 'Agrega tu equipo con sus especialidades y horarios',
            accentColor: _colorSecondary.withValues(alpha: 0.9),
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 10 : 14),
          _buildFeatureItem(
            icon: Icons.chat_rounded,
            title: 'WhatsApp integrado',
            subtitle: 'Confirmaciones y recordatorios automaticos',
            accentColor: _colorAccent,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 10 : 14),
          _buildFeatureItem(
            icon: Icons.bar_chart_rounded,
            title: 'Reportes en vivo',
            subtitle: 'Estadisticas, graficos y control total de tu salon',
            accentColor: _colorPrimary,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  // ─── Paso 2: Cómo funciona ───
  Widget _buildHowItWorksStep(bool isMobile) {
    return SingleChildScrollView(
      key: const ValueKey('step_howitworks'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Como funciona?',
            style: TextStyle(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            'En 3 simples pasos',
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              color: _textDark.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 28),
          _buildStepCard(
            number: '1',
            title: 'Contactanos por WhatsApp',
            description: 'Te creamos tu salon en minutos y te damos tu link personalizado',
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildStepCard(
            number: '2',
            title: 'Configura tu salon',
            description: 'Subi logos, elegí colores, carga tus servicios, profesionales y horarios',
            icon: Icons.settings_rounded,
            color: _colorSecondary,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildStepCard(
            number: '3',
            title: 'Listo! Ya podes recibir turnos',
            description: 'Tus clientes reservan online, vos gestionas todo desde el panel admin',
            icon: Icons.rocket_launch_rounded,
            color: _colorPrimary,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _colorPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: _colorPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'El sistema organiza los turnos por vos',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: _colorPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Paso 3: CTA final ───
  Widget _buildCtaStep(bool isMobile) {
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
                        color: _colorAccent.withValues(alpha: 0.7), size: 32),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value.abs()),
                  child: const Icon(Icons.content_cut_rounded, color: _colorPrimary, size: 48),
                ),
                const SizedBox(width: 8),
                Transform.translate(
                  offset: Offset(_bounceAnimation.value, _bounceAnimation.value),
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Icon(Icons.brush_rounded,
                        color: _colorAccent.withValues(alpha: 0.7), size: 32),
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
            color: _textDark,
            height: 1.2,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_colorSecondary, _colorPrimary],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _colorAccent, width: 2),
          ),
          child: Column(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: _colorPrimary, size: 28),
              const SizedBox(height: 8),
              Text(
                'Gratis por 15 dias',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sin tarjeta, sin compromiso',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.white.withValues(alpha: 0.8),
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
            color: _textDark.withValues(alpha: 0.35),
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 16),
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

  // ─── Helpers ───

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
                  color: _textDark,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: _textDark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: _textDark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isActive = i == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? _colorPrimary
                : _textDark.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildButtons(bool isMobile) {
    final isLastStep = _currentStep == 3;

    return Column(
      children: [
        GestureDetector(
          onTap: _nextStep,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
            decoration: BoxDecoration(
              gradient: isLastStep
                  ? const LinearGradient(colors: [_colorPrimary, _colorSecondary])
                  : null,
              color: isLastStep ? null : _colorAccent,
              borderRadius: BorderRadius.circular(16),
              border: isLastStep
                  ? null
                  : Border.all(color: _colorSecondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLastStep)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                  ),
                Text(
                  isLastStep ? 'Empezar ahora' : 'Siguiente',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 17,
                    fontWeight: isLastStep ? FontWeight.w700 : FontWeight.w600,
                    color: isLastStep ? Colors.white : _textDark,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!isLastStep)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.arrow_forward_rounded, color: _textDark, size: 18),
                  ),
              ],
            ),
          ),
        ),
        if (_currentStep > 0) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _prevStep,
            child: Text(
              'Atras',
              style: TextStyle(
                fontSize: 14,
                color: _textDark.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
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
      final top = random.nextDouble() * 600;
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
