import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';
import 'package:jellyfish/providers/jellyseerr_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfish/providers/services_provider.dart';

/// Écran d'affichage des requêtes Jellyseerr
class JellyseerrRequestsScreen extends ConsumerStatefulWidget {
  const JellyseerrRequestsScreen({super.key});

  @override
  ConsumerState<JellyseerrRequestsScreen> createState() =>
      _JellyseerrRequestsScreenState();
}

class _JellyseerrRequestsScreenState
    extends ConsumerState<JellyseerrRequestsScreen> {
  final _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jellyseerr'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text(
                      'Voulez-vous vraiment vous déconnecter de Jellyseerr ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await ref
                    .read(jellyseerrAuthStateProvider.notifier)
                    .logout();
              }
            },
          ),
        ],
      ),
      body: _searchQuery != null
          ? _buildSearchResults()
          : _buildRequestsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSearchDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRequestsList() {
    final requestsAsync = ref.watch(
      jellyseerrRequestsProvider(const RequestsFilter()),
    );

    return requestsAsync.when(
      data: (response) {
        if (response.results.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune requête',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Appuyez sur + pour demander un média',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(jellyseerrRequestsProvider);
          },
          child: ListView.builder(
            itemCount: response.results.length,
            itemBuilder: (context, index) {
              final request = response.results[index];
              return _buildRequestCard(request);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(jellyseerrRequestsProvider);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(JellyseerrRequest request) {
    final storageService = ref.read(storageServiceProvider);
    final serverUrl = storageService.getJellyseerrServerUrl() ?? '';

    return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: request.media.posterPath != null && serverUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: '$serverUrl${request.media.posterPath}',
                      width: 50,
                      height: 75,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 50,
                    height: 75,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.movie),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 50,
                    height: 75,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.movie),
              ),
        title: Text(
          request.media.title ?? 'Titre inconnu',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Type: ${request.media.mediaType}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            _buildStatusChip(request.status),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Supprimer la requête'),
                content: Text(
                    'Voulez-vous vraiment supprimer la requête pour "${request.media.title}" ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              try {
                await ref
                    .read(jellyseerrAuthStateProvider.notifier)
                    .deleteRequest(request.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Requête supprimée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  ref.invalidate(jellyseerrRequestsProvider);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'En attente';
        break;
      case 'approved':
        color = Colors.blue;
        label = 'Approuvé';
        break;
      case 'available':
        color = Colors.green;
        label = 'Disponible';
        break;
      case 'declined':
        color = Colors.red;
        label = 'Refusé';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return const Center(child: Text('Entrez un terme de recherche'));
    }

    final searchAsync = ref.watch(jellyseerrSearchProvider(_searchQuery!));

    return searchAsync.when(
      data: (response) {
        if (response.results.isEmpty) {
          return const Center(
            child: Text('Aucun résultat trouvé'),
          );
        }

        return ListView.builder(
          itemCount: response.results.length,
          itemBuilder: (context, index) {
            final media = response.results[index];
            return _buildMediaCard(media);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }

  Widget _buildMediaCard(MediaSearchResult media) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: media.posterPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: 'https://image.tmdb.org/t/p/w200${media.posterPath}',
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                ),
              )
            : null,
        title: Text(media.displayTitle),
        subtitle: Text(media.displayDate),
        trailing: const Icon(Icons.add_circle_outline),
        onTap: () {
          _showRequestDialog(media);
        },
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher un média'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Titre du film ou de la série',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _searchQuery = null;
              });
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _searchQuery = _searchController.text;
              });
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog(MediaSearchResult media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander ce média'),
        content: Text('Voulez-vous demander "${media.displayTitle}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(jellyseerrAuthStateProvider.notifier)
                    .createRequest(
                      CreateRequestBody(
                        mediaId: media.id,
                        mediaType: media.mediaType,
                      ),
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Requête créée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    _searchQuery = null;
                  });
                  ref.invalidate(jellyseerrRequestsProvider);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Demander'),
          ),
        ],
      ),
    );
  }
}

