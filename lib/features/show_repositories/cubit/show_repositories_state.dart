part of 'show_repositories_cubit.dart';

@immutable
sealed class ShowRepositoriesState extends Equatable {
  final List<Repository> publicRepositories;
  final List<Repository> privateRepositories;
  final RepositoryError? error;
  final bool isLoading;

  const ShowRepositoriesState({
    required this.publicRepositories,
    required this.privateRepositories,
    this.error,
    this.isLoading = false,
  });
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
class RepositoriesState extends ShowRepositoriesState {
  const RepositoriesState({
    required super.publicRepositories,
    required super.privateRepositories,
    super.error,
    super.isLoading,
  });

  @override
  List<Object?> get props => [publicRepositories, privateRepositories, error, isLoading];
}
