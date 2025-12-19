class UserFriendlyException implements Exception {
  final String userMessage;
  final String? technicalMessage;
  final Object? originalError;

  UserFriendlyException({
    required this.userMessage,
    this.technicalMessage,
    this.originalError,
  });

  @override
  String toString() => userMessage;

  static UserFriendlyException fromError(Object error) {
    final errorStr = error.toString();

    // Erro 401 - Not Authorized
    if (errorStr.contains('401')) {
      return UserFriendlyException(
        userMessage: 'Não foi possível autenticar.',
        technicalMessage: errorStr,
        originalError: error,
      );
    }

    // Erro 403 - Forbidden
    if (errorStr.contains('403')) {
      return UserFriendlyException(
        userMessage: 'Acesso negado. Verifique suas permissões.',
        technicalMessage: errorStr,
        originalError: error,
      );
    }

    // Erro 404 - Not Found
    if (errorStr.contains('404')) {
      return UserFriendlyException(
        userMessage: 'Serviço não encontrado. Tente novamente mais tarde.',
        technicalMessage: errorStr,
        originalError: error,
      );
    }

    // Error 500/502/503 - Server
    if (errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503')) {
      return UserFriendlyException(
        userMessage: 'Servidor temporariamente indisponível. Tente novamente.',
        technicalMessage: errorStr,
        originalError: error,
      );
    }

    // Connectivity Errors
    if (errorStr.toLowerCase().contains('network') ||
        errorStr.toLowerCase().contains('connection') ||
        errorStr.toLowerCase().contains('timeout')) {
      return UserFriendlyException(
        userMessage: 'Sem conexão com a internet. Verifique sua conexão.',
        technicalMessage: errorStr,
        originalError: error,
      );
    }

    // Other DioException errors
    if (errorStr.contains('DioException')) {
      return UserFriendlyException(
        userMessage: 'Erro de comunicação com o servidor. Tente novamente.',
        technicalMessage: errorStr,
        originalError: error,
      );
    }

    // Generic error
    return UserFriendlyException(
      userMessage: 'Erro ao carregar dados. Tente novamente.',
      technicalMessage: errorStr,
      originalError: error,
    );
  }
}
