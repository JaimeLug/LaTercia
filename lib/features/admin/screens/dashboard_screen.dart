import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/admin_panel.dart';
import '../widgets/report_charts.dart';
import '../widgets/system_health_card.dart';

/// Dashboard — mismos widgets de marca que Reportes (`report_charts.dart`):
/// antes usaba `Card`/emojis/colores de Material genéricos y las gráficas de
/// barra no dejaban aire arriba de la barra más alta (se sentían "cortadas").
/// Feedback de sitio 2026-07-22: "no se ve profesional".
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final activeOrders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Una sola consulta combinada — antes cada card/gráfica disparaba
            // su propio FutureBuilder (varios spinners parpadeando en
            // momentos distintos, y "producto estrella" se consultaba dos
            // veces).
            FutureBuilder<_DashboardData>(
              future: _load(ref),
              builder: (ctx, snapshot) {
                final data = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid con quiebres explícitos (4 → 2×2 → 1×4) en vez de
                    // un `Wrap` libre — con Wrap, según el ancho exacto de la
                    // ventana el sobrante podía caer disparejo (3 en una fila
                    // + 1 solo en la siguiente); el grid siempre parte parejo.
                    // Feedback de sitio 2026-07-22.
                    _ResponsiveGrid(
                      children: [
                        StatCard(
                          label: 'Ventas hoy',
                          value: formatCurrency(data?.revenue ?? 0.0, symbol),
                          icon: Icons.payments_outlined,
                        ),
                        StatCard(
                          label: 'Órdenes hoy',
                          value: '${data?.orderCount ?? 0}',
                          icon: Icons.receipt_long_outlined,
                          accent: LaTerciaColors.catFria,
                        ),
                        StatCard(
                          label: 'Ticket promedio',
                          value: formatCurrency(data?.avgTicket ?? 0.0, symbol),
                          icon: Icons.trending_up,
                          accent: LaTerciaColors.catExtra,
                        ),
                        StatCard(
                          label: 'Producto estrella',
                          value: data?.topProduct ?? '—',
                          icon: Icons.star_outline,
                          accent: LaTerciaColors.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Cola en vivo — mismos tonos que StatusPill (orders_screen.dart):
                    // el color de estado es fijo/reservado, no se inventa uno nuevo aquí.
                    _ResponsiveGrid(
                      children: [
                        _QueueStat(
                          label: 'Pendiente',
                          count: activeOrders
                              .where((o) => o.order.status == 'pendiente')
                              .length,
                          tone: StatusTone.warn,
                        ),
                        _QueueStat(
                          label: 'En preparación',
                          count: activeOrders
                              .where((o) => o.order.status == 'en_preparacion')
                              .length,
                          tone: StatusTone.progress,
                        ),
                        _QueueStat(
                          label: 'Listo',
                          count: activeOrders
                              .where((o) => o.order.status == 'listo')
                              .length,
                          tone: StatusTone.ok,
                        ),
                        _QueueStat(
                          label: 'Entregado',
                          count: activeOrders
                              .where((o) => o.order.status == 'entregado')
                              .length,
                          tone: StatusTone.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (context, constraints) {
                      // Umbral más bajo que antes (900) para que las dos
                      // gráficas queden lado a lado en más tamaños de
                      // ventana comunes — solo se apilan en ventanas
                      // genuinamente angostas/cuadradas.
                      final stacked = constraints.maxWidth < 760;
                      final revenueCard = Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PanelTitle('Ventas últimos 7 días'),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 240,
                              child: data == null
                                  ? loadingChart()
                                  : brandBarChart(
                                      context,
                                      data.dailyRevenue.entries.toList(),
                                      color: LaTerciaColors.burntOrange,
                                      symbol: symbol,
                                      bottomLabel: (i) => data.dailyRevenue
                                          .entries
                                          .toList()[i]
                                          .key,
                                    ),
                            ),
                          ],
                        ),
                      );
                      final topProductsCard = Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PanelTitle('Top productos',
                                subtitle: 'Hoy · por unidades'),
                            const SizedBox(height: 6),
                            if (data == null)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: LaTerciaColors.gold)),
                              )
                            else if (data.topProducts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('Sin ventas hoy.',
                                    style: TextStyle(
                                        color: LaTerciaColors.tan)),
                              )
                            else
                              ...() {
                                final entries =
                                    data.topProducts.entries.toList();
                                final maxV = entries
                                    .map((e) => e.value)
                                    .reduce((a, b) => a > b ? a : b);
                                return entries
                                    .asMap()
                                    .entries
                                    .map((e) => BreakdownRow(
                                          label: e.value.key,
                                          valueText: '${e.value.value} u',
                                          fraction: maxV > 0
                                              ? e.value.value / maxV
                                              : 0,
                                          color: chartColors[
                                              e.key % chartColors.length],
                                        ));
                              }(),
                          ],
                        ),
                      );

                      if (stacked) {
                        return Column(
                          children: [
                            revenueCard,
                            const SizedBox(height: 16),
                            topProductsCard,
                          ],
                        );
                      }
                      // Sin `IntrinsicHeight`: a diferencia de `_ResponsiveGrid`
                      // (arriba), este Row usa CrossAxisAlignment.start, no
                      // stretch — no necesita un alto acotado para estirar
                      // hijos, así que no hay riesgo de "infinite height" aquí.
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: revenueCard),
                          const SizedBox(width: 16),
                          Expanded(child: topProductsCard),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const SystemHealthCard(),
          ],
        ),
      ),
    );
  }

  Future<_DashboardData> _load(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final results = await Future.wait([
      db.reportsDao.getTotalRevenueForRange(start, end),
      db.reportsDao.getOrderCountForRange(start, end),
      db.reportsDao.getTopProductsToday(),
      db.reportsDao.getDailyRevenueLast7Days(),
    ]);
    final revenue = results[0] as double;
    final orderCount = results[1] as int;
    final topProducts = results[2] as Map<String, int>;
    final dailyRevenue = results[3] as Map<String, double>;

    return _DashboardData(
      revenue: revenue,
      orderCount: orderCount,
      avgTicket: orderCount > 0 ? revenue / orderCount : 0.0,
      topProduct: topProducts.isNotEmpty ? topProducts.keys.first : '—',
      topProducts: topProducts,
      dailyRevenue: dailyRevenue,
    );
  }
}

