import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/backup_helper.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/admin_panel.dart';

const _panelTitleStyle = TextStyle(
    fontWeight: FontWeight.w700, fontSize: 15, color: LaTerciaColors.darkBrown);

/// Pantalla dedicada al dueño (no a los cajeros) para manejar la base de
/// datos por completo desde la app: respaldo/restauración `.db` (el único
/// formato de restauración real — ver `PLAN_ACTUALIZACION_GRANDE_2026-07.md`),
/// más exportación de tablas elegidas a `.sql`/`.xlsx` para reportes o
/// revisar datos específicos. Antes el backup automático vivía en
/// Configuración → Respaldo; se mudó aquí para que todo esté en un solo lugar.
class BackupsScreen extends ConsumerStatefulWidget {
  const BackupsScreen({super.key});

  @override
  ConsumerState<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends ConsumerState<BackupsScreen> {
  bool _backupAuto = true;
  late TextEditingController _retentionDays;
  bool _settingsLoaded = false;

  List<BackupInfo> _history = [];
  bool _historyLoading = true;

  // Todas marcadas por defecto — "quiero toda la base" es el caso más común.
  final Set<String> _selectedTables = {...BackupService.exportableTables.keys};

  // Restauración parcial: grupo elegido en el desplegable.
  String _restoreGroup = BackupService.restoreGroups.keys.first;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _retentionDays = TextEditingController();
    _loadHistory();
  }

  @override
  void dispose() {
    _retentionDays.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await ref.read(backupServiceProvider).listBackups();
    if (mounted) {
      setState(() {
        _history = list;
        _historyLoading = false;
      });
    }
  }

  void _loadAutoSettingsOnce(Map<String, String> s) {
    if (_settingsLoaded) return;
    _settingsLoaded = true;
    _backupAuto = s['backup_auto'] != 'false';
    _retentionDays.text = s['backup_retention_days'] ?? '14';
  }

