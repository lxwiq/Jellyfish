import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../models/github_release.dart';
import '../../services/native_update_service.dart';
import 'package:intl/intl.dart';

/// Dialog pour afficher les détails d'une mise à jour native disponible
class NativeUpdateDialog extends StatefulWidget {
  final GitHubRelease release;

  const NativeUpdateDialog({
    super.key,
    required this.release,
  });

  @override
  State<NativeUpdateDialog> createState() => _NativeUpdateDialogState();
}

class _NativeUpdateDialogState extends State<NativeUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parser la date de publication de manière sécurisée
    DateTime publishedDate;
    String formattedDate;
    try {
      publishedDate = DateTime.parse(widget.release.publishedAt);
      formattedDate = DateFormat('dd/MM/yyyy').format(publishedDate);
    } catch (e) {
      formattedDate = 'Date inconnue';
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            IconsaxPlusBold.refresh,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Mise à jour disponible'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    IconsaxPlusBold.code,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Version ${widget.release.version}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Publiée le $formattedDate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notes de version
            Text(
              'Nouveautés',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                widget.release.body.isNotEmpty
                    ? widget.release.body
                    : 'Aucune note de version disponible.',
                style: theme.textTheme.bodyMedium,
              ),
            ),

            // Barre de progression
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Bouton "Ignorer cette version"
        if (!_isDownloading)
          TextButton(
            onPressed: () async {
              await NativeUpdateService.instance.skipVersion(widget.release.version);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Version ${widget.release.version} ignorée'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Ignorer'),
          ),

        // Bouton "Plus tard"
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),

        // Bouton "Télécharger"
        if (!_isDownloading)
          FilledButton.icon(
            onPressed: _downloadAndInstall,
            icon: const Icon(IconsaxPlusLinear.document_download),
            label: const Text('Télécharger'),
          ),
      ],
    );
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Téléchargement en cours...';
      _downloadProgress = 0.0;
    });

    // Capture Navigator & ScaffoldMessenger before async gaps to avoid using context later
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);


    final success = await NativeUpdateService.instance.downloadAndInstall(
      widget.release,
      onProgress: (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      },
    );

    if (!context.mounted) return;


    if (success) {
      setState(() {
        _statusMessage = 'Installation en cours...';
      });

      // Attendre un peu pour que l'utilisateur voie le message
      await Future.delayed(const Duration(seconds: 1));

      if (!context.mounted) return;
      navigator.pop();
    } else {
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Erreur lors du téléchargement';
      });


      if (!context.mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du téléchargement de la mise à jour'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

