// Copyright 2026 Void Sower Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';

import '../services/haptic_service.dart';
import '../theme/void_theme.dart';

/// Tactile interactive button with animated 0.95x squish, neon glow, and haptic feedback.
class TactileButton extends StatefulWidget {
  const TactileButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.accentColor = VoidTheme.solarGold,
    this.minWidth = 120.0,
    this.height = 48.0,
    this.isPrimary = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
    this.fontSize = 13.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color accentColor;
  final double minWidth;
  final double height;
  final bool isPrimary;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    _controller.forward();
    HapticService.instance.sowTick();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed == null) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final color = isEnabled ? widget.accentColor : VoidTheme.textMuted;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          constraints: BoxConstraints(
            minWidth: widget.minWidth,
            minHeight: widget.height,
          ),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? color.withValues(alpha: isEnabled ? 0.22 : 0.08)
                : VoidTheme.cardSurface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: color.withValues(alpha: isEnabled ? 0.9 : 0.4),
              width: widget.isPrimary ? 1.8 : 1.2,
            ),
            boxShadow: isEnabled && widget.isPrimary
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10.0,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: color, size: 18.0),
                const SizedBox(width: 8.0),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isEnabled
                        ? VoidTheme.textPrimary
                        : VoidTheme.textMuted,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
