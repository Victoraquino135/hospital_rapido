part of '../main.dart';

class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});
  final String password;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
          'Senha: 8+ caracteres, maiúscula, minúscula, número e símbolo',
          style: TextStyle(
              color: strongPassword(password) ? Colors.green : null,
              fontSize: 12)));
}
