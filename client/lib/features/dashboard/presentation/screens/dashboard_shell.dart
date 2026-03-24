// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:phosphor_flutter/phosphor_flutter.dart';
// // import '../../../../core/theme/app_colors.dart';
// // import '../../../../core/widgets/app_drawer.dart';
// // import '../../../auth/data/auth_api.dart';
// // import '../../../auth/models/user_model.dart';
// // import '../../../customers/presentation/screens/customers_list_screen.dart';
// // import 'dashboard_home_screen.dart';
// // import 'delivery_screen.dart';
// // import 'payments_screen.dart';

// // class DashboardShell extends StatefulWidget {
// //   const DashboardShell({super.key, this.adminName = 'Vendor'});

// //   final String adminName;

// //   @override
// //   State<DashboardShell> createState() => _DashboardShellState();
// // }

// // class _DashboardShellState extends State<DashboardShell> {
// //   int _selectedIndex = 0;
// //   String _vendorDisplayName = 'Vendor';
// //   bool _profileLoaded = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadVendorProfile();
// //   }

// //   Future<void> _loadVendorProfile() async {
// //     try {
// //       final user = await AuthApi.getProfile();
// //       if (mounted) {
// //         setState(() {
// //           _vendorDisplayName = _displayNameFromUser(user);
// //           _profileLoaded = true;
// //         });
// //       }
// //     } catch (_) {
// //       if (mounted) {
// //         setState(() {
// //           _vendorDisplayName = widget.adminName;
// //           _profileLoaded = true;
// //         });
// //       }
// //     }
// //   }

// //   static String _displayNameFromUser(UserModel user) {
// //     if (user.businessName.isNotEmpty) return user.businessName;
// //     if (user.name.isNotEmpty) return user.name;
// //     return 'Vendor';
// //   }

