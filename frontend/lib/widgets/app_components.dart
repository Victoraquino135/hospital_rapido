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

class AvailabilitySlotCard extends StatelessWidget {
  const AvailabilitySlotCard({
    super.key,
    required this.slot,
    required this.selected,
    required this.onPressed,
  });

  final Slot slot;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = slot.selectable && onPressed != null;
    final label = selected
        ? 'Selecionado'
        : slot.selectable
            ? 'Disponível'
            : 'Indisponível';
    final apiLabel = slot.label.trim();
    final detail = !selected &&
            apiLabel.isNotEmpty &&
            apiLabel.toLowerCase() != label.toLowerCase()
        ? apiLabel
        : null;
    final icon = selected
        ? Icons.check_circle_outline
        : slot.selectable
            ? Icons.event_available_outlined
            : Icons.event_busy_outlined;
    final accent = selected
        ? colors.primary
        : slot.selectable
            ? colors.tertiary
            : colors.outline;
    final borderWidth = accessibility.highContrast || selected ? 2.0 : 1.0;
    final time =
        '${slot.scheduledAt.hour.toString().padLeft(2, '0')}:${slot.scheduledAt.minute.toString().padLeft(2, '0')}';

    return Semantics(
      container: true,
      button: slot.selectable,
      enabled: enabled,
      selected: selected,
      label: '$time, $label${detail == null ? '' : ', $detail'}',
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected && !accessibility.highContrast
                ? colors.primaryContainer
                : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent, width: borderWidth),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accessibility.highContrast ? null : accent),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(time,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(label, style: Theme.of(context).textTheme.bodySmall),
                        if (detail != null)
                          Text(detail,
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
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
}

class AvailabilityLegend extends StatelessWidget {
  const AvailabilityLegend({super.key});

  @override
  Widget build(BuildContext context) => const Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          _AvailabilityLegendItem(
              icon: Icons.event_available_outlined, label: 'Disponível'),
          _AvailabilityLegendItem(
              icon: Icons.event_busy_outlined, label: 'Indisponível'),
          _AvailabilityLegendItem(
              icon: Icons.check_circle_outline, label: 'Selecionado'),
        ],
      );
}

class _AvailabilityLegendItem extends StatelessWidget {
  const _AvailabilityLegendItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.event_available_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _AppFeedbackState(
        icon: icon,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

enum StatusTone { neutral, info, success, warning, danger }

StatusTone statusToneFor(String status) => switch (status) {
      'concluido' => StatusTone.success,
      'cancelado' || 'falta' => StatusTone.danger,
      'em_atendimento' || 'em_triagem' => StatusTone.info,
      'em_espera' => StatusTone.warning,
      _ => StatusTone.neutral,
    };

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.semanticLabel,
  });

  final String label;
  final StatusTone tone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (tone) {
      StatusTone.info =>
        (colors.primaryContainer, colors.onPrimaryContainer, Icons.info_outline),
      StatusTone.success => (const Color(0xFFDFF4E8), const Color(0xFF155D36),
          Icons.check_circle_outline),
      StatusTone.warning => (const Color(0xFFFFF0C7), const Color(0xFF6D4C00),
          Icons.schedule_outlined),
      StatusTone.danger =>
        (colors.errorContainer, colors.onErrorContainer, Icons.error_outline),
      StatusTone.neutral =>
        (colors.surfaceContainerHighest, colors.onSurface, Icons.event_outlined),
    };
    final effectiveBackground =
        accessibility.highContrast ? Colors.black : background;
    final effectiveForeground =
        accessibility.highContrast ? Colors.yellow : foreground;

    return Semantics(
      container: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: effectiveBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: effectiveForeground,
              width: accessibility.highContrast ? 2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: effectiveForeground),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label,
                    style: TextStyle(
                        color: effectiveForeground,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
