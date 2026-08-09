import 'package:flutter/material.dart';

class NavigateCard extends StatelessWidget {
  const NavigateCard({
    super.key,
    this.height = 100,
    this.width = 100,
    required this.title,
    this.subtitle = '',
    required this.destination,
    this.backgroundColor = Colors.blueAccent,
    this.icon = const Icon(Icons.arrow_forward, color: Colors.white),
  });

  final String title;
  final String subtitle;
  final Widget destination;
  final Color backgroundColor;
  final Widget icon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => destination));
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 8,
              top: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Positioned(right: 8, bottom: 8, child: icon),
          ],
        ),
      ),
    );
  }
}
