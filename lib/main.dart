import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:web_socket_channel/io.dart';

final formatadorData = DateFormat('dd/MM/yyyy');
final formatadorHora = DateFormat('HH:mm:ss');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunmi Printer',
      theme: ThemeData(
        primaryColor: const Color(0xFFDC853D),
        scaffoldBackgroundColor: const Color(0xFFDC853D),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            color: Color(0xFFDC853D),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0027DF),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 40),
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final IOWebSocketChannel _channel;
  int _numeroSenha = 0;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    _channel = IOWebSocketChannel.connect(
      Uri.parse('ws://192.168.1.121:8080'),
    );

    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['tipo'] == 'ultima_senha') {
        setState(() {
          _numeroSenha = data['senha'];
        });
      } else if (data['tipo'] == 'nova_senha') {
        setState(() {
          _numeroSenha = data['senha'];
          _isConnected = true;
        });
        if (_isConnected) {
          _imprimirSenha();
        } else {
          print("Erro: Não foi possível conectar ao servidor WebSocket.");
        }
      } else if (data['tipo'] == 'erro') {
        print("Erro do servidor: ${data['mensagem']}");
      }
    }, onDone: () {
      print('Conexão WebSocket fechada');
    }, onError: (error) {
      print('Erro WebSocket: $error');
    });
  }

  void _buscarUltimaSenha() {
    _channel.sink.add('buscar_ultima_senha');
  }

  void _verUltimaSenha() {
    _channel.sink.add('ver_ultima_senha');
  }

  void _gerarEInserirSenha() {
    _channel.sink.add('criar_e_imprimir_senha');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: const Color(0xFFF58634),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _gerarEInserirSenha();
                    _imprimirSenha();
                  },
                  child: Text("RETIRE SUA SENHA APERTANDO ESTE BOTÃO."),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _imprimirSenha() async {
    final agora = DateTime.now();
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText('SUPERMERCADO SANTA INÊS');
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText('ATENDIMENTO AÇOUGUE');
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.line();
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printText('SENHA: $_numeroSenha');
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.line();
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText("FIQUE A VONTADE PARA FAZER");
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText("SUAS COMPRAS.");
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText("APONTE A CÂMERA NO QR CODE E ACOMPANHE A FILA PELO CELULAR.");
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.resetBold();
    await SunmiPrinter.lineWrap(5);
    await SunmiPrinter.printQRCode(
      'http://www.supermercadosantaines.com.br/',
      size: 6,
    );
    await SunmiPrinter.lineWrap(5);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
    await SunmiPrinter.printText('Data: ${formatadorData.format(agora)}');
    await SunmiPrinter.setAlignment(SunmiPrintAlign.RIGHT);
    await SunmiPrinter.printText('Hora: ${formatadorHora.format(agora)}');
    await SunmiPrinter.lineWrap(2);
    await SunmiPrinter.exitTransactionPrint(true);
    await SunmiPrinter.cut();
  }
  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}

  Future<Uint8List> readFileBytes(String path) async {
    ByteData fileData = await rootBundle.load(path);
    return fileData.buffer.asUint8List(fileData.offsetInBytes, fileData.lengthInBytes);
  }


