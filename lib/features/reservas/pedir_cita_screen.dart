import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../core/widgets.dart';
import '../catalogo/modelos.dart';
import 'reservas_repository.dart';

/// La clienta propone fecha y hora; la profesional acepta o rechaza (plan, 1.2).
class PedirCitaScreen extends StatefulWidget {
  const PedirCitaScreen({super.key, required this.perfil, this.servicioId});

  final PerfilProfesional perfil;

  /// Servicio que venía buscando; queda elegido de una vez.
  final int? servicioId;

  /// Máximo de anticipación, igual que en la API.
  static const diasMaximos = 60;

  @override
  State<PedirCitaScreen> createState() => _PedirCitaScreenState();
}

class _PedirCitaScreenState extends State<PedirCitaScreen> {
  final _formulario = GlobalKey<FormState>();
  final _direccion = TextEditingController();
  final _notas = TextEditingController();

  ServicioOfrecido? _servicio;
  Zona? _zona;
  DateTime? _fecha;
  TimeOfDay? _hora;

  bool _enviando = false;
  String? _error;
  ApiException? _errorApi;

  @override
  void initState() {
    super.initState();
    final servicios = widget.perfil.servicios;
    _servicio =
        servicios.where((s) => s.servicioId == widget.servicioId).firstOrNull ??
        (servicios.length == 1 ? servicios.first : null);
    if (widget.perfil.zonas.length == 1) _zona = widget.perfil.zonas.first;
  }

  @override
  void dispose() {
    _direccion.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = ahoraEnColombia();
    final primera = DateTime(hoy.year, hoy.month, hoy.day);
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? primera,
      firstDate: primera,
      lastDate: primera.add(
        const Duration(days: PedirCitaScreen.diasMaximos - 1),
      ),
      helpText: 'Fecha de la cita',
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: _hora ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Hora de la cita',
    );
    if (elegida != null) setState(() => _hora = elegida);
  }

  /// La fecha y hora elegidas (hora de Colombia) ya pasaron.
  bool _yaPaso(DateTime fecha, TimeOfDay hora) {
    final instante = DateTime.utc(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    ).add(const Duration(hours: 5));
    return !instante.isAfter(DateTime.now().toUtc());
  }

  Future<void> _enviar() async {
    setState(() {
      _error = null;
      _errorApi = null;
    });
    final valido = _formulario.currentState!.validate();
    final fecha = _fecha;
    final hora = _hora;

    if (fecha == null || hora == null) {
      setState(() => _error = 'Elige la fecha y la hora de la cita.');
      return;
    }
    if (_yaPaso(fecha, hora)) {
      setState(() => _error = 'Elige una fecha y hora que no hayan pasado.');
      return;
    }
    if (!valido) return;

    setState(() => _enviando = true);
    final messenger = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    try {
      await ReservasScope.of(context).pedir(
        profesionalId: widget.perfil.id,
        servicioId: _servicio!.servicioId,
        zonaId: _zona!.id,
        fechaHora: isoColombia(fecha, hora.hour, hora.minute),
        direccion: _direccion.text.trim(),
        notas: _notas.text.trim(),
      );
      navegador.popUntil((ruta) => ruta.isFirst);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Solicitud enviada. Te avisaremos aquí cuando '
            '${widget.perfil.nombre.split(' ').first} la acepte.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorApi = e;
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;
    final servicio = _servicio;
    final textos = Theme.of(context).textTheme;
    final errorFecha = _errorApi?.errorDe('fecha_hora');

    return Scaffold(
      appBar: AppBar(title: const Text('Pedir cita')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Con ${perfil.nombre}', style: textos.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<ServicioOfrecido>(
              initialValue: servicio,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Servicio',
                errorText: _errorApi?.errorDe('servicio_id'),
              ),
              items: [
                for (final s in perfil.servicios)
                  DropdownMenuItem(
                    value: s,
                    child: Text('${s.nombre} · ${formatoPesos(s.precio)}'),
                  ),
              ],
              validator: (s) => s == null ? 'Elige el servicio.' : null,
              onChanged: (s) => setState(() => _servicio = s),
            ),
            if (servicio != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Dura aprox. ${formatoDuracion(servicio.duracionMinutos)}. '
                  'Pagas ${formatoPesos(servicio.precio)} directamente a la '
                  'profesional al terminar.',
                  style: textos.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Selector(
                    icono: Icons.event,
                    etiqueta: 'Fecha',
                    valor: _fecha == null
                        ? null
                        : formatoDiaCalendario(_fecha!),
                    onTap: _enviando ? null : _elegirFecha,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Selector(
                    icono: Icons.schedule,
                    etiqueta: 'Hora',
                    valor: _hora?.format(context),
                    onTap: _enviando ? null : _elegirHora,
                  ),
                ),
              ],
            ),
            if (_error ?? errorFecha case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: MensajeError(error),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Zona>(
              initialValue: _zona,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Zona',
                prefixIcon: const Icon(Icons.place_outlined),
                errorText: _errorApi?.errorDe('zona_id'),
              ),
              items: [
                for (final z in perfil.zonas)
                  DropdownMenuItem(value: z, child: Text(z.nombre)),
              ],
              validator: (z) => z == null ? 'Elige la zona.' : null,
              onChanged: (z) => setState(() => _zona = z),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _direccion,
              enabled: !_enviando,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 255,
              decoration: InputDecoration(
                labelText: 'Dirección',
                hintText: 'Calle 10 # 5-20, apto 301',
                helperText:
                    'La profesional la verá solo cuando acepte la cita.',
                errorText: _errorApi?.errorDe('direccion'),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Escribe la dirección.'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notas,
              enabled: !_enviando,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Indicaciones para llegar, diseño que quieres…',
              ),
            ),
            if (_errorApi != null && _errorApi!.errores.isEmpty) ...[
              const SizedBox(height: 8),
              MensajeError(_errorApi!.mensaje),
            ] else if (_errorApi?.errorDe('profesional_id')
                case final error?) ...[
              const SizedBox(height: 8),
              MensajeError(error),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const CargandoEnBoton()
                  : const Text('Enviar solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo que abre un selector (fecha u hora).
class _Selector extends StatelessWidget {
  const _Selector({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final String? valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono),
        ),
        isEmpty: valor == null,
        child: Text(valor ?? '', maxLines: 2),
      ),
    );
  }
}
