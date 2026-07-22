import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Kit de widgets compartido para las pantallas de listado del Admin
/// (Modificadores, Órdenes, Turnos, …): AppBar de marca, panel cremita, chip
/// de estado y estado vacío — reemplaza el look Material default (DataTable
/// pelado sobre fondo blanco) por el mismo lenguaje visual del POS/KDS/Reportes.

/// AppBar consistente para las pantallas de Admin: fondo cream, título en
/// serif, opcionalmente con acciones a la derecha. [leading] es para las
/// pantallas embebidas dentro de Configuración (Envío, Botonera, Quiosco,
/// Monitores, Backups): como se muestran con un cambio de estado (no un
/// `Navigator.push`), el botón "atrás" automático de Flutter no aparece solo
/// — hay que pasarlo explícito para volver a la cuadrícula de Configuración.
PreferredSizeWidget adminAppBar(String title,
    {List<Widget>? actions, Widget? leading}) {
  return AppBar(
    backgroundColor: LaTerciaColors.cream,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    titleSpacing: 20,
    leading: leading,
    title: Text(title,
        style: const TextStyle(
            fontFamily: 'DM Serif Display',
            fontSize: 24,
            color: LaTerciaColors.darkBrown)),
    actions: actions,
  );
}

/// Panel cremita con borde suave — la unidad visual base de estas pantallas.
class AdminPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AdminPanel(
      {super.key, required this.child, this.padding = const EdgeInsets.all(0)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: LaTerciaColors.creamAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LaTerciaColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Cabecera de columnas de una lista tipo tabla (fila con fondo tenue).
class AdminHeaderRow extends StatelessWidget {
  final List<Widget> cells;
  const AdminHeaderRow({super.key, required this.cells});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: const BoxDecoration(
        color: LaTerciaColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: LaTerciaColors.border)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: LaTerciaColors.tan),
        child: Row(children: cells),
      ),
    );
  }
}

/// Fila de datos, con hover sutil y separador inferior.
class AdminRow extends StatelessWidget {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool isLast;
  const AdminRow(
      {super.key, required this.cells, this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: LaTerciaColors.border)),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 13.5, color: LaTerciaColors.cocoa),
            child: Row(children: cells),
          ),
        ),
      ),
    );
  }
}

/// Pastilla de estado con color semántico — reemplaza el `Chip` Material
/// default. [tone] elige el color desde una paleta fija por nombre lógico.
class StatusPill extends StatelessWidget {
  final String label;
  final StatusTone tone;
  const StatusPill(this.label, {super.key, this.tone = StatusTone.neutral});

  @override
  Widget build(BuildContext context) {
    final c = _toneColor(tone);
    // Align(centerLeft) evita que el Container se estire a todo lo ancho
    // cuando esta pastilla va dentro de un Expanded/Row (el caso normal en
    // las tablas de Admin) — sin esto, el borde circular(100) solo se ve
    // redondeado en los extremos de una barra larga en vez de una pastilla.
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
      ),
    );
  }

  Color _toneColor(StatusTone t) {
    switch (t) {
      case StatusTone.warn:
        return LaTerciaColors.gold;
      case StatusTone.progress:
        return LaTerciaColors.goldDark;
      case StatusTone.ok:
        return LaTerciaColors.success;
      case StatusTone.info:
        return LaTerciaColors.llevar;
      case StatusTone.danger:
        return LaTerciaColors.danger;
      case StatusTone.neutral:
        return LaTerciaColors.tan;
    }
  }
}

enum StatusTone { neutral, warn, progress, ok, info, danger }

/// Estado vacío consistente: ícono + mensaje, centrado.
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const AdminEmptyState(
      {super.key, this.icon = Icons.inbox_outlined, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: LaTerciaColors.tanLight),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: LaTerciaColors.tan, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

Widget adminLoading() =>
    const Center(child: CircularProgressIndicator(color: LaTerciaColors.gold));

/// Caja de búsqueda consistente para las pantallas de Admin (filtra en vivo).
/// Lupa a la izquierda y botón ✕ para limpiar cuando hay texto. El filtrado
/// lo hace la pantalla en memoria; este widget solo captura el texto.
class AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        prefixIcon:
            const Icon(Icons.search, size: 20, color: LaTerciaColors.tan),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: LaTerciaColors.tan),
                tooltip: 'Limpiar',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

/// Tarjeta de categoría para landings tipo Ajustes (Configuración, Inventario):
/// ícono + título + subtítulo, tocable. Reusada por cualquier pantalla que
/// quiera un menú de tarjetas en vez de una lista larga.
class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Material(
        color: LaTerciaColors.creamAlt,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LaTerciaColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: LaTerciaColors.burntOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child:
                      Icon(icon, size: 21, color: LaTerciaColors.burntOrange),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: LaTerciaColors.darkBrown)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: LaTerciaColors.tan)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid responsivo de [CategoryCard]s (Configuración, Inventario): **mínimo 3
/// columnas siempre** — en vez de un `Wrap` libre de cards a ancho fijo
/// (230px), que en una ventana angosta puede caer a solo 2 por fila. Aquí las
/// cards se ACHICAN antes de bajar de 3 columnas, y se SUMAN columnas (4, 5,
/// 6…) conforme la ventana crece, en vez de dejarlas crecer sin límite.
/// Feedback de sitio 2026-07-22.
class CategoryCardGrid extends StatelessWidget {
  final List<Widget> children;
  const CategoryCardGrid({super.key, required this.children});

  static const _spacing = 14.0;
  static const _idealWidth = 230.0;
  static const _minColumns = 3;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final fitting =
          ((constraints.maxWidth + _spacing) / (_idealWidth + _spacing))
              .floor();
      final columns = children.length < _minColumns
          ? children.length
          : fitting.clamp(_minColumns, children.length);
      final cardWidth =
          (constraints.maxWidth - _spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: _spacing,
        runSpacing: _spacing,
        children: [
          for (final child in children)
            SizedBox(width: cardWidth, child: child),
        ],
      );
    });
  }
}
