// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Verify Supabase Connectivity and Schema', () async {
    // Credentials
    const supabaseUrl = 'https://lroliomhhjkjjczrtmph.supabase.co';
    const supabaseKey = 'sb_publishable_1h0tF13PS3hoOY5EJ5IThw_4VRcLCQg';

    print('\n--- DIAGNOSTIC START ---');
    print('Target: $supabaseUrl');

    final client = SupabaseClient(supabaseUrl, supabaseKey);

    // Helper to check table
    Future<void> checkTable(String table) async {
      print('Checking table: $table...');
      try {
        // Use timeout to avoid hanging forever
        await client
            .from(table)
            .select()
            .limit(1)
            .timeout(const Duration(seconds: 10));
        print('✅ Table "$table" exists and is accessible.');
      } on PostgrestException catch (e) {
        if (e.message.contains('relation') &&
            e.message.contains('does not exist')) {
          print('❌ Table "$table" DOES NOT EXIST.'); // 404 for table
        } else {
          print('❌ Error accessing "$table": ${e.message} (Code: ${e.code})');
        }
      } catch (e) {
        print('❌ Error accessing "$table": $e');
      }
    }

    try {
      await checkTable('profiles');
      await checkTable('posts');
      await checkTable('comments');
    } catch (e) {
      print('❌ FATAL: Test execution failed: $e');
    }

    print('--- DIAGNOSTIC END ---\n');
  });
}
