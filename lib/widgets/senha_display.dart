import 'package:flutter/material.dart';
import 'package:santainessunmi/services/database_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SenhasDisplay extends StatefulWidget {
  @override
  _SenhasDisplayState createState() => _SenhasDisplayState();
}

class _SenhasDisplayState extends State<SenhasDisplay> {
  Future<List<Map<String, dynamic>>>? _ultimasSenhas;

  @override
  void initState() {
    super.initState();
    _buscarUltimasSenhas();
  }

  Future<void> _buscarUltimasSenhas() async {
    setState(() {
      _ultimasSenhas = DatabaseService.buscarUltimasSenhas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>( // Altere o tipo aqui
      future: _ultimasSenhas,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Erro ao buscar senhas: ${snapshot.error}');
        } else {
          final ultimasSenhas = snapshot.data!;
          return ListView.builder(
            itemCount: ultimasSenhas.length,
            itemBuilder: (context, index) {
              final senhaData = ultimasSenhas[index]; // Obtém o mapa da senha
              return ListTile(
                title: Text('Senha: ${senhaData['numero_senha']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solicitado em: ${senhaData['horario_solicitacao']}'),
                    if (senhaData['horario_atendimento'] !=null)
                      Text('Atendido em: ${senhaData['horario_atendimento']}'),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}
