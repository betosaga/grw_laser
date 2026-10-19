import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'alignment_option.dart';
import 'panel_config_result.dart';

part 'panel_alignment_dialog_state.dart';

class PanelAlignmentDialog extends StatefulWidget {
  final String current;
  final bool showTakenPointsPanel;
  const PanelAlignmentDialog({
    super.key,
    required this.current,
    required this.showTakenPointsPanel,
  });

  @override
  State<PanelAlignmentDialog> createState() => _PanelAlignmentDialogState();
}
