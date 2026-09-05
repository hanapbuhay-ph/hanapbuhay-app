import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hanapbuhayapp/data/repositories/mock/mock_worker_repository.dart';
import 'package:hanapbuhayapp/providers/worker_provider.dart';
import 'package:hanapbuhayapp/screens/section_1_client/job_post_detail_screen.dart';

final List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  late MockWorkerRepository repository;
  late WorkerProvider provider;

  setUp(() {
    HttpOverrides.global = _MockHttpOverrides();
    repository = MockWorkerRepository();
    provider = WorkerProvider(repository);
  });

  Widget createWidgetUnderTest(String postId) {
    return MaterialApp(
      home: ChangeNotifierProvider<WorkerProvider>.value(
        value: provider,
        child: JobPostDetailScreen(postId: postId),
      ),
    );
  }

  testWidgets('JobPostDetailScreen loads and displays post details for valid post', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest('jp1'));
    // Initially shows loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Advance time past the mock delay (300ms)
    await tester.pump(const Duration(milliseconds: 500));

    // Verify title and worker information
    expect(find.text('Expert Pipe & Leak Repair'), findsOneWidget);
    expect(find.text('Ricardo Dalisay'), findsOneWidget);
    expect(find.text('Book This Service'), findsOneWidget);
  });

  testWidgets('JobPostDetailScreen shows not found state for unknown post', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest('unknown_post_id'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('This post is no longer available'), findsOneWidget);
    expect(find.text('Go Back'), findsOneWidget);
  });
}

