import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/employees_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Paleta categórica de la marca para las gráficas — reemplaza los
/// `Colors.blue/red/...` genéricos por los tonos de La Tercia, en un orden con
/// buen contraste entre vecinos.
const _chartColors = <Color>[
  LaTerciaColors.burntOrange,
  LaTerciaColors.gold,
  LaTerciaColors.catFria,
  LaTerciaColors.catExtra,
  LaTerciaColors.catPostre,
  LaTerciaColors.delivery,
  LaTerciaColors.goldDark,
  LaTerciaColors.cocoa,
];

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        backgroundColor: LaTerciaColors.appBg,
        appBar: AppBar(
          backgroundColor: LaTerciaColors.cream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 20,
          title: const Text('Reportes',
              style: TextStyle(
                  fontFamily: 'DM Serif Display',
                  fontSize: 24,
                  color: LaTerciaColors.darkBrown)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              alignment: Alignment.centerLeft,
              color: LaTerciaColors.cream,
              child: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: LaTerciaColors.burntOrange,
                unselectedLabelColor: LaTerciaColors.tan,
                indicatorColor: LaTerciaColors.burntOrange,
                indicatorWeight: 2.5,
                dividerColor: LaTerciaColors.border,
                labelStyle:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                unselectedLabelStyle:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                tabs: [
                  Tab(text: 'Diario'),
                  Tab(text: 'Semanal'),
                  Tab(text: 'Mensual'),
                  Tab(text: 'Por categoría'),
                  Tab(text: 'Por empleado'),
                  Tab(text: 'Método de pago'),
                  Tab(text: 'Productos top'),
                  Tab(text: 'Antifraude'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _DailyTab(symbol: symbol),
            _WeeklyTab(symbol: symbol),
            _MonthlyTab(symbol: symbol),
            _CategoryTab(symbol: symbol),
            _EmployeeTab(symbol: symbol),
            _PaymentMethodTab(symbol: symbol),
            _TopProductsTab(symbol: symbol),
            const _AntifraudTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets reutilizables de la marca ───────────────────────────────────────

/// Envoltura de panel: card cremita con borde suave y padding consistente.
class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LaTerciaColors.creamAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LaTerciaColors.border),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _PanelTitle(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: LaTerciaColors.darkBrown)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12.5, color: LaTerciaColors.tan)),
        ],
      ],
    );
  }
}

/// Tarjeta KPI: etiqueta en mayúsculas + valor grande en serif.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = LaTerciaColors.burntOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LaTerciaColors.creamAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LaTerciaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 14),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: LaTerciaColors.tan)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'DM Serif Display',
                  fontSize: 26,
                  color: LaTerciaColors.darkBrown)),
        ],
      ),
    );
  }
}

/// Fila de desglose con barra de proporción — reemplaza los DataTable pelados.
class _BreakdownRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double fraction; // 0..1 respecto al máximo
  final Color color;
  const _BreakdownRow({
    required this.label,
    required this.valueText,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LaTerciaColors.cocoa)),
              ),
              Text(valueText,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LaTerciaColors.darkBrown,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: LaTerciaColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _loading() =>
    const Center(child: CircularProgressIndicator(color: LaTerciaColors.gold));

Widget _empty(String msg) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart_rounded,
              size: 44, color: LaTerciaColors.tanLight),
          const SizedBox(height: 10),
          Text(msg,
              style: const TextStyle(
                  color: LaTerciaColors.tan, fontSize: 15)),
        ],
      ),
    );

/// Leyenda + donut para las gráficas de proporción.
class _Donut extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final String symbol;
  const _Donut({required this.entries, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final total = entries.fold(0.0, (a, e) => a + e.value);
    final maxV = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    final chart = SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 52,
          sectionsSpace: 2,
          sections: entries.asMap().entries.map((e) {
            return PieChartSectionData(
              value: e.value.value,
              title: '',
              color: _chartColors[e.key % _chartColors.length],
              radius: 34,
            );
          }).toList(),
        ),
      ),
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.asMap().entries.map((e) {
        final pct = total > 0 ? (e.value.value / total * 100) : 0;
        return _BreakdownRow(
          label: e.value.key,
          valueText:
              '${formatCurrency(e.value.value, symbol)} · ${pct.toStringAsFixed(0)}%',
          fraction: maxV > 0 ? e.value.value / maxV : 0,
          color: _chartColors[e.key % _chartColors.length],
        );
      }).toList(),
    );

    return LayoutBuilder(builder: (ctx, c) {
      if (c.maxWidth > 640) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 220, child: chart),
            const SizedBox(width: 24),
            Expanded(child: legend),
          ],
        );
      }
      return Column(children: [chart, const SizedBox(height: 12), legend]);
    });
  }
}

// ─── Tab: Diario ─────────────────────────────────────────────────────────────

