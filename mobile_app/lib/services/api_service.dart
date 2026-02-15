import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  // PERMENANT URL for the FastAPI backend using Google Cloud Run
  static const String baseUrl = "https://uniserve-backend-951442291563.us-central1.run.app"; 

  static Future<Map<String, dynamic>?> scanMatricCard(File imageFile) async {
    try {
      // 1. Prepare the Endpoint
      var uri = Uri.parse("$baseUrl/verify-matric"); // Make sure this matches your FastAPI route!

      // 2. Prepare the Request (Multipart Request)
      var request = http.MultipartRequest('POST', uri);
      
      // 3. Attach the Image
      final mimeTypeData = lookupMimeType(imageFile.path)!.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'file', // The name must match `file: UploadFile` in FastAPI
        imageFile.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));

      // 4. Send & Wait
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Success! Return the JSON (Name, ID, Kulliyyah)
        return jsonDecode(response.body);
      } else {
        print("Server Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Connection Error: $e");
      return null;
    }
  }
}