import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';

/// Widget pour une section collapsible de paramètres
class SettingSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  const SettingSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<SettingSection> createState() => _SettingSectionState();
}

class _SettingSectionState extends State<SettingSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surface1.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icône
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.jellyfinPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: AppColors.jellyfinPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Titre
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.text6,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    // Flèche
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        IconsaxPlusLinear.arrow_down_1,
                        size: 20,
                        color: AppColors.text4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Contenu
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.surface1,
                  indent: 16,
                  endIndent: 16,
                ),
                const SizedBox(height: 8),
                ...widget.children,
                const SizedBox(height: 8),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

