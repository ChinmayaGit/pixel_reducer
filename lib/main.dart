import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:pixel_reducer/folderpermission.dart';
import 'package:pixel_reducer/imageCompresser.dart';
import 'package:pixel_reducer/pdfCompresser.dart';
import 'package:pixel_reducer/pdfImg.dart';

void main() => runApp(
    const GetMaterialApp(
      home: HomePage(),
    ),);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    createFolder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Compress"),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              createFolder();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.info_outline),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          containerBox(
            Colors.deepOrange,
            "Compress\nPdf",
            PdfCompressor(),
          ),
          containerBox(
            Colors.blue,
            "Compress\nImage",
            ImageCompressor(),
          ),
          containerBox(
            Colors.green,
            "Compress\nAll Pdf and Image",
            FileCompressor(),
          ),
        ],
      ),
    );
  }
}

Widget containerBox(MaterialColor color, String txt, Widget goto) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          Get.to(goto);
        },
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
