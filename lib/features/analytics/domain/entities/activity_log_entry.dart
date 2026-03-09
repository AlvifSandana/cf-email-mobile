class ActivityLogEntry {
  const ActivityLogEntry({
    required this.address,
    required this.status,
    required this.spf,
    required this.dkim,
    required this.dmarc,
    required this.timestamp,
  });

  final String address;
  final String status;
  final String spf;
  final String dkim;
  final String dmarc;
  final DateTime timestamp;
}
