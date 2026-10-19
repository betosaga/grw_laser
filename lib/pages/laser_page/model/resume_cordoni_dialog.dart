import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'radio_option.dart';
import 'resume_result.dart';

part 'resume_cordoni_dialog_state.dart';

class ResumeCordoniDialog extends StatefulWidget {
  final int cordoneCorrente;
  final int numerocordonitotale;

  const ResumeCordoniDialog({
    super.key,
    required this.cordoneCorrente,
    required this.numerocordonitotale,
  });

  @override
  State<ResumeCordoniDialog> createState() => _ResumeCordoniDialogState();
}
