import 'package:dio/dio.dart';
import 'dart:io';

void main() async {
  final dio = Dio();
  final url = 'https://places.googleapis.com/v1/places:searchNearby';

  try {
    final response = await dio.post(
      url,
      data: {
        "includedTypes": ["gas_station"],
        "maxResultCount": 10,
        "locationRestriction": {
          "circle": {
            "center": {"latitude": 2.046934, "longitude": 45.318162},
            "radius": 10000.0,
          },
        },
      },
      options: Options(
        headers: {
          'X-Goog-Api-Key': 'AIzaSyAHOeUAFjHezZRr9FT4RdGXxBpi9RQmKYE',
          'X-Goog-FieldMask':
              'places.displayName,places.formattedAddress,places.location',
        },
      ),
    );
    File('places_new_error.txt').writeAsStringSync(response.data.toString());
  } on DioException catch (e) {
    File(
      'places_new_error.txt',
    ).writeAsStringSync('Error: ${e.response?.data}');
  }
}