  Future<void> _saveAutoSettings() async {
    await ref
        .read(settingsProvider.notifier)
        .setSetting('backup_auto', _backupAuto.toString());
    final v = _retentionDays.text.trim();
    await ref
        .read(settingsProvider.notifier)
        .setSetting('backup_retention_days', v.isEmpty ? '14' : v);
  }

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    final file =
        await ref.read(backupServiceProvider).backupNow(reason: 'manual');
    await _loadHistory();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(file != null
          ? 'Respaldo creado.'
          : 'No se pudo crear el respaldo — revisa el log.'),
    ));
  }

  Future<void> _exportSql() async {
    if (_selectedTables.isEmpty) return;
    setState(() => _busy = true);
    final sql = await ref
        .read(backupServiceProvider)
        .exportSql(tables: _selectedTables.toList());
    if (mounted) setState(() => _busy = false);

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar exportación SQL',
      fileName: 'latercia-export-$date.sql',
      type: FileType.custom,
      allowedExtensions: ['sql'],
    );
    if (result == null) return;
    await File(result).writeAsString(sql);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exportado: $result')));
    }
  }

  Future<void> _exportXlsx() async {
    if (_selectedTables.isEmpty) return;
    setState(() => _busy = true);
    final bytes = await ref
        .read(backupServiceProvider)
        .exportXlsxBytes(tables: _selectedTables.toList());
    if (mounted) setState(() => _busy = false);

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar exportación Excel',
      fileName: 'latercia-export-$date.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null) return;
    await File(result).writeAsBytes(bytes);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exportado: $result')));
    }
  }

  /// Exporta las tablas elegidas a un `.db` parcial (esquema + filas). Este sí
  /// se puede traer a otro equipo con "Restaurar solo una parte".
  Future<void> _exportDb() async {
    if (_selectedTables.isEmpty) return;
    setState(() => _busy = true);
    final bytes = await ref
        .read(backupServiceProvider)
        .exportDbBytes(tables: _selectedTables.toList());
    if (mounted) setState(() => _busy = false);

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar .db por partes',
      fileName: 'latercia-partes-$date.db',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result == null) return;
    await File(result).writeAsBytes(bytes);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exportado: $result')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings != null) _loadAutoSettingsOnce(settings);

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Backups'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _autoBackupPanel(),
                const SizedBox(height: 16),
                _dbPanel(),
                const SizedBox(height: 16),
                _partialRestorePanel(),
                const SizedBox(height: 16),
                _historyPanel(),
                const SizedBox(height: 16),
                _exportPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoBackupPanel() {
    return AdminPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Backup automático'),
            subtitle: const Text('Uno al día y al cerrar turno.'),
            value: _backupAuto,
            onChanged: (v) {
              setState(() => _backupAuto = v);
              _saveAutoSettings();
            },
            contentPadding: EdgeInsets.zero,
          ),
          if (_backupAuto) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _retentionDays,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Días de retención',
                      helperText: '0 = no borrar',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _saveAutoSettings,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dbPanel() {
    return AdminPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Base de datos completa (.db)', style: _panelTitleStyle),
          const SizedBox(height: 4),
          const Text(
            'El único formato que se puede restaurar. Úsalo para respaldos '
            'reales o para mover la base a otro equipo.',
            style: TextStyle(fontSize: 12.5, color: LaTerciaColors.tan),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Respaldar ahora'),
                onPressed: _busy ? null : _backupNow,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Descargar backup'),
                onPressed: () =>
                    downloadBackup(context, ref.read(databaseProvider)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Restaurar todo'),
                onPressed: () => restoreBackup(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _partialRestorePanel() {
    return AdminPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Restaurar solo una parte', style: _panelTitleStyle),
          const SizedBox(height: 4),
          const Text(
            'Trae solo un grupo de datos desde un archivo .db (ej. solo '
            'Clientes o solo Catálogo), sin tocar el resto. Operación '
            '(ventas, turnos, pagos) no se restaura por partes — para eso usa '
            '"Restaurar todo".',
            style: TextStyle(fontSize: 12.5, color: LaTerciaColors.tan),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: _restoreGroup,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Grupo a restaurar',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final g in BackupService.restoreGroups.keys)
                      DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged:
                      _busy ? null : (v) => setState(() => _restoreGroup = v!),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.rule),
                label: const Text('Elegir .db y revisar'),
                onPressed: _busy ? null : _pickAndPreviewRestore,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Elige un `.db`, compara contra la base actual y abre el asistente de
  /// fusión. Todo el I/O pesado (abrir el `.db`, comparar) corre aquí; el
  /// diálogo solo decide y luego llama a `applyGroupRestore`.
  Future<void> _pickAndPreviewRestore() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Elegir respaldo .db',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;

    setState(() => _busy = true);
    List<RestoreRowDiff> diffs;
    try {
      diffs = await ref
          .read(backupServiceProvider)
          .previewGroupRestore(backupPath: path, group: _restoreGroup);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo leer el archivo: $e'),
        ));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    final applied = await showDialog<RestoreApplyResult>(
      context: context,
      builder: (_) => _RestoreWizardDialog(
        group: _restoreGroup,
        diffs: diffs,
        service: ref.read(backupServiceProvider),
        backupPath: path,
      ),
    );
    if (applied != null) {
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Restauración aplicada: ${applied.added} agregadas, '
              '${applied.updated} actualizadas, ${applied.kept} mantenidas.'),
        ));
      }
    }
  }

  Widget _historyPanel() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
            child:
                Text('Historial de respaldos (.db)', style: _panelTitleStyle),
          ),
          if (_historyLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: CircularProgressIndicator(color: LaTerciaColors.gold)),
            )
          else if (_history.isEmpty)
            const AdminEmptyState(
              icon: Icons.backup_outlined,
              message: 'Aún no hay respaldos locales.',
            )
          else ...[
            const AdminHeaderRow(cells: [
              Expanded(flex: 3, child: Text('FECHA')),
              Expanded(flex: 2, child: Text('TAMAÑO')),
            ]),
            for (var i = 0; i < _history.length; i++)
              AdminRow(
                isLast: i == _history.length - 1,
                cells: [
                  Expanded(
                      flex: 3,
                      child: Text(formatDateTime(_history[i].modified))),
                  Expanded(
                      flex: 2, child: Text(_humanSize(_history[i].sizeBytes))),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _exportPanel() {
    return AdminPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exportar', style: _panelTitleStyle),
          const SizedBox(height: 4),
          const Text(
            'Elige qué tablas incluir. .sql y .xlsx son para reportes o revisar '
            'datos (no se reimportan). El .db por partes SÍ se puede traer a '
            'otro equipo con "Restaurar solo una parte".',
            style: TextStyle(fontSize: 12.5, color: LaTerciaColors.tan),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _selectedTables
                    ..clear()
                    ..addAll(BackupService.exportableTables.keys);
                }),
                child: const Text('Seleccionar todo'),
              ),
              TextButton(
                onPressed: () => setState(_selectedTables.clear),
                child: const Text('Ninguno'),
              ),
            ],
          ),
          for (final group in BackupService.exportGroups.entries) ...[
            const SizedBox(height: 4),
            Text(group.key,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: LaTerciaColors.darkBrown)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final table in group.value)
                  FilterChip(
                    label: Text(BackupService.exportableTables[table]!),
                    selected: _selectedTables.contains(table),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedTables.add(table);
                      } else {
                        _selectedTables.remove(table);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Text(
              '${_selectedTables.length} de '
              '${BackupService.exportableTables.length} tablas seleccionadas',
              style: const TextStyle(fontSize: 12, color: LaTerciaColors.tan)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.description_outlined),
                label: const Text('Exportar .sql'),
                onPressed:
                    (_busy || _selectedTables.isEmpty) ? null : _exportSql,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.grid_on_outlined),
                label: const Text('Exportar .xlsx'),
                onPressed:
                    (_busy || _selectedTables.isEmpty) ? null : _exportXlsx,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.dataset_outlined),
                label: const Text('Exportar .db (por partes)'),
                onPressed:
                    (_busy || _selectedTables.isEmpty) ? null : _exportDb,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _humanSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Etiqueta legible de una fila para el asistente de fusión — usa el primer
