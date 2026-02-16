import 'package:flutter/material.dart';

/// Breakpoint for switching between mobile and desktop layouts
const double kDesktopBreakpoint = 600.0;

/// A responsive scaffold that shows bottom nav on mobile and a sidebar on desktop.
class ResponsiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> destinations;
  final List<NavigationDestination> navItems;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.navItems,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;

        if (isDesktop) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF121212),
              Color(0xFF2C2C2C),
            ],
          ),
        ),
        child: Row(
          children: [
            // Sidebar navigation
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              backgroundColor: Colors.transparent,
              indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'TaskIt',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              destinations: navItems.map((item) => NavigationRailDestination(
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                label: Text(item.label),
              )).toList(),
            ),
            // Divider
            Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            // Main content
            Expanded(
              child: Stack(
                children: [
                  destinations[selectedIndex],
                  if (floatingActionButton != null)
                    Positioned(
                      right: 24,
                      bottom: 24,
                      child: floatingActionButton!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF121212),
              Color(0xFF2C2C2C),
            ],
          ),
        ),
        child: destinations[selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        destinations: navItems,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
