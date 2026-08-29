import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock/mock_auth_repository.dart';
import '../data/repositories/api/api_auth_repository.dart';

/// Single swap point for repository implementations.
final AuthRepository authRepository = AuthRepository.useMock
    ? MockAuthRepository()
    : ApiAuthRepository();
