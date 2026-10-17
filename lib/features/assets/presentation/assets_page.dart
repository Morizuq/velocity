import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import 'widgets/asset_velocity_tracker.dart';

/// Presentation page for the Assets bucket.
class AssetsPage extends ConsumerWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wealth Assets'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.l),
        child: AssetVelocityTracker(),
      ),
    );
  }
}
