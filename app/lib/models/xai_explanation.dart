class XaiExplanation {
  final String variable;
  final double contribution;
  final String direction;

  const XaiExplanation({
    required this.variable,
    required this.contribution,
    required this.direction,
  });
}