class _DashboardData {
  final double revenue;
  final int orderCount;
  final double avgTicket;
  final String topProduct;
  final Map<String, int> topProducts;
  final Map<String, double> dailyRevenue;
  const _DashboardData({
    required this.revenue,
    required this.orderCount,
    required this.avgTicket,
    required this.topProduct,
    required this.topProducts,
    required this.dailyRevenue,
  });
}

/// Contador de la cola en vivo por estado — mismos tonos que `StatusPill`
/// (orders_screen.dart): el color de estado es fijo/reservado en la app, no
/// se inventa uno nuevo aquí.
class _QueueStat extends StatelessWidget {
  final String label;
  final int count;
  final StatusTone tone;
  const _QueueStat({
    required this.label,
    required this.count,
    required this.tone,
  });

  Color get _color => switch (tone) {
        StatusTone.warn => LaTerciaColors.gold,
        StatusTone.progress => LaTerciaColors.goldDark,
        StatusTone.ok => LaTerciaColors.success,
        StatusTone.info => LaTerciaColors.llevar,
        StatusTone.danger => LaTerciaColors.danger,
        StatusTone.neutral => LaTerciaColors.tan,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: LaTerciaColors.creamAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LaTerciaColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text('$count',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: LaTerciaColors.tan)),
        ],
      ),
    );
  }
}

/// Grid con quiebres explícitos — 4 en una fila si hay espacio, si no 2×2, si
/// no 1 columna — en vez de un `Wrap` libre que puede partir disparejo (3+1).
/// Genérico: se usa tanto para los KPI de arriba como para la cola en vivo.
class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  const _ResponsiveGrid({required this.children});

  static const _spacing = 14.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final perRow = constraints.maxWidth >= 680
          ? children.length
          : constraints.maxWidth >= 380
              ? (children.length / 2).ceil()
              : 1;
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += perRow) {
        final rowChildren = children.skip(i).take(perRow).toList();
        if (rows.isNotEmpty) rows.add(const SizedBox(height: _spacing));
        // IntrinsicHeight es obligatorio aquí: este Row vive dentro de un
        // SingleChildScrollView (alto no acotado), y `stretch` necesita un
        // alto acotado para poder estirar a los hijos — sin esto tira
        // "BoxConstraints forces an infinite height" desde el primer frame
        // (crash reportado en sitio 2026-07-22, sin relación con el resize).
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < rowChildren.length; j++) ...[
                if (j > 0) const SizedBox(width: _spacing),
                Expanded(child: rowChildren[j]),
              ],
            ],
          ),
        ));
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    });
  }
}
