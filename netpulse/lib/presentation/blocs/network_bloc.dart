import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class NetworkEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchMetrics extends NetworkEvent {}

abstract class NetworkState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NetworkInitial extends NetworkState {}
class NetworkLoading extends NetworkState {}
class NetworkLoaded extends NetworkState {}
class NetworkError extends NetworkState {
  final String error;
  NetworkError(this.error);
  @override
  List<Object?> get props => [error];
}

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  NetworkBloc() : super(NetworkInitial()) {
    on<FetchMetrics>(_onFetchMetrics);
  }

  void _onFetchMetrics(FetchMetrics event, Emitter<NetworkState> emit) {
    // Placeholder
  }
}