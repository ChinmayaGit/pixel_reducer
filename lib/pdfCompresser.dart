import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:pick_or_save/pick_or_save.dart';

class PdfCompressor extends StatefulWidget {
  @override
  _PdfCompressorState createState() => _PdfCompressorState();
}

class _PdfCompressorState extends State<PdfCompressor> {
  String? _selectedFolderPath;
  List<File>? _selectedFiles;
  String? _outputFolderPath;
  String? _statusMessage;
  double _imageQuality = 100; // Initial image quality

  Future<void> _selectFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        setState(() {
          _selectedFolderPath = selectedDirectory;
          _selectedFiles = null; // Reset files if folder is picked
        });
      }
    } catch (e) {
      print('Error selecting folder: $e');
    }
  }

  Future<void> _selectFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.paths.map((path) => File(path!)).toList();
          _selectedFolderPath = null; // Reset folder if files are picked
        });
      }
    } catch (e) {
      print('Error selecting files: $e');
    }
  }

  Future<void> _compressPdfFiles(String folderPath, String outputPath) async {
    try {
      Directory directory = Directory(folderPath);
      List<FileSystemEntity> entities = directory.listSync();

      for (FileSystemEntity entity in entities) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          await _compressPdfFile(entity, outputPath);
        } else if (entity is Directory) {
          // Recursively compress PDFs in subfolders
          await _compressPdfFiles(entity.path, outputPath);
        }
      }
      setState(() {
        _statusMessage = 'PDF files compressed successfully.';
      });
    } catch (e) {
      print('Error compressing PDF files: $e');
    }
  }

  Future<void> _compressPdfFile(File file, String outputPath) async {
    try {
      String? compressedPdf = await PdfManipulator().pdfCompressor(
        params: PDFCompressorParams(
          pdfPath: file.path,
          imageQuality: _imageQuality.toInt(), // Use selected image quality
          imageScale: 1, // Adjust as needed (1.0 means no scaling)
        ),
      );

      if (compressedPdf != null) {
        // Determine relative path within selected folder
        String relativePath = path.relative(file.path, from: _selectedFolderPath ?? '');

        // Construct output path based on relative path
        String newFilePath = path.join(outputPath, relativePath);

        // Ensure directories exist
        await Directory(path.dirname(newFilePath)).create(recursive: true);

        // Copy compressed PDF to output directory
        await File(compressedPdf).copy(newFilePath);

        print('Compressed PDF saved to: $newFilePath');
      } else {
        print('Failed to compress PDF: ${file.path}');
      }
    } catch (e) {
      print('Error compressing PDF file: $e');
    }
  }

  Future<void> _compressSelectedFiles(String outputPath) async {
    try {
      for (var file in _selectedFiles!) {
        await _compressPdfFile(file, outputPath);
      }

      setState(() {
        _statusMessage = 'PDF files compressed successfully.';
      });
    } catch (e) {
      print('Error compressing selected PDF files: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Compressor'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(

          children: <Widget>[
            Row(
              children: [
                containerBox(Colors.green,"Pick Files",_selectFiles),
                containerBox(Colors.red,"Pick Folder",_selectFolder),

              ],
            ),

            SizedBox(height: 20),
            if (_selectedFolderPath != null)
              Text('Selected Folder: $_selectedFolderPath'),
            if (_selectedFiles != null)
              Text('Selected Files: ${_selectedFiles!.map((e) => e.path.split('/').last).join(', ')}'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Pdf Quality:'),
                SizedBox(width: 10),
                Slider(
                  value: _imageQuality,
                  min: 1,
                  max: 100,
                  divisions: 100,
                  label: _imageQuality.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _imageQuality = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_selectedFolderPath != null || _selectedFiles != null) {
                  // Specify the output directory directly
                  _outputFolderPath = '/storage/emulated/0/PR'; // Use specific directory

                  Directory outputDirectory = Directory(_outputFolderPath!);
                  if (!await outputDirectory.exists()) {
                    await outputDirectory.create(recursive: true);
                  }

                  if (_selectedFolderPath != null) {
                    // Compress PDF files in the selected folder
                    await _compressPdfFiles(_selectedFolderPath!, _outputFolderPath!);
                  } else if (_selectedFiles != null) {
                    // Compress the selected PDF files
                    await _compressSelectedFiles(_outputFolderPath!);
                  }
                }
              },
              child: Text('Compress PDF Files'),
            ),
            SizedBox(height: 20),
            if (_statusMessage != null)
              Text('Status: $_statusMessage'),
          ],
        ),
      ),
    );
  }
}
containerBox(MaterialColor color, String txt, goto) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: goto,
        child: Container(
          height: Get.height / 4,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(42)),
            boxShadow: [
              BoxShadow(
                color: color.shade400, // Using MaterialColor shades
                offset: const Offset(0, 20),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [
                color.shade200, // Using MaterialColor shades
                color.shade300, // Using MaterialColor shades
                color.shade500, // Using MaterialColor shades
                color.shade500, // Using MaterialColor shades
              ],
              stops: const [0.1, 0.3, 0.9, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              txt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    ),
  );
}

