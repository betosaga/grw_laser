import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/vibrator.dart';

class LaserDebugButton extends StatelessWidget {
  final LaserPageController controller;
  const LaserDebugButton({super.key, required this.controller});

  Future<void> _showDebugDialog(BuildContext context) async {
    final textController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => _LaserDebugDialog(
        textController: textController,
        controller: controller,
      ),
    );

    textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => Vibrator.shortVibration(),
      child: TextButton(
        onPressed: () => _showDebugDialog(context),
        child: const Icon(
          Icons.bug_report,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LaserDebugDialog extends StatefulWidget {
  final TextEditingController textController;
  final LaserPageController controller;

  const _LaserDebugDialog({
    required this.textController,
    required this.controller,
  });

  @override
  State<_LaserDebugDialog> createState() => _LaserDebugDialogState();
}

class _LaserDebugDialogState extends State<_LaserDebugDialog> {
  bool _isSending = false;
  bool _isLoading = false;

  static const _brunoUrl =
      'https://rswonline.saga-srl.it/bruno-robot/bruno.json';

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(_brunoUrl));
      if (response.statusCode == 200) {
        widget.textController.text = response.body;
      } else {
        if (mounted) {
          _showSnackbar(context, 'Errore HTTP ${response.statusCode}',
              success: false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(context, 'Errore caricamento: $e', success: false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final rawText = widget.textController.text.trim();
    if (rawText.isEmpty) {
      _showSnackbar(context, 'Il campo è vuoto.', success: false);
      return;
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(rawText) as Map<String, dynamic>;
    } catch (_) {
      _showSnackbar(context, 'JSON non valido.', success: false);
      return;
    }

    setState(() => _isSending = true);
    try {
      await widget.controller.sendMessageToRobot(decoded);
      if (mounted) {
        _showSnackbar(context, 'Messaggio inviato.', success: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(context, 'Errore: $e', success: false);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnackbar(BuildContext context, String message,
      {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Debug',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: widget.textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Incolla il JSON qui...',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.multiline,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ANNULLA'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: (_isLoading || _isSending) ? null : _load,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('CARICA'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_isSending || _isLoading) ? null : _send,
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('INVIA'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
