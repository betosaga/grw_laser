import 'package:flutter/material.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/robot/robot_command.dart';

class LaserCommunicationStatus extends StatelessWidget {
  const LaserCommunicationStatus({super.key, required this.controller});

  final LaserPageController controller;

  String _label(RobotCommandStatus status) {
    switch (status) {
      case RobotCommandStatus.notSent:
        return 'Non inviato';
      case RobotCommandStatus.waiting:
        return 'In attesa di risposta';
      case RobotCommandStatus.responseObserved:
        return 'Risposta compatibile ricevuta';
      case RobotCommandStatus.stateObserved:
        return 'Stato atteso osservato';
      case RobotCommandStatus.unknown:
        return 'Esito sconosciuto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = controller.robotCommandHistory;
    final last = history.isEmpty ? null : history.last;
    final warning = controller.robotCommunicationWarning;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _showHistory(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              const Icon(Icons.history, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  last == null
                      ? controller.robotConnectionDescription
                      : '${controller.robotConnectionDescription} · '
                          '${last.command}: ${_label(last.outcome.status)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Text('Dettagli', style: TextStyle(fontSize: 12)),
            ]),
          ),
        ),
        if (warning != null)
          Container(
            color: Colors.orange.shade100,
            padding: const EdgeInsets.only(left: 12),
            child: Row(children: [
              const Icon(Icons.warning_amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(warning, style: const TextStyle(fontSize: 12))),
              IconButton(
                tooltip: 'Chiudi avviso',
                onPressed: controller.dismissRobotCommunicationWarning,
                icon: const Icon(Icons.close, size: 18),
              ),
            ]),
          ),
      ],
    );
  }

  void _showHistory(BuildContext context) {
    // An explicit snapshot; the live status remains on the main page.
    final entries = controller.robotCommandHistory.reversed.map((receipt) {
      return ListTile(
        dense: true,
        title: Text('${receipt.command}: ${_label(receipt.outcome.status)}'),
        subtitle:
            Text('${receipt.createdAt.toLocal()}\n${receipt.outcome.reason}'),
      );
    }).toList();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comunicazione con il robot'),
        content: SizedBox(
          width: 540,
          height: 360,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(controller.robotConnectionDescription),
            const SizedBox(height: 8),
            const Text('Le risposte e gli stati osservati non garantiscono '
                'l’esecuzione del singolo comando. I comandi non vengono reinviati automaticamente.'),
            const Divider(),
            Expanded(child: ListView(children: entries)),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi'))
        ],
      ),
    );
  }
}
