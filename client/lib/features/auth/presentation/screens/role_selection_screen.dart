// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/router/app_routes.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_theme.dart';

// /// Root screen when no token. Role selection is navigation helper only;
// /// actual role comes from backend on verify-otp.
// class RoleSelectionScreen extends StatelessWidget {
//   const RoleSelectionScreen({super.key});

//   static const Map<String, _RoleDef> _roles = {
//     'vendor': _RoleDef(
//       icon: Icons.store_rounded,
//       title: 'Vendor',
//       subtitle: 'Manage your\ntiffin business',
//       color: AppColors.primary,
//     ),
//     'customer': _RoleDef(
//       icon: Icons.person_rounded,
//       title: 'Customer',
//       subtitle: 'Order your\ndaily meals',
//       color: AppColors.success,
//     ),
//     'delivery_staff': _RoleDef(
//       icon: Icons.delivery_dining_rounded,
//       title: 'Delivery',
//       subtitle: 'Manage your\ndeliveries',
//       color: AppColors.warning,
//     ),
//     'admin': _RoleDef(
//       icon: Icons.admin_panel_settings_rounded,
//       title: 'Admin',
//       subtitle: 'System\nadministration',
//       color: AppColors.danger,
//     ),
//   };

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 48),
//               Center(
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.restaurant,
//                       size: 64,
//                       color: AppColors.primary,
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'TiffinCRM',
//                       style: theme.textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Select your role to continue',
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 48),
//               GridView(
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 16,
//                   mainAxisSpacing: 16,
//                   childAspectRatio: 0.85,
//                 ),
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 children: _roles.entries.map((e) {
//                   return _RoleCard(
//                     icon: e.value.icon,
//                     title: e.value.title,
//                     subtitle: e.value.subtitle,
//                     roleColor: e.value.color,
//                     onTap: () {
//                       context.push(
//                         AppRoutes.login,
//                         extra: <String, String>{'selectedRole': e.key},
//                       );
//                     },
//                   );
//                 }).toList(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _RoleDef {
//   const _RoleDef({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.color,
//   });
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final Color color;
// }

// class _RoleCard extends StatelessWidget {
//   const _RoleCard({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.roleColor,
//     required this.onTap,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final Color roleColor;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Card(
//       elevation: 1,
//       shadowColor: AppColors.shadow.withValues(alpha: 0.06),
//       color: AppColors.surface,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppTheme.cardRadius),
//         side: const BorderSide(color: AppColors.border, width: 1),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(AppTheme.cardRadius),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: roleColor.withValues(alpha: 0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(icon, color: roleColor, size: 32),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 style: theme.textTheme.titleSmall?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textPrimary,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 subtitle,
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   color: AppColors.textSecondary,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'vendor';

  static const _roles = [
    _RoleDef(
      key: 'vendor',
      title: 'Vendor',
      subtitle: 'Run & manage your\ntiffin centre',
      tag1: 'Orders',
      tag2: 'Payments',
      color: Color(0xFF5B2D8E),
      bgColor: Color(0xFFF0EBF9),
      tagBg: Color(0xFFF0EBF9),
      tagText: Color(0xFF5B2D8E),
      isAdmin: false,
      isPopular: true,
    ),
    _RoleDef(
      key: 'customer',
      title: 'Customer',
      subtitle: 'Order & track your\ndaily meals',
      tag1: 'Meals',
      tag2: 'Wallet',
      color: Color(0xFF1D9E75),
      bgColor: Color(0xFFE8F8F2),
      tagBg: Color(0xFFE8F8F2),
      tagText: Color(0xFF0F6E56),
      isAdmin: false,
      isPopular: false,
    ),
    _RoleDef(
      key: 'delivery_staff',
      title: 'Delivery',
      subtitle: 'Handle & complete\ndeliveries',
      tag1: 'Tasks',
      tag2: 'Routes',
      color: Color(0xFFBA7517),
      bgColor: Color(0xFFFEF5E7),
      tagBg: Color(0xFFFEF5E7),
      tagText: Color(0xFF854F0B),
      isAdmin: false,
      isPopular: false,
    ),
    _RoleDef(
      key: 'admin',
      title: 'Admin',
      subtitle: 'Full system control\n& config',
      tag1: 'Users',
      tag2: 'Settings',
      color: Color(0xFFA32D2D),
      bgColor: Color(0xFFFDEAEA),
      tagBg: Color(0xFFFDEAEA),
      tagText: Color(0xFF791F1F),
      isAdmin: true,
      isPopular: false,
    ),
  ];

  List<Color> _getLogoGradient(String role) {
    switch (role) {
      case 'vendor':
        return [const Color(0xFF9B59D0), const Color(0xFF3B1472)];
      case 'customer':
        return [const Color(0xFF1DB87A), const Color(0xFF0A5C3A)];
      case 'delivery_staff':
        return [const Color(0xFFE8A020), const Color(0xFF8B4A00)];
      case 'admin':
        return [const Color(0xFFD64444), const Color(0xFF7A1212)];
      default:
        return [const Color(0xFF9B59D0), const Color(0xFF3B1472)];
    }
  }

  void _onContinue() {
    HapticFeedback.lightImpact();
    context.push(
      AppRoutes.login,
      extra: <String, String>{'selectedRole': _selectedRole},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _roles.firstWhere((r) => r.key == _selectedRole);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getLogoGradient(_selectedRole),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: selected.color.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lunch_dining_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TiffinCRM',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A0A2E),
                        ),
                      ),
                      Text(
                        'Smart tiffin business management',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8B7BAE),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Info Banner ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Who are you logging in as?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select your role below. Your access will be confirmed after OTP verification.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8B7BAE),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Role Cards Grid ──────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.60,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _roles.map((role) {
                  final isSelected = _selectedRole == role.key;
                  return _RoleCard(
                    role: role,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedRole = role.key);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Admin Warning ────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _selectedRole == 'admin'
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F8),
                          border: Border.all(color: const Color(0xFFF7C1C1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFA32D2D),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Restricted Access',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFFA32D2D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Only one admin account exists per system. You cannot log in as Admin unless an admin account has already been created for you. Contact your system administrator.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF791F1F),
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedRole = 'vendor',
                                    ),
                                    child: Text(
                                      'Not an admin? Continue as Vendor →',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Continue Button ──────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  color: selected.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onContinue,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Text(
                        'Continue as ${selected.title} →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Footer ───────────────────────────────────────────
              Text(
                'By continuing you agree to our Terms of Service.\nRole access is verified via OTP.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFB0A3C8),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role Card Widget ─────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final _RoleDef role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? role.color : const Color(0xFFEEEBF8),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: role.color.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Popular badge (fixed height for all cards)
            SizedBox(
              height: 20,
              child: role.isPopular
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Popular',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFCC0000),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // ── Icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: role.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _RoleIcon(roleKey: role.key, color: role.color),
              ),
            ),

            const SizedBox(height: 10),

            // ── Title
            Text(
              role.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A0A2E),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // ── Subtitle
            Text(
              role.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8B7BAE),
                height: 1.4,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // ── Divider
            Container(height: 1, color: const Color(0xFFF4F1FB)),

            const SizedBox(height: 8),

            // ── Tags — Wrap to prevent overflow
            // ── Tags
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Tag(label: role.tag1, bg: role.tagBg, textColor: role.tagText),
                const SizedBox(width: 6),
                _Tag(label: role.tag2, bg: role.tagBg, textColor: role.tagText),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tag Widget ───────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.bg, required this.textColor});

  final String label;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Role Icon ─────────────────────────────────────────────────────────────────

class _RoleIcon extends StatelessWidget {
  const _RoleIcon({required this.roleKey, required this.color});

  final String roleKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (roleKey) {
      case 'vendor':
        return Icon(Icons.storefront_outlined, color: color, size: 26);
      case 'customer':
        return Icon(Icons.person_outline_rounded, color: color, size: 26);
      case 'delivery_staff':
        return Icon(Icons.delivery_dining_rounded, color: color, size: 26);
      case 'admin':
        return Icon(Icons.shield_outlined, color: color, size: 26);
      default:
        return Icon(Icons.circle_outlined, color: color, size: 26);
    }
  }
}

// ── Role Definition ───────────────────────────────────────────────────────────

class _RoleDef {
  const _RoleDef({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.tag1,
    required this.tag2,
    required this.color,
    required this.bgColor,
    required this.tagBg,
    required this.tagText,
    required this.isAdmin,
    required this.isPopular,
  });

  final String key;
  final String title;
  final String subtitle;
  final String tag1;
  final String tag2;
  final Color color;
  final Color bgColor;
  final Color tagBg;
  final Color tagText;
  final bool isAdmin;
  final bool isPopular;
}
