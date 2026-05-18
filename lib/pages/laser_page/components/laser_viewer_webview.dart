import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/pages/laser_page/laser_panel_state.dart';
import 'package:grw_laser/services/vibrator.dart';
import 'package:unicons/unicons.dart';

class LaserViewerWebview extends StatefulWidget {
  final LaserPageController controller;
  final VoidCallback? onExpand;

  const LaserViewerWebview({super.key, required this.controller, this.onExpand});

  @override
  State<LaserViewerWebview> createState() => _LaserViewerWebviewState();
}

class _LaserViewerWebviewState extends State<LaserViewerWebview>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? _loadedUrl;
  bool _viewerLoading = false;
  String? _viewerError;

  bool _filoIsPressed = false;
  bool _gasIsPressed = false;

  ViewerModel? _model;
  int _selectedLayer = 0;
  int? _selectedCordone;
  Set<String> _executedCordoniKeys = <String>{};

  double _yaw = -0.75;
  double _pitch = -0.45;
  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  Offset? _lastFocalPoint;
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.controller.webviewDispatchFlutterMessage = _dispatchViewerMessage;
    widget.controller.viewerUrlNotifier.addListener(_onUrlChanged);

    final currentUrl = widget.controller.viewerUrlNotifier.value;
    if (currentUrl != null) {
      _loadFromUrl(currentUrl);
    }
  }

  @override
  void dispose() {
    widget.controller.webviewDispatchFlutterMessage = null;
    widget.controller.viewerUrlNotifier.removeListener(_onUrlChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final url = widget.controller.viewerUrlNotifier.value;
    if (url == null || url.trim().isEmpty) return;
    _loadFromUrl(url);
  }

  Future<void> _dispatchViewerMessage(dynamic data) async {
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);
    final action = map['action']?.toString().trim().toUpperCase();

    if (action == 'SET_EXECUTED_CORDONI') {
      final executedKeys = _parseExecutedCordoniKeys(map['executedCordoni']);
      if (!mounted) return;
      setState(() {
        _executedCordoniKeys = executedKeys;
      });
    }
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  Set<String> _parseExecutedCordoniKeys(dynamic rawValue) {
    dynamic value = rawValue;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return <String>{};
      }
    }

    if (value is! List) {
      return <String>{};
    }

    final keys = <String>{};
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final strato = _toInt(map['strato'] ?? map['Strato']);
      final cordone = _toInt(map['cordone'] ?? map['Cordone']);
      if (strato == null || cordone == null) continue;

      keys.add('$strato:$cordone');
    }
    return keys;
  }

  Future<void> _loadFromUrl(String url) async {
    setState(() {
      _loadedUrl = url;
      _viewerLoading = true;
      _viewerError = null;
      _model = null;
    });

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final parsedJson = jsonDecode(response.body);
      if (parsedJson is! Map<String, dynamic>) {
        throw Exception('Formato JSON non valido');
      }

      final parsedModel = ViewerModel.fromPlotlyJson(parsedJson);

      if (!mounted) return;
      setState(() {
        _model = parsedModel;
        _selectedLayer = parsedModel.selectedLayer;
        _selectedCordone = null;
        _executedCordoniKeys = <String>{};
        _resetCamera();
        _viewerLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _viewerLoading = false;
        _viewerError = e.toString();
      });
      if (Constants.LASER_DEBUG) {
        print('[laser_native_viewer] load error: $e');
      }
    }
  }

  void _resetCamera() {
    _yaw = -0.75;
    _pitch = -0.45;
    _zoom = 1.0;
    _pan = Offset.zero;
  }

  void _setIso() {
    setState(() {
      _yaw = -0.75;
      _pitch = -0.45;
      _zoom = 1.0;
      _pan = Offset.zero;
    });
  }

  void _setTop() {
    setState(() {
      _yaw = 0.0;
      _pitch = -math.pi / 2;
      _zoom = 1.0;
      _pan = Offset.zero;
    });
  }

  void _setFront() {
    setState(() {
      _yaw = 0.0;
      _pitch = 0.0;
      _zoom = 1.0;
      _pan = Offset.zero;
    });
  }

  void _setSide() {
    setState(() {
      _yaw = math.pi / 2;
      _pitch = 0.0;
      _zoom = 1.0;
      _pan = Offset.zero;
    });
  }

  void _resetSelection() {
    setState(() {
      _selectedCordone = null;
    });
  }

  ViewerTrace? _selectedCordoneTrace() {
    final m = _model;
    final selected = _selectedCordone;
    if (m == null || selected == null) return null;

    for (final trace in m.traces) {
      if (trace.kind != 'cordone') continue;
      if (trace.layer != _selectedLayer) continue;
      if (trace.index != selected) continue;
      return trace;
    }
    return null;
  }

  Widget _buildSelectedCordoneDetails() {
    final trace = _selectedCordoneTrace();
    if (trace == null) return const SizedBox.shrink();

    final details = ViewerCordoneDetails.fromTrace(trace);
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff0f172a).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cordone ${details.cordone ?? '-'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Strato ${details.strato ?? trace.layer}'),
                  Text(
                      'Attivo: ${details.attivo ?? (trace.active ? 'SI' : 'NO')}'),
                  Text(
                      'DX: ${details.dx != null ? _fmtNum(details.dx!) : '-'} | DY: ${details.dy != null ? _fmtNum(details.dy!) : '-'} | DZ: ${details.dz != null ? _fmtNum(details.dz!) : '-'}'),
                  const SizedBox(height: 6),
                  Text(
                    'START  X1: ${details.x1 != null ? _fmtNum(details.x1!) : '-'}  Y1: ${details.y1 != null ? _fmtNum(details.y1!) : '-'}  Z1: ${details.z1 != null ? _fmtNum(details.z1!) : '-'}',
                  ),
                  Text(
                    '       J1_1: ${details.j11 != null ? _fmtNum(details.j11!) : '-'}  J2_1: ${details.j21 != null ? _fmtNum(details.j21!) : '-'}  J3_1: ${details.j31 != null ? _fmtNum(details.j31!) : '-'}',
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'END    X2: ${details.x2 != null ? _fmtNum(details.x2!) : '-'}  Y2: ${details.y2 != null ? _fmtNum(details.y2!) : '-'}  Z2: ${details.z2 != null ? _fmtNum(details.z2!) : '-'}',
                  ),
                  Text(
                    '       J1_2: ${details.j12 != null ? _fmtNum(details.j12!) : '-'}  J2_2: ${details.j22 != null ? _fmtNum(details.j22!) : '-'}  J3_2: ${details.j32 != null ? _fmtNum(details.j32!) : '-'}',
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Lunghezza: ${details.lunghezza != null ? _fmtNum(details.lunghezza!) : '-'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  String _fmtNum(double value) {
    return value.toStringAsFixed(3);
  }

  Widget _buildTopControls() {
    final m = _model;
    if (m == null) return const SizedBox.shrink();
    final rightInset =
        widget.controller.pageState == LaserPanelState.tipoSaldatura
            ? 180.0
            : 12.0;

    final layers = m.layers.toList()..sort();
    final selectedLayer =
        layers.contains(_selectedLayer) ? _selectedLayer : layers.first;

    return Positioned(
      left: 12,
      right: rightInset,
      top: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xff0f172a).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Layer',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: selectedLayer,
                  dropdownColor: const Color(0xff111827),
                  style: const TextStyle(color: Colors.white),
                  items: layers
                      .map((l) => DropdownMenuItem<int>(
                            value: l,
                            child: Text('Strato $l'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedLayer = v;
                      _selectedCordone = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Tracce: ${m.traces.length}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(width: 12),
                Text('Cordoni: ${m.cordoniCount}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(width: 12),
                Text('Selezionato: ${_selectedCordone ?? '-'}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details, Size size) {
    final m = _model;
    if (m == null) return;

    final projector = Projector(
      bounds: m.bounds,
      size: size,
      yaw: _yaw,
      pitch: _pitch,
      zoom: _zoom,
      pan: _pan,
    );

    double bestDistance = double.infinity;
    int? bestCordone;

    for (final trace in m.traces) {
      if (trace.kind != 'cordone') continue;
      if (trace.layer != _selectedLayer) continue;
      if (trace.points.length < 2) continue;

      final a = projector.project(trace.points[0]);
      final b = projector.project(trace.points[1]);
      final distance = distancePointToSegment(details.localPosition, a, b);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestCordone = trace.index;
      }
    }

    if (bestDistance <= 18 && bestCordone != null) {
      setState(() {
        _selectedCordone = bestCordone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller.viewerUrlNotifier,
        widget.controller.sendingSimulationNotifier,
      ]),
      builder: (_, __) {
        final url = widget.controller.viewerUrlNotifier.value;
        final isSending = widget.controller.sendingSimulationNotifier.value;
        final canReturnToPointSelection =
            widget.controller.canReturnToPointSelection;

        if (!isSending && url == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  if (_filoIsPressed)
                    const Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'PROVA FILO IN CORSO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_gasIsPressed)
                    const Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'PROVA GAS IN CORSO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Container(color: Colors.grey[200]),
                  ),
                  if (_model != null)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size =
                              Size(constraints.maxWidth, constraints.maxHeight);

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) => _onTapDown(details, size),
                            onScaleStart: (details) {
                              _lastFocalPoint = details.focalPoint;
                              _lastScale = 1.0;
                            },
                            onScaleUpdate: (details) {
                              setState(() {
                                if (details.pointerCount >= 2) {
                                  final scaleDelta = details.scale / _lastScale;
                                  _zoom =
                                      (_zoom * scaleDelta).clamp(0.15, 12.0);
                                  _lastScale = details.scale;

                                  if (_lastFocalPoint != null) {
                                    _pan +=
                                        details.focalPoint - _lastFocalPoint!;
                                    _lastFocalPoint = details.focalPoint;
                                  }
                                } else {
                                  final delta = details.focalPointDelta;
                                  _yaw += delta.dx * 0.008;
                                  _pitch += delta.dy * 0.008;
                                  _pitch =
                                      _pitch.clamp(-math.pi / 2, math.pi / 2);
                                }
                              });
                            },
                            child: CustomPaint(
                              painter: LaserViewerPainter(
                                model: _model!,
                                yaw: _yaw,
                                pitch: _pitch,
                                zoom: _zoom,
                                pan: _pan,
                                selectedLayer: _selectedLayer,
                                selectedCordone: _selectedCordone,
                                executedCordoniKeys: _executedCordoniKeys,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          );
                        },
                      ),
                    ),
                  _buildTopControls(),
                  if (!isSending && _viewerLoading)
                    Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  if (!isSending && _viewerError != null)
                    Container(
                      color: Colors.grey[200],
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          'Errore caricamento viewer: $_viewerError\nURL: ${_loadedUrl ?? '-'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  if (isSending)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, __) => Opacity(
                        opacity: _pulseAnimation.value,
                        child: Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.controller.pageState ==
                          LaserPanelState.tipoSaldatura &&
                      widget.onExpand != null)
                    Positioned(
                      left: 16,
                      bottom: 106,
                      child: GestureDetector(
                        onTap: widget.onExpand,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.sagaBlue,
                          ),
                          width: 30,
                          height: 30,
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  if (widget.controller.pageState ==
                      LaserPanelState.tipoSaldatura)
                    Positioned(
                      left: 16,
                      bottom: 61,
                      child: Listener(
                        onPointerDown: (_) {
                          setState(() {
                            _filoIsPressed = true;
                          });
                          widget.controller.filoTouchedDown();
                        },
                        onPointerUp: (_) {
                          setState(() {
                            _filoIsPressed = false;
                          });
                          widget.controller.filoTouchedUp();
                        },
                        onPointerCancel: (_) {
                          setState(() {
                            _filoIsPressed = false;
                          });
                          widget.controller.filoTouchedUp();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _filoIsPressed
                                ? Colors.yellow
                                : AppColors.sagaBlue,
                          ),
                          width: 30,
                          height: 30,
                          child: const Icon(UniconsLine.drill),
                        ),
                      ),
                    ),
                  if (widget.controller.pageState ==
                      LaserPanelState.tipoSaldatura)
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Listener(
                        onPointerDown: (_) {
                          setState(() {
                            _gasIsPressed = true;
                          });
                          widget.controller.gasTouchedDown();
                        },
                        onPointerUp: (_) {
                          setState(() {
                            _gasIsPressed = false;
                          });
                          widget.controller.gasTouchedUp();
                        },
                        onPointerCancel: (_) {
                          setState(() {
                            _gasIsPressed = false;
                          });
                          widget.controller.gasTouchedUp();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _gasIsPressed
                                ? Colors.yellow
                                : AppColors.sagaBlue,
                          ),
                          width: 30,
                          height: 30,
                          child: const Icon(UniconsLine.sanitizer),
                        ),
                      ),
                    ),
                  if (widget.controller.pageState ==
                      LaserPanelState.tipoSaldatura)
                    Positioned(
                      right: 16,
                      top: 96,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Iso',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              onPressed: _setIso,
                              icon: const Icon(Icons.view_in_ar,
                                  color: Colors.white, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Top',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              onPressed: _setTop,
                              icon: const Icon(Icons.vertical_align_top,
                                  color: Colors.white, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Front',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              onPressed: _setFront,
                              icon: const Icon(Icons.crop_16_9,
                                  color: Colors.white, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Side',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              onPressed: _setSide,
                              icon: const Icon(Icons.view_sidebar,
                                  color: Colors.white, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Reset selection',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              onPressed: _resetSelection,
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.controller.pageState ==
                      LaserPanelState.tipoSaldatura)
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: canReturnToPointSelection
                              ? () {
                                  Vibrator.shortVibration();
                                  widget.controller.unfocusScreen();
                                  widget.controller.printLog(
                                    'Tieni premuto per tornare a prendi punti',
                                  );
                                }
                              : null,
                          onLongPress: canReturnToPointSelection
                              ? () {
                                  Vibrator.mediumVibration();
                                  widget.controller
                                      .returnToPointSelectionMode();
                                }
                              : null,
                          child: Ink(
                            decoration: BoxDecoration(
                              color: canReturnToPointSelection
                                  ? AppColors.sagaBlue.withValues(alpha: 0.82)
                                  : AppColors.lightGray.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.undo_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Prendi punti',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_selectedCordone != null) _buildSelectedCordoneDetails(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LaserViewerPainter extends CustomPainter {
  final ViewerModel model;
  final double yaw;
  final double pitch;
  final double zoom;
  final Offset pan;
  final int selectedLayer;
  final int? selectedCordone;
  final Set<String> executedCordoniKeys;

  LaserViewerPainter({
    required this.model,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.pan,
    required this.selectedLayer,
    required this.selectedCordone,
    required this.executedCordoniKeys,
  });

  bool _isExecutedCordone(ViewerTrace trace) {
    if (trace.kind != 'cordone' || trace.index == null) return false;
    return executedCordoniKeys.contains('${trace.layer}:${trace.index!}');
  }

  bool _sameExecutedSet(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  double _dot3(Point3 a, Point3 b) => a.x * b.x + a.y * b.y + a.z * b.z;

  Point3 _sub3(Point3 a, Point3 b) => Point3(a.x - b.x, a.y - b.y, a.z - b.z);

  Point3 _cross3(Point3 a, Point3 b) {
    return Point3(
      a.y * b.z - a.z * b.y,
      a.z * b.x - a.x * b.z,
      a.x * b.y - a.y * b.x,
    );
  }

  Point3 _normalize3(Point3 p) {
    final len = math.sqrt(p.x * p.x + p.y * p.y + p.z * p.z);
    if (len <= 1e-9) return const Point3(0, 0, 1);
    return Point3(p.x / len, p.y / len, p.z / len);
  }

  Color _shadeColor(Color base, double intensity, double opacity) {
    final k = intensity.clamp(0.0, 1.0);
    return Color.fromRGBO(
      (base.red * k).round().clamp(0, 255),
      (base.green * k).round().clamp(0, 255),
      (base.blue * k).round().clamp(0, 255),
      opacity,
    );
  }

  void _drawMesh(
    Canvas canvas,
    Projector projector,
    ViewerTrace trace, {
    required Color fillColor,
    required Color strokeColor,
  }) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = strokeColor;

    final projected = trace.points.map(projector.project).toList();
    final triangleCount =
        math.min(trace.i.length, math.min(trace.j.length, trace.k.length));

    final lightDir = _normalize3(const Point3(-0.35, -0.55, 0.75));
    final triangles = <_MeshTriangle>[];

    for (int n = 0; n < triangleCount; n++) {
      final ia = trace.i[n];
      final ib = trace.j[n];
      final ic = trace.k[n];

      if (ia < 0 || ib < 0 || ic < 0) continue;
      if (ia >= projected.length ||
          ib >= projected.length ||
          ic >= projected.length) {
        continue;
      }
      if (ia >= trace.points.length ||
          ib >= trace.points.length ||
          ic >= trace.points.length) {
        continue;
      }

      final pa = trace.points[ia];
      final pb = trace.points[ib];
      final pc = trace.points[ic];

      final normal = _normalize3(_cross3(_sub3(pb, pa), _sub3(pc, pa)));
      final lambert = _dot3(normal, lightDir).abs();
      final intensity = 0.28 + lambert * 0.72;
      final avgZ = (pa.z + pb.z + pc.z) / 3.0;

      triangles.add(
        _MeshTriangle(
          a: projected[ia],
          b: projected[ib],
          c: projected[ic],
          avgZ: avgZ,
          color: _shadeColor(fillColor, intensity, fillColor.opacity),
        ),
      );
    }

    triangles.sort((a, b) => a.avgZ.compareTo(b.avgZ));

    for (final tri in triangles) {
      final path = Path()
        ..moveTo(tri.a.dx, tri.a.dy)
        ..lineTo(tri.b.dx, tri.b.dy)
        ..lineTo(tri.c.dx, tri.c.dy)
        ..close();

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = tri.color;

      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  Color _cordoneGradientColor(int index, int total, double opacity) {
    const start = Color.fromRGBO(120, 180, 255, 1.0);
    const end = Color.fromRGBO(20, 60, 170, 1.0);

    if (total <= 1) return start.withOpacity(opacity);

    final t = ((index - 1) / (total - 1)).clamp(0.0, 1.0);
    final r = (start.red + (end.red - start.red) * t).round();
    final g = (start.green + (end.green - start.green) * t).round();
    final b = (start.blue + (end.blue - start.blue) * t).round();

    return Color.fromRGBO(r, g, b, opacity);
  }

  int _cordoniCountForLayer(int layer) {
    return model.traces
        .where((t) => t.kind == 'cordone' && t.layer == layer)
        .length;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xff080d18);
    canvas.drawRect(Offset.zero & size, bg);

    final projector = Projector(
      bounds: model.bounds,
      size: size,
      yaw: yaw,
      pitch: pitch,
      zoom: zoom,
      pan: pan,
    );

    final sorted = [...model.traces];
    sorted.sort((a, b) {
      final za = a.points.isEmpty
          ? 0.0
          : a.points.map((p) => p.z).reduce((x, y) => x + y) / a.points.length;
      final zb = b.points.isEmpty
          ? 0.0
          : b.points.map((p) => p.z).reduce((x, y) => x + y) / b.points.length;
      return za.compareTo(zb);
    });

    for (final trace in sorted) {
      if (trace.type != 'mesh3d' || trace.points.isEmpty) continue;

      if (trace.kind == 'binario') {
        _drawMesh(
          canvas,
          projector,
          trace,
          fillColor: const Color.fromARGB(255, 187, 187, 187).withOpacity(1),
          strokeColor: Colors.white.withOpacity(0.08),
        );
      } else if (trace.kind == 'safe_position') {
        _drawMesh(
          canvas,
          projector,
          trace,
          fillColor: Colors.yellow.withOpacity(1),
          strokeColor: Colors.orangeAccent.withOpacity(0.9),
        );
      }
    }

    for (final trace in sorted) {
      if (trace.type == 'mesh3d' || trace.points.length < 2) continue;

      final isSelectedLayer = trace.layer == selectedLayer;
      final projected = trace.points.map(projector.project).toList();

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      if (trace.kind == 'layer') {
        paint.color = isSelectedLayer
            ? Colors.redAccent
            : Colors.redAccent.withOpacity(0.18);
        paint.strokeWidth = isSelectedLayer ? 3.5 : 1.2;
      } else if (trace.kind == 'cordone') {
        final isWhite = selectedCordone != null &&
            trace.index == selectedCordone &&
            trace.layer == selectedLayer;
        final isExecuted = _isExecutedCordone(trace);

        if (isWhite) {
          paint.color = Colors.white;
          paint.strokeWidth = 6;
        } else if (isExecuted) {
          paint.color = Colors.orangeAccent;
          paint.strokeWidth = 5;
        } else {
          final totalLayerCordoni = _cordoniCountForLayer(trace.layer);
          final idx = trace.index ?? 1;
          paint.color = _cordoneGradientColor(
            idx,
            totalLayerCordoni,
            isSelectedLayer ? (trace.active ? 0.95 : 0.55) : 0.18,
          );
          paint.strokeWidth = isSelectedLayer ? 3.2 : 1.2;
        }
      } else {
        paint.color = Colors.white.withOpacity(0.25);
        paint.strokeWidth = 1;
      }

      final path = Path()..moveTo(projected.first.dx, projected.first.dy);
      for (int i = 1; i < projected.length; i++) {
        path.lineTo(projected[i].dx, projected[i].dy);
      }
      canvas.drawPath(path, paint);

      if (trace.kind == 'cordone' && projected.length >= 2) {
        final markerPaintStart = Paint()
          ..color = isSelectedLayer
              ? Colors.greenAccent
              : Colors.greenAccent.withOpacity(0.25);

        final markerPaintEnd = Paint()
          ..color = isSelectedLayer
              ? Colors.purpleAccent
              : Colors.purpleAccent.withOpacity(0.25);

        canvas.drawCircle(
            projected.first, isSelectedLayer ? 4 : 2, markerPaintStart);
        canvas.drawCircle(
            projected.last, isSelectedLayer ? 4 : 2, markerPaintEnd);
      }
    }

    _drawHud(canvas, size);
  }

  void _drawHud(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text:
            'Touch: ruota | pinch: zoom/pan | layer: $selectedLayer | cordone: ${selectedCordone ?? '-'}',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20);

    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant LaserViewerPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.pan != pan ||
        oldDelegate.selectedLayer != selectedLayer ||
        oldDelegate.selectedCordone != selectedCordone ||
        !_sameExecutedSet(
            oldDelegate.executedCordoniKeys, executedCordoniKeys) ||
        oldDelegate.model != model;
  }
}

class ViewerModel {
  static const bool _rotate180AroundZ = true;

  final List<ViewerTrace> traces;
  final Bounds3 bounds;
  final Set<int> layers;
  final int selectedLayer;

  ViewerModel({
    required this.traces,
    required this.bounds,
    required this.layers,
    required this.selectedLayer,
  });

  int get cordoniCount => traces.where((t) => t.kind == 'cordone').length;

  factory ViewerModel.fromPlotlyJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? []);
    final traces = <ViewerTrace>[];

    for (final raw in data) {
      if (raw is! Map<String, dynamic>) continue;

      final type = raw['type']?.toString() ?? 'scatter3d';
      final x = _numList(raw['x']);
      final y = _numList(raw['y']);
      final z = _numList(raw['z']);

      final n = math.min(x.length, math.min(y.length, z.length));
      if (n < 1) continue;

      final meta = raw['meta'];
      final metaMap = meta is Map<String, dynamic> ? meta : <String, dynamic>{};

      final points = <Point3>[];
      for (int p = 0; p < n; p++) {
        if (_rotate180AroundZ) {
          points.add(Point3(-x[p], y[p], z[p]));
        } else {
          points.add(Point3(x[p], y[p], z[p]));
        }
      }

      final name = raw['name']?.toString() ?? '';
      final kind = metaMap['kind']?.toString() ?? _kindFromName(name);
      final layer = _asInt(metaMap['layer']) ?? _layerFromName(name) ?? 0;
      final index = _asInt(metaMap['index']) ?? _indexFromName(name);
      final active =
          metaMap['active'] == true || metaMap['active']?.toString() == 'true';

      List<dynamic> customData = const [];
      final rawCustomData = raw['customdata'];
      if (rawCustomData is List && rawCustomData.isNotEmpty) {
        final first = rawCustomData.first;
        if (first is List) {
          customData = List<dynamic>.from(first);
        } else {
          customData = List<dynamic>.from(rawCustomData);
        }
      }

      traces.add(
        ViewerTrace(
          name: name,
          kind: kind,
          type: type,
          layer: layer,
          index: index,
          active: active,
          points: points,
          customData: customData,
          hoverTemplate: raw['hovertemplate']?.toString(),
          i: _intList(raw['i']),
          j: _intList(raw['j']),
          k: _intList(raw['k']),
        ),
      );
    }

    final allPoints = traces.expand((t) => t.points).toList();
    final bounds = Bounds3.fromPoints(allPoints);
    final layers = traces.map((t) => t.layer).toSet();

    final layout = json['layout'];
    final meta = layout is Map<String, dynamic> ? layout['meta'] : null;
    final metaMap = meta is Map<String, dynamic> ? meta : <String, dynamic>{};

    final selectedLayer =
        _asInt(metaMap['selected_layer']) ?? _asInt(metaMap['strato']) ?? 0;

    return ViewerModel(
      traces: traces,
      bounds: bounds,
      layers: layers.isEmpty ? {0} : layers,
      selectedLayer: selectedLayer,
    );
  }

  static List<double> _numList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => (e as num).toDouble()).toList();
  }

  static List<int> _intList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => (e as num).toInt()).toList();
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _kindFromName(String? name) {
    final n = name ?? '';
    if (n.startsWith('CORDONE_')) return 'cordone';
    if (n.startsWith('LAYER_')) return 'layer';
    if (n == 'BINARIO_SOLIDO') return 'binario';
    if (n == 'SAFE_POSITION_CONE') return 'safe_position';
    return 'other';
  }

  static int? _layerFromName(String? name) {
    if (name == null) return null;

    final layerMatch = RegExp(r'LAYER_(\d+)').firstMatch(name);
    if (layerMatch != null) return int.tryParse(layerMatch.group(1)!);

    final cordoneMatch = RegExp(r'CORDONE_(\d+)_(\d+)').firstMatch(name);
    if (cordoneMatch != null) return int.tryParse(cordoneMatch.group(1)!);

    return null;
  }

  static int? _indexFromName(String? name) {
    if (name == null) return null;

    final cordoneMatch = RegExp(r'CORDONE_(\d+)_(\d+)').firstMatch(name);
    if (cordoneMatch != null) return int.tryParse(cordoneMatch.group(2)!);

    return null;
  }
}

class ViewerTrace {
  final String name;
  final String kind;
  final String type;
  final int layer;
  final int? index;
  final bool active;
  final List<Point3> points;
  final List<dynamic> customData;
  final String? hoverTemplate;
  final List<int> i;
  final List<int> j;
  final List<int> k;

  ViewerTrace({
    required this.name,
    required this.kind,
    required this.type,
    required this.layer,
    required this.index,
    required this.active,
    required this.points,
    this.customData = const [],
    this.hoverTemplate,
    this.i = const [],
    this.j = const [],
    this.k = const [],
  });
}

class ViewerCordoneDetails {
  final int? cordone;
  final int? strato;
  final String? attivo;

  final double? x1;
  final double? y1;
  final double? z1;
  final double? j11;
  final double? j21;
  final double? j31;

  final double? x2;
  final double? y2;
  final double? z2;
  final double? j12;
  final double? j22;
  final double? j32;

  final double? lunghezza;
  final double? dx;
  final double? dy;
  final double? dz;

  const ViewerCordoneDetails({
    this.cordone,
    this.strato,
    this.attivo,
    this.x1,
    this.y1,
    this.z1,
    this.j11,
    this.j21,
    this.j31,
    this.x2,
    this.y2,
    this.z2,
    this.j12,
    this.j22,
    this.j32,
    this.lunghezza,
    this.dx,
    this.dy,
    this.dz,
  });

  factory ViewerCordoneDetails.fromTrace(ViewerTrace trace) {
    final data = trace.customData;

    if (data.length >= 19) {
      return ViewerCordoneDetails(
        cordone: _asInt(data[0]) ?? trace.index,
        strato: _asInt(data[1]) ?? trace.layer,
        x1: _asDouble(data[2]),
        y1: _asDouble(data[3]),
        z1: _asDouble(data[4]),
        j11: _asDouble(data[5]),
        j21: _asDouble(data[6]),
        j31: _asDouble(data[7]),
        x2: _asDouble(data[8]),
        y2: _asDouble(data[9]),
        z2: _asDouble(data[10]),
        j12: _asDouble(data[11]),
        j22: _asDouble(data[12]),
        j32: _asDouble(data[13]),
        lunghezza: _asDouble(data[14]),
        attivo: data[15]?.toString(),
        dx: _asDouble(data[16]),
        dy: _asDouble(data[17]),
        dz: _asDouble(data[18]),
      );
    }

    final start = trace.points.isNotEmpty ? trace.points.first : null;
    final end = trace.points.length >= 2 ? trace.points.last : null;

    return ViewerCordoneDetails(
      cordone: trace.index,
      strato: trace.layer,
      attivo: trace.active ? 'SI' : 'NO',
      x1: start?.x,
      y1: start?.y,
      z1: start?.z,
      x2: end?.x,
      y2: end?.y,
      z2: end?.z,
      lunghezza: (start != null && end != null)
          ? math.sqrt(
              math.pow(end.x - start.x, 2) +
                  math.pow(end.y - start.y, 2) +
                  math.pow(end.z - start.z, 2),
            )
          : null,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class Point3 {
  final double x;
  final double y;
  final double z;

  const Point3(this.x, this.y, this.z);
}

class Bounds3 {
  final Point3 min;
  final Point3 max;
  final Point3 center;
  final double span;

  Bounds3({
    required this.min,
    required this.max,
    required this.center,
    required this.span,
  });

  factory Bounds3.fromPoints(List<Point3> points) {
    if (points.isEmpty) {
      return Bounds3(
        min: const Point3(-1, -1, -1),
        max: const Point3(1, 1, 1),
        center: const Point3(0, 0, 0),
        span: 2,
      );
    }

    double minX = points.first.x;
    double minY = points.first.y;
    double minZ = points.first.z;
    double maxX = points.first.x;
    double maxY = points.first.y;
    double maxZ = points.first.z;

    for (final p in points) {
      minX = math.min(minX, p.x);
      minY = math.min(minY, p.y);
      minZ = math.min(minZ, p.z);
      maxX = math.max(maxX, p.x);
      maxY = math.max(maxY, p.y);
      maxZ = math.max(maxZ, p.z);
    }

    final center = Point3(
      (minX + maxX) / 2,
      (minY + maxY) / 2,
      (minZ + maxZ) / 2,
    );

    final span = math.max(
        1.0, math.max(maxX - minX, math.max(maxY - minY, maxZ - minZ)));

    return Bounds3(
      min: Point3(minX, minY, minZ),
      max: Point3(maxX, maxY, maxZ),
      center: center,
      span: span,
    );
  }
}

class Projector {
  final Bounds3 bounds;
  final Size size;
  final double yaw;
  final double pitch;
  final double zoom;
  final Offset pan;

  Projector({
    required this.bounds,
    required this.size,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.pan,
  });

  Offset project(Point3 p) {
    final x = p.x - bounds.center.x;
    final y = p.y - bounds.center.y;
    final z = p.z - bounds.center.z;

    final cy = math.cos(yaw);
    final sy = math.sin(yaw);
    final cp = math.cos(pitch);
    final sp = math.sin(pitch);

    final x1 = x * cy - y * sy;
    final y1 = x * sy + y * cy;
    final z1 = z;

    final z2 = y1 * sp + z1 * cp;
    final scale = math.min(size.width, size.height) / bounds.span * 0.75 * zoom;

    return Offset(
      size.width / 2 + x1 * scale + pan.dx,
      size.height / 2 - z2 * scale + pan.dy,
    );
  }
}

double distancePointToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final ap = p - a;

  final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (ab2 <= 1e-9) return (p - a).distance;

  final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / ab2).clamp(0.0, 1.0);
  final c = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);

  return (p - c).distance;
}

class _MeshTriangle {
  final Offset a;
  final Offset b;
  final Offset c;
  final double avgZ;
  final Color color;

  const _MeshTriangle({
    required this.a,
    required this.b,
    required this.c,
    required this.avgZ,
    required this.color,
  });
}
