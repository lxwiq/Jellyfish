import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:jellyfish/theme/app_colors.dart';

/// Bouton de demande de média avec états (disponible, demandé, en cours)
class MediaRequestButton extends StatelessWidget {
  final bool isRequesting;
  final bool isRequested;
  final bool isAvailable;
  final VoidCallback onRequest;
  final bool isDesktop;

  const MediaRequestButton({
    super.key,
    required this.isRequesting,
    required this.isRequested,
    required this.isAvailable,
    required this.onRequest,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: isDesktop ? 56 : 50,
        child: ElevatedButton.icon(
          onPressed: isRequesting || isRequested || isAvailable
              ? null
              : onRequest,
          icon: _getIcon(),
          label: Text(
            _getLabel(),
            style: TextStyle(
              fontSize: isDesktop ? 16 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getBackgroundColor(),
            foregroundColor: _getForegroundColor(),
            disabledBackgroundColor: _getDisabledBackgroundColor(),
            disabledForegroundColor: _getDisabledForegroundColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _getIcon() {
    if (isRequesting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.text6,
        ),
      );
    }

    if (isAvailable) {
      return const Icon(IconsaxPlusBold.tick_circle);
    }

    if (isRequested) {
      return const Icon(IconsaxPlusBold.clock);
    }

    return const Icon(IconsaxPlusBold.add_circle);
  }

  String _getLabel() {
    if (isRequesting) {
      return 'Demande en cours...';
    }

    if (isAvailable) {
      return 'Disponible sur Jellyfin';
    }

    if (isRequested) {
      return 'Déjà demandé';
    }

    return 'Demander ce contenu';
  }

  Color _getBackgroundColor() {
    return AppColors.jellyfinPurple;
  }

  Color _getForegroundColor() {
    return AppColors.text6;
  }

  Color _getDisabledBackgroundColor() {
    if (isAvailable) {
      return Colors.green.withValues(alpha: 0.3);
    }

    if (isRequested) {
      return AppColors.surface1;
    }

    return AppColors.surface1;
  }

  Color _getDisabledForegroundColor() {
    if (isAvailable) {
      return Colors.green;
    }

    if (isRequested) {
      return AppColors.text4;
    }

    return AppColors.text4;
  }
}