class _DailyTab extends ConsumerStatefulWidget {
  final String symbol;
  const _DailyTab({required this.symbol});

  @override
  ConsumerState<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<_DailyTab> {
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final start = DateTime(_date.year, _date.month, _date.day);
    final end = start.add(const Duration(days: 1));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 17),
          label: Text(formatDate(_date)),
          style: OutlinedButton.styleFrom(
            foregroundColor: LaTerciaColors.cocoa,
            side: const BorderSide(color: LaTerciaColors.border),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (d != null) setState(() => _date = d);
          },
        ),
        const SizedBox(height: 18),
        FutureBuilder<Map<String, dynamic>>(
          future: _loadData(start, end),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                  padding: EdgeInsets.only(top: 60), child: _LoadingBox());
            }
            final d = snapshot.data!;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _StatCard(
                    label: 'Ingresos',
                    value: formatCurrency(d['revenue'], widget.symbol),
                    icon: Icons.payments_outlined),
                _StatCard(
                    label: 'Órdenes',
                    value: '${d['orders']}',
                    icon: Icons.receipt_long_outlined,
                    accent: LaTerciaColors.catFria),
                _StatCard(
                    label: 'Ticket promedio',
                    value: formatCurrency(d['avg'], widget.symbol),
                    icon: Icons.trending_up,
                    accent: LaTerciaColors.catExtra),
                _StatCard(
                    label: 'Producto estrella',
                    value: d['top'] as String,
                    icon: Icons.star_outline,
                    accent: LaTerciaColors.gold),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _loadData(DateTime from, DateTime to) async {
    final db = ref.read(databaseProvider);
    final revenue = await db.reportsDao.getTotalRevenueForRange(from, to);
    final count = await db.reportsDao.getOrderCountForRange(from, to);
    final top = await db.reportsDao.getTopProductsToday();
    return {
      'revenue': revenue,
      'orders': count,
      'avg': count > 0 ? revenue / count : 0.0,
      'top': top.isNotEmpty ? top.keys.first : '—',
    };
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) => _loading();
}

// ─── Tab: Semanal ────────────────────────────────────────────────────────────

