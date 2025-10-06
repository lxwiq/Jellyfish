import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/home_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';

/// Hero carousel en haut de la page d'accueil
class HomeHeroCarousel extends ConsumerStatefulWidget {
  final bool isDesktop;

  const HomeHeroCarousel({
    super.key,
    required this.isDesktop,
  });

  @override
  ConsumerState<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends ConsumerState<HomeHeroCarousel> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  int _lastItemCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  void _startAutoScroll(int itemCount) {
    // Ne démarrer le timer que si on a des items et qu'il n'est pas déjà actif
    if (itemCount == 0) return;

    // Si le nombre d'items a changé, redémarrer le timer
    if (_lastItemCount != itemCount) {
      _autoScrollTimer?.cancel();
      _lastItemCount = itemCount;

      _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        // Utiliser le nombre d'items limité à 5 pour le carousel
        final maxItems = itemCount > 5 ? 5 : itemCount;
        final nextPage = (_currentPage + 1) % maxItems;

        if (_pageController.hasClients) {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latestItemsAsync = ref.watch(latestItemsProvider);

    // Écouter les changements de données pour redémarrer le timer
    ref.listen<AsyncValue<List<BaseItemDto>>>(latestItemsProvider, (previous, next) {
      next.whenData((items) {
        if (items.isNotEmpty) {
          _startAutoScroll(items.length);
        }
      });
    });

    return latestItemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyHero(context);
        }

        final heroItems = items.take(5).toList();

        return Container(
          height: widget.isDesktop ? 500 : 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // PageView
                PageView.builder(
                  controller: _pageController,
                  itemCount: heroItems.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    if (mounted) {
                      setState(() {
                        _currentPage = index;
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    final item = heroItems[index];
                    return RepaintBoundary(
                      child: _buildHeroSlide(item),
                    );
                  },
                ),

                // Indicateurs de page
                Positioned(
                  bottom: 24,
                  right: widget.isDesktop ? 48 : 24,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      heroItems.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _buildEmptyHero(context),
      error: (error, stack) => _buildEmptyHero(context),
    );
  }

  Widget _buildHeroSlide(BaseItemDto item) {
    final backdropUrl = getItemBackdropUrl(ref, item, maxWidth: 1920);
    final title = item.name ?? 'Sans titre';
    final overview = item.overview ?? 'Aucune description disponible';
    final year = item.productionYear?.toString() ?? '';

    return Stack(
      children: [
        // Image de fond
        if (backdropUrl != null)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: backdropUrl,
              fit: BoxFit.cover,
              memCacheWidth: widget.isDesktop ? 1920 : 1280,
              memCacheHeight: widget.isDesktop ? 1080 : 720,
              fadeInDuration: const Duration(milliseconds: 300),
              fadeOutDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => Container(
                color: AppColors.surface1,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.jellyfinPurple,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.jellyfinPurple.withValues(alpha: 0.3),
                      AppColors.jellyfinBlue.withValues(alpha: 0.2),
                      AppColors.background3,
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.jellyfinPurple.withValues(alpha: 0.3),
                    AppColors.jellyfinBlue.withValues(alpha: 0.2),
                    AppColors.background3,
                  ],
                ),
              ),
            ),
          ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),

        // Contenu
        Positioned(
          left: widget.isDesktop ? 48 : 24,
          right: widget.isDesktop ? 48 : 24,
          bottom: widget.isDesktop ? 48 : 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Tendance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.jellyfinPurple.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      IconsaxPlusBold.star_1,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tendance',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Titre
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.isDesktop ? 42 : 28,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (year.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  year,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: widget.isDesktop ? 18 : 16,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Description
              Text(
                overview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: widget.isDesktop ? 16 : 14,
                  height: 1.5,
                ),
                maxLines: widget.isDesktop ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Lecture
                      },
                      icon: const Icon(IconsaxPlusBold.play, size: 18),
                      label: const Text('Lecture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.jellyfinPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isDesktop ? 32 : 16,
                          vertical: widget.isDesktop ? 16 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Plus d'infos
                      },
                      icon: const Icon(IconsaxPlusLinear.info_circle, size: 18),
                      label: const Text('Infos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isDesktop ? 32 : 16,
                          vertical: widget.isDesktop ? 16 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHero(BuildContext context) {
    return Container(
      height: widget.isDesktop ? 400 : 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.jellyfinPurple.withValues(alpha: 0.3),
            AppColors.jellyfinBlue.withValues(alpha: 0.2),
            AppColors.background3,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconsaxPlusBold.video_square,
              size: 64,
              color: AppColors.jellyfinPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenue',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.text1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Découvrez vos films et séries préférés',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

