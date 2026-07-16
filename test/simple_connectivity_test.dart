// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('Simple Connectivity Test', () async {
    print('Starting simple connectivity test...');
    final dio = Dio();
    try {
      // Just check if we can reach google or supabase.co
      final response = await dio.get('https://google.com');
      print('✅ Google is reachable. Status: ${response.statusCode}');
    } catch (e) {
      print('❌ Google unreachable: $e');
    }

    const supabaseUrl = 'https://lroliomhhjkjjczrtmph.supabase.co';
    try {
      final response = await dio.get(supabaseUrl);
      print('✅ Supabase URL reachable. Status: ${response.statusCode}');
    } catch (e) {
      print('❌ Supabase URL unreachable: $e');
    }
  });
}
