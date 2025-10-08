import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import '../theme/app_colors.dart';
import '../providers/cast_provider.dart';

/// Wrapper pour le mini-controller de Cast
/// 
/// Affiche un mini-controller flottant en bas de l'écran quand une session Cast est active.
/// Permet de contrôler rapidement la lecture sans quitter l'écran actuel.
class CastMiniControllerWrapper extends ConsumerWidget {
  final Widget child;

  const CastMiniControllerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ne pas afficher sur web et desktop
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return child;
    }

    final isConnected = ref.watch(isConnectedToCastProvider);

    return Stack(
      children: [
        child,
        if (isConnected)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GoogleCastMiniController(
              theme: GoogleCastPlayerTheme(
                backgroundColor: AppColors.background2,
                titleTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                deviceTextStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w400,
                ),
                iconColor: AppColors.jellyfinPurple,
                iconSize: 24,
                imageBorderRadius: BorderRadius.circular(8),
                imageShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.all(8),
              borderRadius: BorderRadius.circular(12),
              showDeviceName: true,
            ),
          ),
      ],
    );
  }
}

