import 'package:equatable/equatable.dart';

/// Base state for cache management
abstract class CacheState extends Equatable {
  static const int decimalPlaces = 2;

  const CacheState();

  @override
  List<Object?> get props => [];
}

/// Initial state when cache info hasn't been loaded yet
class CacheInitial extends CacheState {
  const CacheInitial();
}

/// State when cache info is being loaded or cache is being cleared
class CacheLoading extends CacheState {
  const CacheLoading();
}

/// State when cache info has been successfully loaded
class CacheLoaded extends CacheState {
  final int totalFiles;
  final double sizeInMB;

  const CacheLoaded({
    required this.totalFiles,
    required this.sizeInMB,
  });

  @override
  List<Object?> get props => [totalFiles, sizeInMB];

  CacheLoaded copyWith({
    int? totalFiles,
    double? sizeInMB,
  }) {
    return CacheLoaded(
      totalFiles: totalFiles ?? this.totalFiles,
      sizeInMB: sizeInMB ?? this.sizeInMB,
    );
  }

  @override
  String toString() =>
      'CacheLoaded(totalFiles: $totalFiles, sizeInMB: ${sizeInMB.toStringAsFixed(CacheState.decimalPlaces)})';
}

/// State when cache has been successfully cleared
class CacheCleared extends CacheState {
  const CacheCleared();
}

/// State when an error occurred
class CacheError extends CacheState {
  final String message;

  const CacheError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'CacheError(message: $message)';
}