class _WeeklyTab extends ConsumerWidget {
  final String symbol;
  const _WeeklyTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: ref.read(databaseProvider).reportsDao.getDailyRevenueLast7Days(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return _loading();
        final entries = snapshot.data!.entries.toList();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelTitle('Ingresos últimos 7 días'),
                const SizedBox(height: 20),
                SizedBox(
                  height: 260,
                  child: _brandBarChart(
                    context,
                    entries,
                    color: LaTerciaColors.burntOrange,
                    symbol: symbol,
                    bottomLabel: (i) => entries[i].key,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab: Mensual ────────────────────────────────────────────────────────────

class _MonthlyTab extends ConsumerWidget {
  final String symbol;
  const _MonthlyTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: _loadMonthly(ref),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return _loading();
        final entries = snapshot.data!.entries.toList();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelTitle('Ingresos mensuales',
                    subtitle: '${DateTime.now().year}'),
                const SizedBox(height: 20),
                SizedBox(
                  height: 260,
                  child: _brandBarChart(
                    context,
                    entries,
                    color: LaTerciaColors.goldDark,
                    symbol: symbol,
                    bottomLabel: (i) => entries[i].key,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, double>> _loadMonthly(WidgetRef ref) async {
    final months = <String, double>{};
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    const monthNames = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    for (int m = 1; m <= now.month; m++) {
      final start = DateTime(now.year, m);
      final end = DateTime(now.year, m + 1);
      months[monthNames[m - 1]] =
          await db.reportsDao.getTotalRevenueForRange(start, end);
    }
    return months;
  }
}

/// Gráfica de barras con el estilo de la marca (barras redondeadas, grid tenue).
Widget _brandBarChart(
  BuildContext context,
  List<MapEntry<String, double>> entries, {
  required Color color,
  required String symbol,
  required String Function(int) bottomLabel,
}) {
  if (entries.isEmpty) return _empty('Sin datos en el periodo');
  final maxV = entries.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxV == 0 ? 1 : maxV * 1.2,
      barGroups: entries
          .asMap()
          .entries
          .map((e) => BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: color,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ]))
          .toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= entries.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(bottomLabel(i),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LaTerciaColors.tan)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            getTitlesWidget: (v, _) => Text(
                formatCurrency(v, symbol, decimals: 0),
                style: const TextStyle(
                    fontSize: 10, color: LaTerciaColors.tanLight)),
          ),
        ),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(
            color: LaTerciaColors.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => LaTerciaColors.darkBrown,
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            formatCurrency(rod.toY, symbol),
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ),
  );
}

// ─── Tab: Por categoría ──────────────────────────────────────────────────────

class _CategoryTab extends ConsumerWidget {
  final String symbol;
  const _CategoryTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: ref.read(databaseProvider).reportsDao.getSalesByCategory(
          DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return _loading();
        final data = snapshot.data!;
        if (data.isEmpty) return _empty('Sin ventas en los últimos 30 días');
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Ventas por categoría',
                      subtitle: 'Últimos 30 días'),
                  const SizedBox(height: 18),
                  _Donut(entries: entries, symbol: symbol),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Tab: Por empleado ───────────────────────────────────────────────────────

class _EmployeeTab extends ConsumerWidget {
  final String symbol;
  const _EmployeeTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: ref.read(databaseProvider).reportsDao.getSalesByEmployee(
          DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return _loading();
        final data = snapshot.data!;
        if (data.isEmpty) return _empty('Sin ventas en los últimos 30 días');
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final maxV = entries.first.value;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Ventas por empleado',
                      subtitle: 'Últimos 30 días'),
                  const SizedBox(height: 6),
                  ...entries.asMap().entries.map((e) => _BreakdownRow(
                        label: e.value.key,
                        valueText: formatCurrency(e.value.value, symbol),
                        fraction: maxV > 0 ? e.value.value / maxV : 0,
                        color: _chartColors[e.key % _chartColors.length],
                      )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Tab: Método de pago ─────────────────────────────────────────────────────

class _PaymentMethodTab extends ConsumerWidget {
  final String symbol;
  const _PaymentMethodTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: ref.read(databaseProvider).reportsDao.getSalesByPaymentMethod(
          DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return _loading();
        final data = snapshot.data!;
        if (data.isEmpty) return _empty('Sin ventas en los últimos 30 días');
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Ventas por método de pago',
                      subtitle: 'Últimos 30 días'),
                  const SizedBox(height: 18),
                  _Donut(entries: entries, symbol: symbol),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Tab: Productos top ──────────────────────────────────────────────────────

class _TopProductsTab extends ConsumerWidget {
  final String symbol;
  const _TopProductsTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, int>>(
      future: ref.read(databaseProvider).reportsDao.getTopProductsToday(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return _loading();
        final entries = snapshot.data!.entries.toList();
        if (entries.isEmpty) return _empty('Sin ventas hoy');
        final maxV = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Productos más vendidos',
                      subtitle: 'Hoy · por unidades'),
                  const SizedBox(height: 6),
                  ...entries.asMap().entries.map((e) => _BreakdownRow(
                        label: e.value.key,
                        valueText: '${e.value.value} u',
                        fraction: maxV > 0 ? e.value.value / maxV : 0,
                        color: _chartColors[e.key % _chartColors.length],
                      )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Tab: Antifraude ─────────────────────────────────────────────────────────

/// 2.6 — anulaciones por empleado + aperturas de gaveta sin venta, ambas
/// derivadas de `audit_log`.
class _AntifraudTab extends ConsumerWidget {
  const _AntifraudTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider).valueOrNull ?? [];
    final empMap = {for (final e in employees) e.id: e.name};

    return FutureBuilder<List<List<AuditLogData>>>(
      future: Future.wait([
        ref.read(databaseProvider).auditLogDao.getByAction(
            PermissionAction.anular.key, limit: 1000),
        ref.read(databaseProvider).auditLogDao.getByAction(
            PermissionAction.abrirGavetaSinVenta.key, limit: 1000),
      ]),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return _loading();
        final cancellations = snapshot.data![0];
        final drawerOpens = snapshot.data![1];

        final byEmployee = <int?, int>{};
        for (final row in cancellations) {
          byEmployee[row.employeeId] = (byEmployee[row.employeeId] ?? 0) + 1;
        }
        final sorted = byEmployee.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final maxV = sorted.isEmpty
            ? 1
            : sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Anulaciones por empleado',
                      subtitle: 'Órdenes canceladas registradas en auditoría'),
                  const SizedBox(height: 6),
                  if (sorted.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Sin anulaciones registradas.',
                          style: TextStyle(color: LaTerciaColors.tan)),
                    )
                  else
                    ...sorted.asMap().entries.map((e) => _BreakdownRow(
                          label: e.value.key == null
                              ? 'Desconocido'
                              : (empMap[e.value.key] ??
                                  'Empleado #${e.value.key}'),
                          valueText: '${e.value.value}',
                          fraction: maxV > 0 ? e.value.value / maxV : 0,
                          color: LaTerciaColors.catPostre,
                        )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Aperturas de gaveta sin venta'),
                  const SizedBox(height: 10),
                  if (drawerOpens.isEmpty)
                    const Text('Sin registros.',
                        style: TextStyle(color: LaTerciaColors.tan))
                  else
                    ...drawerOpens.map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: LaTerciaColors.gold, size: 19),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                    empMap[r.employeeId] ?? 'Desconocido',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: LaTerciaColors.cocoa)),
                              ),
                              Text(formatDateTime(r.ts),
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: LaTerciaColors.tan)),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
