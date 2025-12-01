import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/package_model.dart';
import '../../../models/merchant_model.dart';
import '../repository/packages_repository.dart';
import 'packages_event.dart';
import 'packages_state.dart';

class PackagesBloc extends Bloc<PackagesEvent, PackagesState> {
  PackagesBloc(this._repository) : super(const PackagesInitial()) {
    on<PackagesFetchRequested>(_onFetchRequested);
    on<PackageConfirmPickupRequested>(_onConfirmPickup);
    on<PackageReceiveFromOfficeRequested>(_onReceiveFromOffice);
    on<PackageStartDeliveryRequested>(_onStartDelivery);
    on<PackageMarkDeliveredRequested>(_onMarkDelivered);
    on<PackageCollectCodRequested>(_onCollectCod);
    on<PackageContactCustomerRequested>(_onContactCustomer);
    on<PackageReturnToOfficeRequested>(_onReturnToOffice);
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

      // Group pickups by merchant (using merchant ID as key)
      final Map<int, MerchantModel> merchantMap = {};
      final Map<int, List<PackageModel>> pickupsByMerchantId = {};

      for (var package in pickups) {
        if (package.merchant != null) {
          final merchant = package.merchant!;
          final merchantId = merchant.id;

          // Store merchant in map
          if (!merchantMap.containsKey(merchantId)) {
            merchantMap[merchantId] = merchant;
          }

          // Group packages by merchant ID
          if (!pickupsByMerchantId.containsKey(merchantId)) {
            pickupsByMerchantId[merchantId] = [];
          }
          pickupsByMerchantId[merchantId]!.add(package);
        }
      }

      // Convert to Map<MerchantModel, List<PackageModel>>
      final Map<MerchantModel, List<PackageModel>> pickupsByMerchant = {};
      for (var entry in pickupsByMerchantId.entries) {
        final merchant = merchantMap[entry.key]!;
        pickupsByMerchant[merchant] = entry.value;
      }

      emit(
        PackagesLoaded(
          assignedDeliveries: assignedDeliveries,
          pickups: pickups,
          pickupsByMerchant: pickupsByMerchant,
        ),
      );
    } catch (e) {
      emit(PackagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onConfirmPickup(
    PackageConfirmPickupRequested event,
    Emitter<PackagesState> emit,
  ) async {
    if (state is! PackagesLoaded) return;
    final currentState = state as PackagesLoaded;

    emit(currentState.copyWith(isActionLoading: true));

    try {
      await _repository.confirmPickupByMerchant(event.merchantId);
      // Refresh packages after successful pickup
      add(const PackagesFetchRequested());
    } catch (e) {
      emit(PackagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onReceiveFromOffice(
    PackageReceiveFromOfficeRequested event,
    Emitter<PackagesState> emit,
  ) async {
    if (state is! PackagesLoaded) return;
    final currentState = state as PackagesLoaded;

    emit(
      currentState.copyWith(
        isActionLoading: true,
        actionPackageId: event.packageId,
      ),
    );

    try {
      await _repository.receiveFromOffice(event.packageId, notes: event.notes);
      // Refresh packages after successful action
      add(const PackagesFetchRequested());
    } catch (e) {
      emit(PackagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onStartDelivery(
    PackageStartDeliveryRequested event,
    Emitter<PackagesState> emit,
  ) async {
    if (state is! PackagesLoaded) return;
    final currentState = state as PackagesLoaded;

    emit(
      currentState.copyWith(
        isActionLoading: true,
        actionPackageId: event.packageId,
      ),
    );

    try {
      await _repository.startDelivery(event.packageId);
      // Refresh packages after successful action
      add(const PackagesFetchRequested());
    } catch (e) {
      emit(PackagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkDelivered(
    PackageMarkDeliveredRequested event,
    Emitter<PackagesState> emit,
  ) async {
    if (state is! PackagesLoaded) return;
    final currentState = state as PackagesLoaded;

    emit(
      currentState.copyWith(
        isActionLoading: true,
        actionPackageId: event.packageId,
      ),
    );

    try {
      await _repository.uploadProof(
        event.packageId,
        photo: event.photo,
        signature: event.signature,
        latitude: event.latitude,
        longitude: event.longitude,
        deliveredToName: event.deliveredToName,
        deliveredToPhone: event.deliveredToPhone,
        notes: event.notes,
      );
      // Refresh packages after successful action
      add(const PackagesFetchRequested());
    } catch (e) {
      emit(PackagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCollectCod(
    PackageCollectCodRequested event,
    Emitter<PackagesState> emit,
  ) async {
    if (state is! PackagesLoaded) return;
    final currentState = state as PackagesLoaded;

    emit(
      currentState.copyWith(
        isActionLoading: true,
        actionPackageId: event.packageId,
      ),
    );

    try {
      await _repository.collectCod(
        event.packageId,
        amount: event.amount,
        collectionProof: event.collectionProof,
      );
      // Refresh packages after successful action
      add(const PackagesFetchRequested());
    } catch (e) {
      emit(PackagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onContactCustomer(
    PackageContactCustomerRequested event,
    Emitter<PackagesState> emit,
  ) async {
    if (state is! PackagesLoaded) return;
    final currentState = state as PackagesLoaded;

    emit(
      currentState.copyWith(
        isActionLoading: true,
        actionPackageId: event.packageId,
      ),
    );

    try {
      await _repository.contactCustomer(
        event.packageId,
        contactResult: event.contactResult,
        notes: event.notes,
      );
      // Refresh packages after successful action
      add(const PackagesFetchRequested());
    } catch (e) {
      emit(PackagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onReturnToOffice(
    PackageReturnToOfficeRequested event,
    Emitter<PackagesState> emit,
  ) async {
    if (state is! PackagesLoaded) return;
    final currentState = state as PackagesLoaded;

    emit(
      currentState.copyWith(
        isActionLoading: true,
        actionPackageId: event.packageId,
      ),
    );

    try {
      await _repository.updateStatus(
        event.packageId,
        status: 'return_to_office',
        notes: event.notes,
      );
      // Refresh packages after successful action
      add(const PackagesFetchRequested());
    } catch (e) {
      emit(PackagesError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
