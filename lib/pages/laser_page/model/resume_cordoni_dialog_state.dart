part of 'resume_cordoni_dialog.dart';

class _ResumeCordoniDialogState extends State<ResumeCordoniDialog> {
  bool _isPrima = true;
  late TextEditingController _ctrl;

  int get _maxPrima => widget.cordoneCorrente;
  int get _maxDopo {
    if (widget.numerocordonitotale > 0) {
      return widget.numerocordonitotale - widget.cordoneCorrente;
    }
    return 9999;
  }

  int get _currentMax => _isPrima ? _maxPrima : _maxDopo;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _clamp() {
    final v = int.tryParse(_ctrl.text) ?? 0;
    _ctrl.text = v.clamp(0, _currentMax).toString();
  }

  void _decrement() {
    final v = (int.tryParse(_ctrl.text) ?? 0) - 1;
    _ctrl.text = v.clamp(0, _currentMax).toString();
  }

  void _increment() {
    final v = (int.tryParse(_ctrl.text) ?? 0) + 1;
    _ctrl.text = v.clamp(0, _currentMax).toString();
  }

  @override
  Widget build(BuildContext context) {
    //
    //
    //
    const blue = AppColors.sagaBlue;
    final title = _isPrima ? 'Arretramento Cordoni' : 'Avanzamento Cordoni';
    final subtitle = _isPrima
        ? 'Torna indietro di N cordoni rispetto al cordone corrente (${widget.cordoneCorrente})'
        : 'Avanza di N cordoni rispetto al cordone corrente (${widget.cordoneCorrente})';
    final rangeHint = '0 — $_currentMax';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Radio Prima / Dopo ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: RadioOption(
                  label: 'Prima',
                  selected: _isPrima,
                  onTap: () => setState(() {
                    _isPrima = true;
                    _clamp();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RadioOption(
                  label: 'Dopo',
                  selected: !_isPrima,
                  onTap: () => setState(() {
                    _isPrima = false;
                    _clamp();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Testo contestuale ───────────────────────────────────
          Text(subtitle, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Intervallo: $rangeHint',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          // ── Stepper + TextField ─────────────────────────────────
          Row(
            children: [
              SizedBox(
                width: 42,
                child: ElevatedButton(
                  onPressed: _decrement,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(4),
                    backgroundColor: blue,
                    foregroundColor: blue,
                  ),
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => _clamp(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                child: ElevatedButton(
                  onPressed: _increment,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(4),
                    backgroundColor: blue,
                    foregroundColor: blue,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.sagaBlue,
          ),
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text(
            'Annulla',
            style: TextStyle(color: AppColors.sagaBlue),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final v = int.tryParse(_ctrl.text);
            if (v == null) return;
            if (v < 0 || v > _currentMax) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Valore non compreso tra 0 e $_currentMax'),
                ),
              );
              return;
            }
            Navigator.of(
              context,
            ).pop(ResumeResult(count: v, isPrima: _isPrima));
          },
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}
