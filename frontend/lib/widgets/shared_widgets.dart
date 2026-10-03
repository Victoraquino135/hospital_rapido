part of '../main.dart';

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: accessibility,
      builder: (context, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(accessibility.fontSizeScale)),
          child: Scaffold(
              backgroundColor: accessibility.pageBackground,
              body: Stack(fit: StackFit.expand, children: [
                const Positioned.fill(child: WaveBackground()),
                SafeArea(
                    child: FocusTraversalGroup(
                        child: Stack(children: [
                  child,
                  const Positioned(
                      top: 12,
                      right: 16,
                      left: 16,
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: AccessibilityMenu()))
                ])))
              ]))));
}

class AccessibilityMenu extends StatefulWidget {
  const AccessibilityMenu({super.key});
  @override
  State<AccessibilityMenu> createState() => _AccessibilityMenuState();
}

class _AccessibilityMenuState extends State<AccessibilityMenu> {
  bool open = false;
  @override
  Widget build(BuildContext context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Semantics(
                button: true,
                label: 'Abrir preferências de acessibilidade',
                child: FilledButton.icon(
                    onPressed: () => setState(() => open = !open),
                    icon: const Icon(Icons.accessibility_new),
                    label: const Text('Preferências de acessibilidade'))),
            if (open)
              Card(
                  child: SizedBox(
                      width: (MediaQuery.sizeOf(context).width - 32)
                          .clamp(0, 310)
                          .toDouble(),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Opções de acessibilidade',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                const Text('Tamanho da fonte',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Row(children: [
                                  Semantics(
                                      button: true,
                                      label: 'Diminuir tamanho da fonte',
                                      child: OutlinedButton(
                                          onPressed: accessibility.decreaseFont,
                                          child: const Text('A-'))),
                                  Expanded(
                                      child: TextButton(
                                          onPressed: () =>
                                              accessibility.setFontScale(1),
                                          child: const Text('A'))),
                                  Semantics(
                                      button: true,
                                      label: 'Aumentar tamanho da fonte',
                                      child: OutlinedButton(
                                          onPressed: accessibility.increaseFont,
                                          child: const Text('A+')))
                                ]),
                                SwitchListTile(
                                    value: accessibility.highContrast,
                                    onChanged: accessibility.setContrast,
                                    title: const Text('Alto contraste'),
                                    subtitle: const Text(
                                        'Preto, branco e amarelo em toda a interface')),
                                SwitchListTile(
                                    value: accessibility.screenReaderSupport,
                                    onChanged: accessibility.setReaderSupport,
                                    title: const Text(
                                        'Suporte a leitores de tela'),
                                    subtitle: const Text(
                                        'Mantém descrições acessíveis nos controles')),
                                const Text(
                                    'Use TAB para navegar e ENTER para confirmar.',
                                    style: TextStyle(fontSize: 12))
                              ]))))
          ]);
}

class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: accessibility,
      builder: (context, _) => CustomPaint(
          painter: WavePainter(highContrast: accessibility.highContrast)));
}

class WavePainter extends CustomPainter {
  WavePainter({this.highContrast = false});
  final bool highContrast;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = highContrast ? Colors.black : pageBackgroundColor);
    final green = Path()
      ..moveTo(0, size.height * .88)
      ..quadraticBezierTo(size.width * .22, size.height * .78, size.width * .50,
          size.height * .88)
      ..quadraticBezierTo(
          size.width * .78, size.height * .78, size.width, size.height * .84)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(green,
        Paint()..color = highContrast ? Colors.black : const Color(0xFF19A77E));
    final blue = Path()
      ..moveTo(0, size.height * .98)
      ..quadraticBezierTo(size.width * .24, size.height * .91, size.width * .55,
          size.height * .98)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    if (highContrast) {
      canvas.drawPath(
          green,
          Paint()
            ..color = Colors.yellow
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    canvas.drawPath(blue,
        Paint()..color = highContrast ? Colors.black : const Color(0xFF0879BE));
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.highContrast != highContrast;
}

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 82, 20, 30),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(30), child: child)))));
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: accessibility.highContrast
              ? Colors.black
              : const Color(0xFFE8F1FF),
          border: Border.all(
              color: accessibility.highContrast ? Colors.yellow : blue,
              width: accessibility.highContrast ? 2 : 0),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: accessibility.highContrast ? Colors.yellow : blue),
        const SizedBox(width: 10),
        Expanded(child: Text(text))
      ]));
}

Widget field(TextEditingController controller, String label, IconData icon,
        {String? hint,
        String? errorText,
        bool number = false,
        bool secret = false,
        Widget? suffix,
        String? Function(String?)? validator,
        List<TextInputFormatter>? inputFormatters}) =>
    Semantics(
        textField: true,
        label: accessibility.screenReaderSupport
            ? '$label${hint == null ? '' : '. $hint'}'
            : label,
        child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
                controller: controller,
                keyboardType:
                    number ? TextInputType.number : TextInputType.text,
                inputFormatters: inputFormatters ??
                    (number ? [FilteringTextInputFormatter.digitsOnly] : null),
                validator: validator,
                forceErrorText: errorText,
                errorBuilder: (context, error) => Semantics(
                    liveRegion: true,
                    child: Text(error,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: null,
                textInputAction: TextInputAction.next,
                obscureText: secret,
                decoration: InputDecoration(
                    labelText: label,
                    errorMaxLines: 4,
                    hintText: hint,
                    prefixIcon: Icon(icon),
                    suffixIcon: suffix))));
