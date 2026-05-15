import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';

class LaserNumericPadInput extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final TextAlign textAlign;
  final bool enabled;

  const LaserNumericPadInput({
    super.key,
    required this.controller,
    this.decoration,
    this.textAlign = TextAlign.start,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: true,
      showCursor: false,
      textAlign: textAlign,
      decoration: decoration,
      onTap: () async {
        if (!enabled) return;
        FocusScope.of(context).unfocus();
        final nextValue = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _LaserNumericPadDialog(
            initialValue: controller.text,
          ),
        );
        if (nextValue == null) return;
        controller
          ..text = nextValue
          ..selection = TextSelection.collapsed(offset: nextValue.length);
      },
    );
  }
}

class _LaserNumericPadDialog extends StatefulWidget {
  final String initialValue;

  const _LaserNumericPadDialog({required this.initialValue});

  @override
  State<_LaserNumericPadDialog> createState() => _LaserNumericPadDialogState();
}

class _LaserNumericPadDialogState extends State<_LaserNumericPadDialog> {
  late final ValueNotifier<String> _draftNotifier;

  @override
  void initState() {
    super.initState();
    _draftNotifier = ValueNotifier(_sanitize(widget.initialValue));
  }

  @override
  void dispose() {
    _draftNotifier.dispose();
    super.dispose();
  }

  String _sanitize(String raw) {
    final negative = raw.startsWith('-');
    final filtered = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (filtered.isEmpty) return '';
    final firstDot = filtered.indexOf('.');
    String result;
    if (firstDot == -1) {
      result = filtered;
    } else {
      final prefix = filtered.substring(0, firstDot + 1);
      final suffix = filtered.substring(firstDot + 1).replaceAll('.', '');
      result = '$prefix$suffix';
    }
    return negative && result.isNotEmpty ? '-$result' : result;
  }

  void _append(String char) {
    var draft = _draftNotifier.value;
    if (char == '.') {
      if (draft.contains('.')) return;
      if (draft.isEmpty) {
        draft = '0.';
      } else if (draft == '-') {
        draft = '-0.';
      } else {
        draft = '$draft.';
      }
    } else {
      // Sostituisce uno zero intero iniziale con il nuovo digit (es. "0" -> "5", "-0" -> "-5")
      if (draft == '0') {
        draft = char;
      } else if (draft == '-0') {
        draft = '-$char';
      } else {
        draft = '$draft$char';
      }
    }
    _draftNotifier.value = draft;
  }

  void _toggleSign() {
    final draft = _draftNotifier.value;
    if (draft.startsWith('-')) {
      _draftNotifier.value = draft.substring(1);
    } else if (draft.isEmpty) {
      _draftNotifier.value = '-';
    } else {
      _draftNotifier.value = '-$draft';
    }
  }

  void _deleteLast() {
    final draft = _draftNotifier.value;
    if (draft.isEmpty) return;
    _draftNotifier.value = draft.substring(0, draft.length - 1);
  }

  Widget _buildKey(
    String label, {
    VoidCallback? onPressed,
    required double keyFontSize,
    required double keyCornerRadius,
  }) {
    final action = onPressed ?? () => _append(label);
    return Material(
      color: AppColors.sagaBlue,
      borderRadius: BorderRadius.circular(keyCornerRadius),
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.white24,
        borderRadius: BorderRadius.circular(keyCornerRadius),
        onTap: action,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: keyFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;
    final isTablet = shortestSide >= 600;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final dialogMaxWidth = isTablet ? (isLandscape ? 680.0 : 560.0) : 360.0;
    final dialogHorizontalInset = isTablet ? (isLandscape ? 96.0 : 72.0) : 24.0;
    final dialogVerticalInset = isTablet ? 24.0 : 16.0;
    final contentPadding = isTablet ? 20.0 : 16.0;
    final valueFontSize = isTablet ? 52.0 : 42.0;
    final keyFontSize = isTablet ? 24.0 : 20.0;
    final keyCornerRadius = isTablet ? 24.0 : 20.0;
    final keypadSpacing = isTablet ? 12.0 : 8.0;
    final actionButtonHeight = isTablet ? 50.0 : 40.0;
    final actionCornerRadius = isTablet ? 24.0 : 20.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: dialogHorizontalInset,
        vertical: dialogVerticalInset,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogMaxWidth),
        child: Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Solo il display si ricostruisce ad ogni keystroke
              ValueListenableBuilder<String>(
                valueListenable: _draftNotifier,
                builder: (_, draft, __) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        draft.isEmpty ? '0' : draft,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w700,
                          color: draft.isEmpty ? Colors.grey.shade400 : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.backspace_outlined),
                      iconSize: keyFontSize + 4,
                      color: AppColors.sagaBlue,
                      onPressed: _deleteLast,
                    ),
                  ],
                ),
              ),
              SizedBox(height: keypadSpacing + 4),
              // La griglia NON si ricostruisce ad ogni keystroke
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: keypadSpacing,
                crossAxisSpacing: keypadSpacing,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isTablet ? 1.65 : 1.5,
                children: [
                  _buildKey('1', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('2', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('3', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('4', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('5', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('6', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('7', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('8', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('9', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('+/-', onPressed: _toggleSign, keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('0', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                  _buildKey('.', keyFontSize: keyFontSize, keyCornerRadius: keyCornerRadius),
                ],
              ),
              SizedBox(height: keypadSpacing + 4),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: actionButtonHeight,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.sagaBlue,
                          side: const BorderSide(color: AppColors.sagaBlue),
                          shape: ContinuousRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(actionCornerRadius),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Annulla',
                          style: TextStyle(
                            fontSize: isTablet ? 21 : 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: keypadSpacing),
                  Expanded(
                    child: SizedBox(
                      height: actionButtonHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sagaBlue,
                          foregroundColor: Colors.white,
                          shape: ContinuousRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(actionCornerRadius),
                          ),
                        ),
                        onPressed: () {
                          var result = _draftNotifier.value;
                          if (result == '-') result = '';
                          if (result.endsWith('.')) {
                            result = result.substring(0, result.length - 1);
                          }
                          Navigator.of(context).pop(result);
                        },
                        child: Text(
                          'Conferma',
                          style: TextStyle(
                            fontSize: isTablet ? 21 : 16,
                          ),
                        ),
                      ),
                    ),
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
