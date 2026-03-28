import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/service.dart';
import '../../models/professional.dart';
import '../../models/appointment.dart';
import '../../models/operating_hours.dart';
import '../../models/block.dart';
import '../../services/supabase_service.dart';
import '../../services/confirmation_code_service.dart';
import '../../widgets/time_slot_widget.dart';
import '../../widgets/urgency_banner.dart';
import '../../widgets/page_background.dart';
import '../confirmation_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  final Service? preselectedService;
  final Professional? preselectedProfessional;

  const BookingFlowScreen({super.key, this.preselectedService, this.preselectedProfessional});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final _svc = SupabaseService.instance;
  final _pageController = PageController();
  int _currentPage = 0;

  List<Service> _services = [];
  List<Professional> _professionals = [];
  List<OperatingHours> _hours = [];
  List<Block> _blocks = [];
  List<Appointment> _existingAppointments = [];

  Service? _selectedService;
  Professional? _selectedProfessional;
  DateTime? _selectedDate;
  String? _selectedTime;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _commentsController = TextEditingController();

  List<String> _timeSlots = [];
  Map<String, bool> _slotAvailability = {};
  int _availableSlots = 0;
  int _totalSlots = 0;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.preselectedService;
    _selectedProfessional = widget.preselectedProfessional;
    _loadInitial();
  }

  Color get _primary {
    final t = _svc.currentTenant;
    return t != null ? AppConfig.hexToColor(t.colorPrimario) : AppConfig.colorPrimario;
  }

  Color get _accent {
    final t = _svc.currentTenant;
    return t != null ? AppConfig.hexToColor(t.colorAcento) : AppConfig.colorAcento;
  }

  Future<void> _loadInitial() async {
    try {
      final services = await _svc.loadActiveServices();
      final professionals = await _svc.loadActiveProfessionals();
      final hours = await _svc.loadOperatingHours();
      if (mounted) {
        setState(() {
          _services = services;
          _professionals = professionals;
          _hours = hours;
          _loading = false;
          // Skip steps if preselected
          if (_selectedService != null && _selectedProfessional != null) {
            _currentPage = 2;
            _pageController.jumpToPage(2);
          } else if (_selectedService != null) {
            _currentPage = 1;
            _pageController.jumpToPage(1);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _loadTimeSlots() async {
    if (_selectedDate == null) return;

    final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final dayOfWeek = _selectedDate!.weekday % 7;

    final dayHours = _hours.where((h) => h.diaSemana == dayOfWeek).toList();
    if (dayHours.isEmpty) {
      setState(() {
        _timeSlots = [];
        _slotAvailability = {};
      });
      return;
    }

    // Load blocks and appointments for date
    _blocks = await _svc.loadBlocks(fecha: dateStr);
    _existingAppointments = await _svc.loadAppointmentsByDate(dateStr);

    final slots = <String>[];
    for (final h in dayHours) {
      final start = _parseTime(h.horaInicio);
      final end = _parseTime(h.horaFin);
      final interval = h.intervaloMinutos;
      var current = start;
      while (current < end) {
        final timeStr = '${(current ~/ 60).toString().padLeft(2, '0')}:${(current % 60).toString().padLeft(2, '0')}';
        slots.add(timeStr);
        current += interval;
      }
    }

    // Check availability
    final availability = <String, bool>{};
    final now = DateTime.now();
    final tenant = _svc.currentTenant;
    final minHoras = tenant?.minAnticipacionHoras ?? 2;

    for (final slot in slots) {
      bool available = true;

      // Check if in the past
      if (_selectedDate!.year == now.year && _selectedDate!.month == now.month && _selectedDate!.day == now.day) {
        final slotMinutes = _parseTime(slot);
        final nowMinutes = now.hour * 60 + now.minute + (minHoras * 60);
        if (slotMinutes <= nowMinutes) available = false;
      }

      // Check blocks
      for (final block in _blocks) {
        if (block.diaCompleto) {
          available = false;
          break;
        }
        if (block.hora == slot) {
          if (block.professionalId == null || block.professionalId == _selectedProfessional?.id) {
            available = false;
            break;
          }
        }
      }

      // Check existing appointments for same service/professional
      if (available && _selectedService != null) {
        final slotsForTime = _existingAppointments.where((a) { // ignore: unused_local_variable
          if (a.hora != slot) return false;
          if (_selectedProfessional != null && a.professionalId == _selectedProfessional!.id) return true;
          if (a.servicioId == _selectedService!.id) return true;
          return false;
        }).length;

        final maxTurnos = _selectedService!.maxTurnosDia;
        // Count all appointments for this service on this date
        final totalForService = _existingAppointments.where((a) => a.servicioId == _selectedService!.id).length;
        if (totalForService >= maxTurnos) {
          available = false;
        }

        // Check professional busy at this time
        if (_selectedProfessional != null) {
          final profBusy = _existingAppointments.any((a) =>
            a.hora == slot && a.professionalId == _selectedProfessional!.id);
          if (profBusy) available = false;
        }
      }

      availability[slot] = available;
    }

    final avail = availability.values.where((v) => v).length;
    setState(() {
      _timeSlots = slots;
      _slotAvailability = availability;
      _availableSlots = avail;
      _totalSlots = slots.length;
    });
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _submit() async {
    if (_selectedService == null || _selectedDate == null || _selectedTime == null) return;
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      _showError('Por favor completa nombre y telefono');
      return;
    }

    setState(() => _submitting = true);
    try {
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final code = ConfirmationCodeService.generate();

      final appointment = await _svc.createAppointment({
        'fecha': dateStr,
        'hora': _selectedTime,
        'duracion_minutos': _selectedService!.duracionMinutos,
        'nombre_cliente': _nameController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'servicio_id': _selectedService!.id,
        'servicio_nombre': _selectedService!.nombre,
        'professional_id': _selectedProfessional?.id,
        'professional_nombre': _selectedProfessional?.nombre,
        'codigo_confirmacion': code,
        'comentarios': _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ConfirmationScreen(
            appointment: appointment,
            precioServicio: _selectedService!.precioEfectivoFinal,
            requiereSena: _selectedService!.requiereSena,
          )),
        );
      }
    } catch (e) {
      _showError('Error al crear el turno: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Error', style: TextStyle(color: Colors.grey.shade800)),
          ],
        ),
        content: Text(msg, style: TextStyle(color: Colors.grey.shade800)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: _primary))),
        ],
      ),
    );
  }

  void _showWaitlistDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.local_fire_department, color: _accent),
            const SizedBox(width: 8),
            Expanded(child: Text('Lista de espera', style: TextStyle(color: _primary, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Todos los turnos estan ocupados. Dejanos tus datos y te avisaremos cuando haya disponibilidad.',
              style: const TextStyle(color: Color(0xFF424242), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              style: TextStyle(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Telefono'),
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade800)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
              final dateStr = _selectedDate != null
                  ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                  : DateTime.now().toIso8601String().substring(0, 10);
              await _svc.addToWaitlist({
                'fecha': dateStr,
                'servicio_id': _selectedService?.id,
                'professional_id': _selectedProfessional?.id,
                'nombre': nameCtrl.text.trim(),
                'telefono': phoneCtrl.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Te agregamos a la lista de espera!'), backgroundColor: _primary),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: const Text('Anotarme'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(title: const Text('Reservar Turno')),
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(220),
        foregroundColor: Colors.grey[800],
        elevation: 0,
        title: Text('Reservar Turno', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey[800])),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(_primary),
          ),
        ),
      ),
      body: PageBackground(child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          _buildServicePage(),
          _buildProfessionalPage(),
          _buildDateTimePage(),
          _buildDataPage(),
        ],
      )),
    );
  }

  // Page 0: Select Service
  Widget _buildServicePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Elige tu servicio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _primary)),
        const SizedBox(height: 16),
        ..._services.map((s) => _selectionTile(
          title: s.nombre,
          subtitle: '${s.duracionMinutos} min${s.precioEfectivoFinal != null ? ' - Efect. \$${s.precioEfectivoFinal!.toStringAsFixed(0)}' : ''}${s.precioTarjetaFinal != null ? ' / Tarj. \$${s.precioTarjetaFinal!.toStringAsFixed(0)}' : ''}',
          icon: Icons.spa,
          selected: _selectedService?.id == s.id,
          imageUrl: s.imagenUrl,
          onTap: () {
            setState(() => _selectedService = s);
            _goToPage(1);
          },
        )),
      ],
    );
  }

  // Page 1: Select Professional
  Widget _buildProfessionalPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Elige tu profesional', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _primary)),
        const SizedBox(height: 8),
        Text('(opcional)', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
        const SizedBox(height: 16),
        // "Sin preferencia" option
        _selectionTile(
          title: 'Sin preferencia',
          subtitle: 'Cualquier profesional disponible',
          icon: Icons.group,
          selected: _selectedProfessional == null,
          onTap: () {
            setState(() => _selectedProfessional = null);
            _goToPage(2);
          },
        ),
        ..._professionals.map((p) => _selectionTile(
          title: p.nombre,
          subtitle: p.especialidad,
          icon: Icons.person,
          selected: _selectedProfessional?.id == p.id,
          imageUrl: p.fotoUrl,
          onTap: () {
            setState(() => _selectedProfessional = p);
            _goToPage(2);
          },
        )),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _goToPage(0),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Volver'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[500]),
        ),
      ],
    );
  }

  // Calendar state
  late DateTime _calendarMonth = DateTime.now();

  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  // Page 2: Select Date & Time
  Widget _buildDateTimePage() {
    final tenant = _svc.currentTenant;
    final maxDays = tenant?.maxAnticipacionDias ?? 60;
    final closedDay = tenant?.diaCerrado ?? 0;
    final now = DateTime.now();
    final lastDate = now.add(Duration(days: maxDays));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('¿Cuándo te gustaría venir?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _primary)),
        const SizedBox(height: 6),
        Text('Elegí el día y horario que más te guste', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        const SizedBox(height: 20),
        // Inline calendar
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _buildInlineCalendar(now, lastDate, closedDay),
          ),
        ),
        // Time slots
        if (_timeSlots.isNotEmpty) ...[
          const SizedBox(height: 20),
          UrgencyBanner(available: _availableSlots, total: _totalSlots, primary: _primary),
          const SizedBox(height: 12),
          Text(
            _availableSlots > 0 ? 'Horarios disponibles' : 'Todos los horarios estan ocupados',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _availableSlots > 0 ? Colors.grey[700] : Colors.redAccent,
            ),
          ),
          if (_availableSlots == 0) ...[
            const SizedBox(height: 6),
            Text(
              'Proba con otra fecha',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _timeSlots.map((slot) => TimeSlotWidget(
                time: slot,
                isSelected: _selectedTime == slot,
                isAvailable: _slotAvailability[slot] ?? false,
                primary: _primary,
                onTap: () {
                  setState(() => _selectedTime = slot);
                },
              )).toList(),
            ),
          ),
          if (_availableSlots == 0) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showWaitlistDialog,
              icon: const Icon(Icons.notification_add, size: 18),
              label: const Text('Anotarme en lista de espera'),
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
            ),
          ],
        ] else if (_selectedDate != null && _timeSlots.isEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy, color: Colors.redAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No hay horarios disponibles para esta fecha',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Proba con otra fecha',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _goToPage(1),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Volver'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[500]),
            ),
            const Spacer(),
            if (_selectedTime != null)
              ElevatedButton.icon(
                onPressed: () => _goToPage(3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Continuar'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineCalendar(DateTime now, DateTime lastDate, int closedDay) {
    final firstOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    // Monday = 1 in Dart weekday, we want Monday as first column (index 0)
    final startWeekday = firstOfMonth.weekday; // 1=Mon, 7=Sun
    final blanks = startWeekday - 1;

    final canGoPrev = DateTime(_calendarMonth.year, _calendarMonth.month).isAfter(DateTime(now.year, now.month));
    final canGoNext = DateTime(_calendarMonth.year, _calendarMonth.month).isBefore(DateTime(lastDate.year, lastDate.month));

    final monthNames = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _primary.withAlpha(15), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: canGoPrev ? () {
                  setState(() {
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                  });
                } : null,
                icon: Icon(Icons.chevron_left, color: canGoPrev ? _primary : Colors.grey[300]),
              ),
              Text(
                '${monthNames[_calendarMonth.month - 1]} ${_calendarMonth.year}',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey[800]),
              ),
              IconButton(
                onPressed: canGoNext ? () {
                  setState(() {
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                  });
                } : null,
                icon: Icon(Icons.chevron_right, color: canGoNext ? _primary : Colors.grey[300]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day headers
          Row(
            children: _dayNames.map((d) => Expanded(
              child: Center(
                child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400])),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Day grid
          ...List.generate(((blanks + daysInMonth) / 7).ceil(), (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (col) {
                  final dayIndex = week * 7 + col - blanks + 1;
                  if (dayIndex < 1 || dayIndex > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 42));
                  }

                  final date = DateTime(_calendarMonth.year, _calendarMonth.month, dayIndex);
                  final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                  final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
                  final isClosed = date.weekday % 7 == closedDay;
                  final isAfterMax = date.isAfter(lastDate);
                  final isDisabled = isPast || isClosed || isAfterMax;
                  final isSelected = _selectedDate != null &&
                      date.year == _selectedDate!.year &&
                      date.month == _selectedDate!.month &&
                      date.day == _selectedDate!.day;

                  return Expanded(
                    child: GestureDetector(
                      onTap: isDisabled ? null : () async {
                        setState(() {
                          _selectedDate = date;
                          _selectedTime = null;
                          _timeSlots = [];
                        });
                        await _loadTimeSlots();
                      },
                      child: Container(
                        height: 42,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primary
                              : isToday
                                  ? _primary.withAlpha(20)
                                  : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$dayIndex',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : isDisabled
                                      ? Colors.grey[300]
                                      : isToday
                                          ? _primary
                                          : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Page 3: Client Data
  Widget _buildDataPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tus datos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _primary)),
        const SizedBox(height: 8),
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow(Icons.spa, _selectedService?.nombre ?? ''),
              if (_selectedProfessional != null) _summaryRow(Icons.person, _selectedProfessional!.nombre),
              _summaryRow(Icons.calendar_today, '${_selectedDate?.day}/${_selectedDate?.month}/${_selectedDate?.year}'),
              _summaryRow(Icons.access_time, _selectedTime ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 8),
        UrgencyBanner(available: _availableSlots, total: _totalSlots, primary: _primary),
        const SizedBox(height: 16),
        _bookingField(_nameController, 'Nombre completo *', Icons.person_outline, textCapitalization: TextCapitalization.words),
        const SizedBox(height: 12),
        _bookingField(_phoneController, 'Telefono *', Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _bookingField(_emailController, 'Email (opcional)', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _bookingField(_commentsController, 'Comentarios (opcional)', Icons.comment_outlined, maxLines: 3),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _goToPage(2),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Volver'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[500]),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(_submitting ? 'Reservando...' : 'Confirmar Turno'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _bookingField(TextEditingController ctrl, String label, IconData icon, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      style: TextStyle(color: Colors.grey[800], fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: _primary.withAlpha(150)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _selectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _primary.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _primary : Colors.grey[200]!, width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 24),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: _primary, size: 22),
          ],
        ),
      ),
    );
  }
}
