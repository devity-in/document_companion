import 'package:document_companion/config/custom_colors.dart';
import 'package:document_companion/config/custom_theme.dart';
import 'package:document_companion/modules/home/services/ad_service.dart';
import 'package:document_companion/utils/ux_helpers.dart';
import 'package:document_companion/local_database/document_file_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatefulWidget {
  static const String route = '/settings';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _checkAdStatus();
    // Check ad status periodically
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAdReady = adService.isRewardedAdReady;
        });
      }
    });
  }

  Future<void> _showStorageDialog(BuildContext context) async {
    final usage = await documentFileStore.usage();
    if (!context.mounted) return;
    final megabytes = usage.bytes / (1024 * 1024);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage'),
        content: Text(
          '${usage.files} document${usage.files == 1 ? '' : 's'} using '
          '${megabytes.toStringAsFixed(megabytes < 10 ? 1 : 0)} MB on this device.\n\n'
          'Documents are stored only on this device. Delete documents or '
          'folders you no longer need to free up space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _checkAdStatus() {
    setState(() {
      _isAdReady = adService.isRewardedAdReady;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CustomTheme();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            UXHelpers.selectionFeedback();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Appearance Section
          _SettingsSection(
            title: 'Appearance',
            children: [
              _SettingsTile(
                leading: Icon(
                  theme.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: CustomColors.primary,
                ),
                title: 'Theme',
                subtitle: theme.isDarkMode ? 'Dark Mode' : 'Light Mode',
                trailing: Switch(
                  value: theme.isDarkMode,
                  onChanged: (value) {
                    UXHelpers.selectionFeedback();
                    theme.toggleTheme();
                    setState(() {});
                    UXHelpers.successFeedback();
                  },
                  activeThumbColor: CustomColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // General Section
          _SettingsSection(
            title: 'General',
            children: [
              _SettingsTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: CustomColors.primary,
                ),
                title: 'About',
                subtitle: 'App version and information',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: CustomColors.textTertiary,
                ),
                onTap: () {
                  UXHelpers.selectionFeedback();
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Premium Section
          _SettingsSection(
            title: 'Premium',
            children: [
              _SettingsTile(
                leading: Icon(
                  Icons.ads_click_rounded,
                  color: CustomColors.primary,
                ),
                title: 'Remove Ads',
                subtitle: adService.adsDisabled
                    ? 'Ad-free until ${DateFormat('EEE h:mm a').format(adService.adsDisabledUntil.value!)}'
                    : 'Watch an ad to remove ads for 24 hours',
                trailing: Icon(
                  Icons.play_circle_outline_rounded,
                  color: CustomColors.primary,
                ),
                onTap: () {
                  UXHelpers.selectionFeedback();
                  _showRemoveAdsDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Section
          _SettingsSection(
            title: 'Data',
            children: [
              _SettingsTile(
                leading: Icon(
                  Icons.storage_rounded,
                  color: CustomColors.primary,
                ),
                title: 'Storage',
                subtitle: 'Manage app storage',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: CustomColors.textTertiary,
                ),
                onTap: () {
                  UXHelpers.selectionFeedback();
                  _showStorageDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vision & Roadmap Section
          _SettingsSection(
            title: 'Vision',
            children: [
              _SettingsTile(
                leading: Icon(
                  Icons.auto_awesome_rounded,
                  color: CustomColors.primary,
                ),
                title: 'Roadmap',
                subtitle: 'See what\'s coming next',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: CustomColors.textTertiary,
                ),
                onTap: () {
                  UXHelpers.selectionFeedback();
                  _showRoadmapDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRemoveAdsDialog(BuildContext context) {
    _checkAdStatus();
    final isAdReady = _isAdReady;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.ads_click_rounded, color: CustomColors.primary),
            SizedBox(width: 12),
            Text('Remove Ads'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Watch a short ad to remove all ads from the app for 24 hours.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: CustomColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('No banner ads', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: CustomColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'No interstitial ads',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: CustomColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ad-free experience',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            if (!isAdReady) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ad is loading. Please wait a moment.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              UXHelpers.selectionFeedback();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isAdReady
                ? () {
                    UXHelpers.selectionFeedback();
                    Navigator.of(context).pop();

                    // Show rewarded ad
                    final shown = adService.showRewardedAd(
                      onRewarded: () {
                        adService.disableAdsFor(const Duration(hours: 24));
                        if (mounted) setState(() {});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ads removed for 24 hours! 🎉'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          UXHelpers.successFeedback();
                        }
                      },
                      onAdDismissed: () {
                        // Ad was dismissed (user may or may not have earned reward)
                        if (context.mounted) {
                          _checkAdStatus();
                        }
                      },
                      onAdFailedToShow: (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to show ad: $error'),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          _checkAdStatus();
                        }
                      },
                    );

                    if (!shown && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ad is loading. Please try again in a moment.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isAdReady) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Text('Watch Ad'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRoadmapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.rocket_launch_rounded, color: CustomColors.primary),
            const SizedBox(width: 12),
            const Text('Product Roadmap'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoadmapPhase(
                phase: 'Phase 1: Core Foundation',
                status: '✅ Complete',
                features: [
                  'Document Scanning',
                  'Folder Organization',
                  'PDF Operations',
                  'File Import',
                  'Search & Filter',
                ],
                isComplete: true,
              ),
              const SizedBox(height: 16),
              _RoadmapPhase(
                phase: 'Phase 2: Enhancement',
                status: '🚧 In Progress',
                features: [
                  'OCR (Text Recognition)',
                  'Document Annotations',
                  'Digital Signatures',
                  'Basic Image Editing',
                ],
                isComplete: false,
              ),
              const SizedBox(height: 16),
              _RoadmapPhase(
                phase: 'Phase 3: Advanced Features',
                status: '📅 Coming Soon',
                features: [
                  'Local Backup & Export',
                  'Advanced PDF Editing',
                  'Receipt Management',
                  'Business Card Scanner',
                ],
                isComplete: false,
              ),
              const SizedBox(height: 16),
              _RoadmapPhase(
                phase: 'Phase 4: Security & Privacy',
                status: '📅 Planned',
                features: [
                  'App Lock & Encryption',
                  'Secure Document Storage',
                  'Password Protection',
                  'Advanced Security Features',
                ],
                isComplete: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              UXHelpers.selectionFeedback();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CustomColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: CustomColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Document Companion')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your complete document solution. Scan, organize, convert, and manage all your documents in one place.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CustomColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CustomColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        size: 16,
                        color: CustomColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: CustomColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• OCR (Text Recognition)\n• Document Annotations\n• Digital Signatures\n• Local Backup & Export\n• Advanced PDF Editing',
                    style: TextStyle(
                      fontSize: 11,
                      color: CustomColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12, color: CustomColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              UXHelpers.selectionFeedback();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CustomColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _RoadmapPhase extends StatelessWidget {
  final String phase;
  final String status;
  final List<String> features;
  final bool isComplete;

  const _RoadmapPhase({
    required this.phase,
    required this.status,
    required this.features,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete
            ? CustomColors.accent.withValues(alpha: 0.05)
            : CustomColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? CustomColors.accent.withValues(alpha: 0.2)
              : CustomColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  phase,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isComplete
                        ? CustomColors.accent
                        : CustomColors.primary,
                  ),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  color: CustomColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    isComplete ? Icons.check_circle : Icons.circle_outlined,
                    size: 14,
                    color: isComplete
                        ? CustomColors.accent
                        : CustomColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 11,
                        color: CustomColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}
