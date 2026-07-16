import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/system_health_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final activeOrders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            FutureBuilder<Map<String, dynamic>>(
              future: _getTodaySummary(ref),
              builder: (ctx, snapshot) {
                final data = snapshot.data ?? {};
                return Row(
                  children: [
                    _SummaryCard(
                      icon: '💰',
                      title: 'Ventas hoy',
                      value: formatCurrency(
                          data['revenue'] ?? 0.0, symbol),
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      icon: '🧾',
                      title: 'Órdenes hoy',
                      value: '${data['orders'] ?? 0}',
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      icon: '📊',
                      title: 'Ticket promedio',
                      value: formatCurrency(
                          data['avgTicket'] ?? 0.0, symbol),
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      icon: '🏆',
                      title: 'Producto estrella',
                      value: data['topProduct'] ?? '-',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            // Live order status counts
            Row(
              children: [
                _statusCard(
                    'Pendiente',
                    activeOrders
                        .where((o) => o.order.status == 'pendiente')
                        .length,
                    Colors.amber),
                const SizedBox(width: 8),
                _statusCard(
                    'En prep.',
                    activeOrders
                        .where(
                            (o) => o.order.status == 'en_preparacion')
                        .length,
                    Colors.orange),
                const SizedBox(width: 8),
                _statusCard(
                    'Listo',
                    activeOrders
                        .where((o) => o.order.status == 'listo')
                        .length,
                    Colors.green),
                const SizedBox(width: 8),
                _statusCard(
                    'Entregado',
                    activeOrders
                        .where((o) => o.order.status == 'entregado')
                        .length,
                    Colors.blue),
              ],
            ),
            const SizedBox(height: 24),
            // Charts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _WeeklyRevenueChart(symbol: symbol),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TopProductsChart(symbol: symbol),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SystemHealthCard(),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getTodaySummary(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final revenue =
        await db.reportsDao.getTotalRevenueForRange(start, end);
    final count =
        await db.reportsDao.getOrderCountForRange(start, end);
    final topProducts = await db.reportsDao.getTopProductsToday();

    return {
      'revenue': revenue,
      'orders': count,
      'avgTicket': count > 0 ? revenue / count : 0.0,
      'topProduct':
          topProducts.isNotEmpty ? topProducts.keys.first : '-',
    };
  }

  Widget _statusCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text(
                    '$count',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold),
                  )),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;

  const _SummaryCard(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyRevenueChart extends ConsumerWidget {
  final String symbol;
  const _WeeklyRevenueChart({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ventas últimos 7 días',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<Map<String, double>>(
                future: ref
                    .read(databaseProvider)
                    .reportsDao
                    .getDailyRevenueLast7Days(),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  final entries = data.entries.toList();
                  return BarChart(
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
                                    width: 20,
                                    borderRadius:
                                        const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) => Text(
                              entries[v.toInt()].key,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsChart extends ConsumerWidget {
  final String symbol;
  const _TopProductsChart({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top productos hoy',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<Map<String, int>>(
                future: ref
                    .read(databaseProvider)
                    .reportsDao
                    .getTopProductsToday(),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  final entries = data.entries.take(5).toList();
                  if (entries.isEmpty) {
                    return const Center(
                        child: Text('Sin ventas hoy'));
                  }
                  return BarChart(
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
                                        .secondary,
                                    width: 20,
                                  ),
                                ],
                              ))
                          .toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) {
                              if (v.toInt() >= entries.length) {
                                return const SizedBox();
                              }
                              return RotatedBox(
                                quarterTurns: 1,
                                child: Text(
                                  entries[v.toInt()].key,
                                  style: const TextStyle(fontSize: 9),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                            reservedSize: 60,
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
