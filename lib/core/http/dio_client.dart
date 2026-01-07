import 'package:dio/dio.dart';

final dioProvider = DioProvider.instance;

class DioProvider {
  DioProvider._();

  static final instance = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );
}

