import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/packages_repository.dart';
import 'packages_event.dart';
import 'packages_state.dart';

class PackagesBloc extends Bloc<PackagesEvent, PackagesState> {
  PackagesBloc(this._repository) : super(const PackagesInitial()) {
    on<PackagesFetchRequested>(_onFetchRequested);
  }

  final PackagesRepository _repository;

  Future<void> _onFetchRequested(
    PackagesFetchRequested event,
    Emitter<PackagesState> emit,
  ) async {
    emit(const PackagesLoading());

    try {
      final packages = await _repository.getPackages();

      // Separate packages into assigned deliveries and pickups
      final assignedDeliveries = packages
          .where((pkg) => pkg.isForDelivery)
          .toList();

      final pickups = packages.where((pkg) => pkg.isForPickup).toList();

      emit(
        PackagesLoaded(
          assignedDeliveries: assignedDeliveries,
          pickups: pickups,
        ),
      );
    } catch (e) {
      emit(PackagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
