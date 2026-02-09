import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryFetchRequested extends HistoryEvent {
  final int riderId;

  const HistoryFetchRequested(this.riderId);

  @override
  List<Object?> get props => [riderId];
}
