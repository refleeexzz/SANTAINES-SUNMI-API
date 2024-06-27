import 'package:mysql1/mysql1.dart';
export 'database_service.dart';
import 'package:intl/intl.dart';
import 'dart:math';


String gerarCodigoAleatorio(int tamanho) {
  const chars = '0123456789';
  final random = Random();
  return String.fromCharCodes(Iterable.generate(
    tamanho,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
  ));
}

class Contador {
  int _valorAtual = 0;

  int proximoValor() {
    _valorAtual++;
    return _valorAtual;
  }
}

class DatabaseService {
  static late final ConnectionSettings _conn;
  static MySqlConnection? _connection;

  static setMockConnection(MySqlConnection connection) {
    _connection = connection;
  }

  static Future<void> connect() async {
    _conn = ConnectionSettings(
      host: 'IP',
      port: 3306,
      user: 'user',
      password: 'password',
      db: 'db',
    );

    try {
      _connection = await MySqlConnection.connect(_conn);
      print('Conectado ao banco de dados MySQL: ');
    } catch (e) {
      print('Erro ao conectar ao banco de dados: $e');
      throw e;
    }
  }


  static Future<bool> isConnected() async {
    try {
      final result = await _connection!.query('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static MySqlConnection get connection {
    if (_connection != null) {
      return _connection!;
    } else {
      throw Exception('Não há conexão ativa com o banco de dados.');
    }
  }


  static Future<List<Map<String, dynamic>>> buscarUltimasSenhas(
      {int limite = 3}) async {
    try {
      final results = await _connection!.query(
        'SELECT numero_senha, data, horario_solicitacao FROM chamada ORDER BY idchamada DESC LIMIT ?',
        [limite],
      );

      return results.map((row) =>
      {
        'numero_senha': row['numero_senha'] as int,
        'data': row['data'],
        'horario_solicitacao': row['horario_solicitacao'],
      }).toList();
    } catch (e) {
      print('Erro ao buscar últimas senhas: $e');
      throw e;
    }
  }

  static Future<int> obterUltimaSenha() async {
    try {
      final results = await _connection!.query(
          'SELECT numero_senha FROM chamada ORDER BY idchamada DESC LIMIT 1');
      if (results.isNotEmpty) {
        return results.first['numero_senha'] as int;
      } else {
        return 0;
      }
    } catch (e) {
      print('Erro ao obter última senha: $e');
      return 0;
    }
  }

  static Future<void> inserirSenha(int numeroSenha) async {
    try {
      final agora = DateTime.now();
      final dataFormatada = DateFormat('yyyy-MM-dd HH:mm:ss').format(agora);
      final codigoAleatorio = gerarCodigoAleatorio(5);
      await _connection!.transaction((txn) async {
        await txn.query(
          'INSERT INTO chamada (numero_senha, data, horario_solicitacao, horario_atendimento, codigo) VALUES (?, ?, ?, ?, ?)',
          [numeroSenha, dataFormatada, dataFormatada, null, codigoAleatorio], // Remove codigoAleatorio de horario_atendimento
        );
      });

      print('Senha inserida com sucesso!');
    } catch (e) {
      print('Erro ao inserir senha: $e');
      throw e;
    }
  }
  }