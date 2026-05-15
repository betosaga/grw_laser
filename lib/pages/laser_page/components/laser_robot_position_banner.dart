import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserRobotPositionBanner extends StatelessWidget {
  final LaserPageController controller;

  const LaserRobotPositionBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final posizioneRobot = controller.posizioneRobot;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Container(
          padding: const EdgeInsets.all(2.0),
          color: Colors.white,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12.0,
                color: Colors.black,
                fontFamily: 'oswald',
              ),
              children: [
                TextSpan(
                  text: 'Tempo: ${controller.formatDuration(controller.stopwatch.elapsed)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: ' Posizione: X: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: posizioneRobot.x.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const TextSpan(
                  text: ' Y: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: posizioneRobot.y.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const TextSpan(
                  text: ' Z: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: posizioneRobot.z.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const TextSpan(
                  text: ' J1: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: posizioneRobot.j1.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const TextSpan(
                  text: ' J2: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: posizioneRobot.j2.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const TextSpan(
                  text: ' J3: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: posizioneRobot.j3.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const TextSpan(
                  text: ' JT: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      '${posizioneRobot.jt1} , ${posizioneRobot.jt2} , ${posizioneRobot.jt3} , ${posizioneRobot.jt4} , ${posizioneRobot.jt5} , ${posizioneRobot.jt6}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
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
