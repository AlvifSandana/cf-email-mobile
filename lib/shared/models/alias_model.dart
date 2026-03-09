class AliasModel {
  const AliasModel({
    required this.id,
    required this.address,
    required this.destination,
    required this.isEnabled,
    required this.isSupported,
  });

  final String id;
  final String address;
  final String destination;
  final bool isEnabled;
  final bool isSupported;

  static AliasModel fromApi(Map<String, dynamic> json) {
    final id = json['id'];
    final enabled = json['enabled'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Alias id is required.');
    }

    final address = _extractAddress(json['matchers']);
    final destination = _extractDestination(json['actions']);
    final isSupported = address != null && destination != null;

    return AliasModel(
      id: id,
      address: address ?? 'Unsupported routing rule',
      destination: destination ?? 'Unsupported destination',
      isEnabled: enabled is bool ? enabled : true,
      isSupported: isSupported,
    );
  }

  static String? _extractAddress(Object? matchers) {
    if (matchers is! List || matchers.length != 1) {
      return null;
    }

    final matcher = matchers.single;
    if (matcher is! Map<String, dynamic>) {
      return null;
    }

    if (matcher['type'] != 'literal' || matcher['field'] != 'to') {
      return null;
    }

    final value = matcher['value'];
    if (value is String && value.isNotEmpty) {
      return value;
    }

    return null;
  }

  static String? _extractDestination(Object? actions) {
    if (actions is! List || actions.length != 1) {
      return null;
    }

    final action = actions.single;
    if (action is! Map<String, dynamic>) {
      return null;
    }

    if (action['type'] != 'forward') {
      return null;
    }

    final value = action['value'];
    if (value is! List || value.length != 1) {
      return null;
    }

    final destination = value.single;
    if (destination is String && destination.isNotEmpty) {
      return destination;
    }

    return null;
  }
}
