import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'encryption_service.dart';

class ApiService {
  final String baseUrl;
  final String webViewerUrl; // The domain where the web viewer is hosted

  ApiService({
    required this.baseUrl,
    required this.webViewerUrl,
  });

  /// Uploads a cropped JPEG prescription image to the proxy server for Gemini OCR.
  /// Returns a Map representation of the structured medication JSON from Gemini.
  Future<Map<String, dynamic>> processPrescriptionOCR(File imageFile) async {
    final uri = Uri.parse('$baseUrl/ocr');
    final request = http.MultipartRequest('POST', uri);

    // Attach prescription image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'OCR processing failed.');
    }
  }

  /// Sends the encrypted package to the backend and returns the formatted viewer URL
  /// which embeds the Secret Key inside the URL Hash (#) fragment.
  Future<String> generateShareQrUrl(EncryptionResult encryptionResult) async {
    final uri = Uri.parse('$baseUrl/share');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(encryptionResult.toJsonMap()),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      final String dataId = responseData['dataId'];
      
      // Zero-Knowledge Web Viewer Link:
      // dataId is passed to query params, secretKey is kept behind the '#' hash fragment
      return '$webViewerUrl?id=$dataId#${encryptionResult.secretKey}';
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to upload share data.');
    }
  }
}
