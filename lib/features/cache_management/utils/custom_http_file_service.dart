import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomHttpFileService extends HttpFileService {
  /// Defines the duration for which the file is considered valid (`validTill`).
  ///
  /// After this duration has passed since the download time, the file will be treated as expired
  /// and will not be used by the cache manager, prompting a re-download upon request.
  /// Even if the file physically exists in storage (because `stalePeriod` cleanup hasn't run yet),
  /// it will be ignored if its `validTill` date has processing.
  final Duration cacheDuration;

  CustomHttpFileService({required this.cacheDuration});

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final response = await super.get(url, headers: headers);
    return CustomHttpGetResponse(response, cacheDuration);
  }
}

class CustomHttpGetResponse implements FileServiceResponse {
  final FileServiceResponse _source;
  final Duration _cacheDuration;

  CustomHttpGetResponse(this._source, this._cacheDuration);

  @override
  int get statusCode => _source.statusCode;

  @override
  Stream<List<int>> get content => _source.content;

  @override
  int? get contentLength => _source.contentLength;

  @override
  DateTime get validTill {
    // Override validTill to be cacheDuration from now, regardless of headers
    return DateTime.now().add(_cacheDuration);
  }

  @override
  String? get eTag => _source.eTag;

  @override
  String get fileExtension => _source.fileExtension;
}
