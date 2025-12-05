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
        // GANTI DENGAN IP KOMPUTER KAMU !!!
        Uri.parse("http://127.0.0.1:5000/predict"),  
        // atau http://10.0.2.2:5000/predict kalau pakai Android Emulator
      );

      // ← NAMA FIELD DIUBAH JADI "image"
      request.files.add(
        await http.MultipartFile.fromPath("image", file.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("Status: ${response.statusCode}");
      print("Response: $responseBody");

      if (response.statusCode == 200) {
        var jsonData = json.decode(responseBody);
        setState(() {
          result = jsonData["kelas"]?.toString() ?? "Tidak ada hasil";
        });
      } else {
        setState(() {
          result = "Server Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    } finally {
      setState(() => isLoading = false);
    }
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

            // GANTI SELURUH BAGIAN BUTTON DENGAN INI
SizedBox(height: 40),

// TIGA TOMBOL SEJAJAR DENGAN UKURAN SAMA
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // 1. TOMBOL PILIH FOTO
    ElevatedButton.icon(
      onPressed: pickImage,
      icon: Icon(Icons.photo_library, size: 20),
      label: Text("Pilih Foto"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),

    SizedBox(width: 15),

    // 2. TOMBOL AMBIL KAMERA
    ElevatedButton.icon(
      onPressed: pickFromCamera,
      icon: Icon(Icons.camera_alt, size: 20),
      label: Text("Ambil Kamera"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),

    SizedBox(width: 15),

    // 3. TOMBOL PREDIKSI SEKARANG (UKURAN & TINGGI SAMA!)
    ElevatedButton(
      onPressed: (image != null) && !isLoading
          ? () => sendToAPI(image!)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14), // sama dengan yang lain
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              "PREDIKSI SEKARANG",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
    ),
  ],
),

            // TAMPILKAN HASIL PREDIKSI JIKA ADA
            SizedBox(height: 30),
            if (result != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  result!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
