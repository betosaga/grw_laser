// ignore_for_file: must_be_immutable
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/pages/laser_page/components/laser_rectangle_painter.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/vibrator.dart';

enum _PointLongPressAction {
  moveTo,
  delete,
}

class LaserRectangleWithCrossCursor extends StatefulWidget {
  final LaserPageController controller;
  final double scaleX;
  final double scaleZ;
  final Point posizioneRobot;
  final Stopwatch stopwatch;
  final List<double> robotSpeed;

  bool paused;

  LaserRectangleWithCrossCursor({
    super.key,
    required this.controller,
    this.scaleX = 1.0,
    this.scaleZ = 1.0, // default a 1 ma parte a 2
    required this.posizioneRobot,
    required this.robotSpeed,
    required this.stopwatch,
    required this.paused,
  });

  @override
  LaserRectangleWithCrossCursorState createState() =>
      LaserRectangleWithCrossCursorState();
}

class LaserRectangleWithCrossCursorState
    extends State<LaserRectangleWithCrossCursor> {
  Offset _position = Offset(0, 0);
  Offset _panOffset = Offset.zero;
  double _viewScale = 1.0;
  double _gestureStartScale = 1.0;
  Offset? _gestureStartLogicalFocalPoint;
  bool _ignoreNextTapUp = false;
  bool _autoPanDisabled = false;
  double? _robotStartPositionX;
  double? _robotStartPositionZ;

  // Dimensioni del rettangolo virtuale
  late double rectWidth;
  final double rectHeight = 260.0;

  // Metà delle dimensioni per il calcolo del centro
  late double horizontalLimit;
  final double verticalLimit = 260.0 / 2;

  // double fixedStartPointX = 0.8;
  // double fixedStartPointY = 0.8;
  double fixedStartPointX = 1;
  double fixedStartPointY = 1;

  final double circleRadius = 14;
  final double circleRadiusTolerance = 8.0;

  @override
  void initState() {
    super.initState();
    widget.controller.pointSelectionModeNotifier
        .addListener(_onSelectionModeChanged);
  }

  void _onSelectionModeChanged() {
    mySetState(() {});
  }

  @override
  void dispose() {
    widget.controller.pointSelectionModeNotifier
        .removeListener(_onSelectionModeChanged);
    super.dispose();
  }

  void setFixedStartPoint({required bool destraSinistra}) {
    fixedStartPointX = destraSinistra ? -0.8 : 0.8;
    fixedStartPointY = 0.8;
  }

  @override
  void didChangeDependencies() {
    rectWidth = MediaQuery.of(context).size.width;
    horizontalLimit = rectWidth / 2;
    super.didChangeDependencies();
  }

  void updateCursorPosition(Offset newPosition) {
    mySetState(() {
      _position = newPosition;
      if (_autoPanDisabled) return;

      // Con un solo punto, il primo punto deve restare ancorato al centro.
      final firstPoint = widget.controller.points.firstPoint();
      if (firstPoint?.dashboardPosition != null &&
          widget.controller.points.points.length == 1) {
        _centerGraphOnLogicalPoint(firstPoint!.dashboardPosition!);
      } else {
        _autoPan(newPosition);
      }
    });
  }

  /// Sposta il pan in modo che il cursore sia sempre visibile nel viewport.
  void _autoPan(Offset cursorPos) {
    const margin = 24.0;
    double dx = _panOffset.dx;
    double dy = _panOffset.dy;

    final screenX = cursorPos.dx * _viewScale + dx;
    final screenY = cursorPos.dy * _viewScale + dy;

    if (screenX < -horizontalLimit + margin) {
      dx += (-horizontalLimit + margin) - screenX;
    } else if (screenX > horizontalLimit - margin) {
      dx += (horizontalLimit - margin) - screenX;
    }

    if (screenY < -verticalLimit + margin) {
      dy += (-verticalLimit + margin) - screenY;
    } else if (screenY > verticalLimit - margin) {
      dy += (verticalLimit - margin) - screenY;
    }

    _panOffset = Offset(dx, dy);
  }

  /// Centra il pan in modo che tutti i punti + cursore siano visibili.
  void _fitAll() {
    final firstPoint = widget.controller.points.firstPoint();
    if (firstPoint?.dashboardPosition != null &&
        widget.controller.points.points.length == 1) {
      _viewScale = 1.0;
      _centerGraphOnLogicalPoint(firstPoint!.dashboardPosition!);
      return;
    }

    final allPos = <Offset>[
      _position,
      ...widget.controller.points.points
          .where((p) => p.dashboardPosition != null)
          .map((p) => p.dashboardPosition!),
    ];
    if (allPos.length <= 1) {
      _viewScale = 1.0;
      _panOffset = Offset.zero;
      return;
    }

    final minX = allPos.map((o) => o.dx).reduce((a, b) => a < b ? a : b);
    final maxX = allPos.map((o) => o.dx).reduce((a, b) => a > b ? a : b);
    final minY = allPos.map((o) => o.dy).reduce((a, b) => a < b ? a : b);
    final maxY = allPos.map((o) => o.dy).reduce((a, b) => a > b ? a : b);

    const margin = 28.0;
    final spanX = max(1.0, maxX - minX);
    final spanY = max(1.0, maxY - minY);
    final availableWidth = max(1.0, rectWidth - margin * 2);
    final availableHeight = max(1.0, rectHeight - margin * 2);
    final scaleX = availableWidth / spanX;
    final scaleY = availableHeight / spanY;

    // Riduce (o mantiene) la scala in modo che tutti gli elementi rientrino nel viewport.
    _viewScale = min(1.0, min(scaleX, scaleY));

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    _panOffset = Offset(-centerX * _viewScale, -centerY * _viewScale);

    // Garantisce comunque che il cursore rimanga sempre visibile dopo il fit.
    _autoPan(_position);
  }

  void _changeZoom(double factor) {
    mySetState(() {
      _applyZoom(
        nextScale: (_viewScale * factor).clamp(0.25, 3.0).toDouble(),
        focalPoint: _viewportCenter,
      );
    });
  }

  double get _manualPanStep => max(24.0, min(rectWidth, rectHeight) * 0.12);

  void _changePan(Offset delta) {
    mySetState(() {
      _panOffset += delta;
      _updateCanGeneratePoints();
    });
  }

  Offset get _viewportCenter => Offset(rectWidth / 2, rectHeight / 2);

  Offset _screenToLogical(
    Offset localPosition, {
    double? scale,
    Offset? panOffset,
  }) {
    final effectiveScale = scale ?? _viewScale;
    final effectivePanOffset = panOffset ?? _panOffset;

    return Offset(
      (localPosition.dx - rectWidth / 2 - effectivePanOffset.dx) /
          effectiveScale,
      (localPosition.dy - rectHeight / 2 - effectivePanOffset.dy) /
          effectiveScale,
    );
  }

  void _applyZoom({
    required double nextScale,
    required Offset focalPoint,
    Offset? anchoredLogicalPoint,
  }) {
    final clampedScale = nextScale.clamp(0.25, 3.0).toDouble();
    if ((clampedScale - _viewScale).abs() < 0.0001) return;

    final logicalFocalPoint =
        anchoredLogicalPoint ?? _screenToLogical(focalPoint);

    _viewScale = clampedScale;
    _panOffset = Offset(
      focalPoint.dx - rectWidth / 2 - logicalFocalPoint.dx * _viewScale,
      focalPoint.dy - rectHeight / 2 - logicalFocalPoint.dy * _viewScale,
    );
    _updateCanGeneratePoints();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _gestureStartScale = _viewScale;
    _gestureStartLogicalFocalPoint = _screenToLogical(details.localFocalPoint);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;

    final logicalFocalPoint = _gestureStartLogicalFocalPoint;
    if (logicalFocalPoint == null) return;

    mySetState(() {
      _ignoreNextTapUp = true;
      _applyZoom(
        nextScale:
            (_gestureStartScale * details.scale).clamp(0.25, 3.0).toDouble(),
        focalPoint: details.localFocalPoint,
        anchoredLogicalPoint: logicalFocalPoint,
      );
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _gestureStartLogicalFocalPoint = null;
  }

  void _centerGraphOnLogicalPoint(Offset logicalPoint) {
    _panOffset = Offset(
      -logicalPoint.dx * _viewScale,
      -logicalPoint.dy * _viewScale,
    );
  }

  Widget _buildZoomButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Vibrator.shortVibration();
          onTap();
        },
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildAutoPanToggleButton() {
    return Material(
      color: _autoPanDisabled
          ? Colors.orange.withValues(alpha: 0.85)
          : Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Vibrator.shortVibration();
          mySetState(() {
            _autoPanDisabled = !_autoPanDisabled;
          });
        },
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            _autoPanDisabled ? Icons.lock : Icons.lock_open,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void setPaused(bool paused) {
    mySetState(() {
      widget.paused = paused;
    });
  }

  Offset setDStart(double posx, double posz, bool destraSinistra) {
    print("[getPoint] SET DSTART [$posx, $posz]");
    setFixedStartPoint(destraSinistra: destraSinistra);

    widget.controller.canMoveRobot = true;
    _robotStartPositionX = posx;
    _robotStartPositionZ = posz;

    // Imposta la posizione iniziale relativa
    double startX =
        fixedStartPointX * horizontalLimit; // 80% del limite orizzontale
    double startY =
        fixedStartPointY * verticalLimit; // 80% del limite verticale

    print("[getPoint] - [ $startX, $startY ]");

    _position = Offset(startX, startY);
    _panOffset = Offset.zero;
    _viewScale = 1.0;
    mySetState(() {});
    print("[getPoint] $_position");
    return _position;
  }

  /// Imposta il riferimento robot senza spostare il cursore corrente.
  ///
  /// Dopo una disconnessione il widget viene ricreato con [_position] = (0,0)
  /// e [fixedStartPointX/Y] ai valori di default. Se usiamo (0,0) come base
  /// per calcolare [fixedStartPointX/Y], l'origine del grafico si sposta al
  /// centro e il cursore robot finisce sfasato rispetto ai pallini già salvati.
  ///
  /// Il primo punto ha in memoria la propria [dashboardPosition] calcolata come:
  ///   dashboardPosition = Offset(fixedStartPointX * hLimit, fixedStartPointY * vLimit)
  ///
  /// Invertendo la formula recuperiamo i valori originali e manteniamo il
  /// sistema di riferimento coerente con tutti i punti già presi.
  Offset initDStartWithoutMove(double posx, double posz, bool destraSinistra) {
    print("[getPoint] INIT DSTART WITHOUT MOVE [$posx, $posz]");
    widget.controller.canMoveRobot = true;
    _robotStartPositionX = posx;
    _robotStartPositionZ = posz;

    // Dopo reconnect il widget viene ricreato con _position = (0,0).
    // Usare (0,0) come base darebbe fixedStartPointX/Y = 0, spostando l'intera
    // origine e disallineando il cursore rispetto ai punti già salvati.
    // Recupera invece i valori originali dalla dashboardPosition del primo punto:
    //   firstPoint.dashboardPosition = Offset(fixedStartPointX * hLimit, fixedStartPointY * vLimit)
    final firstDashboardPos =
        widget.controller.points.firstPoint()?.dashboardPosition;
    //
    //
    //
    if (firstDashboardPos != null) {
      if (horizontalLimit != 0) {
        fixedStartPointX =
            (firstDashboardPos.dx / horizontalLimit).clamp(-1.0, 1.0);
      }
      if (verticalLimit != 0) {
        fixedStartPointY =
            (firstDashboardPos.dy / verticalLimit).clamp(-1.0, 1.0);
      }
      print(
          "[getPoint] INIT DSTART: restored fixedStart=($fixedStartPointX, $fixedStartPointY) from firstPoint.dashboardPosition");
    } else {
      // Nessun punto ancora: usa la posizione corrente del cursore.
      if (horizontalLimit != 0) {
        fixedStartPointX = (_position.dx / horizontalLimit).clamp(-1.0, 1.0);
      }
      if (verticalLimit != 0) {
        fixedStartPointY = (_position.dy / verticalLimit).clamp(-1.0, 1.0);
      }
    }

    mySetState(() {});
    return _position;
  }

  void updateCursorFromExternalCoordinates(double posx, double posz) {
    final newPosition = calculateCursorPositionFromRobotPosition(posx, posz);
    if (newPosition != null) {
      updateCursorPosition(newPosition);
    } else {
      print("NEW POSITION IS NULL");
    }
  }

  Offset? calculateCursorPositionFromRobotPosition(double posx, double posz) {
    if (_robotStartPositionX == null || _robotStartPositionZ == null) {
      print("IL CENTRO E' VUOTO");
      // Se il centro non è impostato, non fare nulla
      // widget.controller.printLog("LASER: CENTRO NON IMPOSTATO");
      return null;
    }
    //
    //
    //
    // print(
    //     "LASER: CENTER X: $_robotStartPositionX, CENTER Z: $_robotStartPositionZ");
    // print("posx: $posx, _robotStartPositionX: $_robotStartPositionX");
    // print("posz: $posz, _robotStartPositionZ: $_robotStartPositionZ");
    //
    //
    //
    double normalizedX = -(-posx - _robotStartPositionX!) * widget.scaleX;
    double normalizedZ = -(posz - _robotStartPositionZ!) *
        widget.scaleZ; // Inverti la coordinata z

    // Calcolare la nuova posizione del cursore rispetto alla posizione iniziale

    // la X del robot corrisponde alla X del disegno
    // la Z del robot corrisponde alla Y del disegno

    Offset newPosition = Offset(
      fixedStartPointX * horizontalLimit + normalizedX,
      fixedStartPointY * verticalLimit + normalizedZ,
    );

    return newPosition;
  }

  Offset getPoint() {
    print("[getPoint] CALLED FROM HERE: [$_position]");
    return _position;
  }

  Offset _calculateDashboardPositionFromWorldPoint(
      double worldX, double worldZ) {
    return calculateCursorPositionFromRobotPosition(-worldX, worldZ) ??
        Offset.zero;
  }

  Offset? calculateDashboardPositionFromWorldCoordinates(
      double worldX, double worldZ) {
    return calculateCursorPositionFromRobotPosition(-worldX, worldZ);
  }

  void setHomeReferenceAsGraphCenter(double posx, double posz) {
    widget.controller.canMoveRobot = true;
    _robotStartPositionX = posx;
    _robotStartPositionZ = posz;

    // HOME = origine grafico (0,0)
    fixedStartPointX = 0;
    fixedStartPointY = 0;
    _position = Offset.zero;
    _panOffset = Offset.zero;

    // Ricalcola tutti i punti già presi nel nuovo riferimento HOME-centrico.
    final usePiano = widget.controller.isPianoRotolamento;
    for (final point in widget.controller.points.points) {
      point.dashboardPosition = _calculateDashboardPositionFromWorldPoint(
          point.x, usePiano ? point.y * -1 : point.z);
    }

    _fitAll();
    _updateCanGeneratePoints();
    mySetState(() {});
  }

  void redrawPoints() {
    final validPoints = widget.controller.points.points
        .where((p) => p.dashboardPosition != null)
        .toList();

    if (!_autoPanDisabled) {
      // Regola UX richiesta: il primo punto deve comparire al centro e restarci.
      // Dal secondo punto in poi il grafico torna ad adattarsi all'insieme.
      if (validPoints.length == 1) {
        _viewScale = 1.0;
        _centerGraphOnLogicalPoint(validPoints.first.dashboardPosition!);
        _position = validPoints.first.dashboardPosition!;
      } else if (validPoints.length > 1) {
        _fitAll();
      }
    } else if (validPoints.isNotEmpty) {
      // Aggiorna solo la posizione del cursore senza spostare la vista.
      _position = validPoints.first.dashboardPosition!;
    }
    _updateCanGeneratePoints();
    mySetState(() {});
  }

  bool _isPointInsideGraph(Offset center) {
    final halfWidth = rectWidth / 2;
    final halfHeight = rectHeight / 2;
    final adjusted = Offset(
      center.dx * _viewScale + _panOffset.dx,
      center.dy * _viewScale + _panOffset.dy,
    );
    return adjusted.dx >= -halfWidth &&
        adjusted.dx <= halfWidth &&
        adjusted.dy >= -halfHeight &&
        adjusted.dy <= halfHeight;
  }

  void _updateCanGeneratePoints() {
    final points = widget.controller.points.points;
    final orderablePoints = points
        .where((point) =>
            point.dashboardPosition != null &&
            _isPointInsideGraph(point.dashboardPosition!))
        .toList();

    final bool canGenerate;
    if (widget.controller.modalitaNuvola) {
      // Nuvola: almeno 4 punti totali, di cui ≥2 base e ≥2 limite (tra i punti perimetro ordinati)
      final orderedPoints = orderablePoints.where((p) => p.order != null).toList();
      final baseCount = orderedPoints.where((p) => p.isBase).length;
      final limiteCount = orderedPoints.where((p) => p.isLimite).length;
      canGenerate = orderedPoints.length >= 4 &&
          baseCount >= 2 &&
          limiteCount >= 2;
    } else {
      // Normale: almeno 2 punti, tutti con ordinamento assegnato
      canGenerate = orderablePoints.length >= 2 &&
          orderablePoints.every((point) => point.order != null);
    }
    widget.controller.setCanGeneratePoints(canGenerate);
  }

  void _toggleOrderAt(Offset localPosition) {
    print(
        "[pallino-tapped] tap localPosition=(${localPosition.dx.toStringAsFixed(2)}, ${localPosition.dy.toStringAsFixed(2)})");
    final points = widget.controller.points.points;
    final mode = widget.controller.pointSelectionMode;
    bool touched = false;
    for (int i = 0; i < points.length; i++) {
      if (points[i].dashboardPosition == null) continue;
      if (_isTapInsideCircle(localPosition, points[i].dashboardPosition!,
          circleRadius + circleRadiusTolerance)) {
        Vibrator.shortVibration();
        touched = true;
        final oldOrder = points[i].order;

        if (widget.controller.modalitaNuvola) {
          // Modalità nuvola: usa pointSelectionMode
          final mode = widget.controller.pointSelectionMode;
          if (mode == 'perimetro') {
            if (points[i].order == null) {
              points[i].order = widget.controller.points.getNextOrderNumber();
            } else {
              points[i].order = null;
              widget.controller.points.normalizeOrder();
            }
          } else if (mode == 'base') {
            points[i].isBase = !points[i].isBase;
          } else if (mode == 'limite') {
            points[i].isLimite = !points[i].isLimite;
          }
        } else {
          // Modalità standard: comportamento originale
          if (points[i].order == null) {
            points[i].order = widget.controller.points.getNextOrderNumber();
          } else {
            points[i].order = null;
            widget.controller.points.normalizeOrder();
          }
        }
        print(
            "[pallino-tapped] hit index=$i mode=$mode oldOrder=$oldOrder newOrder=${points[i].order}");
        widget.controller.notifyPointsOrderChanged();
        _updateCanGeneratePoints();
        mySetState(() {});
        widget.controller.mySetState?.call(() {});
        widget.controller.dashboardRedrawPoints?.call();

        break;
      }
    }
    if (!touched) {
      print("[pallino-tapped] no-hit");
    }
    print("Toccato: $touched");
  }

  Future<_PointLongPressAction?> _showPointActionMenu() {
    return showDialog<_PointLongPressAction>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Azione punto'),
          content: const Text('Seleziona l\'azione da eseguire.'),
          actions: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Vibrator.mediumVibration();
                Navigator.of(ctx).pop(_PointLongPressAction.moveTo);
              },
              icon: const Icon(Icons.near_me),
              label: const Text('Vai al punto'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Vibrator.longVibration();
                Navigator.of(ctx).pop(_PointLongPressAction.delete);
              },
              icon: const Icon(Icons.delete),
              label: const Text('Elimina punto'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.sagaBlue,
                backgroundColor: Colors.transparent,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Vibrator.shortVibration();
                Navigator.of(ctx).pop();
              },
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePointLongPress(Point point) async {
    Vibrator.mediumVibration();
    point.isSelected = true;
    setState(() {});

    final action = await _showPointActionMenu();

    if (action == _PointLongPressAction.delete) {
      final confirmed = await Messenger.askMessage(
            context,
            'Conferma',
            'Eliminare il punto?',
            'Elimina',
            'Annulla',
          ) ??
          false;

      if (confirmed) {
        widget.controller.points.remove(point: point);
        widget.controller.points.normalizeOrder();
        widget.controller.notifyPointsOrderChanged();
        _fitAll();
        _updateCanGeneratePoints();
        setState(() {});
        return;
      }
    } else if (action == _PointLongPressAction.moveTo) {
      await widget.controller.moveToPoint(point);
    }

    point.isSelected = false;
    setState(() {});
  }

  List<Widget> _buildOrderLabels() {
    final labels = <Widget>[];
    final points = widget.controller.points.points;

    for (final point in points) {
      if (point.dashboardPosition == null || point.order == null) continue;

      final centerDx = point.dashboardPosition!.dx * _viewScale +
          _panOffset.dx +
          rectWidth / 2;
      final centerDy = point.dashboardPosition!.dy * _viewScale +
          _panOffset.dy +
          rectHeight / 2;

      labels.add(
        Positioned(
          left: centerDx - circleRadius,
          top: centerDy - circleRadius,
          width: circleRadius * 2,
          height: circleRadius * 2,
          child: IgnorePointer(
            child: Center(
              child: Text(
                "${point.order}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return labels;
  }

  @override
  Widget build(BuildContext context) {
    //
    //
    //
    widget.controller.dashboardClear = this.clear;
    widget.controller.dashboardSetDStart = this.setDStart;
    widget.controller.dashboardSetHomeReferenceCenter =
        this.setHomeReferenceAsGraphCenter;
    widget.controller.dashboardInitDStartWithoutMove =
        this.initDStartWithoutMove;
    widget.controller.dashboardGetPoint = this.getPoint;
    widget.controller.dashboardUpdateCursorFromExternalCoordinates =
        this.updateCursorFromExternalCoordinates;
    widget.controller.dashboardUpdateCursorPosition = this.updateCursorPosition;
    widget.controller.dashboardSetPaused = this.setPaused;
    widget.controller.dashboardRedrawPoints = this.redrawPoints;
    widget.controller.dashboardCalculatePointPosition =
        this.calculateDashboardPositionFromWorldCoordinates;
    widget.controller.dashboardHasRobotReferenceFrame =
        () => _robotStartPositionX != null && _robotStartPositionZ != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.ensureDashboardRobotReferenceFrame();
    });

    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      onLongPressStart: (details) async {
        Offset localPosition = details.localPosition;

        final points = widget.controller.points.points;
        bool touched = false;
        for (int i = 0; i < points.length; i++) {
          if (points[i].dashboardPosition == null) continue;
          if (_isTapInsideCircle(localPosition, points[i].dashboardPosition!,
              circleRadius + circleRadiusTolerance)) {
            touched = true;
            await _handlePointLongPress(points[i]);

            break;
          }
        }
        print("Toccato Long: $touched");
      },
      onTapUp: (details) {
        if (_ignoreNextTapUp) {
          _ignoreNextTapUp = false;
          return;
        }
        _toggleOrderAt(details.localPosition);
      },
      child: SizedBox(
        width: rectWidth,
        height: rectHeight,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(rectWidth, rectHeight),
              painter: LaserRectanglePainter(
                  _position,
                  widget.controller.points,
                  rectWidth,
                  rectHeight,
                  circleRadius,
                  _panOffset,
                  _viewScale),
            ),
            ..._buildOrderLabels(),
            Positioned(
              right: 10,
              top: 10,
              child: Builder(
                builder: (context) {
                  const crossGap = 6.0;
                  const buttonSize = 34.0;
                  const crossWidth = buttonSize * 3 + crossGap * 2;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: crossWidth,
                        child: Center(
                          child: _buildZoomButton(
                            icon: Icons.keyboard_arrow_up,
                            onTap: () => _changePan(Offset(0, _manualPanStep)),
                          ),
                        ),
                      ),
                      const SizedBox(height: crossGap),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildZoomButton(
                            icon: Icons.keyboard_arrow_left,
                            onTap: () => _changePan(Offset(_manualPanStep, 0)),
                          ),
                          const SizedBox(width: crossGap),
                          _buildZoomButton(
                            icon: Icons.fit_screen,
                            onTap: redrawPoints,
                          ),
                          const SizedBox(width: crossGap),
                          _buildZoomButton(
                            icon: Icons.keyboard_arrow_right,
                            onTap: () => _changePan(Offset(-_manualPanStep, 0)),
                          ),
                        ],
                      ),
                      const SizedBox(height: crossGap),
                      SizedBox(
                        width: crossWidth,
                        child: Center(
                          child: _buildZoomButton(
                            icon: Icons.keyboard_arrow_down,
                            onTap: () => _changePan(Offset(0, -_manualPanStep)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAutoPanToggleButton(),
                  const SizedBox(width: 6),
                  _buildZoomButton(
                    icon: Icons.remove,
                    onTap: () => _changeZoom(1 / 1.2),
                  ),
                  const SizedBox(width: 6),
                  _buildZoomButton(
                    icon: Icons.add,
                    onTap: () => _changeZoom(1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isTapInsideCircle(Offset tap, Offset center, double radius) {
    final adjustedX = center.dx * _viewScale + _panOffset.dx + rectWidth / 2;
    final adjustedY = center.dy * _viewScale + _panOffset.dy + rectHeight / 2;
    double distance =
        sqrt(pow(tap.dx - adjustedX, 2) + pow(tap.dy - adjustedY, 2));
    return distance <= radius;
  }

  void clear() {
    mySetState(() {
      _position = Offset(0, 0);
      _panOffset = Offset.zero;
      _viewScale = 1.0;
      _robotStartPositionX = null;
      _robotStartPositionZ = null;
    });
    widget.controller.setCanGeneratePoints(false);
  }

  void mySetState(VoidCallback? f) {
    if (f == null) {
      print("DASHBOARD ----> SET STATE INTERRUPTED");
      return;
    }
    if (mounted) {
      setState(f);
    }
  }
}
