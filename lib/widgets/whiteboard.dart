import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class Whiteboard extends StatefulWidget {
  const Whiteboard({super.key});

  @override
  State<Whiteboard> createState() => _WhiteboardState();
}

class _WhiteboardState extends State<Whiteboard> {
  final List<_Stroke> _strokes = [];
  _Stroke? _activeStroke;
  Color _activeColor = AppPalette.accent;
  double _activeWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toolbar(
          activeColor: _activeColor,
          activeWidth: _activeWidth,
          onColorChanged: (color) => setState(() => _activeColor = color),
          onWidthChanged: (width) => setState(() => _activeWidth = width),
          onClear: _clear,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: AppPalette.surface,
              child: GestureDetector(
                onPanStart: _startStroke,
                onPanUpdate: _extendStroke,
                onPanEnd: _endStroke,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _WhiteboardPainter(strokes: _strokes),
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startStroke(DragStartDetails details) {
    final stroke = _Stroke(
      color: _activeColor,
      width: _activeWidth,
      points: [details.localPosition],
    );
    setState(() {
      _activeStroke = stroke;
      _strokes.add(stroke);
    });
  }

  void _extendStroke(DragUpdateDetails details) {
    setState(() {
      _activeStroke?.points.add(details.localPosition);
    });
  }

  void _endStroke(DragEndDetails details) {
    _activeStroke = null;
  }

  void _clear() {
    setState(() => _strokes.clear());
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.activeColor,
    required this.activeWidth,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onClear,
  });

  final Color activeColor;
  final double activeWidth;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onWidthChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.wash,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            'Ink',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          ...[
            AppPalette.accent,
            AppPalette.accentWarm,
            const Color(0xFF2E4057),
            const Color(0xFF111111),
          ].map(
            (color) => _ColorChip(
              color: color,
              selected: activeColor == color,
              onTap: () => onColorChanged(color),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Weight',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          ...[2.5, 4.0, 6.0].map(
            (width) => _WeightChip(
              width: width,
              selected: activeWidth == width,
              onTap: () => onWidthChanged(width),
            ),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppPalette.ink : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _WeightChip extends StatelessWidget {
  const _WeightChip({
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppPalette.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.border),
        ),
        child: Text(
          width.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : AppPalette.muted,
          ),
        ),
      ),
    );
  }
}

class _Stroke {
  _Stroke({required this.color, required this.width, required this.points});

  final Color color;
  final double width;
  final List<Offset> points;
}

class _WhiteboardPainter extends CustomPainter {
  const _WhiteboardPainter({required this.strokes});

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) {
        continue;
      }
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return true;
  }
}
