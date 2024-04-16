import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PdfView extends StatefulWidget {
  final String pdfUrl;

  const PdfView({required this.pdfUrl, Key? key}) : super(key: key);

  @override
  _PdfViewState createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  late Future<String> _localFilePath;

  @override
  void initState() {
    super.initState();
    _localFilePath = _downloadPdf(widget.pdfUrl);
  }

  Future<String> _downloadPdf(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/downloaded.pdf';
    final response = await http.get(Uri.parse(url)); // Use http.get with the imported http package

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: FutureBuilder<String>(
        future: _localFilePath,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return PDFView(filePath: snapshot.data!);
          }
        },
      ),
    );
  }
}
