import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Widget de carousel horizontal réutilisable
/// Supporte le swipe tactile et le scroll à la souris
class HorizontalCarousel extends StatelessWidget {
  final List<Widget> children;
  final double height;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  const HorizontalCarousel({
    super.key,
    required this.children,
    required this.height,
    this.padding,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: children.length,
          separatorBuilder: (context, index) => SizedBox(width: spacing),
          itemBuilder: (context, index) => children[index],
        ),
      ),
    );
  }
}

