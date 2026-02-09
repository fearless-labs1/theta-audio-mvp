import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WindowControlsOverlay extends StatefulWidget {
  const WindowControlsOverlay({super.key});

  @override
  State<WindowControlsOverlay> createState() => _WindowControlsOverlayState();
}

class _WindowControlsOverlayState extends State<WindowControlsOverlay> {
  static const MethodChannel _channel =
      MethodChannel('theta/window_controls');

  bool _hovering = false;

  Future<void> _invokeControl(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            color: Colors.transparent,
            child: SizedBox(
              width: 132,
              height: 40,
              child: IgnorePointer(
                ignoring: !_hovering,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  opacity: _hovering ? 1 : 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _WindowControlButton(
                        icon: Icons.remove,
                        color: const Color(0xFF7EC8FF),
                        onPressed: () => _invokeControl('minimize'),
                      ),
                      _WindowControlButton(
                        icon: Icons.crop_square,
                        color: const Color(0xFF00D46A),
                        onPressed: () => _invokeControl('toggleMaximize'),
                      ),
                      _WindowControlButton(
                        icon: Icons.close,
                        color: const Color(0xFFFF3B30),
                        onPressed: () => _invokeControl('close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowControlButton extends StatelessWidget {
  const _WindowControlButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 40),
      splashRadius: 18,
    );
  }
}
