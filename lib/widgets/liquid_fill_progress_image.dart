import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget qui affiche une image avec un effet de remplissage liquide
/// L'image commence en noir et blanc et se remplit de couleur de bas en haut
class LiquidFillProgressImage extends StatefulWidget {
  final String? imageUrl;
  final double progress; // 0.0 à 1.0
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LiquidFillProgressImage({
    super.key,
    required this.imageUrl,
    required this.progress,
    this.width = 120,
    this.height = 180,
    this.borderRadius,
  });

  @override
  State<LiquidFillProgressImage> createState() => _LiquidFillProgressImageState();
}

class _LiquidFillProgressImageState extends State<LiquidFillProgressImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _waveAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_waveController);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.imageUrl != null
            ? _buildImageWithProgress()
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildImageWithProgress() {
    return Stack(
      children: [
        // Couche de fond: Image en noir et blanc
        _buildGrayscaleImage(),
        
        // Couche de dessus: Image en couleur avec effet de remplissage liquide
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return ClipPath(
              clipper: LiquidFillClipper(
                progress: widget.progress,
                wavePhase: _waveAnimation.value,
              ),
              child: child,
            );
          },
          child: _buildColorImage(),
        ),

        // Overlay pour montrer le pourcentage
        if (widget.progress < 1.0)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(widget.progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrayscaleImage() {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
        placeholder: (context, url) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.movie, size: 48),
        ),
      ),
    );
  }

  Widget _buildColorImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      fit: BoxFit.cover,
      width: widget.width,
      height: widget.height,
      placeholder: (context, url) => const SizedBox.shrink(),
      errorWidget: (context, url, error) => const SizedBox.shrink(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.movie, size: 48),
    );
  }
}

/// Clipper personnalisé pour créer l'effet de remplissage liquide
class LiquidFillClipper extends CustomClipper<Path> {
  final double progress; // 0.0 à 1.0
  final double wavePhase; // 0 à 2π pour l'animation de la vague

  LiquidFillClipper({
    required this.progress,
    required this.wavePhase,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Si le progrès est 0, ne rien clipper (tout est masqué)
    if (progress <= 0) {
      return path;
    }

    // Si le progrès est 1, tout afficher
    if (progress >= 1) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    // Calculer la hauteur de remplissage (de bas en haut)
    final fillHeight = size.height * progress;
    final waveTop = size.height - fillHeight;

    // Créer la vague
    path.moveTo(0, waveTop);

    // Paramètres de la vague
    const waveAmplitude = 8.0; // Amplitude de la vague
    const waveFrequency = 2.0; // Nombre de vagues
    final waveLength = size.width / waveFrequency;

    // Dessiner la vague sinusoïdale
    for (double x = 0; x <= size.width; x += 1) {
      final relativeX = x / waveLength;
      final y = waveTop + 
                math.sin((relativeX * 2 * math.pi) + wavePhase) * waveAmplitude;
      path.lineTo(x, y);
    }

    // Compléter le chemin pour remplir le bas
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(LiquidFillClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.wavePhase != wavePhase;
  }
}

