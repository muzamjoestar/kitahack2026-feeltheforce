import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {

  // TODO: Replace this with your actual Ngrok URL (e.g., https://a1b2-c3d4.ngrok-free.app)
  static const String baseUrl = "https://janett-prepituitary-funereally.ngrok-free.dev";

  static Future<Map<String, dynamic>?> scanMatricCard(File imageFile) async {
    try {
      // 1. Prepare the Endpoint
      var uri = Uri.parse(
          "$baseUrl/verify-matric-card"); // Make sure this matches your FastAPI route!

      // 2. Prepare the Request (Multipart Request)
      var request = http.MultipartRequest('POST', uri);

      // 3. Attach the Image
      if (!await imageFile.exists()) {
        print("Error: File does not exist at ${imageFile.path}");
        return null;
      }

      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeTypeData = mimeType.split('/');

      request.files.add(await http.MultipartFile.fromPath(
        'file', // The name must match `file: UploadFile` in FastAPI
        imageFile.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));

      // 4. Send & Wait
      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 90));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Success! Return the JSON (Name, ID, Kulliyyah)
        final data = jsonDecode(response.body);

        // Map backend response to what ScannerScreen expects
        if (data['valid'] == true && data['details'] != null) {
          final details = data['details'];
          return {
            'fullName': details['name'],
            'matricNumber': details['matric_number'],
            'kulliyyah': details['kulliyyah'],
          };
        }
        return null;
      } else {
        print("Server Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print(
          "🔥🔥🔥 STOP! HERE IS THE ERROR: $e"); // Search for "STOP" in console
      return null;
    }
  }
}
