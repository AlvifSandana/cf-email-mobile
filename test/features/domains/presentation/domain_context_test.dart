import 'dart:async';

import 'package:bariskode_cf_email/features/domains/data/domain_repository.dart';
import 'package:bariskode_cf_email/features/domains/data/selected_domain_store.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores persisted selected domain when it still exists', () async {
    final store = FakeSelectedDomainStore(initialDomainId: 'zone-2');
    final context = DomainContext(
      repository: FakeDomainRepository(
        domains: const [
          DomainSummary(id: 'zone-1', name: 'example.com'),
          DomainSummary(id: 'zone-2', name: 'startup.io'),
        ],
      ),
      selectedDomainStore: store,
    );

    await context.loadDomains();

    expect(context.selectedDomain?.id, 'zone-2');
    expect(context.selectedDomain?.name, 'startup.io');
  });

  test(
    'falls back to first domain when persisted selection is missing',
    () async {
      final store = FakeSelectedDomainStore(initialDomainId: 'missing-zone');
      final context = DomainContext(
        repository: FakeDomainRepository(
          domains: const [
            DomainSummary(id: 'zone-1', name: 'example.com'),
            DomainSummary(id: 'zone-2', name: 'startup.io'),
          ],
        ),
        selectedDomainStore: store,
      );

      await context.loadDomains();

      expect(context.selectedDomain?.id, 'zone-1');
      expect(store.savedDomainIds, ['zone-1']);
    },
  );

  test(
    'selectDomain persists the active domain and clearSelection clears it',
    () async {
      final store = FakeSelectedDomainStore();
      final context = DomainContext(
        repository: FakeDomainRepository(),
        selectedDomainStore: store,
      );

      context.selectDomain(
        const DomainSummary(id: 'zone-9', name: 'bariskode.dev'),
      );
      await Future<void>.delayed(Duration.zero);
      context.clearSelection();
      await Future<void>.delayed(Duration.zero);

      expect(store.savedDomainIds, ['zone-9']);
      expect(store.clearCalls, 1);
      expect(store.currentDomainId, isNull);
    },
  );

  test('ignores persisted-domain store read failures', () async {
    final context = DomainContext(
      repository: FakeDomainRepository(
        domains: const [
          DomainSummary(id: 'zone-1', name: 'example.com'),
          DomainSummary(id: 'zone-2', name: 'startup.io'),
        ],
      ),
      selectedDomainStore: ThrowingSelectedDomainStore(throwOnRead: true),
    );

    await context.loadDomains();

    expect(context.selectedDomain?.id, 'zone-1');
  });

  test('ignores persisted-domain store write and clear failures', () async {
    final store = ThrowingSelectedDomainStore(
      throwOnSave: true,
      throwOnClear: true,
    );
    final context = DomainContext(
      repository: FakeDomainRepository(),
      selectedDomainStore: store,
    );

    context.selectDomain(
      const DomainSummary(id: 'zone-9', name: 'bariskode.dev'),
    );
    await Future<void>.delayed(Duration.zero);
    context.clearSelection();
    await Future<void>.delayed(Duration.zero);

    expect(context.selectedDomain, isNull);
    expect(store.saveAttempts, 1);
    expect(store.clearAttempts, 1);
  });

  test(
    'serializes store operations to preserve latest selection outcome',
    () async {
      final store = SequencedSelectedDomainStore();
      final context = DomainContext(
        repository: FakeDomainRepository(),
        selectedDomainStore: store,
      );

      context.selectDomain(
        const DomainSummary(id: 'zone-1', name: 'example.com'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(store.startedOperations, ['save:zone-1']);

      context.clearSelection();
      context.selectDomain(
        const DomainSummary(id: 'zone-2', name: 'startup.io'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(store.startedOperations, ['save:zone-1']);

      await store.completeNextOperation();
      await Future<void>.delayed(Duration.zero);
      expect(store.startedOperations, ['save:zone-1', 'clear']);

      await store.completeNextOperation();
      await Future<void>.delayed(Duration.zero);
      expect(store.startedOperations, ['save:zone-1', 'clear', 'save:zone-2']);

      await store.completeNextOperation();
      await Future<void>.delayed(Duration.zero);

      expect(store.completedOperations, [
        'save:zone-1',
        'clear',
        'save:zone-2',
      ]);
      expect(store.currentDomainId, 'zone-2');
    },
  );
}

class FakeDomainRepository implements DomainRepositoryContract {
  FakeDomainRepository({this.domains = const []});

  final List<DomainSummary> domains;

  @override
  Future<List<DomainSummary>> listDomains() async => domains;
}

class FakeSelectedDomainStore implements SelectedDomainStoreContract {
  FakeSelectedDomainStore({String? initialDomainId})
    : currentDomainId = initialDomainId;

  int clearCalls = 0;
  String? currentDomainId;
  final List<String> savedDomainIds = <String>[];

  @override
  Future<void> clearSelectedDomainId() async {
    clearCalls += 1;
    currentDomainId = null;
  }

  @override
  Future<String?> readSelectedDomainId() async => currentDomainId;

  @override
  Future<void> saveSelectedDomainId(String domainId) async {
    currentDomainId = domainId;
    savedDomainIds.add(domainId);
  }
}

class ThrowingSelectedDomainStore implements SelectedDomainStoreContract {
  ThrowingSelectedDomainStore({
    this.throwOnRead = false,
    this.throwOnSave = false,
    this.throwOnClear = false,
  });

  final bool throwOnRead;
  final bool throwOnSave;
  final bool throwOnClear;
  int saveAttempts = 0;
  int clearAttempts = 0;

  @override
  Future<void> clearSelectedDomainId() async {
    clearAttempts += 1;
    if (throwOnClear) {
      throw Exception('clear failed');
    }
  }

  @override
  Future<String?> readSelectedDomainId() async {
    if (throwOnRead) {
      throw Exception('read failed');
    }

    return null;
  }

  @override
  Future<void> saveSelectedDomainId(String domainId) async {
    saveAttempts += 1;
    if (throwOnSave) {
      throw Exception('save failed');
    }
  }
}

class SequencedSelectedDomainStore implements SelectedDomainStoreContract {
  final List<String> startedOperations = <String>[];
  final List<String> completedOperations = <String>[];
  final List<_PendingStoreOperation> _pendingOperations =
      <_PendingStoreOperation>[];
  String? currentDomainId;

  @override
  Future<void> clearSelectedDomainId() async {
    final completer = Completer<void>();
    startedOperations.add('clear');
    _pendingOperations.add(
      _PendingStoreOperation(
        label: 'clear',
        completer: completer,
        onComplete: () {
          currentDomainId = null;
          completedOperations.add('clear');
        },
      ),
    );
    await completer.future;
  }

  @override
  Future<String?> readSelectedDomainId() async => currentDomainId;

  @override
  Future<void> saveSelectedDomainId(String domainId) async {
    final label = 'save:$domainId';
    final completer = Completer<void>();
    startedOperations.add(label);
    _pendingOperations.add(
      _PendingStoreOperation(
        label: label,
        completer: completer,
        onComplete: () {
          currentDomainId = domainId;
          completedOperations.add(label);
        },
      ),
    );
    await completer.future;
  }

  Future<void> completeNextOperation() async {
    final operation = _pendingOperations.removeAt(0);
    operation.onComplete();
    operation.completer.complete();
  }
}

class _PendingStoreOperation {
  _PendingStoreOperation({
    required this.label,
    required this.completer,
    required this.onComplete,
  });

  final String label;
  final Completer<void> completer;
  final void Function() onComplete;
}
