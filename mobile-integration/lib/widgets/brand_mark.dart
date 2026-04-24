import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.assetPath, required this.width});

  final String assetPath;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          child: const Text(
            'Watch It',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF5350),
            ),
          ),
        );
      },
    );
  }
}
