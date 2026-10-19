part of 'panel_alignment_dialog.dart';

class _PanelAlignmentDialogState extends State<PanelAlignmentDialog> {
  late String _selected;
  late bool _showTakenPointsPanel;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _showTakenPointsPanel = widget.showTakenPointsPanel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Configurazione pannello',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AlignmentOption(
            value: 'left',
            selected: _selected,
            label: 'Destra',
            description: 'Cloche a destra',
            icon: Icons.align_horizontal_right,
            onTap: (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 12),
          AlignmentOption(
            value: 'right',
            selected: _selected,
            label: 'Sinistra',
            description: 'Cloche a sinistra',
            icon: Icons.align_horizontal_left,
            onTap: (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: _showTakenPointsPanel,
            title: const Text('Mostra elenco punti'),
            onChanged: (value) {
              setState(() {
                _showTakenPointsPanel = value ?? true;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.sagaBlue,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Annulla',
            style: TextStyle(color: AppColors.sagaBlue),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sagaBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(
            PanelConfigResult(
              alignment: _selected,
              showTakenPointsPanel: _showTakenPointsPanel,
            ),
          ),
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}
