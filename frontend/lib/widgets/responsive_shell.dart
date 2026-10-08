part of '../main.dart';

class AppDestination {
  const AppDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

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
  });

  final Widget body;
  final String title;
  final String? subtitle;
  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? primaryAction;

  @override
  Widget build(BuildContext context) => AppPage(
        child: LayoutBuilder(builder: (context, constraints) {
          final screenClass = screenClassForWidth(constraints.maxWidth);
          return screenClass == ScreenClass.wide
              ? _wide(context)
              : _compact(context);
        }),
      );

  Widget _wide(BuildContext context) => Row(
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

  Widget _compact(BuildContext context) => Column(
        children: [
          Expanded(child: _content(context, showBrand: true)),
          if (destinations.isNotEmpty)
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
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: BrandMark(compact: true)),
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
