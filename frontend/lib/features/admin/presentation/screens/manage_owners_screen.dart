// ------------------------------------------------------------------------------
// File: manage_owners_screen.dart
// Purpose: Granular control interface for platform-wide grocery store accounts.
// Rationale: Implements the full lifecycle management for Shop Owners, including
//   complex search/filtering, account suspension toggle, and record deletion. 
//   Serves as the primary defensive tool against system abuse or churn metadata.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Material framework
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/utils/snackbar_utils.dart'; // Utils: Feedback surface
import 'package:frontend/features/admin/presentation/providers/admin_provider.dart'; // State: Administrative data source
import 'package:frontend/features/admin/presentation/utils/owner_pdf_utils.dart'; // Utils: PDF report generator
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: User identity model
import 'package:frontend/shared/widgets/modern_pdf_icon.dart'; // UI: Custom asset widgets
import 'package:frontend/shared/widgets/shimmer_loading.dart'; // UI: Async state indicators
import 'package:frontend/shared/widgets/tactile_scale.dart'; // UI: Interaction physics
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design tokens
import 'package:animate_do/animate_do.dart'; // UI: Motion design framework


class ManageOwnersScreen extends StatefulWidget {
  const ManageOwnersScreen({super.key});

  @override
  State<ManageOwnersScreen> createState() => _ManageOwnersScreenState();
}

