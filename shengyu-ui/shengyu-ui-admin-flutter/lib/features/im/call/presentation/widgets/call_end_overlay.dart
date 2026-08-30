import 'package:flutter/material.dart';

class CallEndOverlay extends StatelessWidget {
  const CallEndOverlay({
    super.key,
    required this.text,
    required this.elapsedText,
    required this.showElapsed,
  });

  final String text;
  final String elapsedText;
  final bool showElapsed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xEB0B0B0D),
        child: IgnorePointer(
          child: Center(
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showElapsed) ...[
                    const SizedBox(height: 10),
                    Text(
                      elapsedText,
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 15,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
