part of 'repositories_cubit.dart';

@immutable
sealed class ShowRepositoriesState extends Equatable {
  const ShowRepositoriesState({
    required this.repositories,
  });

  final List<Repository> repositories;
}

@immutable
class InitRepositoryState extends ShowRepositoriesState {
  const InitRepositoryState() : super(repositories: const []);

  @override
  List<Object?> get props => [repositories];
}

@immutable
class RepositoriesLoadedState extends ShowRepositoriesState {
  const RepositoriesLoadedState({required super.repositories});

  @override
  List<Object?> get props => [repositories];
}
