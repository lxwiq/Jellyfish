import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/offline_download_provider.dart';

/// Badge indiquant qu'un item est téléchargé
class DownloadedBadge extends ConsumerWidget {
  final String itemId;
  final double size;

  const DownloadedBadge({
    super.key,
    required this.itemId,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloadedAsync = ref.watch(isItemDownloadedProvider(itemId));

    return isDownloadedAsync.when(
      data: (isDownloaded) {
        if (!isDownloaded) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.download_done,
            size: size,
            color: Colors.white,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

