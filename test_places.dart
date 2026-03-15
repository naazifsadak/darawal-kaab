import 'package:dio/dio.dart';
import 'dart:io';

void main() async {
  final dio = Dio();
  final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  try {
    final response = await dio.get(
      url,
      queryParameters: {
        'location': '2.046934,45.318162',
        'radius': 10000,
        'keyword': 'gas station',
        'key': 'AIzaSyAHOeUAFjHezZRr9FT4RdGXxBpi9RQmKYE',
      },
    );
    File('places_error.txt').writeAsStringSync(response.data.toString());
  } on DioException catch (e) {
    File('places_error.txt').writeAsStringSync('Error: ${e.response?.data}');
  }
}
