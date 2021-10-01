import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

import 'camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
const String ssd = "Start Classification";


class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomePage(this.cameras);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  String updateMsg = "Mise à jour";
  bool exists = false;
  _HomePageState(){
    loadModel();
  }
  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }



  loadModel() async {
    String res;
    try{
      res = await Tflite.loadModel(
        model: await _localPath+'/flowers_model.tflite',
        labels: await _localPath+"/labels.txt", isAsset: false);
    }catch(e){
      res = await Tflite.loadModel(
        model:  "assets/flowers.tflite",
        labels:  "assets/labels.txt", isAsset: true);
    }

    print(res);

  }



  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;

    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child:ListView(
            padding:EdgeInsets.zero,
            children: [
              Container(
                  color: Colors.white,
                  height: 130,
                  child: DrawerHeader(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image:AssetImage("assets/logo.png"),
                            fit: BoxFit.contain
                        )
                    ),
                  )),
              ListTile(
                title: Text(updateMsg,style: TextStyle(fontSize: 16,color: Colors.white),),
                tileColor: Colors.green,
                onTap: () {
                  update();
                },
              ),
              ListTile(
                title: Text('All rights reserved 2021'),
                onTap: () {
                  // Update the state of the app.
                  // ...
                },
              ),

            ],
          ) ,
        )
      ),
      floatingActionButton: Builder(
        builder: (context)=>
          FloatingActionButton(
            onPressed: ()=>Scaffold.of(context).openDrawer(),
            child:Icon(Icons.menu),
            backgroundColor: Colors.green,
          )

        ,
      ),
      body: Camera(
        widget.cameras,
        "",
        setRecognitions,
      ),
    );
  }
  void update() async{
    setState(() {
      updateMsg = "Mise à jour en cours ...";
    });
    var modelUri = Uri.parse("http://localhost:5000/getMobileModel");
    var labelsUri = Uri.parse("http://localhost:5000/getlabels");
    try {
      final responseM = await http.get(modelUri,
          headers: {"Connection": "keep-alive"});

      print(responseM.statusCode);
      if(responseM.contentLength>0){
        final responseL = await http.get(labelsUri,
            headers: {"Connection": "keep-alive"});
        final path = await _localPath;
        final model =  File(path+'/flowers_model.tflite');
        await model.writeAsBytes(responseM.bodyBytes);
        final labels =  File(path+'/labels.txt');
        await labels.writeAsBytes(responseL.bodyBytes);
        setState(() {
          updateMsg = "Mise à jour est installé";
        });
      }

      }

    catch (value) {
      setState(() {
        updateMsg = "Erreur dans l'installation du mise à jour";
      });
    }
  }
}
Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}






