class HomeEvent {
  const HomeEvent();

  const factory HomeEvent.fetchRequested() = HomeFetchRequested;
}

class HomeFetchRequested extends HomeEvent {
  const HomeFetchRequested();
}

