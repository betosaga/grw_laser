import 'package:flutter/material.dart';
import 'package:grw_laser/model/point.dart';
import 'package:grw_laser/pages/laser_page/laser_page_controller.dart';

class LaserTakenPointsDisplay extends StatelessWidget {
  final LaserPageController controller;
  final bool fillAvailableHeight;
  const LaserTakenPointsDisplay({
    required this.controller,
    this.fillAvailableHeight = false,
  });

  List<_PointRowItem> _buildOrderedItems() {
    final entries = controller.points.points
        .asMap()
        .entries
        .map(
          (entry) => _PointRowItem(
            originalIndex: entry.key,
            point: entry.value,
          ),
        )
        .toList();

    entries.sort((a, b) {
      final aOrder = a.point.order;
      final bOrder = b.point.order;

      if (aOrder == null && bOrder == null) {
        return a.originalIndex.compareTo(b.originalIndex);
      }
      if (aOrder == null) return 1;
      if (bOrder == null) return -1;

      final byOrder = aOrder.compareTo(bOrder);
      if (byOrder != 0) return byOrder;

      return a.originalIndex.compareTo(b.originalIndex);
    });

    return entries;
  }

  String _fmt(double value) => value.toStringAsFixed(2);

  Widget _pointCard(_PointRowItem item) {
    final point = item.point;
    final orderValue = point.order?.toString() ?? '-';
    final positionJText = point.positionJ == null
        ? ''
        : ' | positionJ j1:${_fmt(point.positionJ!.j1)} j2:${_fmt(point.positionJ!.j2)} '
            'j3:${_fmt(point.positionJ!.j3)} j4:${_fmt(point.positionJ!.j4)} '
            'j5:${_fmt(point.positionJ!.j5)} j6:${_fmt(point.positionJ!.j6)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '- Punto $orderValue | x:${_fmt(point.x)} y:${_fmt(point.y)} z:${_fmt(point.z)} '
          '| j1:${_fmt(point.j1)} j2:${_fmt(point.j2)} j3:${_fmt(point.j3)} '
          '| jt1:${_fmt(point.jt1)} jt2:${_fmt(point.jt2)} jt3:${_fmt(point.jt3)} '
          '| jt4:${_fmt(point.jt4)} jt5:${_fmt(point.jt5)} jt6:${_fmt(point.jt6)}$positionJText',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFFD7D7D7)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.pointsOrderVersion,
      builder: (_, __, ___) {
        final items = _buildOrderedItems();
        final maxHeight = MediaQuery.of(context).size.height * 0.50;
        final listHeight = (items.length * 42.0).clamp(130.0, maxHeight);

        Widget listBox() {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD7D7D7)),
            ),
            child: fillAvailableHeight
                ? ListView.builder(
                    primary: false,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _pointCard(item),
                      );
                    },
                  )
                : SizedBox(
                    height: listHeight,
                    child: ListView.builder(
                      primary: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _pointCard(item),
                        );
                      },
                    ),
                  ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Elenco punti',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Text(
                  'Nessun punto acquisito',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                )
              else
                if (fillAvailableHeight) Expanded(child: listBox()) else listBox(),
            ],
          ),
        );
      },
    );
  }
}

class _PointRowItem {
  final int originalIndex;
  final Point point;

  const _PointRowItem({required this.originalIndex, required this.point});
}
