import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/fiscal_export_service.dart';
import '../../../core/services/fiscal_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../pos/widgets/factura_capture_dialog.dart';
import '../widgets/admin_panel.dart';

/// Módulo de facturación: genera la factura global del periodo y exporta el
/// prellenado CFDI 4.0 (no timbra). `docs/facturacion.md`.
class FacturacionScreen extends ConsumerStatefulWidget {
  const FacturacionScreen({super.key});

  @override
  ConsumerState<FacturacionScreen> createState() => _FacturacionScreenState();
}

class _FacturacionScreenState extends ConsumerState<FacturacionScreen> {
  DateTimeRange _periodo = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );
  bool _busy = false;
  List<FiscalDoc> _docs = const [];

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final db = ref.read(databaseProvider);
    final docs = await (db.select(db.fiscalDocs)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    if (mounted) setState(() => _docs = docs);
  }

  DateTime get _desde =>
      DateTime(_periodo.start.year, _periodo.start.month, _periodo.start.day);
  DateTime get _hasta => DateTime(
      _periodo.end.year, _periodo.end.month, _periodo.end.day + 1); // exclusivo

  String get _periodoRef {
    final f = DateFormat('yyyy-MM-dd');
    return '${f.format(_periodo.start)}_a_${f.format(_periodo.end)}';
  }

  Future<void> _generarGlobal() async {
    setState(() => _busy = true);
    final id = await ref.read(fiscalServiceProvider).buildGlobal(
          desde: _desde,
          hasta: _hasta,
          periodoRef: _periodoRef,
        );
    await _loadDocs();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Factura global generada (doc #$id).')),
    );
  }

  Future<void> _exportar({
    required Future<FiscalExport> Function() build,
    required String nombre,
  }) async {
    setState(() => _busy = true);
    final out = await build();
    if (mounted) setState(() => _busy = false);
    if (out.rows.length <= 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No hay nada que exportar en el periodo.')),
        );
      }
      return;
    }
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar prellenado CFDI',
      fileName: '$nombre.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null) return;
    final svc = ref.read(fiscalExportServiceProvider);
    await File(result).writeAsBytes(svc.toXlsx(out.rows));
    await svc.markExported(out.docIds);
    await _loadDocs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportado: $result')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final emisorListo = (settings['rfc_emisor'] ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Facturación'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _disclaimer(),
                const SizedBox(height: 16),
                if (!emisorListo) ...[
                  _emisorWarning(),
                  const SizedBox(height: 16),
                ],
                _periodoYExport(),
                const SizedBox(height: 16),
                _docsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LaTerciaColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LaTerciaColors.gold.withValues(alpha: 0.5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: LaTerciaColors.goldDark, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este archivo es un PRELLENADO para timbrar, NO es una factura '
              'válida. El CFDI existe solo cuando tu facturador/PAC lo timbra.',
              style: TextStyle(
                  color: LaTerciaColors.darkBrown, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emisorWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LaTerciaColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LaTerciaColors.danger.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: LaTerciaColors.danger, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Faltan los datos del emisor. Captúralos en '
              'Configuración → Facturación (emisor) antes de exportar.',
              style: TextStyle(color: LaTerciaColors.darkBrown),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodoYExport() {
    final f = DateFormat('d MMM yyyy', 'es_MX');
    return AdminPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Periodo',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: LaTerciaColors.darkBrown)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text('${f.format(_periodo.start)} — '
                      '${f.format(_periodo.end)}'),
                  onPressed: _busy ? null : _pickPeriodo,
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: LaTerciaColors.burntOrange),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Generar factura global'),
                onPressed: _busy ? null : _generarGlobal,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.description_outlined),
                label: const Text('Exportar individuales pendientes'),
                onPressed: _busy
                    ? null
                    : () => _exportar(
                          build: () => ref
                              .read(fiscalExportServiceProvider)
                              .exportIndividualesPendientes(_desde, _hasta),
                          nombre: 'cfdi-individuales-$_periodoRef',
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickPeriodo() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _periodo,
    );
    if (r != null) setState(() => _periodo = r);
  }

  Widget _docsPanel() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Text('Documentos fiscales',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: LaTerciaColors.darkBrown)),
          ),
          if (_docs.isEmpty)
            const AdminEmptyState(
              icon: Icons.request_quote_outlined,
              message: 'Aún no hay documentos fiscales.',
            )
          else ...[
            const AdminHeaderRow(cells: [
              Expanded(flex: 2, child: Text('TIPO')),
              Expanded(flex: 3, child: Text('RECEPTOR / PERIODO')),
              Expanded(flex: 2, child: Text('CREADO')),
              Expanded(flex: 2, child: Text('ESTADO')),
              SizedBox(width: 96, child: Text('')),
            ]),
            for (var i = 0; i < _docs.length; i++) _docRow(_docs[i], i),
          ],
        ],
      ),
    );
  }

  Widget _docRow(FiscalDoc d, int i) {
    final esGlobal = d.tipo == 'global';
    return AdminRow(
      isLast: i == _docs.length - 1,
      cells: [
        Expanded(
          flex: 2,
          child: StatusPill(esGlobal ? 'Global' : 'Individual',
              tone: esGlobal ? StatusTone.info : StatusTone.neutral),
        ),
        Expanded(
          flex: 3,
          child: Text(
            esGlobal
                ? (d.periodoRef ?? 'Público en general')
                : (d.receptorRazonSocial ?? d.receptorRfc ?? '—'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(flex: 2, child: Text(formatDate(d.createdAt))),
        Expanded(flex: 2, child: _estadoPill(d.estado)),
        SizedBox(width: 108, child: _accion(d)),
      ],
    );
  }

  Widget _estadoPill(String estado) {
    switch (estado) {
      case 'exportada':
        return const StatusPill('Exportada', tone: StatusTone.ok);
      case 'sin_datos':
        return const StatusPill('Faltan datos', tone: StatusTone.danger);
      default:
        return const StatusPill('Pendiente', tone: StatusTone.warn);
    }
  }

  Widget _accion(FiscalDoc d) {
    // Un documento con datos faltantes se completa antes de poder exportarse.
    if (d.estado == 'sin_datos') {
      return TextButton(
        onPressed: _busy
            ? null
            : () async {
                await showFacturaCapture(context, ref, docToComplete: d);
                await _loadDocs();
              },
        child: const Text('Completar'),
      );
    }
    return TextButton(
      onPressed: _busy
          ? null
          : () => _exportar(
                build: () =>
                    ref.read(fiscalExportServiceProvider).exportDoc(d.id),
                nombre: 'cfdi-${d.tipo}-${d.id}',
              ),
      child: const Text('Exportar'),
    );
  }
}
