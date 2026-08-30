import 'package:flutter/material.dart';

class CallStatusBanner extends StatelessWidget {
  const CallStatusBanner({
    super.key,
    required this.text,
    this.recovered = false,
  });

  final String text;
  final bool recovered;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: (recovered ? const Color(0xFF07C160) : const Color(0xFFFFB020))
              .withValues(alpha: .9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              recovered
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
