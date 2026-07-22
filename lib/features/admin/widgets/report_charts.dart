import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Widgets de la marca para gráficas y KPIs — compartidos entre Reportes y
/// Dashboard (antes vivían solo en `reports_screen.dart`; Dashboard usaba
/// `Card`/emojis/colores de Material genéricos en su lugar, feedback de
/// sitio 2026-07-22: "no se ve profesional").

/// Paleta categórica de la marca para las gráficas — reemplaza los
/// `Colors.blue/red/...` genéricos por los tonos de La Tercia, en un orden con
/// buen contraste entre vecinos.
const chartColors = <Color>[
  LaTerciaColors.burntOrange,
  LaTerciaColors.gold,
  LaTerciaColors.catFria,
  LaTerciaColors.catExtra,
  LaTerciaColors.catPostre,
  LaTerciaColors.delivery,
  LaTerciaColors.goldDark,
  LaTerciaColors.cocoa,
];

/// Envoltura de panel: card cremita con borde suave y padding consistente.
class Panel extends StatelessWidget {
  final Widget child;
  const Panel({super.key, required this.child});

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

class PanelTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const PanelTitle(this.title, {super.key, this.subtitle});

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
              style:
                  const TextStyle(fontSize: 12.5, color: LaTerciaColors.tan)),
        ],
      ],
    );
  }
}

/// Tarjeta KPI: etiqueta en mayúsculas + valor grande en serif.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  const StatCard({
    super.key,
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
class BreakdownRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double fraction; // 0..1 respecto al máximo
  final Color color;
  const BreakdownRow({
    super.key,
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

Widget loadingChart() =>
    const Center(child: CircularProgressIndicator(color: LaTerciaColors.gold));

Widget emptyChart(String msg) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart_rounded,
              size: 44, color: LaTerciaColors.tanLight),
          const SizedBox(height: 10),
          Text(msg,
              style: const TextStyle(color: LaTerciaColors.tan, fontSize: 15)),
        ],
      ),
    );

/// Gráfica de barras con el estilo de la marca: barras redondeadas, grid
/// horizontal tenue, tooltip al tocar, y **20% de aire arriba de la barra más
/// alta** (`maxY: maxV * 1.2`) — sin ese margen la barra más alta toca el
/// borde del panel y se siente "cortada" (feedback de sitio 2026-07-22).
Widget brandBarChart(
  BuildContext context,
  List<MapEntry<String, double>> entries, {
  required Color color,
  required String symbol,
  required String Function(int) bottomLabel,
}) {
  if (entries.isEmpty) return emptyChart('Sin datos en el periodo');
  final maxV = entries.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
  // Con puros ceros (nada vendido en todo el periodo) fl_chart dibujaba
  // líneas de referencia sobre una escala de 0 a 1 — el eje mostraba
  // "$1 $1 $1 $0 $0 $0" repetido y confuso. Con nada que graficar, el mismo
  // estado vacío que ya usa el resto de las gráficas es más honesto y se ve
  // más profesional. Feedback de sitio 2026-07-22.
  if (maxV == 0) return emptyChart('Sin datos en el periodo');
  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxV * 1.2,
      barGroups: entries
          .asMap()
          .entries
          .map((e) => BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: color,
                  width: 22,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: LaTerciaColors.border, strokeWidth: 1),
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
