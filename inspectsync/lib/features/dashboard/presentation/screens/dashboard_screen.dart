import 'package:flutter/material.dart';
import 'package:inspectsync/l10n/app_localizations.dart';
import '../../../tasks/presentation/widgets/task_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.sync_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              l10n.precisionField,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Text(
                'JD',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Sync Status Strip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.allLocalDataSynchronized,
                      style: textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
                  Text(
                    l10n.lastUpdate('2M'),
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Active Operations Header
            Text(
              l10n.activeOperations,
              style: textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: l10n.taskUnitsRemaining(12),
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: ' ${l10n.remaining.toLowerCase()}',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // List/Map Toggle
            Row(
              children: [
                _buildToggleButton(context, l10n.listTab, Icons.list, true),
                const SizedBox(width: 8),
                _buildToggleButton(context, l10n.mapTab, Icons.map, false),
              ],
            ),
            const SizedBox(height: 24),
            // Task List
            const TaskCard(
              title: "Utility Pole Inspection",
              subtitle: "Sector 7G - Structural integrity and equipment inventory audit.",
              time: "08:30 AM",
              status: TaskStatus.synced,
            ),
            const TaskCard(
              title: "Substation Delta-9",
              subtitle: "Image upload timeout. Manual retry required for 4 attachments.",
              status: TaskStatus.failed,
            ),
            const TaskCard(
              title: "Water Main Assessment",
              subtitle: "Awaiting supervisor clearance for confined space entry.",
              location: "Downtown Plaza",
              status: TaskStatus.pending,
            ),
            TaskCard(
              title: "Fiber Backbone Routing",
              subtitle: "Optimizing 4.2km trenching path through residential zone 4. Terrain analysis pending final GPS lock.",
              status: TaskStatus.inProgress,
              imageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=400&auto=format&fit=crop', // Temporary placeholder
            ),
            const SizedBox(height: 24),
            // Daily Velocity Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C), // Deep dark for velocity card
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dailyVelocity,
                    style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildVelocityRow(context, l10n.target, '15', Colors.grey),
                  const SizedBox(height: 12),
                  // Simple progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 12/15,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVelocityRow(context, l10n.achieved, '12', Colors.greenAccent),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  Text(
                    l10n.systemHealthy(12),
                    style: textTheme.bodySmall?.copyWith(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for FAB/Bottom Nav
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context, String label, IconData icon, bool isActive) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.surfaceContainerLowest : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityRow(BuildContext context, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
