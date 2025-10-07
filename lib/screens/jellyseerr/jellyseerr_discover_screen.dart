import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:jellyfish/theme/app_colors.dart';
import 'package:jellyfish/providers/jellyseerr_provider.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';
import 'package:jellyfish/widgets/horizontal_carousel.dart';
import 'package:jellyfish/widgets/card_constants.dart';
import 'widgets/jellyseerr_media_card.dart';
import 'widgets/jellyseerr_section_title.dart';
import 'jellyseerr_search_screen.dart';

/// Écran de découverte de contenu Jellyseerr redesigné
/// Suit les patterns de design de l'application
class JellyseerrDiscoverScreen extends ConsumerStatefulWidget {
  const JellyseerrDiscoverScreen({super.key});

  @override
  ConsumerState<JellyseerrDiscoverScreen> createState() =>
      _JellyseerrDiscoverScreenState();
}

class _JellyseerrDiscoverScreenState
    extends ConsumerState<JellyseerrDiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: AppColors.background1,
      body: CustomScrollView(
        slivers: [
          // AppBar avec design cohérent
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background2,
            foregroundColor: AppColors.text6,
            elevation: 0,
            title: Row(
              children: [
                Image.asset(
                  'assets/icons/jellyseerr.png',
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Jellyseerr',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text6,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  IconsaxPlusLinear.search_normal,
                  color: AppColors.jellyfinPurple,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const JellyseerrSearchScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  IconsaxPlusLinear.logout,
                  color: AppColors.text4,
                ),
                onPressed: () async {
                  await ref.read(jellyseerrAuthStateProvider.notifier).logout();
                },
              ),
              SizedBox(width: isDesktop ? 16 : 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.jellyfinPurple,
              labelColor: AppColors.jellyfinPurple,
              unselectedLabelColor: AppColors.text4,
              tabs: const [
                Tab(
                  text: 'Tendances',
                  icon: Icon(IconsaxPlusBold.trend_up),
                ),
                Tab(
                  text: 'Films',
                  icon: Icon(IconsaxPlusBold.video_square),
                ),
                Tab(
                  text: 'Séries',
                  icon: Icon(IconsaxPlusBold.monitor),
                ),
              ],
            ),
          ),

          // Contenu des tabs
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTrendingTab(isDesktop, isTablet),
                _buildMoviesTab(isDesktop, isTablet),
                _buildTvTab(isDesktop, isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTab(bool isDesktop, bool isTablet) {
    final trendingAsync = ref.watch(jellyseerrTrendingProvider(1));

    return trendingAsync.when(
      data: (response) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(jellyseerrTrendingProvider);
        },
        color: AppColors.jellyfinPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JellyseerrSectionTitle(
                  title: 'Tendances du moment',
                  icon: IconsaxPlusBold.trend_up,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),
                _buildMediaCarousel(response.results, isDesktop, isTablet),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.jellyfinPurple,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error.toString(),
        () => ref.invalidate(jellyseerrTrendingProvider),
        isDesktop,
      ),
    );
  }

  Widget _buildMoviesTab(bool isDesktop, bool isTablet) {
    final moviesAsync = ref.watch(jellyseerrPopularMoviesProvider(1));

    return moviesAsync.when(
      data: (response) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(jellyseerrPopularMoviesProvider);
        },
        color: AppColors.jellyfinPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JellyseerrSectionTitle(
                  title: 'Films populaires',
                  icon: IconsaxPlusBold.video_square,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),
                _buildMediaCarousel(response.results, isDesktop, isTablet),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.jellyfinPurple,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error.toString(),
        () => ref.invalidate(jellyseerrPopularMoviesProvider),
        isDesktop,
      ),
    );
  }

  Widget _buildTvTab(bool isDesktop, bool isTablet) {
    final tvAsync = ref.watch(jellyseerrPopularTvProvider(1));

    return tvAsync.when(
      data: (response) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(jellyseerrPopularTvProvider);
        },
        color: AppColors.jellyfinPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JellyseerrSectionTitle(
                  title: 'Séries populaires',
                  icon: IconsaxPlusBold.monitor,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),
                _buildMediaCarousel(response.results, isDesktop, isTablet),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.jellyfinPurple,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error.toString(),
        () => ref.invalidate(jellyseerrPopularTvProvider),
        isDesktop,
      ),
    );
  }

  Widget _buildMediaCarousel(
    List<MediaSearchResult> media,
    bool isDesktop,
    bool isTablet,
  ) {
    if (media.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Center(
          child: Column(
            children: [
              Icon(
                IconsaxPlusBold.box,
                size: 64,
                color: AppColors.text2,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun contenu disponible',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  color: AppColors.text4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sizes = CardSizeHelper.getSizes(isDesktop, isTablet);
    final cardHeight = sizes.posterTotalHeight;

    return HorizontalCarousel(
      height: cardHeight,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
      spacing: isDesktop ? 16 : 12,
      children: media.map((item) {
        return JellyseerrMediaCard(
          media: item,
          isDesktop: isDesktop,
          isTablet: isTablet,
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(
    String error,
    VoidCallback onRetry,
    bool isDesktop,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                color: AppColors.text5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13,
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.jellyfinPurple,
                foregroundColor: AppColors.text6,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}