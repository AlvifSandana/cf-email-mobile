class DomainSummary {
  const DomainSummary({
    required this.id,
    required this.name,
    this.accountId = '',
  });

  final String id;
  final String name;
  final String accountId;
}
