import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock/mock_auth_repository.dart';
import '../data/repositories/api/api_auth_repository.dart';
import '../data/repositories/worker_repository.dart';
import '../data/repositories/mock/mock_worker_repository.dart';
import '../data/repositories/api/api_worker_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/mock/mock_booking_repository.dart';
import '../data/repositories/api/api_booking_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/mock/mock_report_repository.dart';
import '../data/repositories/api/api_report_repository.dart';

/// Single swap point for repository implementations.
final AuthRepository authRepository = AuthRepository.useMock
    ? MockAuthRepository()
    : ApiAuthRepository();

final WorkerRepository workerRepository = AuthRepository.useMock
    ? MockWorkerRepository()
    : ApiWorkerRepository();

final BookingRepository bookingRepository = AuthRepository.useMock
    ? MockBookingRepository()
    : ApiBookingRepository();

final ReportRepository reportRepository = AuthRepository.useMock
    ? MockReportRepository()
    : ApiReportRepository();
