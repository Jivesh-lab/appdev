$content = @"

// --- Aggregate chip widget ---

class _AggChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AggChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('`$count`', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// --- Question tile widget ---

class _QuestionTile extends StatelessWidget {
  final Question question;
  final VoidCallback onMarkAnswered;

  const _QuestionTile({required this.question, required this.onMarkAnswered});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: question.isAnswered ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: question.isAnswered ? Colors.green : Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              question.title,
              style: TextStyle(color: question.isAnswered ? Colors.green[300] : Colors.white, fontSize: 12),
            ),
          ),
          if (!question.isAnswered)
            GestureDetector(
              onTap: onMarkAnswered,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(6)),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
  }
}

// --- Summary row widget ---

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _SummaryRow({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF2D5BFF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c)),
        ],
      ),
    );
  }
}
"@

Add-Content -Path "G:\appdev\lib\teacher\teacher_screens.dart" -Value $content -Encoding UTF8
Write-Host "Done. Lines: $((Get-Content 'G:\appdev\lib\teacher\teacher_screens.dart').Count)"
