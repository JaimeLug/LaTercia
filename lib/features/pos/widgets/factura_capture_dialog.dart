import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/fiscal_service.dart';
import '../../../core/services/sat_catalog_service.dart';

/// Captura/edita los datos fiscales del receptor. Dos modos:
/// - **crear** ([order] != null): tras cobrar, congela la factura individual.
///   Si se guarda sin RFC, queda marcada "faltan datos".
/// - **completar** ([docToComplete] != null): llena los datos de un documento
///   que quedó `sin_datos`, dejándolo listo para exportar.
/// `docs/facturacion.md` §"Flujo A".
Future<void> showFacturaCapture(
  BuildContext context,
  WidgetRef ref, {
  Order? order,
  FiscalDoc? docToComplete,
}) {
  assert((order == null) != (docToComplete == null),
      'Pasa exactamente uno: order (crear) o docToComplete (completar).');
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FacturaCaptureDialog(order: order, doc: docToComplete),
  );
}

class _FacturaCaptureDialog extends ConsumerStatefulWidget {
  const _FacturaCaptureDialog({this.order, this.doc});
  final Order? order;
  final FiscalDoc? doc;

  @override
  ConsumerState<_FacturaCaptureDialog> createState() =>
      _FacturaCaptureDialogState();
}

class _FacturaCaptureDialogState extends ConsumerState<_FacturaCaptureDialog> {
  final _rfc = TextEditingController();
  final _razon = TextEditingController();
  final _cp = TextEditingController();
  String? _regimen, _uso = 'G03';
  List<SatEntry> _regimenes = const [], _usos = const [];
  bool _saving = false;

  bool get _isComplete => widget.doc != null;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final cat = ref.read(satCatalogServiceProvider);
    final regs = await cat.regimenesFiscales();
    final usos = await cat.usosCfdi();

    if (_isComplete) {
      // Modo completar: prellena con lo que ya tenga el documento.
      final d = widget.doc!;
      _rfc.text = d.receptorRfc ?? '';
      _razon.text = d.receptorRazonSocial ?? '';
      _cp.text = d.receptorCpFiscal ?? '';
      _regimen = d.receptorRegimen;
      _uso = d.receptorUsoCfdi ?? 'G03';
    } else if (widget.order?.customerId != null) {
      // Modo crear: prellena con los datos fiscales del cliente de la orden.
      final db = ref.read(databaseProvider);
      final cli = await (db.select(db.customers)
            ..where((t) => t.id.equals(widget.order!.customerId!)))
          .getSingleOrNull();
      if (cli != null) {
        _rfc.text = cli.rfc ?? '';
        _razon.text = cli.razonSocial ?? '';
        _cp.text = cli.cpFiscal ?? '';
        _regimen = cli.regimenFiscal;
        _uso = cli.usoCfdiPreferido ?? 'G03';
      }
    }
    if (!mounted) return;
    setState(() {
      _regimenes = regs;
      _usos = usos;
    });
  }

  @override
  void dispose() {
    _rfc.dispose();
    _razon.dispose();
    _cp.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final fiscal = ref.read(fiscalServiceProvider);
    String? nn(String s) => s.trim().isEmpty ? null : s.trim();
    final rfc = nn(_rfc.text)?.toUpperCase();
    final receptor = (
      rfc: rfc,
      razonSocial: nn(_razon.text),
      cpFiscal: nn(_cp.text),
      regimen: _regimen,
      usoCfdi: _uso,
    );

    int? customerId;
    if (_isComplete) {
      await fiscal.completarReceptor(widget.doc!.id, receptor);
      // Guarda en el cliente de la orden, si la tiene.
      final order = widget.doc!.orderId == null
          ? null
          : await db.ordersDao.getOrderById(widget.doc!.orderId!);
      customerId = order?.customerId;
    } else {
      await fiscal.freezeIndividual(
        orderId: widget.order!.id,
        receptor: receptor,
        usoCfdi: _uso ?? 'G03',
      );
      customerId = widget.order!.customerId;
    }

    // Guarda los datos fiscales en el cliente para la próxima vez.
    if (customerId != null) {
      await (db.update(db.customers)..where((t) => t.id.equals(customerId!)))
          .write(CustomersCompanion(
        rfc: Value(rfc),
        razonSocial: Value(nn(_razon.text)),
        cpFiscal: Value(nn(_cp.text)),
        regimenFiscal: Value(_regimen),
        usoCfdiPreferido: Value(_uso),
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String? optValue(List<SatEntry> opts, String? v) =>
        opts.any((e) => e.id == v) ? v : null;
    final sinRfc = _rfc.text.trim().isEmpty;
    return AlertDialog(
      title: Text(
          _isComplete ? 'Completar datos de factura' : 'Datos para factura'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Prellenado CFDI. NO es una factura válida hasta que tu '
                  'facturador la timbre. Puedes guardar sin datos y completarlos '
                  'después.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rfc,
                decoration: const InputDecoration(labelText: 'RFC'),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _razon,
                decoration:
                    const InputDecoration(labelText: 'Razón social / Nombre'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cp,
                decoration: const InputDecoration(labelText: 'CP fiscal'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: optValue(_regimenes, _regimen),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Régimen fiscal'),
                items: [
                  for (final r in _regimenes)
                    DropdownMenuItem(
                        value: r.id,
                        child: Text('${r.id} · ${r.texto}',
                            overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _regimen = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: optValue(_usos, _uso),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Uso de CFDI'),
                items: [
                  for (final u in _usos)
                    DropdownMenuItem(
                        value: u.id,
                        child: Text('${u.id} · ${u.texto}',
                            overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _uso = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(_isComplete ? 'Cancelar' : 'No facturar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _guardar,
          child: Text(
              sinRfc && !_isComplete ? 'Guardar (faltan datos)' : 'Guardar'),
        ),
      ],
    );
  }
}
