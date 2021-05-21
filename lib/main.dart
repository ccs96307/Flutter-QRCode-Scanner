import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';


// Main
void main() => runApp(MaterialApp(home: QRViewPage()));


// Main page
class QRViewPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewPageState();
}

// _QRViewPage
class _QRViewPageState extends State<QRViewPage> {
  // Init
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // Zoom
  double _zoomValue = 1.0;
  
  // Regex
  RegExp smsFormat = RegExp("smsto");

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 7, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.transparent,
              // fit: BoxFit.contain,
              child: Column(
                children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.lightGreenAccent,
                              child: IconButton(
                                icon: Icon(Icons.lightbulb_outline),
                                onPressed: () async {
                                  await controller?.toggleFlash();
                                  setState(() {
                                    // Shock
                                    Vibration.vibrate();
                                  });
                                },
                              ),
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.green,
                                width: 2.0,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.lightGreenAccent,
                            child: IconButton(
                              icon: Icon(Icons.rotate_90_degrees_ccw),
                              onPressed: () async {
                                await controller?.flipCamera();
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Slider(
                        value: _zoomValue,
                        min: 0.1,
                        max: 2.0,
                        divisions: 6,
                        label: ((_zoomValue*10).toInt()/10).toDouble().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _zoomValue = value;
                          });
                        }
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? MediaQuery.of(context).size.width/(3.0-_zoomValue)
        : MediaQuery.of(context).size.width/(3.0-_zoomValue);
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.cyanAccent,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        _launchURL();
      });
    });
  }

  void _launchURL() async {
    String openData = result!.code;
    if (smsFormat.hasMatch(openData)) {
      List<String> items = openData.split(':');

      if (Platform.isAndroid) {
        openData = "sms:" + items[1] + "?body=" + items[2];
      }
      else {
        openData = "sms:" + items[1] + "&body=" + items[2];
      }
    }

    // Shock
    HapticFeedback.vibrate();

    await canLaunch(openData)
        ? await launch(openData)
        : throw "Could not launch $openData";
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}