part of '../main.dart';

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.destructive = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool destructive;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = destructive
        ? FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          )
        : null;
    final button = FilledButton.icon(
      style: style,
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.arrow_forward),
      label: Text(busy ? 'Aguarde…' : label),
    );
    return Semantics(
      button: true,
      label: label,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.md),
            action!,
          ],
        ],
      );
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
        shape: Theme.of(context).cardTheme.shape,
        child: Padding(padding: padding, child: child),
      );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.event_available_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _AppFeedbackState(
        icon: icon,
        title: 'Tudo certo por aqui',
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.actionLabel = 'Tentar novamente',
    this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _AppFeedbackState(
        icon: Icons.error_outline,
        title: 'Não foi possível carregar',
        message: message,
        actionLabel: onAction == null ? null : actionLabel,
        onAction: onAction,
      );
}

class _AppFeedbackState extends StatelessWidget {
  const _AppFeedbackState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(message, textAlign: TextAlign.center),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppActionButton(
                    label: actionLabel!,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
