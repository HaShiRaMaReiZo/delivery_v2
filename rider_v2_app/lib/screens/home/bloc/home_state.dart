class HomeState {
  const HomeState();

  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.loaded({
    required int assignedDeliveries,
    required int assignedPickups,
    required int deliveredThisMonth,
  }) = HomeLoaded;
  const factory HomeState.error(String message) = HomeError;
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final int assignedDeliveries;
  final int assignedPickups;
  final int deliveredThisMonth;

  const HomeLoaded({
    required this.assignedDeliveries,
    required this.assignedPickups,
    required this.deliveredThisMonth,
  });
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);
}

