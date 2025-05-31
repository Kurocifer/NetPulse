import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/network_service.dart';

abstract class NetworkEvent {}

class NetworkStatusRequested extends NetworkEvent {}

class NetworkState {
  final String networkType;
  final String isp;

  NetworkState({required this.networkType, required this.isp});
}

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final NetworkService _networkService;

  NetworkBloc(this._networkService)
      : super(NetworkState(
          networkType: _networkService.getCurrentNetworkInfoSync()['networkType'] ?? 'Offline',
          isp: _networkService.getCurrentNetworkInfoSync()['isp'] ?? 'Offline',
        )) {
    on<NetworkStatusRequested>((event, emit) async {
      final info = await _networkService.getNetworkInfo();
      emit(NetworkState(
        networkType: info['networkType'],
        isp: info['isp'],
      ));

      await for (final info in _networkService.getNetworkStream()) {
        emit(NetworkState(
          networkType: info['networkType'],
          isp: info['isp'],
        ));
      }
    });

    add(NetworkStatusRequested());
  }
}