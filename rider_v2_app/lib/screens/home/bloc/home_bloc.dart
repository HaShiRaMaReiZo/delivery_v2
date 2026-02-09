import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/package_model.dart';
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
    // If already loaded, keep showing cached data (don't show loading again)
    // Only show loading if we're in initial state
    final currentState = state;
    if (currentState is! HomeLoaded) {
      emit(HomeLoading());
    }

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

      // Get upcoming packages (prioritize deliveries, then pickups)
      // Limit to top 5 most urgent packages
      final upcomingPackages = <PackageModel>[];

      // First, add delivery packages (ready_for_delivery, on_the_way)
      final deliveryPackages = packages.where((pkg) {
        return pkg.isForDelivery &&
            (pkg.status == 'ready_for_delivery' || pkg.status == 'on_the_way');
      }).toList();
      upcomingPackages.addAll(deliveryPackages);

      // Then, add pickup packages (assigned_to_rider for pickup)
      final pickupPackages = packages.where((pkg) {
        return pkg.isForPickup && pkg.status == 'assigned_to_rider';
      }).toList();
      upcomingPackages.addAll(pickupPackages);

      // Sort by assignedAt (most recent first) and limit to 5
      upcomingPackages.sort((a, b) {
        final aAssigned = a.assignedAt;
        final bAssigned = b.assignedAt;
        if (aAssigned == null && bAssigned == null) return 0;
        if (aAssigned == null) return 1;
        if (bAssigned == null) return -1;
        return bAssigned.compareTo(aAssigned);
      });

      final limitedPackages = upcomingPackages.take(5).toList();

      emit(
        HomeLoaded(
          assignedDeliveries: assignedDeliveries,
          assignedPickups: assignedPickups,
          deliveredThisMonth: deliveredThisMonth,
          upcomingPackages: limitedPackages,
        ),
      );
    } catch (e) {
      emit(HomeError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
