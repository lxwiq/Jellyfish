import 'package:flutter/material.dart';
import 'package:jellyfish/theme/app_colors.dart';

/// Section de synopsis/overview du média
class MediaOverviewSection extends StatefulWidget {
  final String overview;
  final bool isDesktop;

  const MediaOverviewSection({
    super.key,
    required this.overview,
    this.isDesktop = false,
  });

  @override
  State<MediaOverviewSection> createState() => _MediaOverviewSectionState();
}

class _MediaOverviewSectionState extends State<MediaOverviewSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.overview.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 32 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Synopsis',
            style: TextStyle(
              fontSize: widget.isDesktop ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text6,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              widget.overview,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: widget.isDesktop ? 15 : 14,
                color: AppColors.text5,
                height: 1.5,
              ),
            ),
            secondChild: Text(
              widget.overview,
              style: TextStyle(
                fontSize: widget.isDesktop ? 15 : 14,
                color: AppColors.text5,
                height: 1.5,
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (widget.overview.length > 200)
            TextButton(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Voir moins' : 'Voir plus',
                    style: const TextStyle(
                      color: AppColors.jellyfinPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.jellyfinPurple,
                    size: 20,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

