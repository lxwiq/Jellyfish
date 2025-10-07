import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services_provider.dart';
import '../../services/update_service.dart';
import '../onboarding_screen.dart';

/// Écran des paramètres de l'application
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;
  DateTime? _lastUpdateCheck;
  DateTime? _lastUpdateApplied;
  String? _currentPatchNumber;
  List<UpdateHistoryEntry> _updateHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadUpdateInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _loadUpdateInfo() async {
    final lastCheck = await UpdateService.instance.getLastUpdateCheck();
    final lastApplied = await UpdateService.instance.getLastUpdateApplied();
    final patchNumber = await UpdateService.instance.getCurrentPatchNumber();
    final history = await UpdateService.instance.getUpdateHistory();

    setState(() {
      _lastUpdateCheck = lastCheck;
      _lastUpdateApplied = lastApplied;
      _currentPatchNumber = patchNumber;
      _updateHistory = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final storageService = ref.watch(storageServiceProvider);
    final serverUrl = storageService.getServerUrl();
    final deviceId = storageService.getOrCreateDeviceId();

    return Scaffold(
      backgroundColor: AppColors.background1,
      appBar: AppBar(
        backgroundColor: AppColors.background2,
        foregroundColor: AppColors.text6,
        elevation: 0,
        title: Text(
          'Paramètres',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text6,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Utilisateur
          _buildSectionTitle(context, 'Compte', IconsaxPlusLinear.user),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            children: [
              _buildInfoRow(
                context,
                icon: IconsaxPlusLinear.user,
                label: 'Utilisateur',
                value: authState.user?.name ?? 'Non connecté',
              ),
              if (authState.user?.email != null) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: IconsaxPlusLinear.sms,
                  label: 'Email',
                  value: authState.user!.email!,
                ),
              ],
              const Divider(height: 24),
              _buildInfoRow(
                context,
                icon: authState.user?.isAdmin == true
                    ? IconsaxPlusLinear.shield_tick
                    : IconsaxPlusLinear.user,
                label: 'Rôle',
                value: authState.user?.isAdmin == true ? 'Administrateur' : 'Utilisateur',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Section Serveur
          _buildSectionTitle(context, 'Serveur', IconsaxPlusLinear.global),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            children: [
              _buildInfoRow(
                context,
                icon: IconsaxPlusLinear.link,
                label: 'URL du serveur',
                value: serverUrl ?? 'Non configuré',
              ),
              const Divider(height: 24),
              _buildInfoRow(
                context,
                icon: IconsaxPlusLinear.mobile,
                label: 'ID de l\'appareil',
                value: '${deviceId.substring(0, 8)}...',
                subtitle: 'Identifiant unique de cet appareil',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Section Application
          _buildSectionTitle(context, 'Application', IconsaxPlusLinear.info_circle),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            children: [
              _buildInfoRow(
                context,
                icon: IconsaxPlusLinear.code,
                label: 'Version',
                value: _packageInfo != null
                    ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                    : 'Chargement...',
              ),
              const Divider(height: 24),
              _buildInfoRow(
                context,
                icon: IconsaxPlusLinear.document_text,
                label: 'Nom de l\'app',
                value: _packageInfo?.appName ?? 'Jellyfish',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Section Mises à jour
          _buildSectionTitle(context, 'Mises à jour', IconsaxPlusLinear.refresh),
          const SizedBox(height: 12),
          _buildUpdateSection(context),

          const SizedBox(height: 32),

          // Bouton de déconnexion
          _buildLogoutButton(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.jellyfinPurple,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.background3,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.text4,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.text5,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateSection(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return _buildInfoCard(
      context,
      children: [
        _buildInfoRow(
          context,
          icon: IconsaxPlusLinear.tick_circle,
          label: 'Statut',
          value: _lastUpdateApplied != null
              ? 'Application à jour'
              : 'Aucune mise à jour appliquée',
        ),
        if (_currentPatchNumber != null) ...[
          const Divider(height: 24),
          _buildInfoRow(
            context,
            icon: IconsaxPlusLinear.code_circle,
            label: 'Patch actuel',
            value: _currentPatchNumber!,
          ),
        ],
        if (_lastUpdateCheck != null) ...[
          const Divider(height: 24),
          _buildInfoRow(
            context,
            icon: IconsaxPlusLinear.clock,
            label: 'Dernière vérification',
            value: dateFormat.format(_lastUpdateCheck!),
          ),
        ],
        if (_lastUpdateApplied != null) ...[
          const Divider(height: 24),
          _buildInfoRow(
            context,
            icon: IconsaxPlusLinear.refresh_circle,
            label: 'Dernière mise à jour',
            value: dateFormat.format(_lastUpdateApplied!),
          ),
        ],
        if (_updateHistory.isNotEmpty) ...[
          const Divider(height: 24),
          const SizedBox(height: 8),
          Text(
            'Historique des mises à jour',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._updateHistory.take(5).map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  IconsaxPlusLinear.tick_square,
                  size: 16,
                  color: AppColors.jellyfinPurple.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateFormat.format(entry.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.text3,
                    ),
                  ),
                ),
                if (entry.patchNumber != null)
                  Text(
                    'Patch ${entry.patchNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.text5,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showLogoutDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  IconsaxPlusLinear.logout,
                  size: 20,
                  color: Colors.red.shade400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Se déconnecter',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  size: 16,
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Text(
          'Déconnexion',
          style: TextStyle(color: AppColors.text1),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: AppColors.text3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.text4),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authStateProvider.notifier).logout();

      if (!mounted) return;

      // Retourner à l'écran d'onboarding
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
        (route) => false,
      );
    }
  }
}

