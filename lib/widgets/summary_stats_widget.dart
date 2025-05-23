import 'package:flutter/material.dart';

class SummaryStatsWidget extends StatelessWidget {
  final String title;
  final List<SummaryStat> stats;
  final Widget? additionalInfo;
  final EdgeInsetsGeometry? margin;

  const SummaryStatsWidget({
    Key? key,
    required this.title,
    required this.stats,
    this.additionalInfo,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Estadísticas
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: stats.map((stat) => _buildSummaryItem(
              context,
              stat.title,
              stat.count,
              stat.color,
              isDarkMode,
            )).toList(),
          ),
          
          // Información adicional
          if (additionalInfo != null) ...[
            const SizedBox(height: 12),
            additionalInfo!,
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    int count,
    Color color,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class SummaryStat {
  final String title;
  final int count;
  final Color color;

  const SummaryStat({
    required this.title,
    required this.count,
    required this.color,
  });
}