class _ManageOwnersScreenState extends State<ManageOwnersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final filteredOwners = _buildFilteredOwners(adminProvider.owners);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Owner Management',
          style: TextStyle(
            color: Color(0xFF16302B),
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        actions: [
          TactileScale(
            onTap: adminProvider.isLoading || filteredOwners.isEmpty
                ? null
                : () => OwnerPdfUtils.generateOwnerListPdf(
                      owners: filteredOwners,
                      filterName: _selectedFilter,
                    ),
            child: IconButton(
              tooltip: 'Export to PDF',
              onPressed: null, // Handled by TactileScale
              icon: const ModernPdfIcon(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: adminProvider.isLoading && adminProvider.owners.isEmpty
            ? _buildOwnersShimmer()
            : RefreshIndicator(
                onRefresh: () => context.read<AdminProvider>().fetchOwners(),
                color: const Color(0xFF0F9D58),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  children: [
                    _OverviewPanel(provider: adminProvider),
                    const SizedBox(height: 18),
                    _SearchBar(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _StatusFilters(
                      selectedFilter: _selectedFilter,
                      onChanged: (value) =>
                          setState(() => _selectedFilter = value),
                      provider: adminProvider,
                    ),
                    const SizedBox(height: 18),
                    if (adminProvider.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDA4AF)),
                        ),
                        child: Text(
                          adminProvider.error!,
                          style: const TextStyle(
                            color: Color(0xFFBE123C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Owner Accounts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16302B),
                          ),
                        ),
                        Text(
                          '${filteredOwners.length} shown',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5E7A73),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (filteredOwners.isEmpty)
                      _EmptyOwnersState(activeFilter: _selectedFilter)
                    else
                      ...filteredOwners.indexed.map(
                        (entry) => FadeInLeft(
                          duration: const Duration(milliseconds: 500),
                          delay: Duration(milliseconds: entry.$1 * 100),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _OwnerCard(owner: entry.$2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOwnersShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ShimmerLoading(
            isLoading: true,
            child: ShimmerSkeleton(height: 180, borderRadius: 24),
          ),
        ),
      ),
    );
  }

  List<Owner> _buildFilteredOwners(List<Owner> owners) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = owners.where((owner) {
      // Reactive switch: Filtering by operational status (Active vs Suspended).
      final matchesFilter = switch (_selectedFilter) {
        'active' =>
          owner.isSuspended == false && owner.status != 'suspended',
        'suspended' =>
          owner.isSuspended == true || owner.status == 'suspended',
        _ => true,
      };

      // Multi-criteria aggregation: Searching across name, shop, phone, and email.
      final searchable = [
        owner.name,
        owner.shopName,
        owner.phone,
        owner.email,
        owner.status,
      ].join(' ').toLowerCase();

      final matchesQuery = query.isEmpty || searchable.contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    filtered.sort((a, b) {
      // Priority sorting: Show suspended accounts at the bottom or highlighted depending on rank.
      final rankA = _statusRank(a);
      final rankB = _statusRank(b);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  int _statusRank(Owner owner) {
    if (owner.isSuspended || owner.status == 'suspended') return 1;
    return 0;
  }
}

class _OverviewPanel extends StatelessWidget {
  final AdminProvider provider;

  const _OverviewPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF163D35), Color(0xFF0F9D58)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163D35).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Owner account control',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update owner profiles, suspend risky accounts, and delete records that should no longer stay in the system.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Active',
                  value: provider.activeOwners.toString(),
                  tint: const Color(0xFFB7F7CE),
                  isLoading: provider.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Suspended',
                  value: provider.suspendedOwners.toString(),
                  tint: const Color(0xFFFFC9D2),
                  isLoading: provider.isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color tint;
  final bool isLoading;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.tint,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: tint,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by owner, shop, email, phone, or status',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;
  final AdminProvider provider;

  const _StatusFilters({
    required this.selectedFilter,
    required this.onChanged,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'All', provider.totalOwners),
      ('active', 'Active', provider.activeOwners),
      ('suspended', 'Suspended', provider.suspendedOwners),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((entry) {
          final isSelected = selectedFilter == entry.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text('${entry.$2} (${entry.$3})'),
              selected: isSelected,
              onSelected: (_) => onChanged(entry.$1),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFD8F4E4),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF0F9D58)
                    : const Color(0xFFE2E8F0),
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFF0F6C3C)
                    : const Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyOwnersState extends StatelessWidget {
  final String activeFilter;

  const _EmptyOwnersState({required this.activeFilter});

  @override
  Widget build(BuildContext context) {
    final text = switch (activeFilter) {
      'active' => 'No active owner accounts match your search.',
      'suspended' => 'No suspended owners found.',
      _ => 'No owner accounts found.',
    };

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 30,
              color: Color(0xFF0F9D58),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF16302B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  final Owner owner;

  const _OwnerCard({required this.owner});

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle;
    final registeredDate = owner.createdAt.isNotEmpty
        ? owner.createdAt.split('T').first
        : 'Unknown';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusStyle.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.storefront, color: statusStyle.foreground),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        owner.shopName.isNotEmpty
                            ? owner.shopName
                            : 'Unnamed grocery store',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16302B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        owner.name.isNotEmpty ? owner.name : 'Owner name missing',
                        style: const TextStyle(
                          color: Color(0xFF516A64),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusStyle.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusStyle.label,
                    style: TextStyle(
                      color: statusStyle.foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                _InfoChip(
                  icon: Icons.call_outlined,
                  label: owner.phone.isNotEmpty ? owner.phone : 'Phone missing',
                ),
                _InfoChip(
                  icon: Icons.mail_outline_rounded,
                  label: owner.email.isNotEmpty ? owner.email : 'No email',
                ),
                _InfoChip(
                  icon: Icons.calendar_month_outlined,
                  label: 'Registered $registeredDate',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                _ActionButton(
                  label: owner.isSuspended ? 'Unsuspend' : 'Suspend',
                  icon: owner.isSuspended 
                      ? Icons.play_circle_outline_rounded 
                      : Icons.pause_circle_outline_rounded,
                  color: owner.isSuspended 
                      ? AppColors.success 
                      : AppColors.warning,
                  onPressed: () => _runAction(
                    context,
                    // Administrative suspension: Toggling account access via AdminProvider.
                    () => context.read<AdminProvider>().suspendOwner(owner.id),
                    owner.isSuspended 
                        ? 'Owner unsuspended successfully' 
                        : 'Owner suspended successfully',
                  ),
                ),
                _ActionButton(
                  label: 'Update',
                  icon: Icons.edit_rounded,
                  color: const Color(0xFF3B82F6),
                  onPressed: () => _showEditDialog(context),
                ),
                _ActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  onPressed: () => _deleteOwner(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _OwnerStatusStyle get _statusStyle {
    if (owner.isSuspended || owner.status == 'suspended') {
      return const _OwnerStatusStyle(
        label: 'Suspended',
        foreground: Color(0xFFB42318),
        background: Color(0xFFFFE4E8),
      );
    }
    return const _OwnerStatusStyle(
      label: 'Active',
      foreground: Color(0xFF027A48),
      background: Color(0xFFDFF7E8),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<bool> Function() action,
    String successMessage,
  ) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await action();
    if (!context.mounted) return;
    SnackBarUtils.showTopSnackBar(
      context,
      success ? successMessage : adminProvider.error ?? 'Action failed',
      isError: !success,
    );
  }

  Future<void> _deleteOwner(BuildContext context) async {
    final adminProvider = context.read<AdminProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AdminDeleteConfirmationDialog(owner: owner),
    );

    if (confirmed != true) return;

    final success = await adminProvider.deleteOwner(owner.id);
    if (!context.mounted) return;
    
    SnackBarUtils.showTopSnackBar(
      context,
      success
          ? 'Owner and all associated business data wiped successfully'
          : adminProvider.error ?? 'Failed to delete owner',
      isError: !success,
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => _OwnerEditSheet(owner: owner),
    );
  }
}

class _OwnerStatusStyle {
  final String label;
  final Color foreground;
  final Color background;

  const _OwnerStatusStyle({
    required this.label,
    required this.foreground,
    required this.background,
  });
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF5E7A73)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActionInProgress = context.watch<AdminProvider>().isActionInProgress;
    
    return TactileScale(
      onTap: isActionInProgress ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: const BoxConstraints(minHeight: 36),
        decoration: BoxDecoration(
          color: isActionInProgress ? color.withValues(alpha: 0.5) : color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerEditSheet extends StatefulWidget {
  final Owner owner;

  const _OwnerEditSheet({required this.owner});

  @override
  State<_OwnerEditSheet> createState() => _OwnerEditSheetState();
}

class _OwnerEditSheetState extends State<_OwnerEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _shopNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late bool _isSuspended;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.owner.name);
    _shopNameController = TextEditingController(text: widget.owner.shopName);
    _phoneController = TextEditingController(text: widget.owner.phone);
    _emailController = TextEditingController(text: widget.owner.email);
    _passwordController = TextEditingController();
    _isSuspended = widget.owner.isSuspended;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFCFDFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5DDDA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Update owner details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16302B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Edit owner information and control whether the account stays suspended.',
                  style: TextStyle(
                    height: 1.4,
                    color: Color(0xFF5E7A73),
                  ),
                ),
                const SizedBox(height: 20),
                _SheetField(
                  label: 'Owner name',
                  controller: _nameController,
                ),
                const SizedBox(height: 14),
                _SheetField(
                  label: 'Shop name',
                  controller: _shopNameController,
                ),
                const SizedBox(height: 14),
                _SheetField(
                  label: 'Phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _SheetField(
                  label: 'Email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _SheetField(
                  label: 'New Password (Leave blank to keep current)',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isSuspended 
                        ? const Color(0xFFFFF1F2) 
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isSuspended 
                          ? const Color(0xFFFDA4AF) 
                          : const Color(0xFFD1DCD8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuspended 
                            ? Icons.pause_circle_outline_rounded 
                            : Icons.check_circle_outline_rounded,
                        color: _isSuspended 
                            ? const Color(0xFFDC2626) 
                            : const Color(0xFF0F9D58),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Suspension',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _isSuspended 
                                    ? const Color(0xFF991B1B) 
                                    : const Color(0xFF16302B),
                              ),
                            ),
                            Text(
                              _isSuspended 
                                  ? 'This owner is currently blocked from logging in.' 
                                  : 'This owner has full access to their dashboard.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isSuspended 
                                    ? const Color(0xFFBE123C) 
                                    : const Color(0xFF5E7A73),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isSuspended,
                        onChanged: (val) => setState(() => _isSuspended = val),
                        activeThumbColor: const Color(0xFFDC2626),
                        activeTrackColor: const Color(0xFFDC2626).withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: adminProvider.isActionInProgress
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: adminProvider.isActionInProgress
                            ? null
                            : () async {
                                final data = {
                                  'name': _nameController.text.trim(),
                                  'shopName': _shopNameController.text.trim(),
                                  'phone': _phoneController.text.trim(),
                                  'email': _emailController.text.trim(),
                                  'isSuspended': _isSuspended,
                                };
                                if (_passwordController.text.isNotEmpty) {
                                  data['password'] = _passwordController.text;
                                }
                                final success = await adminProvider.updateOwner(
                                  widget.owner.id,
                                  data,
                                );
                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                  SnackBarUtils.showTopSnackBar(
                                    context,
                                    'Owner details updated successfully',
                                  );
                                } else if (!success && context.mounted) {
                                  SnackBarUtils.showTopSnackBar(
                                    context,
                                    adminProvider.error ?? 'Failed to update owner',
                                    isError: true,
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: adminProvider.isActionInProgress
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;

  const _SheetField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF16302B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminDeleteConfirmationDialog extends StatefulWidget {
  final Owner owner;

  const _AdminDeleteConfirmationDialog({required this.owner});

  @override
  State<_AdminDeleteConfirmationDialog> createState() => _AdminDeleteConfirmationDialogState();
}

class _AdminDeleteConfirmationDialogState extends State<_AdminDeleteConfirmationDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB42318), size: 28),
          const SizedBox(width: 12),
          const Text(
            'Confirm Destruction',
            style: TextStyle(
              color: Color(0xFF16302B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are about to permanently delete:',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront, size: 20, color: Color(0xFF16302B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.owner.shopName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'WARNING: This is a cascading delete. It will immediately wipe:',
            style: TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildImpactItem(Icons.inventory_2_outlined, 'All product inventory'),
          _buildImpactItem(Icons.receipt_long_outlined, 'Full sales database'),
          _buildImpactItem(Icons.people_outline, 'Customer & credit records'),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _confirmed,
                activeColor: const Color(0xFFB42318),
                onChanged: (val) => setState(() => _confirmed = val ?? false),
              ),
              const Expanded(
                child: Text(
                  'I understand this action is irreversible and affects all data.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF5E7A73), fontWeight: FontWeight.w700),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB42318),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _confirmed ? () => Navigator.pop(context, true) : null,
          child: const Text(
            'YES, WIPE DATA',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

