class AliasModel {
  const AliasModel({
    required this.id,
    required this.address,
    required this.destination,
    required this.isEnabled,
    required this.isSupported,
    this.actionType = 'forward',
  });

  final String id;
  final String address;
  final String destination;
  final bool isEnabled;
  final bool isSupported;
  final String actionType;

  bool get isBlocked => actionType == 'drop';

  static AliasModel fromApi(Map<String, dynamic> json) {
    final id = json['id'];
    final enabled = json['enabled'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Alias id is required.');
    }

    final address = _extractAddress(json['matchers']);
    final action = _extractAction(json['actions']);
    final destination = action?.destination;
    final isSupported = address != null && action != null;

    return AliasModel(
      id: id,
      address: address ?? 'Unsupported routing rule',
      destination: destination ?? 'Unsupported destination',
      isEnabled: enabled is bool ? enabled : true,
      isSupported: isSupported,
      actionType: action?.type ?? 'unsupported',
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

  static _ParsedAction? _extractAction(Object? actions) {
    if (actions is! List || actions.length != 1) {
      return null;
    }

    final action = actions.single;
    if (action is! Map<String, dynamic>) {
      return null;
    }

    final type = action['type'];
    if (type == 'drop') {
      return const _ParsedAction(type: 'drop', destination: 'Blocked');
    }

    if (type != 'forward') {
      return null;
    }

    final value = action['value'];
    if (value is! List || value.length != 1) {
      return null;
    }

    final destination = value.single;
    if (destination is String && destination.isNotEmpty) {
      return _ParsedAction(type: 'forward', destination: destination);
    }

    return null;
  }
}

class _ParsedAction {
  const _ParsedAction({required this.type, required this.destination});

  final String type;
  final String destination;
}
