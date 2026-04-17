// ------------------------------------------------------------------------------
// File: account_screen.dart
// Purpose: Owner Command Hub and Profile Control Center.
// Rationale: Acts as the primary navigation tree for all non-transactional 
//   business operations. Facilitates profile management, business 
//   configuration, security, and legal compliance.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity source of truth
import 'package:frontend/features/auth/presentation/screens/login_screen.dart'; // Navigation: Session exit destination
import 'package:frontend/features/suppliers/presentation/screens/supplier_management_screen.dart'; // Navigation: Supply chain entry
import 'package:frontend/features/notifications/presentation/screens/notification_screen.dart'; // Navigation: Communication logs
import 'package:frontend/features/account/presentation/screens/reports_screen.dart'; // Navigation: Business intelligence
import 'package:frontend/features/account/presentation/screens/profile_settings_screen.dart'; // Navigation: Identity mutation
import 'package:frontend/features/sales/presentation/screens/invoice_history_screen.dart'; // Navigation: Transactional archives
import 'package:frontend/features/account/presentation/screens/help_support_screen.dart'; // Navigation: Help desk gateway
import 'package:frontend/features/account/presentation/screens/delete_account_screen.dart'; // Navigation: Irreversible account purge
import 'package:frontend/features/account/presentation/screens/terms_conditions_screen.dart'; // Navigation: Legal compliance
import 'package:frontend/features/account/presentation/screens/privacy_policy_screen.dart'; // Navigation: Privacy data governance
import 'package:frontend/core/widgets/doodle_painter.dart'; // Shared UI: Generative background patterns
import 'package:frontend/shared/widgets/screen_header.dart'; // Shared UI: Consistent titled headers
import 'package:package_info_plus/package_info_plus.dart'; // Infrastructure: Platform versioning

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- Part A: Branded Identity Header ---
              // Rationale: Establishes strong brand presence and confirms the active owner's identity.
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Stack(
                  children: [
                    // Logic: Doodle pattern background for texture and visual premiumness.
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: Opacity(
                          opacity: 0.6,
                          child: DoodleBackground(
                            color: Colors.white.withValues(alpha: 0.12),
                            spacing: 45, // Density: Adjusted for high visibility
                          ),
                        ),
                      ),
                    ),
                    
                    // --- Profile Narrative ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 44, 0, 24),
                      child: Column(
                      children: [
                        const ScreenHeader(
                          title: 'Account',
                          titleColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        const SizedBox(height: 4),
                        // Logic: Reactive synchronization with Global Auth state.
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return Column(
                              children: [
                                // Avatar: Visual identity representation.
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  backgroundImage: (auth.currentOwner?.profilePic != null && 
                                                   auth.currentOwner!.profilePic!.isNotEmpty)
                                      ? NetworkImage(auth.currentOwner!.profilePic!)
                                      : null,
                                  child: (auth.currentOwner?.profilePic == null || 
                                          auth.currentOwner!.profilePic!.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                // Name: Primary identity label.
                                Text(
                                  auth.currentOwner?.name ?? 'Shop Owner',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Shop: Business context label.
                                Text(
                                  auth.currentOwner?.shopName ?? 'ClickBuy Store',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Email: Secondary identifier.
                                Text(
                                  auth.currentOwner?.email ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

              // --- Part B: Navigation Menu Tree ---
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // --- Category: Security & Identity ---
                    Text(
                      'Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      Icons.person_outline,
                      'Profile Settings',
                      'Update your personal info',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    // --- Category: Business Operations ---
                    Text(
                      'Management',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      Icons.local_shipping_outlined,
                      'Supplier Management',
                      'Manage your suppliers & purchases',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplierManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.notifications_outlined,
                      'Notifications',
                      'View alerts and updates',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.bar_chart_outlined,
                      'Reports',
                      'View your business analytics',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.receipt_long_outlined,
                      'Invoice History',
                      'View your past sales & invoices',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvoiceHistoryScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    // --- Category: Support & Legal ---
                    _buildMenuItem(
                      context,
                      Icons.help_outline,
                      'Help & Support',
                      'Get help with the app',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.gavel_outlined,
                      'Terms & Conditions',
                      'Read our terms of service',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsConditionsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.privacy_tip_outlined,
                      'Privacy Policy',
                      'How we protect your data',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),

                    // Critical Action: Account Deletion (Irreversible).
                    _buildMenuItem(
                      context,
                      Icons.delete_forever_outlined,
                      'Delete Account',
                      'Permanently remove all your data',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeleteAccountScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    // --- Session Exit Control ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Logic: Synchronous session purge before routing.
                          Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout, color: AppColors.error),
                        label: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- System Metadata Footnote ---
                    Center(
                      child: FutureBuilder<PackageInfo>(
                        // Integration: Native platform version discovery.
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textLight.withValues(alpha: 0.5),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SizedBox(height: 110), // Buffer to clear the floating navbar in MainShell
    );
  }

  /**
   * UI Component Builder: Standardized Navigation Tile.
   * Rationale: Ensures visual consistency across the multi-section dashboard.
   */
  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container: Provides a vibrant contrast backdrop.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            // Text Narrative: Explains the destination intent.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            // Trailing Hint: Suggests interactability.
            const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

