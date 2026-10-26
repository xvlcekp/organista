part of 'connectivity_cubit.dart';

@immutable
class ConnectivityState extends Equatable {
  const ConnectivityState({required this.isOnline});

  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}
