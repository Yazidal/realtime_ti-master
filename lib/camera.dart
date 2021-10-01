import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';


typedef void Callback(List<dynamic> list, int h, int w);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final String model;
  Camera(this.cameras, this.model, this.setRecognitions);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;
  var _recognition;
  var resp;
  bool respond = false;
  var data;
  List<String> infos;
   getJson() async{
    var jsonData = await rootBundle.loadString('assets/information.json');
    setState(() {
      data = json.decode(jsonData);
    });
    print(data[0]);
  }

  List<String> getInfo(label){
     for(int i = 0;i<data.length;i++){
       if(data[i]["name"] == label) return [data[i]["desc"],data[i]["link"]];
     }
}
  @override
  void initState() {
    super.initState();
    getJson();
    ///now = [0,0,0];
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        controller.startImageStream((CameraImage img) async{

          if (!isDetecting) {
            isDetecting = true;

            int startTime = new DateTime.now().millisecondsSinceEpoch;

            Tflite.runModelOnFrame(
                bytesList: img.planes.map((plane) {
                  return plane.bytes;
                }).toList(),
                imageHeight:img.height,
                imageWidth: img.width,
                imageMean: 127.5,
                imageStd:127.5,
                numResults: 1,
            ).then((recognitions) {
              recognitions.map((res) {
              });
              _recognition = recognitions;
              infos = getInfo(_recognition[0]["label"]);
              print(recognitions);
              int endTime = new DateTime.now().millisecondsSinceEpoch;
              print("Detection took ${endTime - startTime}");
              widget.setRecognitions(recognitions, img.height,                                                                                                                                                                                                                                                                                                                                                                                                                img.width);

              isDetecting = false;
            });
            /*
            if(_recognition[0]["index"] != 0){
               resp = await http.get(new Uri.http("localhost:3004","/flowers/"+_recognition[0]["index"].toString()));
              if(resp.statusCode == 200){
                setState(){
                  respData = json.decode(resp.body);
                  respond = true;
                }
              }
            }*/
          }
        });
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }
    var tmp = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children:[Container(
            height: tmp.height*0.7,
            width: tmp.width*0.9,
            child: CameraPreview(controller),
        ),_recognition != null ?Positioned(
            bottom: 20,
                 left: 15,
                 child:Card(
                   child:Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Column(children:[Text(
                     _recognition[0]["label"]+" : "+(_recognition[0]["confidence"] * 100).toStringAsFixed(0)+"%",
                     style: TextStyle(
                       fontSize: 24,
                       color: Colors.green[600],
                       fontWeight: FontWeight.w500,
                     ), //Textstyle
                 ),

                 ]),
                   ),) //Column
              )


          : Text(""),] ,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width:300,child: infos!=null? Text(infos[0],
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,)):Text(""))
            ],
          ),
        )
      ],
    );


  }
}
