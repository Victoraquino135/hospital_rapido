part of '../main.dart';

class AppDestination {
  const AppDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

enum WideNavigationMode { persistentRail, overlayDrawer, contentOnly }

class ResponsiveAppShell extends StatelessWidget {
  const ResponsiveAppShell({
    super.key,
    required this.body,
    required this.title,
    this.subtitle,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.primaryAction,
    this.wideNavigationMode = WideNavigationMode.persistentRail,
  });

  final Widget body;
  final String title;
  final String? subtitle;
  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? primaryAction;
  final WideNavigationMode wideNavigationMode;

  @override
  Widget build(BuildContext context) => AppPage(
        child: LayoutBuilder(builder: (context, constraints) {
          final screenClass = screenClassForWidth(constraints.maxWidth);
          return screenClass == ScreenClass.wide
              ? _wide(context)
              : _compact(context);
        }),
      );

  Widget _wide(BuildContext context) {
    final mode = destinations.isEmpty
        ? WideNavigationMode.contentOnly
        : wideNavigationMode;
    if (mode == WideNavigationMode.overlayDrawer) {
      return Stack(
        children: [
          _content(context, showBrand: true),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.md,
            child: Semantics(
              button: true,
              label: 'Abrir menu de navegação',
              child: IconButton.filledTonal(
                key: const Key('wide-navigation-menu-button'),
                tooltip: 'Abrir menu de navegação',
                constraints: const BoxConstraints.tightFor(
                  width: AppSizes.minTouchTarget,
                  height: AppSizes.minTouchTarget,
                ),
                onPressed: () => _showWideNavigation(context),
                icon: const Icon(Icons.menu),
              ),
            ),
          ),
        ],
      );
    }
    if (mode == WideNavigationMode.contentOnly) {
      return _content(context, showBrand: true);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
          color: accessibility.highContrast
              ? Colors.black
              : Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              const BrandMark(compact: true),
              const SizedBox(height: AppSpacing.lg),
              if (destinations.isNotEmpty)
                Expanded(
                  child: NavigationRail(
                    extended: true,
                    scrollable: true,
                    backgroundColor: Colors.transparent,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _content(context, showBrand: false)),
      ],
    );
  }

  Future<void> _showWideNavigation(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar menu de navegação',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
      pageBuilder: (dialogContext, animation, secondaryAnimation) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          key: const Key('wide-navigation-panel'),
          elevation: 12,
          color: accessibility.highContrast
              ? Colors.black
              : Theme.of(context).colorScheme.surface,
          child: SafeArea(
            child: SizedBox(
              width: 320,
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: BrandMark(compact: true)),
                        IconButton(
                          tooltip: 'Fechar menu',
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: ListView.builder(
                        itemCount: destinations.length,
                        itemBuilder: (context, index) {
                          final destination = destinations[index];
                          return ListTile(
                            minTileHeight: AppSizes.minTouchTarget,
                            selected: index == selectedIndex,
                            leading: Icon(destination.icon),
                            title: Text(destination.label),
                            onTap: onDestinationSelected == null
                                ? null
                                : () {
                                    Navigator.pop(dialogContext);
                                    onDestinationSelected!(index);
                                  },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compact(BuildContext context) => Column(
        children: [
          Expanded(child: _content(context, showBrand: true)),
          if (destinations.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: DropdownButtonFormField<int>(
                key: const Key('responsive-compact-destination-picker'),
                initialValue: selectedIndex,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Seção', prefixIcon: Icon(Icons.menu)),
                items: [
                  for (var index = 0; index < destinations.length; index++)
                    DropdownMenuItem(
                      value: index,
                      child: Text(destinations[index].label,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onDestinationSelected == null
                    ? null
                    : (value) {
                        if (value != null) onDestinationSelected!(value);
                      },
              ),
            )
          else if (destinations.isNotEmpty)
            NavigationBar(
              height: 72,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
        ],
      );

  Widget _content(BuildContext context, {required bool showBrand}) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 72, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBrand) ...[
                  const BrandMark(compact: true),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ResponsivePageHeader(
                  title: title,
                  subtitle: subtitle,
                  primaryAction: primaryAction,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      );
}

class ResponsivePageHeader extends StatelessWidget {
  const ResponsivePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.primaryAction,
  });

  final String title;
  final String? subtitle;
  final Widget? primaryAction;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ],
        );
        if (constraints.maxWidth < AppBreakpoints.compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text,
              if (primaryAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                primaryAction!,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: text),
            if (primaryAction != null) ...[
              const SizedBox(width: AppSpacing.lg),
              primaryAction!,
            ],
          ],
        );
      });
}
