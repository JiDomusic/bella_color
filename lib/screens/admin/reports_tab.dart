import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/report_service.dart';
import '../../widgets/simple_bar_chart.dart';

class ReportsTab extends StatefulWidget {
  final Color primary;
  final Color accent;

  const ReportsTab({super.key, required this.primary, required this.accent});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    final report = await ReportService.generateReport(_startDate, _endDate);
    if (mounted) setState(() => _report = report);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.accent,
              onPrimary: AppConfig.colorFondoOscuro,
              surface: AppConfig.colorFondoCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _startDate = picked.start;
      _endDate = picked.end;
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range selector
        GestureDetector(
          onTap: _pickDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: widget.accent, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.edit, color: Colors.white.withAlpha(100), size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (report == null || report['total_turnos'] == 0) ...[
          Container(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No hay datos para el periodo seleccionado',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withAlpha(130)),
            ),
          ),
        ] else ...[
          // Metric cards
          Row(children: [
            Expanded(child: _metricCard('Total Turnos', '${report['total_turnos']}', Icons.calendar_today, widget.accent)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('No-Show', '${(report['tasa_no_show'] as double).toStringAsFixed(1)}%', Icons.person_off, Colors.orange)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _metricCard('Cancelacion', '${(report['tasa_cancelacion'] as double).toStringAsFixed(1)}%', Icons.cancel, Colors.red)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('Dia top', report['dia_mas_ocupado'] ?? '-', Icons.today, Colors.purple)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _metricCard('Hora top', report['horario_mas_ocupado'] ?? '-', Icons.access_time, Colors.teal)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('Servicio top', report['servicio_mas_pedido'] ?? '-', Icons.spa, widget.primary)),
          ]),
          const SizedBox(height: 8),
          if (report['profesional_mas_ocupado'] != null)
            _metricCard('Profesional top', report['profesional_mas_ocupado'], Icons.person, Colors.blue),
          const SizedBox(height: 24),

          // Charts
          _chartContainer(SimpleBarChart(
            title: 'Turnos por dia',
            data: _castToIntMap(report['turnos_por_dia']),
            barColor: widget.accent,
          )),
          const SizedBox(height: 16),

          _chartContainer(SimpleBarChart(
            title: 'Turnos por horario',
            data: _castToIntMap(report['turnos_por_hora']),
            barColor: Colors.blue,
            height: 220,
          )),
          const SizedBox(height: 16),

          _chartContainer(SimpleBarChart(
            title: 'Por estado',
            data: _castToIntMap(report['turnos_por_estado']),
            barColor: Colors.amber,
          )),
          const SizedBox(height: 16),

          _chartContainer(SimpleBarChart(
            title: 'Por servicio',
            data: _castToIntMap(report['turnos_por_servicio']),
            barColor: widget.primary,
          )),
          const SizedBox(height: 16),

          if ((report['turnos_por_profesional'] as Map).isNotEmpty)
            _chartContainer(SimpleBarChart(
              title: 'Por profesional',
              data: _castToIntMap(report['turnos_por_profesional']),
              barColor: Colors.purple,
            )),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _chartContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Map<String, int> _castToIntMap(dynamic map) {
    if (map is Map<String, int>) return map;
    if (map is Map) return map.map((k, v) => MapEntry(k.toString(), v is int ? v : 0));
    return {};
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11)),
        ],
      ),
    );
  }
}
