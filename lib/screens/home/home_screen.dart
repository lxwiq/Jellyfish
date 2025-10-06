import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../theme/app_colors.dart';
import '../settings/settings_screen.dart';
import 'widgets/home_hero_carousel.dart';
import 'widgets/continue_watching_section.dart';
import 'widgets/next_up_section.dart';
import 'widgets/library_latest_section.dart';

/// Écran d'accueil principal
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: AppColors.background1,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background2,
            foregroundColor: AppColors.text6,
            elevation: 0,
            title: Row(
              children: [
                Icon(
                  IconsaxPlusBold.video_square,
                  color: AppColors.jellyfinPurple,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Jellyfish',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text6,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(IconsaxPlusLinear.notification),
                color: AppColors.text4,
                onPressed: () {
                  // TODO: Ouvrir les notifications
                },
              ),
              IconButton(
                icon: const Icon(IconsaxPlusLinear.setting_2, size: 20),
                color: AppColors.text3,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Carousel
                  HomeHeroCarousel(isDesktop: isDesktop),
                  
                  const SizedBox(height: 48),

                  // Section Reprise de lecture
                  _buildSectionTitle(context, 'Reprise de lecture', IconsaxPlusLinear.play_circle),
                  const SizedBox(height: 16),
                  ContinueWatchingSection(isDesktop: isDesktop, isTablet: isTablet),

                  const SizedBox(height: 48),

                  // Section Prochains épisodes
                  _buildSectionTitle(context, 'Prochains épisodes', IconsaxPlusLinear.video_play),
                  const SizedBox(height: 16),
                  NextUpSection(isDesktop: isDesktop, isTablet: isTablet),

                  const SizedBox(height: 48),

                  // Section Récemment ajouté (par bibliothèque)
                  _buildSectionTitle(context, 'Récemment ajouté', IconsaxPlusLinear.clock),
                  const SizedBox(height: 16),
                  LibraryLatestSection(isDesktop: isDesktop, isTablet: isTablet),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: AppColors.jellyfinPurple,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text1,
          ),
        ),
      ],
    );
  }
}

