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
import '../widgets/report_charts.dart';

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
              color: chartColors[e.key % chartColors.length],
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
        return BreakdownRow(
          label: e.value.key,
          valueText:
              '${formatCurrency(e.value.value, symbol)} · ${pct.toStringAsFixed(0)}%',
          fraction: maxV > 0 ? e.value.value / maxV : 0,
          color: chartColors[e.key % chartColors.length],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                StatCard(
                    label: 'Ingresos',
                    value: formatCurrency(d['revenue'], widget.symbol),
                    icon: Icons.payments_outlined),
                StatCard(
                    label: 'Órdenes',
                    value: '${d['orders']}',
                    icon: Icons.receipt_long_outlined,
                    accent: LaTerciaColors.catFria),
                StatCard(
                    label: 'Ticket promedio',
                    value: formatCurrency(d['avg'], widget.symbol),
                    icon: Icons.trending_up,
                    accent: LaTerciaColors.catExtra),
                StatCard(
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
  Widget build(BuildContext context) => loadingChart();
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
        if (!snapshot.hasData) return loadingChart();
        final entries = snapshot.data!.entries.toList();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Ingresos últimos 7 días'),
                const SizedBox(height: 20),
                SizedBox(
                  height: 260,
                  child: brandBarChart(
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
        if (!snapshot.hasData) return loadingChart();
        final entries = snapshot.data!.entries.toList();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelTitle('Ingresos mensuales',
                    subtitle: '${DateTime.now().year}'),
                const SizedBox(height: 20),
                SizedBox(
                  height: 260,
                  child: brandBarChart(
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
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
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
        if (!snapshot.hasData) return loadingChart();
        final data = snapshot.data!;
        if (data.isEmpty) return emptyChart('Sin ventas en los últimos 30 días');
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle('Ventas por categoría',
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
        if (!snapshot.hasData) return loadingChart();
        final data = snapshot.data!;
        if (data.isEmpty) return emptyChart('Sin ventas en los últimos 30 días');
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final maxV = entries.first.value;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle('Ventas por empleado',
                      subtitle: 'Últimos 30 días'),
                  const SizedBox(height: 6),
                  ...entries.asMap().entries.map((e) => BreakdownRow(
                        label: e.value.key,
                        valueText: formatCurrency(e.value.value, symbol),
                        fraction: maxV > 0 ? e.value.value / maxV : 0,
                        color: chartColors[e.key % chartColors.length],
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
        if (!snapshot.hasData) return loadingChart();
        final data = snapshot.data!;
        if (data.isEmpty) return emptyChart('Sin ventas en los últimos 30 días');
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle('Ventas por método de pago',
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
        if (!snapshot.hasData) return loadingChart();
        final entries = snapshot.data!.entries.toList();
        if (entries.isEmpty) return emptyChart('Sin ventas hoy');
        final maxV =
            entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle('Productos más vendidos',
                      subtitle: 'Hoy · por unidades'),
                  const SizedBox(height: 6),
                  ...entries.asMap().entries.map((e) => BreakdownRow(
                        label: e.value.key,
                        valueText: '${e.value.value} u',
                        fraction: maxV > 0 ? e.value.value / maxV : 0,
                        color: chartColors[e.key % chartColors.length],
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
        ref
            .read(databaseProvider)
            .auditLogDao
            .getByAction(PermissionAction.anular.key, limit: 1000),
        ref
            .read(databaseProvider)
            .auditLogDao
            .getByAction(PermissionAction.abrirGavetaSinVenta.key, limit: 1000),
      ]),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return loadingChart();
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
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle('Anulaciones por empleado',
                      subtitle: 'Órdenes canceladas registradas en auditoría'),
                  const SizedBox(height: 6),
                  if (sorted.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Sin anulaciones registradas.',
                          style: TextStyle(color: LaTerciaColors.tan)),
                    )
                  else
                    ...sorted.asMap().entries.map((e) => BreakdownRow(
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
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle('Aperturas de gaveta sin venta'),
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
