part of '../main.dart';

enum PasswordStrength { weak, medium, strong }

PasswordStrength passwordStrength(String password) {
  final score = <bool>[
    password.length >= 8,
    RegExp(r'[A-Z]').hasMatch(password),
    RegExp(r'[a-z]').hasMatch(password),
    RegExp(r'[0-9]').hasMatch(password),
    RegExp(r'[^A-Za-z0-9]').hasMatch(password),
  ].where((rule) => rule).length;
  if (score == 5) return PasswordStrength.strong;
  if (score >= 3) return PasswordStrength.medium;
  return PasswordStrength.weak;
}

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    const requirements =
        '8+ caracteres, maiúscula, minúscula, número e símbolo';
    final empty = password.isEmpty;
    final strength = passwordStrength(password);
    final (label, value, color) = switch (strength) {
      PasswordStrength.weak => (
          'Fraca',
          1 / 3,
          Theme.of(context).colorScheme.error
        ),
      PasswordStrength.medium => ('Média', 2 / 3, Colors.orange.shade800),
      PasswordStrength.strong => ('Forte', 1.0, Colors.green.shade700),
    };
    final effectiveColor = accessibility.highContrast && !empty
        ? Theme.of(context).colorScheme.onSurface
        : color;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: empty
          ? 'Requisitos da senha: $requirements'
          : 'Força da senha: $label',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!empty) ...[
              Row(
                children: [
                  const Expanded(child: Text('Força da senha')),
                  Text(label,
                      style: TextStyle(
                          color: effectiveColor, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: value,
                minHeight: 8,
                color: effectiveColor,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              'Senha: $requirements',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: empty ? null : effectiveColor,
                  fontWeight: empty ? null : FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) =>
      PasswordStrengthIndicator(password: password);
}
