import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:santainessunmi/services/database_service.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'dart:io';

final formatadorData = DateFormat('dd/MM/yyyy');
final formatadorHora = DateFormat('HH:mm:ss');
final random = Random();
final numerosAleatorios = List.generate(3, (_) => random.nextInt(100) + 1);



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  try {
    await DatabaseService.connect();
    print ('Conectado ao banco de dados!');
  }catch (e){
    print(('Erro ao conectar ao banco de dados $e'));
  }

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
int _numeroSenha = 0;

class _HomeState extends State<Home> {

  int ultimaSenha = 0;
  bool printBinded = false;
  int paperSize = 0;
  String serialNumber = "";
  String printerVersion = "";
  Future<List<Map<String, dynamic>>>? _ultimasSenhas;


  @override
  void initState() {
    super.initState();
    _bindingPrinter().then((bool? isBind) async {
      if (isBind != null && isBind) {
        final size = await SunmiPrinter.paperSize();
        final version = await SunmiPrinter.printerVersion();
        final serial = await SunmiPrinter.serialNumber();

        if (await DatabaseService.isConnected()) {
          print('Conectado ao banco de dados com sucesso!');
          setState(() {
            printBinded = isBind;
            paperSize = size;
            printerVersion = version;
            serialNumber = serial;
            _buscarUltimasSenhas();
          });
        } else {
          print("Erro ao conectar ao banco de dados.");

          // Exibir AlertDialog de erro (agora dentro do builder)
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Erro de Conexão'),
              content: Text('Não foi possível conectar ao banco de dados.'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    });
  }
  Future<bool?> _bindingPrinter() async {
    final bool? result = await SunmiPrinter.bindingPrinter();
    return result;
  }

  void _gerarEInserirSenha() async {
    final novaSenha = await _obterProximaSenha();
    await DatabaseService.inserirSenha(novaSenha);
    setState(() {
      _numeroSenha = novaSenha;
      _buscarUltimasSenhas();
    });
  }

  Future<int> _obterProximaSenha() async {
    final ultimaSenha = await DatabaseService.obterUltimaSenha();
    return ultimaSenha + 1;
  }

  Future<void> _buscarUltimasSenhas() async {
    setState(() {
      _ultimasSenhas = DatabaseService.buscarUltimasSenhas();
    });
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
          Center( //
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<Uint8List>(
                  future: readFileBytes('assets/images/logo_santa_ines.png'),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white, //
                            width: 2.0, //
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Image.memory(
                          snapshot.data!,
                          width: 400,
                          height: 400,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Erro ao carregar imagem');
                    }
                    return const CircularProgressIndicator();
                  },
                ),

                SizedBox(
                    height: 100,
                    width: 600),
                _buildButton(
                  "RETIRE SUA SENHA APERTANDO ESTE BOTÃO.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildButton(String text) {
    return ElevatedButton(
      onPressed: () async {
        _gerarEInserirSenha();
        final agora = DateTime.now();
        _HomeState()._buscarUltimasSenhas();
        await SunmiPrinter.initPrinter();
        await SunmiPrinter.startTransactionPrint(true);
        //await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
        //await SunmiPrinter.line();
        await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
        await SunmiPrinter.bold();
        await SunmiPrinter.setFontSize(SunmiFontSize.XL);
        await SunmiPrinter.printText('SUPERMERCADO SANTA INÊS');
        await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
        await SunmiPrinter.setFontSize(SunmiFontSize.XL);
        await SunmiPrinter.printText('ATENDIMENTO AÇOUGUE');
        await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
        await SunmiPrinter.line();
        await SunmiPrinter.setFontSize(SunmiFontSize.XL);
        await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
        await SunmiPrinter.bold();
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
        await SunmiPrinter.resetBold();
        await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
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
      },
      child: Text(text),
    );
  }


  Future<Uint8List> readFileBytes(String path) async {
    ByteData fileData = await rootBundle.load(path);
    return fileData.buffer.asUint8List(fileData.offsetInBytes, fileData.lengthInBytes);
  }

}
