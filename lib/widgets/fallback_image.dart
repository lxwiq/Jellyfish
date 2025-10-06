import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../theme/app_colors.dart';
import '../services/custom_cache_manager.dart';

/// Widget qui affiche une image avec plusieurs URLs de fallback
/// Essaie chaque URL dans l'ordre jusqu'à ce qu'une fonctionne
class FallbackImage extends StatefulWidget {
  final List<String?> imageUrls;
  final BoxFit fit;
  final Alignment alignment;
  final int? memCacheWidth;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FallbackImage({
    super.key,
    required this.imageUrls,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.memCacheWidth,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<FallbackImage> createState() => _FallbackImageState();
}

class _FallbackImageState extends State<FallbackImage> {
  int _currentUrlIndex = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _findFirstValidUrl();
  }

  @override
  void didUpdateWidget(FallbackImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si les URLs changent, recommencer depuis le début
    if (oldWidget.imageUrls != widget.imageUrls) {
      setState(() {
        _currentUrlIndex = 0;
        _hasError = false;
      });
      _findFirstValidUrl();
    }
  }

  void _findFirstValidUrl() {
    // Trouver la première URL non-null
    while (_currentUrlIndex < widget.imageUrls.length &&
        widget.imageUrls[_currentUrlIndex] == null) {
      _currentUrlIndex++;
    }
  }

  void _tryNextUrl() {
    setState(() {
      _currentUrlIndex++;
      _hasError = false;
    });
    _findFirstValidUrl();
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: AppColors.surface1,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.jellyfinPurple,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      color: AppColors.surface1,
      child: const Center(
        child: Icon(
          IconsaxPlusLinear.video_square,
          size: 40,
          color: AppColors.text2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si on a dépassé toutes les URLs ou si toutes sont null
    if (_currentUrlIndex >= widget.imageUrls.length) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }

    final currentUrl = widget.imageUrls[_currentUrlIndex];

    // Si l'URL actuelle est null, essayer la suivante
    if (currentUrl == null) {
      _tryNextUrl();
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: currentUrl,
      fit: widget.fit,
      alignment: widget.alignment,
      memCacheWidth: widget.memCacheWidth,
      cacheManager: CustomCacheManager(),
      placeholder: (context, url) =>
          widget.placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        // Si on a une erreur et qu'il reste des URLs à essayer
        if (_currentUrlIndex < widget.imageUrls.length - 1 && !_hasError) {
          _hasError = true;
          // Essayer la prochaine URL après un court délai
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _tryNextUrl();
            }
          });
          return widget.placeholder ?? _buildDefaultPlaceholder();
        }
        // Plus d'URLs à essayer, afficher l'erreur finale
        return widget.errorWidget ?? _buildDefaultErrorWidget();
      },
    );
  }
}

