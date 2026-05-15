import 'package:flutter/material.dart';

class LaserPausedBanner extends StatelessWidget {
  const LaserPausedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: Container(
          color: Colors.red.withAlpha(120),
          child: Center(
            child: Text(
              "LAVORAZIONE IN PAUSA",
              style: TextStyle(
                  color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
