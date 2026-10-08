import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Fila local de solicitações pendentes de envio, com clientRequestId como chave
// de idempotência (seção 5.5 do PIM; PERES, 2026, p. 208; Figura 4).
// Cada linha vira uma requisição POST /api/solicitacoes quando houver conexão.
class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    final caminho = join(await getDatabasesPath(), 'integra_fila.db');
    return openDatabase(
      caminho,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE fila_solicitacoes (
            client_request_id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            criado_em TEXT NOT NULL,
            tentativas INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> enfileirar(String clientRequestId, Map<String, dynamic> payload) async {
    final db = await _database;
    await db.insert(
      'fila_solicitacoes',
      {
        'client_request_id': clientRequestId,
        'payload': jsonEncode(payload),
        'criado_em': DateTime.now().toIso8601String(),
        'tentativas': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> listarPendentes() async {
    final db = await _database;
    final linhas = await db.query('fila_solicitacoes', orderBy: 'criado_em ASC');
    return linhas
        .map((l) => {
              'clientRequestId': l['client_request_id'] as String,
              'payload': jsonDecode(l['payload'] as String) as Map<String, dynamic>,
              'tentativas': l['tentativas'] as int,
            })
        .toList();
  }

  Future<void> registrarTentativa(String clientRequestId) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE fila_solicitacoes SET tentativas = tentativas + 1 WHERE client_request_id = ?',
      [clientRequestId],
    );
  }

  Future<void> remover(String clientRequestId) async {
    final db = await _database;
    await db.delete('fila_solicitacoes', where: 'client_request_id = ?', whereArgs: [clientRequestId]);
  }
}
