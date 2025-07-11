part of 'repositories_cubit.dart';

@immutable
sealed class ShowRepositoriesState extends Equatable {
  const ShowRepositoriesState({
    required this.publicRepositories,
    required this.privateRepositories,
  });

  final List<Repository> publicRepositories;
  final List<Repository> privateRepositories;
}

@immutable
class InitRepositoryState extends ShowRepositoriesState {
  const InitRepositoryState()
    : super(
        publicRepositories: const [],
        privateRepositories: const [],
      );

  @override
  List<Object?> get props => [publicRepositories, privateRepositories];
}

@immutable
class RepositoriesLoadedState extends ShowRepositoriesState {
  const RepositoriesLoadedState({
    required super.publicRepositories,
    required super.privateRepositories,
  });

  @override
  List<Object?> get props => [publicRepositories, privateRepositories];
}
