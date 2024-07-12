import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileCompressor extends StatefulWidget {
  @override
  _FileCompressorState createState() => _FileCompressorState();
}

class _FileCompressorState extends State<FileCompressor> {
  String? _selectedFolderPath;
  List<File>? _selectedFiles;
  String? _statusMessage;
  double _pdfQuality = 100;
  double _imageQuality = 1.0;
  bool _isCompressing = false;

  Future<void> _selectFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        setState(() {
          _selectedFolderPath = selectedDirectory;
          _selectedFiles = null;
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
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.paths.map((path) => File(path!)).toList();
          _selectedFolderPath = null;
        });
      }
    } catch (e) {
      print('Error selecting files: $e');
    }
  }

  Future<void> _compressFiles() async {
    if (_selectedFolderPath == null && _selectedFiles == null) {
      print('No folder or files selected.');
      return;
    }

    setState(() {
      _isCompressing = true;
    });

    try {
      Directory outputDirectory = Directory('/storage/emulated/0/PR');
      if (!outputDirectory.existsSync()) {
        outputDirectory.createSync(recursive: true);
      }

      if (_selectedFolderPath != null) {
        await _compressDirectory(Directory(_selectedFolderPath!), outputDirectory);
      } else if (_selectedFiles != null) {
        for (var file in _selectedFiles!) {
          if (file.path.endsWith('.pdf')) {
            await _compressPdfFile(file, outputDirectory.path);
          } else {
            await _compressImageFile(file, outputDirectory.path);
          }
        }
      }

      setState(() {
        _statusMessage = 'Files compressed successfully.';
      });
    } catch (e) {
      print('Error compressing files: $e');
    } finally {
      setState(() {
        _isCompressing = false;
      });
    }
  }

  Future<void> _compressDirectory(Directory inputDir, Directory outputDir) async {
    List<FileSystemEntity> entities = inputDir.listSync();

    for (var entity in entities) {
      if (entity is File) {
        if (entity.path.endsWith('.pdf')) {
          await _compressPdfFile(entity, outputDir.path, basePath: inputDir.path);
        } else if (_isImageFile(entity)) {
          await _compressImageFile(entity, outputDir.path, basePath: inputDir.path);
        }
      } else if (entity is Directory) {
        String newOutputDirPath = path.join(outputDir.path, path.basename(entity.path));
        Directory newOutputDir = Directory(newOutputDirPath);
        if (!newOutputDir.existsSync()) {
          newOutputDir.createSync(recursive: true);
        }
        await _compressDirectory(entity, newOutputDir);
      }
    }
  }

  Future<void> _compressPdfFile(File file, String outputPath, {String? basePath}) async {
    try {
      String? compressedPdf = await PdfManipulator().pdfCompressor(
        params: PDFCompressorParams(
          pdfPath: file.path,
          imageQuality: _pdfQuality.toInt(),
          imageScale: 1,
        ),
      );

      if (compressedPdf != null) {
        String relativePath = basePath != null ? path.relative(file.path, from: basePath) : path.basename(file.path);
        String newFilePath = path.join(outputPath, relativePath);
        await Directory(path.dirname(newFilePath)).create(recursive: true);
        await File(compressedPdf).copy(newFilePath);
        print('Compressed PDF saved to: $newFilePath');
      } else {
        print('Failed to compress PDF: ${file.path}');
      }
    } catch (e) {
      print('Error compressing PDF file: $e');
    }
  }

  bool _isImageFile(File file) {
    final supportedExtensions = ['jpg', 'jpeg', 'png'];
    final extension = path.extension(file.path).toLowerCase();
    return supportedExtensions.contains(extension.substring(1));
  }

  Future<void> _compressImageFile(File inputFile, String outputBasePath, {String? basePath}) async {
    String relativePath = basePath != null ? path.relative(inputFile.path, from: basePath) : path.basename(inputFile.path);
    String outputFilePath = path.join(outputBasePath, relativePath);

    await Directory(path.dirname(outputFilePath)).create(recursive: true);

    XFile? result = await FlutterImageCompress.compressAndGetFile(
      inputFile.path,
      outputFilePath,
      quality: (_imageQuality * 100).toInt(),
    );

    if (result != null) {
      print('File ${result.path} size after compression: ${await result.length()} bytes');
    } else {
      print('Compression failed for ${inputFile.path}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Compressor'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  containerBox(Colors.green, "Pick Files", _selectFiles),
                  containerBox(Colors.red, "Pick Folder", _selectFolder),
                ],
              ),
              SizedBox(height: 20),
              if (_selectedFolderPath != null) Text('Selected Folder: $_selectedFolderPath'),
              if (_selectedFiles != null) Text('Selected Files: ${_selectedFiles!.map((e) => path.basename(e.path)).join(', ')}'),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('PDF Quality:'),
                  SizedBox(width: 10),
                  Slider(
                    value: _pdfQuality,
                    min: 1,
                    max: 100,
                    divisions: 100,
                    label: _pdfQuality.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _pdfQuality = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Image Quality:'),
                  SizedBox(width: 10),
                  Slider(
                    value: _imageQuality,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: '${(_imageQuality * 100).toInt()}%',
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
                onPressed: _isCompressing ? null : _compressFiles,
                child: _isCompressing ? CircularProgressIndicator() : Text('Compress Files'),
              ),
              SizedBox(height: 20),
              if (_statusMessage != null) Text('Status: $_statusMessage'),
            ],
          ),
        ),
      ),
    );
  }
}

Widget containerBox(MaterialColor color, String txt, Function goto) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => goto(),
        child: Container(
          height: Get.height / 4,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(42)),
            boxShadow: [
              BoxShadow(
                color: color.shade400,
                offset: const Offset(0, 20),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [
                color.shade200,
                color.shade300,
                color.shade500,
                color.shade500,
              ],
              stops: const [0.1, 0.3, 0.9, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              txt,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    ),
  );
}
