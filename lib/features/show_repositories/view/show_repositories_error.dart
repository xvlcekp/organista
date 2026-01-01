import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/show_repositories/models/repository_error.dart';

Future<void> showRepositoriesError({
  required RepositoryError repositoryError,
  required BuildContext context,
}) {
  final message = getLocalizedMessage(repositoryError, context);

  return showErrorDialog(context: context, text: message);
}

String getLocalizedMessage(RepositoryError repositoriesError, BuildContext context) {
  final loc = context.loc;

  if (repositoriesError is RepositoryGenericException) {
    return loc.repositoryGenericError;
  } else if (repositoriesError is RepositoryNotFound) {
    return loc.repositoryNotFoundError;
  } else if (repositoriesError is RepositoryCannotModifyPublic) {
    return loc.repositoryCannotModifyPublicError;
  } else if (repositoriesError is RepositoryCannotModifyOtherUsers) {
    return loc.repositoryCannotModifyOtherUsersError;
  } else if (repositoriesError is MaximumRepositoriesCountExceeded) {
    return loc.maximumRepositoriesCountExceededError(repositoriesError.maximumRepositoriesCount);
  } else if (repositoriesError is RepositoryNetworkException) {
    return loc.repositoryNetworkError;
  }
  return loc.errorUnknownText;
}
