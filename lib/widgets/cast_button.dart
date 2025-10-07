import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../providers/cast_provider.dart';
import '../theme/app_colors.dart';

/// Bouton pour afficher et gérer les appareils Chromecast
class CastButton extends ConsumerWidget {
  final Color? iconColor;
  final double? iconSize;

  const CastButton({
    super.key,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedToCastProvider);
    final devicesAsync = ref.watch(castDevicesProvider);

    return IconButton(
      icon: Icon(
        isConnected ? IconsaxPlusBold.screenmirroring : IconsaxPlusLinear.screenmirroring,
        color: isConnected ? AppColors.jellyfinPurple : (iconColor ?? Colors.white),
        size: iconSize,
      ),
      tooltip: isConnected ? 'Connecté au Cast' : 'Caster',
      onPressed: () {
        _showCastDevicesDialog(context, ref, devicesAsync);
      },
    );
  }

  void _showCastDevicesDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue devicesAsync,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Row(
          children: [
            Icon(
              IconsaxPlusBold.screenmirroring,
              color: AppColors.jellyfinPurple,
            ),
            const SizedBox(width: 12),
            Text(
              'Appareils disponibles',
              style: TextStyle(color: AppColors.text6),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: devicesAsync.when(
            data: (devices) {
              if (devices.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconsaxPlusLinear.search_status,
                        size: 48,
                        color: AppColors.text4,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun appareil trouvé',
                        style: TextStyle(
                          color: AppColors.text5,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Assurez-vous que votre Chromecast est allumé et sur le même réseau',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text4,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final isConnected = ref.watch(castSessionProvider).value?.device?.deviceID == device.deviceID;

                  return ListTile(
                    leading: Icon(
                      IconsaxPlusBold.monitor,
                      color: isConnected ? AppColors.jellyfinPurple : AppColors.text5,
                    ),
                    title: Text(
                      device.friendlyName,
                      style: TextStyle(
                        color: AppColors.text6,
                        fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      device.modelName ?? 'Chromecast',
                      style: TextStyle(color: AppColors.text4),
                    ),
                    trailing: isConnected
                        ? Icon(
                            IconsaxPlusBold.tick_circle,
                            color: AppColors.jellyfinPurple,
                          )
                        : null,
                    onTap: isConnected
                        ? null
                        : () async {
                            final castService = ref.read(castServiceProvider);
                            final success = await castService.connectToDevice(device);
                            
                            if (context.mounted) {
                              if (success) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Connecté à ${device.friendlyName}'),
                                    backgroundColor: AppColors.jellyfinPurple,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Échec de la connexion à ${device.friendlyName}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(
                  color: AppColors.jellyfinPurple,
                ),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconsaxPlusLinear.danger,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur lors de la recherche',
                    style: TextStyle(
                      color: AppColors.text5,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text4,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          // Bouton déconnexion si connecté
          if (ref.watch(isConnectedToCastProvider))
            TextButton(
              onPressed: () async {
                final castService = ref.read(castServiceProvider);
                await castService.disconnect();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Déconnecter',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(color: AppColors.text5),
            ),
          ),
        ],
      ),
    );
  }
}

