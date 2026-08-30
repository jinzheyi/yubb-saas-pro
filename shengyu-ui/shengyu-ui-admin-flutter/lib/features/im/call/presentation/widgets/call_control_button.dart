import 'package:flutter/material.dart';

enum CallControlKind { normal, destructive, accept }

class CallControlButton extends StatelessWidget {
  const CallControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.kind = CallControlKind.normal,
    this.selected = true,
    this.enabled = true,
    this.loading = false,
    this.large = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final CallControlKind kind;
  final bool selected;
  final bool enabled;
  final bool loading;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 56.0;
    final colors = _colors();
    return Semantics(
      button: true,
      enabled: enabled && !loading,
      label: label,
      child: Tooltip(
        message: label,
        child: Opacity(
          opacity: enabled ? 1 : .38,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: colors.$1,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enabled && !loading ? onPressed : null,
                  child: SizedBox.square(
                    dimension: size,
                    child: Center(
                      child: loading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Icon(icon, size: large ? 28 : 26, color: colors.$2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 88,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _colors() {
    if (kind == CallControlKind.destructive) {
      return (const Color(0xFFFA5151), Colors.white);
    }
    if (kind == CallControlKind.accept) {
      return (const Color(0xFF07C160), Colors.white);
    }
    if (!selected) return (const Color(0xFFF2F2F2), const Color(0xFF202124));
    return (const Color(0x24FFFFFF), Colors.white);
  }
}
