import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CircaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isGhost;

  const CircaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isGhost = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isGhost ? Colors.transparent : (onPressed == null ? CircaColors.muted : CircaColors.accent),
          foregroundColor: isGhost ? CircaColors.muted : Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: isGhost ? Colors.transparent : CircaColors.muted.withValues(alpha: 0.3),
          disabledForegroundColor: CircaColors.muted,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isGhost 
                ? const BorderSide(color: CircaColors.line, width: 1.5) 
                : BorderSide.none,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) && !isGhost) {
              return CircaColors.accentDeep;
            }
            return null;
          }),
        ),
        onPressed: onPressed,
        child: Text(label, style: CircaColors.button),
      ),
    );
  }
}

class CircaChoiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const CircaChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<CircaChoiceCard> createState() => _CircaChoiceCardState();
}

class _CircaChoiceCardState extends State<CircaChoiceCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isPressed;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isActive ? CircaColors.accentSoft : CircaColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? CircaColors.accent : CircaColors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: CircaColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: CircaColors.accent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: CircaColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CircaColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward_ios, size: 16, color: CircaColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class CircaLogo extends StatelessWidget {
  final double size;
  final double angle;

  const CircaLogo({super.key, this.size = 22, this.angle = 0});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * 3.141592653589793 / 180,
      child: CustomPaint(
        size: Size(size, size),
        painter: _CircaLogoPainter(),
      ),
    );
  }
}

class _CircaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    
    final arcPaint = Paint()
      ..color = CircaColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11.0 * scale
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = CircaColors.accent
      ..style = PaintingStyle.fill;

    // Draw arc: radius 32, center 50,50, from roughly 40 degrees (top right) to -40 degrees (bottom right) via the left side
    // In Flutter, drawArc takes a bounding rect.
    final rect = Rect.fromCircle(center: Offset(50 * scale, 50 * scale), radius: 32 * scale);
    
    // startAngle: 74.5, 29.4 -> relative to center 50,50 -> dx: 24.5, dy: -20.6
    // atan2(-20.6, 24.5) = -0.698 rad (~ -40 deg)
    // sweepAngle: we want the large arc via left, so sweep is negative.
    // endAngle: 74.5, 70.6 -> dx: 24.5, dy: 20.6 -> atan2(20.6, 24.5) = +0.698 rad (~ +40 deg)
    // -40 to +40 via left means a sweep of roughly -(360 - 80) = -280 degrees
    canvas.drawArc(rect, -0.698, -4.8869, false, arcPaint);

    canvas.drawCircle(Offset(82 * scale, 50 * scale), 7 * scale, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

