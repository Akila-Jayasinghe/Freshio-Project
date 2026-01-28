import 'dart:async';
import 'package:flutter/material.dart';

class ToastUtils {
  static GlobalKey<_ToastStackState>? _toastKey;
  static OverlayEntry? _overlayEntry;

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Icons.check_circle_rounded, Colors.green.shade600);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, Icons.info_rounded, Colors.blueAccent);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, Icons.wifi_off_rounded, Colors.orange.shade800);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, Icons.error_outline_rounded, Colors.redAccent);
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
  ) {
    final String cleanMessage = message.trim();

    if (cleanMessage.isEmpty) return;

    // Initialize the Overlay if it doesn't exist
    if (_overlayEntry == null) {
      _toastKey = GlobalKey<_ToastStackState>();
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 20,
          right: 20,
          child: ToastStack(key: _toastKey),
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }

    // Add the message to the stack
    _toastKey?.currentState?.addToast(cleanMessage, icon, color);
  }
}

// The Stack Manager Widget
class ToastStack extends StatefulWidget {
  const ToastStack({super.key});

  @override
  State<ToastStack> createState() => _ToastStackState();
}

class _ToastStackState extends State<ToastStack> {
  final List<_ToastModel> _toasts = [];

  void addToast(String message, IconData icon, Color color) {
    setState(() {
      // MAX LIMIT LOGIC: If we have 3 or more,
      // remove the oldest (first) immediately
      if (_toasts.length >= 3) {
        _removeToast(_toasts.first.id); // Remove oldest
      }

      // Add New Toast
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      _toasts.add(
        _ToastModel(id: id, message: message, icon: icon, color: color),
      );

      // Set Auto-Remove Timer for this specific toast
      Timer(const Duration(seconds: 3), () {
        _removeToast(id);
      });
    });
  }

  void _removeToast(String id) {
    if (!mounted) return;
    setState(() {
      _toasts.removeWhere((t) => t.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Column allows them to stack vertically
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _toasts.map((toast) {
        return _ToastWidget(
          key: ValueKey(toast.id), // Important for animation to track items
          model: toast,
        );
      }).toList(),
    );
  }
}

// Data Model
class _ToastModel {
  final String id;
  final String message;
  final IconData icon;
  final Color color;

  _ToastModel({
    required this.id,
    required this.message,
    required this.icon,
    required this.color,
  });
}

// Individual Animated Toast Widget
class _ToastWidget extends StatefulWidget {
  final _ToastModel model;

  const _ToastWidget({super.key, required this.model});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
  with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _offset = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10), // Gap between toasts
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.model.color.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.model.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.model.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.model.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
