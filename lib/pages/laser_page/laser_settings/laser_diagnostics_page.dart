import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grw_laser/common_components/gradient_app_bar_background.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';
import 'package:grw_laser/services/messenger.dart';

class LaserDiagnosticsPage extends StatefulWidget {
  final LaserPageController laserPageController;
  final String initialRobotIp;

  const LaserDiagnosticsPage({
    super.key,
    required this.laserPageController,
    required this.initialRobotIp,
  });

  @override
  State<LaserDiagnosticsPage> createState() => _LaserDiagnosticsPageState();
}

enum _DiagnosticTool { ping, stress, testPunti }

class _LaserDiagnosticsPageState extends State<LaserDiagnosticsPage> {
  final math.Random _random = math.Random();

  // ── Controllers & scroll ────────────────────────────────────────────────
  final TextEditingController _pingHostController = TextEditingController();
  final TextEditingController _stressTimeoutController =
      TextEditingController(text: '120');
  final TextEditingController _testPuntiIntervalController =
      TextEditingController(text: '120');

  final ScrollController _pingScrollController = ScrollController();
  final ScrollController _stressScrollController = ScrollController();
  final ScrollController _testPuntiScrollController = ScrollController();

  // ── Log lists ───────────────────────────────────────────────────────────
  final List<String> _pingLogs = <String>[];
  final List<String> _stressLogs = <String>[];
  final List<String> _testPuntiLogs = <String>[];

  // ── State ───────────────────────────────────────────────────────────────
  bool _pingRunning = false;
  bool _stressRunning = false;
  bool _testPuntiRunning = false;
  _DiagnosticTool _selectedTool = _DiagnosticTool.ping;

  int _stressSent = 0;
  int _stressErrors = 0;
  int _testPuntiPointsTaken = 0;
  int _testPuntiCycles = 0;

  // ── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final host = widget.initialRobotIp.trim().isNotEmpty
        ? widget.initialRobotIp.trim()
        : widget.laserPageController.settings.ipRobot;
    _pingHostController.text = host;
  }

  @override
  void dispose() {
    _pingRunning = false;
    _stressRunning = false;
    _testPuntiRunning = false;
    _pingHostController.dispose();
    _stressTimeoutController.dispose();
    _testPuntiIntervalController.dispose();
    _pingScrollController.dispose();
    _stressScrollController.dispose();
    _testPuntiScrollController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  String _timestamp() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  void _appendPingLog(String line) {
    if (!mounted) return;
    setState(() => _pingLogs.add('${_timestamp()}  $line'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pingScrollController.hasClients) return;
      _pingScrollController.animateTo(
        _pingScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _appendStressLog(String line) {
    if (!mounted) return;
    setState(() => _stressLogs.add('${_timestamp()}  $line'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_stressScrollController.hasClients) return;
      _stressScrollController.animateTo(
        _stressScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _appendTestPuntiLog(String line) {
    if (!mounted) return;
    setState(() => _testPuntiLogs.add('${_timestamp()}  $line'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_testPuntiScrollController.hasClients) return;
      _testPuntiScrollController.animateTo(
        _testPuntiScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Ping ─────────────────────────────────────────────────────────────────
  Future<void> _startPing() async {
    if (_pingRunning) return;
    final host = _pingHostController.text.trim();
    if (host.isEmpty) {
      Messenger.showMessageGenericError(
        context,
        'Inserire un IP robot valido',
        2,
      );
      return;
    }
    setState(() => _pingRunning = true);

    const timeout = Duration(seconds: 2);
    const robotPort = 20002;
    var attempt = 0;

    _appendPingLog('Inizio ping su $host:$robotPort');

    while (_pingRunning) {
      attempt++;
      final sw = Stopwatch()..start();
      try {
        final socket = await Socket.connect(host, robotPort, timeout: timeout);
        sw.stop();
        socket.destroy();
        _appendPingLog('[#$attempt] risposta in ${sw.elapsedMilliseconds} ms');
      } on TimeoutException {
        sw.stop();
        _appendPingLog('[#$attempt] timeout dopo ${timeout.inSeconds}s');
      } on SocketException catch (e) {
        sw.stop();
        _appendPingLog('[#$attempt] errore socket: ${e.message}');
      } catch (e) {
        sw.stop();
        _appendPingLog('[#$attempt] errore: $e');
      }
      if (!_pingRunning) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (mounted) setState(() => _pingRunning = false);
  }

  void _stopPing() {
    if (!_pingRunning) return;
    setState(() => _pingRunning = false);
    _appendPingLog('Ping interrotto');
  }

  // ── Stress Test ───────────────────────────────────────────────────────────
  int _stressTimeoutMs() {
    final parsed = int.tryParse(_stressTimeoutController.text.trim());
    if (parsed == null) return 120;
    return parsed.clamp(20, 10000);
  }

  Future<void> _startStressTest() async {
    if (_stressRunning) return;
    if (widget.laserPageController.socket == null) {
      Messenger.showMessageGenericError(
        context,
        'Robot non connesso: connettere il robot prima dello stress test',
        2,
      );
      return;
    }
    _stressRunning = true;
    const int stepsPerLeg = 300;
    const double stepValue = 1.0;
    int cycle = 0;
    final timeoutMs = _stressTimeoutMs();
    while (_stressRunning) {
      cycle++;

      // ── 300 passi a DESTRA ────────────────────────────────────────
      _appendStressLog('Ciclo #$cycle — inizio $stepsPerLeg DESTRA');
      for (int i = 0; i < stepsPerLeg && _stressRunning; i++) {
        if (widget.laserPageController.socket == null) {
          _appendStressLog('Socket non disponibile, test interrotto');
          _stressRunning = false;
          break;
        }
        final msg = <String, dynamic>{
          'f': 'MOVE',
          'deltax': (-stepValue).toStringAsFixed(1),
          'deltay': '0',
          'deltaz': '0',
          'deltaj6': '0',
        };
        try {
          await widget.laserPageController.sendMessageToRobot(
            msg,
            postSendDelay: Duration.zero,
          );
          _stressSent++;
          _appendStressLog(
              '[DESTRA] #${i + 1}/$stepsPerLeg TX: ${msg.toString()}');
        } catch (e) {
          _stressErrors++;
          _appendStressLog('ERRORE TX (DESTRA) #${i + 1}: $e');
        }
        if (_stressRunning && timeoutMs > 0) {
          await Future.delayed(Duration(milliseconds: timeoutMs));
        }
      }
      if (_stressRunning) {
        _appendStressLog(
          'Ciclo #$cycle — completati $stepsPerLeg DESTRA  [tot TX: $_stressSent  ERR: $_stressErrors]',
        );
      }

      if (!_stressRunning) break;

      // ── 300 passi a SINISTRA ──────────────────────────────────────
      _appendStressLog('Ciclo #$cycle — inizio $stepsPerLeg SINISTRA');
      for (int i = 0; i < stepsPerLeg && _stressRunning; i++) {
        if (widget.laserPageController.socket == null) {
          _appendStressLog('Socket non disponibile, test interrotto');
          _stressRunning = false;
          break;
        }
        final msg = <String, dynamic>{
          'f': 'MOVE',
          'deltax': stepValue.toStringAsFixed(1),
          'deltay': '0',
          'deltaz': '0',
          'deltaj6': '0',
        };
        try {
          await widget.laserPageController.sendMessageToRobot(
            msg,
            postSendDelay: Duration.zero,
          );
          _stressSent++;
          _appendStressLog(
              '[SINISTRA] #${i + 1}/$stepsPerLeg TX: ${msg.toString()}');
        } catch (e) {
          _stressErrors++;
          _appendStressLog('ERRORE TX (SINISTRA) #${i + 1}: $e');
        }
        if (_stressRunning && timeoutMs > 0) {
          await Future.delayed(Duration(milliseconds: timeoutMs));
        }
      }
      if (_stressRunning) {
        _appendStressLog(
          'Ciclo #$cycle — completati $stepsPerLeg SINISTRA  [tot TX: $_stressSent  ERR: $_stressErrors]',
        );
      }
    }
    if (mounted) setState(() => _stressRunning = false);
    _appendStressLog(
      'Stress test terminato. Inviati=$_stressSent Errori=$_stressErrors',
    );
  }

  void _stopStressTest() {
    if (!_stressRunning) return;
    setState(() => _stressRunning = false);
    _appendStressLog('Stress test interrotto manualmente');
  }

  // ── Test Punti ────────────────────────────────────────────────────────────
  int _testPuntiIntervalMs() {
    final v = int.tryParse(_testPuntiIntervalController.text.trim());
    if (v == null) return 120;
    return v.clamp(10, 10000);
  }

  Duration _testPuntiPauseBetweenPointAndMove() {
    final seconds = 20 + _random.nextInt(11);
    return Duration(seconds: seconds);
  }

  Future<void> _waitForTestPunti(Duration duration) async {
    var remainingMs = duration.inMilliseconds;
    while (_testPuntiRunning && remainingMs > 0) {
      final waitMs = remainingMs > 500 ? 500 : remainingMs;
      await Future.delayed(Duration(milliseconds: waitMs));
      remainingMs -= waitMs;
    }
  }

  /// Vertici di un poligono regolare a [n] lati con raggio [r].
  /// Coordinate intere arrotondate, centrate sull'origine.
  List<List<int>> _polygonVertices({int n = 20, double r = 30.0}) {
    return List.generate(n, (k) {
      final angle = 2 * math.pi * k / n;
      return [
        (r * math.cos(angle)).round(),
        (r * math.sin(angle)).round(),
      ];
    });
  }

  /// Percorre il segmento da (cx,cy) a (tx,ty) con passi da 1 (diagonali incluse).
  /// Ritorna il numero di MOVE inviati, o -1 se interrotto/errore socket.
  Future<int> _moveSegment(
    int cx,
    int cy,
    int tx,
    int ty,
    int intervalMs,
  ) async {
    int steps = 0;
    int rx = cx, ry = cy;
    while ((rx != tx || ry != ty) && _testPuntiRunning) {
      if (widget.laserPageController.socket == null) return -1;
      final dx = (tx - rx).clamp(-1, 1);
      final dy = (ty - ry).clamp(-1, 1);
      try {
        await widget.laserPageController.sendMessageToRobot(
          <String, dynamic>{
            'f': 'MOVE',
            'deltax': dx.toDouble().toStringAsFixed(1),
            'deltay': dy.toDouble().toStringAsFixed(1),
            'deltaz': '0',
            'deltaj6': '0',
          },
          postSendDelay: Duration.zero,
        );
        rx += dx;
        ry += dy;
        steps++;
      } catch (e) {
        // Errore silenziato, può essere loggato se necessario
      }
    }
    return steps;
  }

  Future<void> _startTestPunti() async {
    if (_testPuntiRunning) return;
    if (widget.laserPageController.socket == null) {
      Messenger.showMessageGenericError(
        context,
        'Robot non connesso: connettere il robot prima del test',
        2,
      );
      return;
    }

    final intervalMs = _testPuntiIntervalMs();
    const int nVertici = 20;
    const double raggio = 30.0;
    final vertices = _polygonVertices(n: nVertici, r: raggio);

    setState(() {
      _testPuntiRunning = true;
      _testPuntiPointsTaken = 0;
      _testPuntiCycles = 0;
    });

    _appendTestPuntiLog(
      'Avvio Test Punti — $nVertici vertici, raggio $raggio, intervallo ${intervalMs}ms',
    );

    int posX = 0, posY = 0; // posizione logica relativa al punto di partenza

    while (_testPuntiRunning) {
      _testPuntiCycles++;
      for (int k = 0; k < nVertici && _testPuntiRunning; k++) {
        final tx = vertices[k][0];
        final ty = vertices[k][1];
        final totalSteps =
            (tx - posX).abs().clamp(0, 1000) + (ty - posY).abs().clamp(0, 1000);
        _appendTestPuntiLog(
          'Vertice ${k + 1}/$nVertici → ($tx, $ty)  Δ(${tx - posX}, ${ty - posY})  ~$totalSteps passi',
        );

        final sent = await _moveSegment(posX, posY, tx, ty, intervalMs);
        if (sent < 0) {
          _appendTestPuntiLog('Movimento interrotto — stop ciclo');
          _testPuntiRunning = false;
          break;
        }
        posX = tx;
        posY = ty;
        _appendTestPuntiLog(
          'Vertice ${k + 1} raggiunto ($posX, $posY) — $sent MOVE inviati',
        );

        if (!_testPuntiRunning) break;

        // ── Presa punto ──────────────────────────────────────────────────
        _testPuntiPointsTaken++;
        final rp = widget.laserPageController.posizioneRobot;
        // Costruisce un Point identico a quello della normale addCurrentPoint:
        // copia solo x,y,z,j1,j2,j3 (jt1-jt6 restano a 0.0) e imposta
        // dashboardPosition a Offset(0,0) per simulare una presa punto reale.
        final testPoint = Point(
          x: rp.x,
          y: rp.y,
          z: rp.z,
          j1: rp.j1,
          j2: rp.j2,
          j3: rp.j3,
          dashboardPosition: const Offset(0.0, 0.0),
          isFirst: false,
        );
        try {
          await widget.laserPageController.sendMessageToRobot(
            <String, dynamic>{
              'f': 'SETPOINT',
              'point': testPoint.toJson(),
              'allontanamento_x':
                  widget.laserPageController.settings.scostamentoX,
              'allontanamento_y':
                  widget.laserPageController.settings.scostamentoY,
              'allontanamento_z':
                  widget.laserPageController.settings.scostamentoZ,
              'assisted': 0,
            },
            postSendDelay: Duration.zero,
          );
          _appendTestPuntiLog(
            'Punto #$_testPuntiPointsTaken acquisito'
            '  [x=${rp.x.toStringAsFixed(2)}'
            ' y=${rp.y.toStringAsFixed(2)}'
            ' z=${rp.z.toStringAsFixed(2)}]',
          );
        } catch (e) {
          _appendTestPuntiLog(
              'ERRORE SETPOINT punto #$_testPuntiPointsTaken: $e');
        }

        if (_testPuntiRunning) {
          final pause = _testPuntiPauseBetweenPointAndMove();
          _appendTestPuntiLog(
            'Attesa simulata post-punto: ${pause.inSeconds}s prima di riprendere il movimento',
          );
          await _waitForTestPunti(pause);
        }
      }

      if (!_testPuntiRunning) break;

      // ── Reset punti dopo il ciclo ────────────────────────────────────────
      _appendTestPuntiLog(
        'Ciclo #$_testPuntiCycles completato — $nVertici punti — reset e nuovo ciclo',
      );
      try {
        await widget.laserPageController.resetPoints();
        _appendTestPuntiLog('Reset OK (RESETSAFEPOSITION inviato)');
      } catch (e) {
        _appendTestPuntiLog('ERRORE reset: $e');
      }
    }

    if (mounted) setState(() => _testPuntiRunning = false);
    _appendTestPuntiLog(
      'Test Punti terminato — cicli=$_testPuntiCycles  punti totali=$_testPuntiPointsTaken',
    );
  }

  void _stopTestPunti() {
    if (!_testPuntiRunning) return;
    setState(() => _testPuntiRunning = false);
    _appendTestPuntiLog('Test Punti interrotto manualmente');
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _buildDiagnosticCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required _DiagnosticTool tool,
  }) {
    final selected = _selectedTool == tool;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedTool = tool),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? AppColors.sagaBlue.withValues(alpha: 0.15)
              : Colors.white,
          border: Border.all(
            color: selected ? AppColors.sagaBlue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: AppColors.sagaBlue),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogBox({
    required List<String> logs,
    required ScrollController scrollController,
  }) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.sagaBlue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: logs.isEmpty
            ? const Align(
                alignment: Alignment.topLeft,
                child: Text('Nessun log'),
              )
            : ListView.builder(
                controller: scrollController,
                itemCount: logs.length,
                itemBuilder: (_, index) => Text(
                  logs[index],
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
      ),
    );
  }

  Widget _buildPingPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ping',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pingHostController,
                    decoration: const InputDecoration(
                      labelText: 'IP Robot',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _pingRunning ? Colors.orange : AppColors.sagaBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _pingRunning ? _stopPing : _startPing,
                  icon: Icon(_pingRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(_pingRunning ? 'STOP' : 'START'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _pingLogs.clear()),
                  child: const Text('PULISCI LOG'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildLogBox(
              logs: _pingLogs,
              scrollController: _pingScrollController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStressPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stress Test',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'In loop: 300 MOVE destra → 300 MOVE sinistra (passo 1). Torna sempre al centro.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 170,
                  child: TextFormField(
                    controller: _stressTimeoutController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Intervallo (ms)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _stressRunning ? Colors.orange : AppColors.sagaBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      _stressRunning ? _stopStressTest : _startStressTest,
                  icon: Icon(_stressRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(_stressRunning ? 'STOP' : 'START'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _stressLogs.clear()),
                  child: const Text('PULISCI LOG'),
                ),
                const Spacer(),
                Text(
                  'TX: $_stressSent  ERR: $_stressErrors',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildLogBox(
              logs: _stressLogs,
              scrollController: _stressScrollController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestPuntiPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Punti',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Percorre 20 vertici di un poligono (raggio 30) con MOVE passo 1, '
              'poi SETPOINT in ogni vertice. Dopo 20 punti: reset e nuovo ciclo.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 170,
                  child: TextFormField(
                    controller: _testPuntiIntervalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Intervallo (ms)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _testPuntiRunning ? Colors.orange : AppColors.sagaBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      _testPuntiRunning ? _stopTestPunti : _startTestPunti,
                  icon: Icon(_testPuntiRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(_testPuntiRunning ? 'STOP' : 'START'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _testPuntiLogs.clear()),
                  child: const Text('PULISCI LOG'),
                ),
                const Spacer(),
                Text(
                  'Cicli: $_testPuntiCycles  Punti: $_testPuntiPointsTaken',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildLogBox(
              logs: _testPuntiLogs,
              scrollController: _testPuntiScrollController,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        title: Text(
          'Diagnostica Robot - ${widget.laserPageController.settings.serialeRobot}',
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: const GradientAppBarBackground(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 110,
              ),
              padding: EdgeInsets.zero,
              children: [
                _buildDiagnosticCard(
                  icon: Icons.network_ping,
                  title: 'Ping',
                  subtitle: 'Raggiungibilita e latenza',
                  tool: _DiagnosticTool.ping,
                ),
                _buildDiagnosticCard(
                  icon: Icons.speed,
                  title: 'Stress Test',
                  subtitle: 'MOVE rapido destra/sinistra',
                  tool: _DiagnosticTool.stress,
                ),
                _buildDiagnosticCard(
                  icon: Icons.adjust,
                  title: 'Test Punti',
                  subtitle: 'MOVE + SETPOINT su poligono',
                  tool: _DiagnosticTool.testPunti,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _selectedTool == _DiagnosticTool.ping
                  ? _buildPingPanel()
                  : _selectedTool == _DiagnosticTool.stress
                      ? _buildStressPanel()
                      : _buildTestPuntiPanel(),
            ),
          ],
        ),
      ),
    );
  }
}
