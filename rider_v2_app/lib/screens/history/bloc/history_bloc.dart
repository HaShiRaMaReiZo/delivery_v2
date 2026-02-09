import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/package_model.dart';
import '../repository/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(this._repository) : super(const HistoryInitial()) {
    on<HistoryFetchRequested>(_onFetchRequested);
  }

  final HistoryRepository _repository;

  Future<void> _onFetchRequested(
    HistoryFetchRequested event,
    Emitter<HistoryState> emit,
  ) async {
    // Only emit loading if we don't have cached data
    if (state is! HistoryLoaded) {
      emit(const HistoryLoading());
    }

    try {
      final packages = await _repository.getHistory(event.riderId);

      // Group packages by delivery date (day)
      final Map<String, List<PackageModel>> packagesByDate = {};

      for (var package in packages) {
        if (package.deliveredAt != null) {
          // Format date as YYYY-MM-DD for grouping
          final dateKey = package.deliveredAt!.toLocal().toString().split(
            ' ',
          )[0];

          if (!packagesByDate.containsKey(dateKey)) {
            packagesByDate[dateKey] = [];
          }
          packagesByDate[dateKey]!.add(package);
        }
      }

      // Sort dates in descending order (most recent first)
      final sortedDates = packagesByDate.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      // Create a new map with sorted dates
      final sortedPackagesByDate = <String, List<PackageModel>>{};
      for (var date in sortedDates) {
        sortedPackagesByDate[date] = packagesByDate[date]!;
      }

      emit(HistoryLoaded(packagesByDate: sortedPackagesByDate));
    } catch (e) {
      emit(HistoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
