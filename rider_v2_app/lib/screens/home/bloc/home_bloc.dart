import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/date_utils.dart';
import '../repository/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._repository) : super(HomeInitial()) {
    on<HomeFetchRequested>(_onFetchRequested);
  }

  final HomeRepository _repository;

  Future<void> _onFetchRequested(
    HomeFetchRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    try {
      // Fetch active packages and delivered packages in parallel
      final packagesFuture = _repository.getPackages();
      final deliveredPackagesFuture = _repository.getDeliveredPackages();

      final packages = await packagesFuture;
      final deliveredPackages = await deliveredPackagesFuture;

      // Count assigned deliveries
      // Delivery assignments: ready_for_delivery, on_the_way
      // These are packages ready to be delivered or currently being delivered
      int assignedDeliveries = 0;
      for (var package in packages) {
        final status = package.status;
        if (status == 'ready_for_delivery' || status == 'on_the_way') {
          assignedDeliveries++;
        }
      }

      // Count assigned pickups
      // Pickup assignments: assigned_to_rider, picked_up
      // These are packages that need to be picked up from merchant
      int assignedPickups = 0;
      for (var package in packages) {
        final status = package.status;
        if (status == 'assigned_to_rider' || status == 'picked_up') {
          assignedPickups++;
        }
      }

      // Count delivered this month
      // Get current month in Myanmar timezone
      final now = MyanmarDateUtils.getMyanmarNow();
      final currentMonth = now.month;
      final currentYear = now.year;

      int deliveredThisMonth = 0;
      for (var package in deliveredPackages) {
        if (package.deliveredAt != null) {
          final deliveredAt = MyanmarDateUtils.toMyanmarTime(
            package.deliveredAt!,
          );
          if (deliveredAt.month == currentMonth &&
              deliveredAt.year == currentYear) {
            deliveredThisMonth++;
          }
        }
      }

      emit(
        HomeLoaded(
          assignedDeliveries: assignedDeliveries,
          assignedPickups: assignedPickups,
          deliveredThisMonth: deliveredThisMonth,
        ),
      );
    } catch (e) {
      emit(HomeError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