// //   static const List<_NavItem> _navItems = [
// //     _NavItem(icon: PhosphorIconsRegular.house, iconSelected: PhosphorIconsFill.house, label: 'Overview'),
// //     _NavItem(icon: PhosphorIconsRegular.receipt, iconSelected: PhosphorIconsFill.receipt, label: 'Orders'),
// //     _NavItem(icon: PhosphorIconsRegular.users, iconSelected: PhosphorIconsFill.users, label: 'Customers'),
// //     _NavItem(icon: PhosphorIconsRegular.wallet, iconSelected: PhosphorIconsFill.wallet, label: 'Finance'),
// //   ];

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         flexibleSpace: Stack(
// //           fit: StackFit.expand,
// //           children: [
// //             Container(
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                   colors: [
// //                     AppColors.primary,
// //                     AppColors.primary.withValues(alpha: 0.92),
// //                     const Color(0xFF3B1578),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             Positioned.fill(
// //               child: DecoratedBox(
// //                 decoration: BoxDecoration(
// //                   color: Colors.white.withValues(alpha: 0.06),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //         leading: Builder(
// //           builder: (context) => IconButton(
// //             icon: const PhosphorIcon(PhosphorIconsRegular.list, size: 22, color: AppColors.onPrimary),
// //             onPressed: () {
// //               HapticFeedback.lightImpact();
// //               Scaffold.of(context).openDrawer();
// //             },
// //             tooltip: 'Open menu',
// //           ),
// //         ),
// //         title: Text(
// //           _profileLoaded ? _vendorDisplayName : 'TiffinCRM',
// //           maxLines: 1,
// //           overflow: TextOverflow.ellipsis,
// //           style: GoogleFonts.inter(
// //             fontSize: 18,
// //             fontWeight: FontWeight.w600,
// //             color: AppColors.onPrimary,
// //           ),
// //         ),
// //         backgroundColor: Colors.transparent,
// //         foregroundColor: AppColors.onPrimary,
// //         elevation: 0,
// //         bottom: PreferredSize(
// //           preferredSize: const Size.fromHeight(1),
// //           child: Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
// //         ),
// //       ),
// //       drawer: Drawer(
// //         child: AppDrawer(fallbackUserName: _vendorDisplayName),
// //       ),
// //       body: IndexedStack(
// //         index: _selectedIndex,
// //         children: [
// //           DashboardHomeScreen(adminName: _vendorDisplayName),
// //           const DeliveryScreen(embeddedInShell: true),
// //           const CustomersListScreen(),
// //           const PaymentsScreen(embeddedInShell: true),
// //         ],
// //       ),
// //       bottomNavigationBar: Container(
// //         decoration: BoxDecoration(
// //           color: AppColors.surface,
// //           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
// //           border: Border.all(color: AppColors.border),
// //           boxShadow: [
// //             BoxShadow(
// //               color: AppColors.primary.withValues(alpha: 0.06),
// //               blurRadius: 16,
// //               offset: const Offset(0, -4),
// //             ),
// //           ],
// //         ),
// //         child: ClipRRect(
// //           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
// //           child: BottomNavigationBar(
// //             currentIndex: _selectedIndex,
// //             onTap: (index) {
// //               HapticFeedback.lightImpact();
// //               setState(() => _selectedIndex = index);
// //             },
// //             type: BottomNavigationBarType.fixed,
// //             backgroundColor: AppColors.surface,
// //             elevation: 0,
// //             selectedItemColor: AppColors.bottomNavSelected,
// //             unselectedItemColor: AppColors.bottomNavUnselected,
// //             selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
// //             unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
// //             items: _navItems
// //                 .asMap()
// //                 .entries
// //                 .map(
// //                   (e) => BottomNavigationBarItem(
// //                     icon: PhosphorIcon(
// //                       _selectedIndex == e.key ? e.value.iconSelected : e.value.icon,
// //                       size: 22,
// //                     ),
// //                     label: e.value.label,
// //                   ),
// //                 )
// //                 .toList(),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _NavItem {
// //   const _NavItem({required this.icon, required this.iconSelected, required this.label});
// //   final IconData icon;
// //   final IconData iconSelected;
// //   final String label;
// // }
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import '../../../../core/router/app_routes.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/widgets/app_drawer.dart';
// import '../../../auth/data/auth_api.dart';
// import '../../../auth/models/user_model.dart';
// import '../../../customers/presentation/screens/customers_list_screen.dart';
// import '../../../dashboard/data/notification_api.dart';
// import 'dashboard_home_screen.dart';
// import 'delivery_screen.dart';
// import 'payments_screen.dart';

// class DashboardShell extends StatefulWidget {
//   const DashboardShell({super.key, this.adminName = 'Vendor'});
//   final String adminName;

//   @override
//   State<DashboardShell> createState() => _DashboardShellState();
// }

// class _DashboardShellState extends State<DashboardShell> {
//   int _selectedIndex = 0;
//   String _vendorDisplayName = 'Vendor';
//   bool _profileLoaded = false;
//   bool _hasUnread = false; // ← NEW

//   @override
//   void initState() {
//     super.initState();
//     _loadVendorProfile();
//     _checkUnread(); // ← NEW
//   }

//   // ── NEW: check unread notifications ─────────────────────
//   Future<void> _checkUnread() async {
//     try {
//       final res = await NotificationApi.getMyNotifications(
//         page: 1,
//         limit: 1,
//         isRead: false,
//       );
//       final total = res['total'] as int? ?? 0;
//       if (mounted) setState(() => _hasUnread = total > 0);
//     } catch (_) {}
//   }

//   Future<void> _loadVendorProfile() async {
//     try {
//       final user = await AuthApi.getProfile();
//       if (mounted) {
//         setState(() {
//           _vendorDisplayName = _displayNameFromUser(user);
//           _profileLoaded = true;
//         });
//       }
//     } catch (_) {
//       if (mounted) {
//         setState(() {
//           _vendorDisplayName = widget.adminName;
//           _profileLoaded = true;
//         });
//       }
//     }
//   }

//   static String _displayNameFromUser(UserModel user) {
//     if (user.businessName.isNotEmpty) return user.businessName;
//     if (user.name.isNotEmpty) return user.name;
//     return 'Vendor';
//   }

//   static const List<_NavItem> _navItems = [
//     _NavItem(
//       icon: PhosphorIconsRegular.house,
//       iconSelected: PhosphorIconsFill.house,
//       label: 'Overview',
//     ),
//     _NavItem(
//       icon: PhosphorIconsRegular.receipt,
//       iconSelected: PhosphorIconsFill.receipt,
//       label: 'Orders',
//     ),
//     _NavItem(
//       icon: PhosphorIconsRegular.users,
//       iconSelected: PhosphorIconsFill.users,
//       label: 'Customers',
//     ),
//     _NavItem(
//       icon: PhosphorIconsRegular.wallet,
//       iconSelected: PhosphorIconsFill.wallet,
//       label: 'Finance',
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         flexibleSpace: Stack(
//           fit: StackFit.expand,
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     AppColors.primary,
//                     AppColors.primary.withValues(alpha: 0.92),
//                     const Color(0xFF3B1578),
//                   ],
//                 ),
//               ),
//             ),
//             Positioned.fill(
//               child: DecoratedBox(
//                 decoration: BoxDecoration(
//                   color: Colors.white.withValues(alpha: 0.06),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         leading: Builder(
//           builder: (context) => IconButton(
//             icon: const PhosphorIcon(
//               PhosphorIconsRegular.list,
//               size: 22,
//               color: AppColors.onPrimary,
//             ),
//             onPressed: () {
//               HapticFeedback.lightImpact();
//               Scaffold.of(context).openDrawer();
//             },
//             tooltip: 'Open menu',
//           ),
//         ),
//         title: Text(
//           _profileLoaded ? _vendorDisplayName : 'TiffinCRM',
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: GoogleFonts.inter(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: AppColors.onPrimary,
//           ),
//         ),
//         backgroundColor: Colors.transparent,
//         foregroundColor: AppColors.onPrimary,
//         elevation: 0,

//         // ── NEW: Notification bell with red dot ──────────────
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 IconButton(
//                   icon: const PhosphorIcon(
//                     PhosphorIconsRegular.bell,
//                     size: 22,
//                     color: AppColors.onPrimary,
//                   ),
//                   onPressed: () async {
//                     HapticFeedback.lightImpact();
//                     await context.push(AppRoutes.notifications);
//                     _checkUnread(); // recheck after returning
//                   },
//                 ),
//                 if (_hasUnread)
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                         border: Border.all(
//                           color: AppColors.primary,
//                           width: 1.5,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],

//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(
//             height: 1,
//             color: Colors.white.withValues(alpha: 0.12),
//           ),
//         ),
//       ),
//       drawer: Drawer(child: AppDrawer(fallbackUserName: _vendorDisplayName)),
//       body: IndexedStack(
//         index: _selectedIndex,
//         children: [
//           DashboardHomeScreen(adminName: _vendorDisplayName),
//           const DeliveryScreen(embeddedInShell: true),
//           const CustomersListScreen(),
//           const PaymentsScreen(embeddedInShell: true),
//         ],
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//           border: Border.all(color: AppColors.border),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.primary.withValues(alpha: 0.06),
//               blurRadius: 16,
//               offset: const Offset(0, -4),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//           child: BottomNavigationBar(
//             currentIndex: _selectedIndex,
//             onTap: (index) {
//               HapticFeedback.lightImpact();
//               setState(() => _selectedIndex = index);
//             },
//             type: BottomNavigationBarType.fixed,
//             backgroundColor: AppColors.surface,
//             elevation: 0,
//             selectedItemColor: AppColors.bottomNavSelected,
//             unselectedItemColor: AppColors.bottomNavUnselected,
//             selectedLabelStyle: GoogleFonts.inter(
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//             ),
//             unselectedLabelStyle: GoogleFonts.inter(
//               fontWeight: FontWeight.w500,
//               fontSize: 12,
//             ),
//             items: _navItems
//                 .asMap()
//                 .entries
//                 .map(
//                   (e) => BottomNavigationBarItem(
//                     icon: PhosphorIcon(
//                       _selectedIndex == e.key
//                           ? e.value.iconSelected
//                           : e.value.icon,
//                       size: 22,
//                     ),
//                     label: e.value.label,
//                   ),
//                 )
//                 .toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NavItem {
//   const _NavItem({
//     required this.icon,
//     required this.iconSelected,
//     required this.label,
//   });
//   final IconData icon;
//   final IconData iconSelected;
//   final String label;
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/notifications/notification_badge_service.dart';
import '../../../auth/data/auth_api.dart';
import '../../../auth/models/user_model.dart';
import '../../../customers/presentation/screens/customers_list_screen.dart';
import 'dashboard_home_screen.dart';
import 'delivery_screen.dart';
import 'finance_shell.dart';
import 'invoices_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, this.adminName = 'Vendor'});
  final String adminName;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String _vendorDisplayName = 'Vendor';
  bool _profileLoaded = false;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadVendorProfile();

    // Init badge service (starts 60s polling internally)
    NotificationBadgeService.init();

    // ValueNotifier triggers rebuild automatically — no setState needed!
    // Just listen so the bell icon rebuilds when count changes.
    NotificationBadgeService.unreadCount.addListener(_onBadgeChanged);
  }

  @override
  void dispose() {
    NotificationBadgeService.unreadCount.removeListener(_onBadgeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever unreadCount changes — triggers a rebuild of the bell
  void _onBadgeChanged() {
    if (mounted) setState(() {});
  }

  /// Re-fetch when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationBadgeService.refreshNow();
    }
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadVendorProfile() async {
    try {
      final user = await AuthApi.getProfile();
      if (mounted) {
        setState(() {
          _vendorDisplayName = _displayNameFromUser(user);
          _profileLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _vendorDisplayName = widget.adminName;
          _profileLoaded = true;
        });
      }
    }
  }

  static String _displayNameFromUser(UserModel user) {
    if (user.businessName.isNotEmpty) return user.businessName;
    if (user.name.isNotEmpty) return user.name;
    return 'Vendor';
  }

  // ─── Nav items ─────────────────────────────────────────────────────────────

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: PhosphorIconsRegular.house,
      iconSelected: PhosphorIconsFill.house,
      label: 'Overview',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.receipt,
      iconSelected: PhosphorIconsFill.receipt,
      label: 'Orders',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.users,
      iconSelected: PhosphorIconsFill.users,
      label: 'Customers',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.wallet,
      iconSelected: PhosphorIconsFill.wallet,
      label: 'Finance',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.receipt,
      iconSelected: PhosphorIconsFill.receipt,
      label: 'Invoice',
    ),
  ];

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Read directly from ValueNotifier — always fresh
    final hasUnread = NotificationBadgeService.unreadCount.value > 0;
    final unreadCount = NotificationBadgeService.unreadCount.value;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.92),
                    const Color(0xFF3B1578),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const PhosphorIcon(
              PhosphorIconsRegular.list,
              size: 22,
              color: AppColors.onPrimary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Open menu',
          ),
        ),
        title: Text(
          _profileLoaded ? _vendorDisplayName : 'TiffinCRM',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const PhosphorIcon(
                    PhosphorIconsRegular.bell,
                    size: 22,
                    color: AppColors.onPrimary,
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    // Optimistically clear dot immediately on tap
                    NotificationBadgeService.adjustBy(
                      -NotificationBadgeService.unreadCount.value,
                    );
                    await context.push(AppRoutes.notifications);
                    // Re-fetch real count after returning from notifications
                    NotificationBadgeService.refreshNow();
                  },
                ),
                // ── Red dot — shows count badge ───────────────────────────
                if (hasUnread)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.45),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        // Show count if ≤ 9, else show "9+"
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
      drawer: Drawer(child: AppDrawer(fallbackUserName: _vendorDisplayName)),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardHomeScreen(adminName: _vendorDisplayName),
          const DeliveryScreen(embeddedInShell: true),
          const CustomersListScreen(),
          const FinanceShell(),
          const InvoicesScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              HapticFeedback.lightImpact();
              setState(() => _selectedIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            elevation: 0,
            selectedItemColor: AppColors.bottomNavSelected,
            unselectedItemColor: AppColors.bottomNavUnselected,
            selectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            items: _navItems
                .asMap()
                .entries
                .map(
                  (e) => BottomNavigationBarItem(
                    icon: PhosphorIcon(
                      _selectedIndex == e.key
                          ? e.value.iconSelected
                          : e.value.icon,
                      size: 22,
                    ),
                    label: e.value.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.iconSelected,
    required this.label,
  });
  final IconData icon;
  final IconData iconSelected;
  final String label;
}