/// campo tipo "nombre" que tenga la fila, o el id como último recurso.
String _rowLabel(RestoreRowDiff d) {
  final v =
      d.status == RestoreRowStatus.nueva ? d.backupValues : d.currentValues;
  for (final key in ['name', 'orderNumber', 'description']) {
    final value = v[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return '#${d.id}';
}

/// Etiquetas en español para las columnas más comunes; el resto cae a una
/// versión "humanizada" del nombre técnico (guiones bajos → espacios).
const _columnLabels = <String, String>{
  'name': 'Nombre',
  'phone': 'Teléfono',
  'email': 'Correo',
  'notes': 'Notas',
  'visits': 'Visitas',
  'total_spent': 'Total gastado',
  'price': 'Precio',
  'cost': 'Costo',
  'description': 'Descripción',
  'sku': 'SKU',
  'stock_quantity': 'Stock',
  'min_stock': 'Stock mínimo',
  'available': 'Disponible',
  'active': 'Activo',
  'color': 'Color',
  'icon': 'Icono',
  'sort_order': 'Orden',
  'category_id': 'Categoría',
  'role': 'Rol',
  'pin': 'PIN',
  'unit': 'Unidad',
  'fee': 'Costo de envío',
  'capacity': 'Capacidad',
  'status': 'Estado',
  'value': 'Valor',
  'type': 'Tipo',
  'price_delta': 'Ajuste de precio',
  'tax_rate': 'IVA',
  'last_unit_cost': 'Último costo',
};

String _columnLabel(String col) {
  final known = _columnLabels[col];
  if (known != null) return known;
  final spaced = col.replaceAll('_', ' ');
  return spaced.isEmpty ? col : spaced[0].toUpperCase() + spaced.substring(1);
}

String _displayValue(Object? v) {
  if (v == null) return '—';
  if (v is List) return '(datos)';
  final s = v.toString();
  return s.isEmpty ? '—' : s;
}

/// Asistente de fusión para la restauración parcial. Deja al usuario:
/// (1) elegir modo Reemplazar vs Agregar; (2) en modo Agregar, resolver los
/// conflictos **columna por columna** — cada fila distinta se expande y, por
/// cada campo que cambió, elige el valor actual o el del respaldo. La fila
/// final puede quedar mezclada. Devuelve el [RestoreApplyResult] si se aplicó,
/// o null si se canceló.
class _RestoreWizardDialog extends StatefulWidget {
  const _RestoreWizardDialog({
    required this.group,
    required this.diffs,
    required this.service,
    required this.backupPath,
  });

  final String group;
  final List<RestoreRowDiff> diffs;
  final BackupService service;
  final String backupPath;

  @override
  State<_RestoreWizardDialog> createState() => _RestoreWizardDialogState();
}

class _RestoreWizardDialogState extends State<_RestoreWizardDialog> {
  // false = Agregar/fusionar (default, seguro); true = Reemplazar.
  bool _replace = false;
  bool _applying = false;

  // Decisión por columna de cada fila "diferente": 'tabla:id' → {columna →
  // decisión}. Default (sin entrada) = mantener el valor actual.
  final Map<String, Map<String, RestoreDecision>> _colDecisions = {};

  List<RestoreRowDiff> get _conflicts => widget.diffs
      .where((d) => d.status == RestoreRowStatus.diferente)
      .toList();

  int get _nuevas =>
      widget.diffs.where((d) => d.status == RestoreRowStatus.nueva).length;
  int get _iguales =>
      widget.diffs.where((d) => d.status == RestoreRowStatus.igual).length;

  /// Columnas de [d] que realmente cambiaron (sin `id`) — las únicas que hay
  /// que decidir; el resto son iguales en ambos lados.
  List<String> _differingColumns(RestoreRowDiff d) => d.currentValues.keys
      .where(
          (c) => c != 'id' && _changed(d.currentValues[c], d.backupValues[c]))
      .toList();

  bool _changed(Object? a, Object? b) {
    if (a is List && b is List) return !listEquals(a, b);
    return a != b;
  }

  RestoreDecision _decisionFor(String rowKey, String col) =>
      _colDecisions[rowKey]?[col] ?? RestoreDecision.mantenerActual;

  void _setDecision(String rowKey, String col, RestoreDecision d) {
    setState(() => (_colDecisions[rowKey] ??= {})[col] = d);
  }

  /// Arma las filas resueltas para el backend: solo las que tengan al menos
  /// una columna tomada del respaldo (las demás se mantienen intactas).
  Map<String, Map<String, Object?>> _resolvedRows() {
    final resolved = <String, Map<String, Object?>>{};
    for (final d in _conflicts) {
      final rowKey = '${d.table}:${d.id}';
      final cols = _differingColumns(d);
      final usesBackup = cols
          .any((c) => _decisionFor(rowKey, c) == RestoreDecision.usarRespaldo);
      if (!usesBackup) continue;
      final merged = <String, Object?>{...d.currentValues};
      for (final c in cols) {
        if (_decisionFor(rowKey, c) == RestoreDecision.usarRespaldo) {
          merged[c] = d.backupValues[c];
        }
      }
      resolved[rowKey] = merged;
    }
    return resolved;
  }

  void _setRowAll(RestoreRowDiff d, RestoreDecision decision) {
    final rowKey = '${d.table}:${d.id}';
    setState(() {
      final map = _colDecisions[rowKey] ??= {};
      for (final c in _differingColumns(d)) {
        map[c] = decision;
      }
    });
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final result = await widget.service.applyGroupRestore(
        backupPath: widget.backupPath,
        group: widget.group,
        replace: _replace,
        resolvedRows: _replace ? const {} : _resolvedRows(),
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        setState(() => _applying = false);
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('No se pudo restaurar'),
            content: Text(
                'La operación se canceló y la base quedó igual que antes.\n\n'
                'Suele pasar al Reemplazar un grupo que sigue en uso (ej. un '
                'producto con ventas). Prueba con "Agregar" en su lugar.\n\n$e'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Restaurar: ${widget.group}'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_nuevas nuevas · $_iguales iguales · '
              '${_conflicts.length} distintas',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: LaTerciaColors.cocoa),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    icon: Icon(Icons.merge),
                    label: Text('Agregar')),
                ButtonSegment(
                    value: true,
                    icon: Icon(Icons.swap_horiz),
                    label: Text('Reemplazar')),
              ],
              selected: {_replace},
              onSelectionChanged:
                  _applying ? null : (s) => setState(() => _replace = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              _replace
                  ? 'Borra este grupo por completo y deja solo lo del archivo. '
                      'Se cancela sin cambios si algo sigue en uso.'
                  : 'Agrega lo que falte. Lo que ya existe se mantiene; en las '
                      'filas distintas, abre cada una y elige campo por campo.',
              style: const TextStyle(fontSize: 12.5, color: LaTerciaColors.tan),
            ),
            if (!_replace && _conflicts.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Filas distintas — elige campo por campo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final d in _conflicts) _conflictTile(d),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _applying ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _applying ? null : _apply,
          child: _applying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _conflictTile(RestoreRowDiff d) {
    final cols = _differingColumns(d);
    return Theme(
      // Quita las líneas divisorias que ExpansionTile pinta por defecto.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 4, bottom: 8),
        title: Text(
          '${BackupService.exportableTables[d.table] ?? d.table}: '
          '${_rowLabel(d)}',
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${cols.length} campo(s) distinto(s)',
            style: const TextStyle(fontSize: 12, color: LaTerciaColors.tan)),
        children: [
          Row(
            children: [
              TextButton(
                onPressed: _applying
                    ? null
                    : () => _setRowAll(d, RestoreDecision.mantenerActual),
                child: const Text('Todo actual'),
              ),
              TextButton(
                onPressed: _applying
                    ? null
                    : () => _setRowAll(d, RestoreDecision.usarRespaldo),
                child: const Text('Todo respaldo'),
              ),
            ],
          ),
          for (final c in cols) _columnDecisionRow(d, c),
        ],
      ),
    );
  }

  Widget _columnDecisionRow(RestoreRowDiff d, String col) {
    final rowKey = '${d.table}:${d.id}';
    final decision = _decisionFor(rowKey, col);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_columnLabel(col),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: LaTerciaColors.darkBrown)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _valueOption(
                  tag: 'Actual',
                  value: _displayValue(d.currentValues[col]),
                  selected: decision == RestoreDecision.mantenerActual,
                  onTap: () =>
                      _setDecision(rowKey, col, RestoreDecision.mantenerActual),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _valueOption(
                  tag: 'Respaldo',
                  value: _displayValue(d.backupValues[col]),
                  selected: decision == RestoreDecision.usarRespaldo,
                  onTap: () =>
                      _setDecision(rowKey, col, RestoreDecision.usarRespaldo),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueOption({
    required String tag,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _applying ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? LaTerciaColors.burntOrange.withValues(alpha: 0.12)
              : null,
          border: Border.all(
              color: selected
                  ? LaTerciaColors.burntOrange
                  : LaTerciaColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 14,
                    color: selected
                        ? LaTerciaColors.burntOrange
                        : LaTerciaColors.tan),
                const SizedBox(width: 4),
                Text(tag,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? LaTerciaColors.burntOrange
                            : LaTerciaColors.tan)),
              ],
            ),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(fontSize: 12.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
