import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show CacheManager;
import 'package:organista/features/cache_management/cubit/cache_cubit.dart';
import 'package:organista/features/cache_management/view/cache_management_view.dart';

/// Cache management page with BLoC provider
///
/// This is the public entry point for the cache management feature.
/// It handles BLoC provider setup internally, so callers don't need to know about CacheCubit.
class CacheManagementPage extends StatelessWidget {
  const CacheManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CacheCubit(cacheManager: context.read<CacheManager>())..loadCacheInfo(),
      child: const CacheManagementView(),
    );
  }
}