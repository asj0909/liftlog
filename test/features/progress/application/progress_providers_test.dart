import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/progress/application/progress_providers.dart';
import 'package:liftlog/features/progress/domain/progress_point.dart';

import '../../../helpers/fake_progress_repository.dart';

void main() {
  late FakeProgressRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeProgressRepository();
    container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        todayProvider.overrideWithValue(DateTime(2026, 11, 1)),
      ],
    );
    addTearDown(container.dispose);
  });

  test('期間の開始日を今日から計算して渡す', () async {
    await container.read(
      exerciseProgressProvider(
        (exerciseId: 'e-bench', range: ProgressRange.threeMonths),
      ).future,
    );
    expect(repo.lastFrom, DateTime(2026, 8, 1));
  });

  test('全期間なら開始日を渡さない', () async {
    await container.read(
      exerciseProgressProvider(
        (exerciseId: 'e-bench', range: ProgressRange.all),
      ).future,
    );
    expect(repo.lastFrom, isNull);
  });
}
