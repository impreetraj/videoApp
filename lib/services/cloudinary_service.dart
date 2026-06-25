import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {

  static const String cloudName = 'dtdmunvih'; 
  
  static const String uploadPreset = 'video-upload'; 

  static Future<String?> uploadFile(File file, String resourceType) async {
    try {
    
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url']; 
      } else {
        print('Upload failed: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  static Future<String?> uploadImage(File file) async {
    return uploadFile(file, 'image');
  }

  static Future<String?> uploadVideo(File file) async {
    return uploadFile(file, 'video');
  }
}
