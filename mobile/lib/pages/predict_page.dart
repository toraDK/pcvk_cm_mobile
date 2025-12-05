import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PredictPage extends StatefulWidget {
  @override
  _PredictPageState createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  XFile? image;           // gambar dari picker
  Uint8List? imageBytes;    // untuk Flutter Web
  String? result;
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();

  pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      imageBytes = await picked.readAsBytes(); // << WAJIB untuk WEB
      setState(() => image = picked);
      // await sendToAPI(picked);
    }
  }

  pickFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      imageBytes = await picked.readAsBytes(); // << WAJIB untuk WEB
      setState(() => image = picked);
      // await sendToAPI(picked);
    }
  }

  sendToAPI(XFile file) async {
    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("http://IP-OR-URL-KAMU:5000/predict"),
      );

      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      var response = await request.send();
      var body = await response.stream.bytesToString();

      print("API Response: $body");

      var jsonData = json.decode(body);

      setState(() {
        result = jsonData["kelas"].toString();
      });
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PCVK Prediction")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ==== PREVIEW GAMBAR ====
            imageBytes != null
                ? Image.memory(imageBytes!, height: 200, fit: BoxFit.cover)
                : Container(
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Text("Belum ada gambar"),
                  ),

            SizedBox(height: 30),

            // ==== BUTTON ====
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: pickImage, child: Text("Pilih Foto")),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: pickFromCamera,
                  child: Text("Ambil Kamera"),
                ),
              ],
            ),

            SizedBox(height: 30),

            // ==== LOADING / RESULT ====
            isLoading
                ? CircularProgressIndicator()
                : result != null
                ? Text(
                    "Hasil Prediksi: $result",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  )
                : Text("Belum ada hasil"),
          ],
        ),
      ),
    );
  }
}
