import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/biometrico.dart';
import '../models/empleado.dart';

class AzureFaceService {
  final String azureEndpoint;
  final String apiKey;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AzureFaceService({
    required this.azureEndpoint,
    required this.apiKey,
  });

  // Detectar rostros en una imagen y extraer faceId
  Future<List<String>> detectFaces(Uint8List imageBytes) async {
    try {
      final String detectUrl = '$azureEndpoint/face/v1.0/detect';
      
      final Map<String, String> queryParams = {
        'returnFaceId': 'true',
        'recognitionModel': 'recognition_04',
        'detectionModel': 'detection_01',
      };
      
      final Uri uri = Uri.parse(detectUrl).replace(queryParameters: queryParams);
      
      final http.Response response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Ocp-Apim-Subscription-Key': apiKey,
        },
        body: imageBytes,
      );
      
      if (response.statusCode == 200) {
        List<dynamic> faces = jsonDecode(response.body);
        return faces.map<String>((face) => face['faceId'] as String).toList();
      } else {
        print('Error detectando rostros: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error en detectFaces: $e');
      return [];
    }
  }

  // Descargar imagen desde URL y convertir a bytes
  Future<Uint8List?> downloadImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error descargando imagen: $e');
      return null;
    }
  }

  // Verificar si dos rostros son de la misma persona
  Future<bool> verifyFaces(String faceId1, String faceId2) async {
    try {
      final String verifyUrl = '$azureEndpoint/face/v1.0/verify';
      
      final Map<String, dynamic> body = {
        'faceId1': faceId1,
        'faceId2': faceId2,
      };
      
      final http.Response response = await http.post(
        Uri.parse(verifyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': apiKey,
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final bool isIdentical = result['isIdentical'] ?? false;
        final double confidence = result['confidence'] ?? 0.0;
        
        // Considerar que son la misma persona si la confianza es mayor a 0.7
        return isIdentical && confidence > 0.7;
      } else {
        print('Error verificando rostros: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error en verifyFaces: $e');
      return false;
    }
  }

  // Identificar empleado por reconocimiento facial
  Future<Empleado?> identificarEmpleadoPorRostro(Uint8List imageBytes, String sedeId) async {
    try {
      print('Iniciando reconocimiento facial...');
      
      // 1. Detectar rostros en la imagen capturada
      final List<String> capturedFaceIds = await detectFaces(imageBytes);
      
      if (capturedFaceIds.isEmpty) {
        print('No se detectó ningún rostro en la imagen');
        return null;
      }
      
      final String capturedFaceId = capturedFaceIds.first;
      print('Rostro detectado con ID: $capturedFaceId');
      
      // 2. Obtener todos los empleados de la sede que tengan datos biométricos
      final empleadosQuery = await _firestore
          .collection('empleados')
          .where('sedeId', isEqualTo: sedeId)
          .where('hayDatosBiometricos', isEqualTo: true)
          .get();
      
      print('Empleados con biométricos encontrados: ${empleadosQuery.docs.length}');
      
      // 3. Para cada empleado, comparar con su imagen biométrica
      for (final empleadoDoc in empleadosQuery.docs) {
        try {
          final empleado = Empleado.fromMap(empleadoDoc.data());
          print('Verificando empleado: ${empleado.nombre} ${empleado.apellidos}');
          
          // Obtener el biométrico del empleado
          final biometricoQuery = await _firestore
              .collection('biometricos')
              .where('empleadoId', isEqualTo: empleado.id)
              .limit(1)
              .get();
          
          if (biometricoQuery.docs.isEmpty) {
            print('No se encontró biométrico para empleado ${empleado.id}');
            continue;
          }
          
          final biometrico = Biometrico.fromMap(biometricoQuery.docs.first.data());
          print('Biométrico encontrado: ${biometrico.datoFacial}');
          
          // Descargar la imagen biométrica
          final Uint8List? storedImageBytes = await downloadImageFromUrl(biometrico.datoFacial);
          
          if (storedImageBytes == null) {
            print('No se pudo descargar la imagen biométrica');
            continue;
          }
          
          // Detectar rostros en la imagen almacenada
          final List<String> storedFaceIds = await detectFaces(storedImageBytes);
          
          if (storedFaceIds.isEmpty) {
            print('No se detectó rostro en la imagen almacenada');
            continue;
          }
          
          final String storedFaceId = storedFaceIds.first;
          print('Comparando rostros: $capturedFaceId vs $storedFaceId');
          
          // Verificar si son el mismo rostro
          final bool isMatch = await verifyFaces(capturedFaceId, storedFaceId);
          
          if (isMatch) {
            print('¡Empleado identificado: ${empleado.nombre} ${empleado.apellidos}!');
            return empleado;
          }
        } catch (e) {
          print('Error procesando empleado ${empleadoDoc.id}: $e');
          continue;
        }
      }
      
      print('No se encontró coincidencia facial');
      return null;
    } catch (e) {
      print('Error en identificarEmpleadoPorRostro: $e');
      return null;
    }
  }
}