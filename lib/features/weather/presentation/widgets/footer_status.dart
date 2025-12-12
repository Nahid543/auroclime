import 'package:flutter/material.dart';

class FooterStatus extends StatelessWidget {
  final String text;

  const FooterStatus({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white38,
            ),
      ),
    );
  }
}
