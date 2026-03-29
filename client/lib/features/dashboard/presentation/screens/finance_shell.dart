import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../expenses/screens/expenses_screen.dart';
import '../../../income/screens/income_screen.dart';
import 'payments_screen.dart';

/// Finance section with Payments, Expenses, and Income (internal bottom nav only).
class FinanceShell extends StatefulWidget {
  const FinanceShell({super.key});

  @override
  State<FinanceShell> createState() => _FinanceShellState();
}

class _FinanceShellState extends State<FinanceShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  RepaintBoundary(
                    child: PaymentsScreen(
                      embeddedInShell: true,
                      embeddedInFinanceShell: true,
                    ),
                  ),
                  RepaintBoundary(
                    child: ExpensesScreen(embeddedInFinanceShell: true),
                  ),
                  RepaintBoundary(
                    child: IncomeScreen(embeddedInFinanceShell: true),
                  ),
                ],
              ),
            ),
            BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
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
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Payments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.trending_down_rounded),
                  label: 'Expenses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.trending_up_rounded),
                  label: 'Income',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
