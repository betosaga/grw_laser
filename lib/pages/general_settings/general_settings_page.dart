import 'package:flutter/material.dart';
import 'package:grw_laser/common_components/gradient_app_bar_background.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/general_settings.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  String _searchMode = GeneralSettings.robotSearchMode;
  bool _saving = false;

  Future<void> _selectSearchMode(String? mode) async {
    if (mode == null || mode == _searchMode || _saving) return;
    setState(() => _saving = true);
    try {
      await GeneralSettings.setRobotSearchMode(mode);
      if (!mounted) return;
      setState(() => _searchMode = GeneralSettings.robotSearchMode);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile salvare la modalità di ricerca. Riprova.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni generali'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: const GradientAppBarBackground(),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Ricerca robot', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Scegli quali robot mostrare quando premi il pulsante +.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: RadioGroup<String>(
                    groupValue: _searchMode,
                    onChanged: _selectSearchMode,
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'FLAT',
                          enabled: !_saving,
                          activeColor: AppColors.sagaBlue,
                          title: const Text('Piatta'),
                          subtitle: const Text(
                            'Mostra tutti i robot presenti nell’elenco del server.',
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          value: 'SCAN',
                          enabled: !_saving,
                          activeColor: AppColors.sagaBlue,
                          title: const Text('Scansione'),
                          subtitle: const Text(
                            'Mostra solo i robot dell’elenco disponibili nella rete locale.',
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _saving
                      ? 'Salvataggio…'
                      : 'La scelta viene salvata su questo tablet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
