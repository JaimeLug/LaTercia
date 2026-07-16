import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/employees_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/formatters.dart';

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
        appBar: AppBar(
          title: const Text('Reportes'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Diario'),
              Tab(text: 'Semanal'),
              Tab(text: 'Mensual'),
              Tab(text: 'Por categoría'),
              Tab(text: 'Por empleado'),
              Tab(text: 'Por método de pago'),
              Tab(text: 'Productos top'),
              Tab(text: 'Antifraude'),
            ],
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

/// 2.6 — anulaciones por empleado + aperturas de gaveta sin venta, ambas
/// derivadas de `audit_log`. La gaveta aún no existe (Fase 3), así que esa
/// lista aparecerá vacía hasta entonces — es el comportamiento esperado, no
/// un bug.
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
            .getByAction(
                PermissionAction.abrirGavetaSinVenta.key, limit: 1000),
      ]),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cancellations = snapshot.data![0];
        final drawerOpens = snapshot.data![1];

        final byEmployee = <int?, int>{};
        for (final row in cancellations) {
          byEmployee[row.employeeId] = (byEmployee[row.employeeId] ?? 0) + 1;
        }
        final sorted = byEmployee.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Anulaciones por empleado',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (sorted.isEmpty)
              const Text('Sin anulaciones registradas.',
                  style: TextStyle(color: Colors.grey))
            else
              DataTable(
                columns: const [
                  DataColumn(label: Text('Empleado')),
                  DataColumn(label: Text('Anulaciones')),
                ],
                rows: sorted
                    .map((e) => DataRow(cells: [
                          DataCell(Text(e.key == null
                              ? 'Desconocido'
                              : (empMap[e.key] ?? 'Empleado #${e.key}'))),
                          DataCell(Text('${e.value}')),
                        ]))
                    .toList(),
              ),
            const SizedBox(height: 28),
            const Text('Aperturas de gaveta sin venta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (drawerOpens.isEmpty)
              const Text(
                  'Sin registros (la apertura de gaveta aún no existe — Fase 3).',
                  style: TextStyle(color: Colors.grey))
            else
              ...drawerOpens.map((r) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.warning_amber, color: Colors.orange),
                    title: Text(empMap[r.employeeId] ?? 'Desconocido'),
                    subtitle: Text(formatDateTime(r.ts)),
                  )),
          ],
        );
      },
    );
  }
}

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(formatDate(_date)),
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
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _loadData(start, end),
            builder: (ctx, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              final d = snapshot.data!;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoCard('Ingresos',
                      formatCurrency(d['revenue'], widget.symbol)),
                  _InfoCard('Órdenes', '${d['orders']}'),
                  _InfoCard('Ticket promedio',
                      formatCurrency(d['avg'], widget.symbol)),
                  _InfoCard(
                      'Producto estrella', d['top'] as String),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadData(
      DateTime from, DateTime to) async {
    final db = ref.read(databaseProvider);
    final revenue =
        await db.reportsDao.getTotalRevenueForRange(from, to);
    final count =
        await db.reportsDao.getOrderCountForRange(from, to);
    final top = await db.reportsDao.getTopProductsToday();
    return {
      'revenue': revenue,
      'orders': count,
      'avg': count > 0 ? revenue / count : 0.0,
      'top': top.isNotEmpty ? top.keys.first : '-',
    };
  }
}

