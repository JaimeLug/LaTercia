import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/sat_catalog_service.dart';
import '../../../core/theme/app_theme.dart';

/// Abre el buscador de claves SAT y devuelve la elegida (o null si se canceló).
/// [search] consulta el catálogo por texto; [sugeridas] (opcional) da un acceso
/// rápido cuando el campo está vacío. `docs/facturacion.md` §"Catálogos SAT".
Future<SatEntry?> showSatClavePicker(
  BuildContext context, {
  required String titulo,
  required Future<List<SatEntry>> Function(String query) search,
  Future<List<SatEntry>> Function()? sugeridas,
}) {
  return showDialog<SatEntry>(
    context: context,
    builder: (_) => _SatClavePicker(
      titulo: titulo,
      search: search,
      sugeridas: sugeridas,
    ),
  );
}

class _SatClavePicker extends StatefulWidget {
  const _SatClavePicker({
    required this.titulo,
    required this.search,
    this.sugeridas,
  });

  final String titulo;
  final Future<List<SatEntry>> Function(String query) search;
  final Future<List<SatEntry>> Function()? sugeridas;

  @override
  State<_SatClavePicker> createState() => _SatClavePickerState();
}

class _SatClavePickerState extends State<_SatClavePicker> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<SatEntry> _results = const [];
  bool _loading = false;
  bool _mostrandoSugeridas = false;

  @override
  void initState() {
    super.initState();
    if (widget.sugeridas != null) _loadSugeridas();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadSugeridas() async {
    setState(() => _loading = true);
    final r = await widget.sugeridas!();
    if (!mounted) return;
    setState(() {
      _results = r;
      _mostrandoSugeridas = true;
      _loading = false;
    });
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    // Debounce para no consultar en cada tecla (búsqueda sobre 52k claves).
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(q));
  }

  Future<void> _run(String q) async {
    if (q.trim().isEmpty) {
      if (widget.sugeridas != null) {
        _loadSugeridas();
      } else {
        setState(() => _results = const []);
      }
      return;
    }
    setState(() {
      _loading = true;
      _mostrandoSugeridas = false;
    });
    final r = await widget.search(q);
    if (!mounted) return;
    setState(() {
      _results = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o clave…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onChanged,
            ),
            if (_mostrandoSugeridas)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sugeridas para cafetería',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LaTerciaColors.tan)),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? const Center(
                          child: Text('Sin resultados',
                              style: TextStyle(color: LaTerciaColors.tan)))
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final e = _results[i];
                            return ListTile(
                              dense: true,
                              title: Text(e.texto),
                              subtitle: Text(e.id),
                              onTap: () => Navigator.pop(context, e),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
