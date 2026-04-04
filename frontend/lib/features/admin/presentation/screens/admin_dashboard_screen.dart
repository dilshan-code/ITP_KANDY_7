import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/admin/presentation/providers/admin_provider.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';
import 'package:frontend/features/admin/presentation/screens/manage_feedback_screen.dart';
import 'package:frontend/features/account/presentation/providers/feedback_provider.dart';


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await adminProvider.fetchOwners();
            if (context.mounted) {
              await adminProvider.fetchSystemHealth();
              if (context.mounted) {
                await context.read<FeedbackProvider>().fetchAllFeedback();
              }
            }
          },

          color: Colors.indigo,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, adminProvider),
                const SizedBox(height: 32),
                if (adminProvider.isLoading && adminProvider.owners.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: Colors.indigo),
                    ),
                  )
                else ...[
                  _buildStatCards(context, adminProvider),
                  const SizedBox(height: 32),

                  _buildSystemHealth(adminProvider),
                  const SizedBox(height: 32),
                  _buildRecentActivity(adminProvider),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Dashboard',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview of ClickBuy partner network',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        IconButton.filled(
          onPressed: provider.isLoading
              ? null
              : () async {
                  await provider.fetchOwners();
                  if (context.mounted) {
                    await provider.fetchSystemHealth();
                    if (context.mounted) {
                      await context.read<FeedbackProvider>().fetchAllFeedback();
                    }
                  }
                },
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            side: BorderSide(color: Colors.grey[200]!),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: provider.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 22),
        ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context, AdminProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _AdminStatCard(
            title: 'Total Owners',
            value: provider.totalOwners.toString(),
            icon: Icons.storefront,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Consumer<FeedbackProvider>(
            builder: (context, feedbackProvider, _) {
              return _AdminStatCard(
                title: 'User Feedback',
                value: feedbackProvider.feedbacks.length.toString(),
                icon: Icons.feedback_outlined,
                color: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageFeedbackScreen()),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildSystemHealth(AdminProvider provider) {
    final mongo = provider.systemHealth;
    final storage = mongo?['storageUsed'] ?? 'Optimal';
    final reads = mongo?['reads']?.toString() ?? '...';
    final writes = mongo?['writes']?.toString() ?? '...';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Health',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'STABLE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHealthRow('MongoDB Storage', storage, Colors.indigo),
          _buildHealthRow('DB Network Load', 'Reads: $reads | Writes: $writes', Colors.green),
          _buildHealthRow('API Server', 'Running', Colors.green),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String service, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            service,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AdminProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Partner Network',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (provider.owners.isNotEmpty)
              Text(
                '${provider.totalOwners} Total',
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.owners.isEmpty)
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, color: Colors.grey[300], size: 40),
                const SizedBox(height: 12),
                Text(
                  'No owners found',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          )
        else
          Column(
            children: (provider.owners.toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                .take(3)
                .map((owner) => _OwnerMiniTile(owner: owner))
                .toList(),
          ),
      ],
    );
  }
}

class _OwnerMiniTile extends StatelessWidget {
  final Owner owner;
  const _OwnerMiniTile({required this.owner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.withValues(alpha: 0.1),
            child: const Icon(Icons.store, color: Colors.indigo, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner.shopName.isNotEmpty ? owner.shopName : 'Unknown Shop',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  owner.name,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(

      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