class _WeeklyTab extends ConsumerWidget {
  final String symbol;
  const _WeeklyTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: ref
          .read(databaseProvider)
          .reportsDao
          .getDailyRevenueLast7Days(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final entries = data.entries.toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ingresos últimos 7 días',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: entries
                        .asMap()
                        .entries
                        .map((e) => BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.value,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  width: 28,
                                ),
                              ],
                            ))
                        .toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Text(
                              entries[v.toInt()].key,
                              style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Text(
                              formatCurrency(v, symbol, decimals: 0),
                              style: const TextStyle(fontSize: 9)),
                          reservedSize: 60,
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  final String symbol;
  const _MonthlyTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<Map<String, double>>(
        future: _loadMonthly(ref),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final entries = data.entries.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Ingresos mensuales — ${DateTime.now().year}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: entries
                        .asMap()
                        .entries
                        .map((e) => BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.value,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                  width: 28,
                                ),
                              ],
                            ))
                        .toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            if (v.toInt() >= entries.length) {
                              return const SizedBox();
                            }
                            return Text(entries[v.toInt()].key,
                                style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, double>> _loadMonthly(WidgetRef ref) async {
    final months = <String, double>{};
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final monthNames = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    for (int m = 1; m <= now.month; m++) {
      final start = DateTime(now.year, m);
      final end = DateTime(now.year, m + 1);
      final rev =
          await db.reportsDao.getTotalRevenueForRange(start, end);
      months[monthNames[m - 1]] = rev;
    }
    return months;
  }
}

class _CategoryTab extends ConsumerWidget {
  final String symbol;
  const _CategoryTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: ref
          .read(databaseProvider)
          .reportsDao
          .getSalesByCategory(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now()),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Center(child: Text('Sin datos'));
        }
        final entries = data.entries.toList();
        final total = data.values.fold(0.0, (a, b) => a + b);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: entries.asMap().entries.map((e) {
                      final colors = [
                        Colors.blue, Colors.green, Colors.orange,
                        Colors.red, Colors.purple, Colors.teal,
                      ];
                      return PieChartSectionData(
                        value: e.value.value,
                        title: e.value.key,
                        color: colors[e.key % colors.length],
                        radius: 120,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListView(
                  children: entries.map((e) {
                    final pct = total > 0
                        ? (e.value / total * 100).toStringAsFixed(1)
                        : '0';
                    return ListTile(
                      title: Text(e.key),
                      trailing: Text(
                          '${formatCurrency(e.value, symbol)} ($pct%)'),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmployeeTab extends ConsumerWidget {
  final String symbol;
  const _EmployeeTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: ref
          .read(databaseProvider)
          .reportsDao
          .getSalesByEmployee(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now()),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return DataTable(
          columns: const [
            DataColumn(label: Text('Empleado')),
            DataColumn(label: Text('Ventas totales')),
          ],
          rows: data.entries.map((e) {
            return DataRow(cells: [
              DataCell(Text(e.key)),
              DataCell(Text(formatCurrency(e.value, symbol))),
            ]);
          }).toList(),
        );
      },
    );
  }
}

class _PaymentMethodTab extends ConsumerWidget {
  final String symbol;
  const _PaymentMethodTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: ref
          .read(databaseProvider)
          .reportsDao
          .getSalesByPaymentMethod(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now()),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Center(child: Text('Sin datos'));
        }
        final entries = data.entries.toList();
        final colors = [
          Colors.green, Colors.blue, Colors.orange, Colors.purple
        ];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: entries.asMap().entries.map((e) {
                      return PieChartSectionData(
                        value: e.value.value,
                        title: e.value.key,
                        color: colors[e.key % colors.length],
                        radius: 120,
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: entries.map((e) {
                    return ListTile(
                      title: Text(e.key),
                      trailing: Text(formatCurrency(e.value, symbol)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopProductsTab extends ConsumerWidget {
  final String symbol;
  const _TopProductsTab({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, int>>(
      future: ref.read(databaseProvider).reportsDao.getTopProductsToday(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final entries = data.entries.toList();

        if (entries.isEmpty) {
          return const Center(child: Text('Sin ventas hoy'));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              barGroups: entries
                  .asMap()
                  .entries
                  .map((e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.value.toDouble(),
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            width: 24,
                          ),
                        ],
                      ))
                  .toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                        entries[v.toInt() >= entries.length
                                ? entries.length - 1
                                : v.toInt()]
                            .key,
                        style: const TextStyle(fontSize: 10)),
                    reservedSize: 120,
                  ),
                ),
                bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: true),
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
