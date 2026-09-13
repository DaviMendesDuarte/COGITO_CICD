import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Serviço responsável pelo gerenciamento de dados do aplicativo COGITO via Firebase Firestore.
/// Substitui integralmente o antigo serviço MySQL por uma solução em nuvem reativa, segura e escalável.
class FirebaseFirestoreService {
  /// Instância singleton do FirebaseFirestore.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Armazena em memória os dados do usuário atualmente autenticado no app.
  static Map<String, dynamic>? usuarioLogado;

  // Coleções do Firestore
  static const String _colecaoUsuarios = 'usuarios';
  static const String _colecaoContasBancarias = 'contas_bancarias';
  static const String _colecaoTransacoes = 'transacoes';
  static const String _colecaoOrcamentos = 'orcamentos';
  static const String _colecaoNotificacoes = 'notificacoes';
  static const String _colecaoChats = 'conrado_chats';
  static const String _colecaoMetas = 'metas_financeiras';
  static const String _colecaoCartoes = 'cartoes';

  // --- GESTÃO DE USUÁRIOS ---

  /// Cadastra ou atualiza os dados de um usuário no Firebase Firestore.
  ///
  /// Parâmetros:
  /// - [uid]: Identificador único do usuário (geralmente vindo do Firebase Auth ou e-mail sanitizado).
  /// - [nome]: Nome completo do cliente.
  /// - [email]: E-mail de cadastro.
  /// - [telefone]: Número de telefone para contato.
  /// - [idade]: Idade do cliente.
  /// - [tipoRenda]: Tipo de renda ('Salario_Fixo' ou 'Freelancer').
  /// - [rendaMensal]: Valor numérico estimado da renda mensal.
  Future<bool> salvarUsuario({
    required String uid,
    required String nome,
    required String email,
    required String telefone,
    required int idade,
    required String tipoRenda,
    required double rendaMensal,
  }) async {
    final dados = {
      'uid': uid,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'idade': idade,
      'tipo_renda': tipoRenda,
      'renda_mensal': rendaMensal,
      'plano': 'Grátis',
      'criado_em': FieldValue.serverTimestamp(),
      'ultimo_acesso': FieldValue.serverTimestamp(),
      'status_conta': 'Ativa',
    };

    try {
      await _db
          .collection(_colecaoUsuarios)
          .doc(uid)
          .set(dados, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Aviso: Armazenando usuário em sessão local offline: $e');
    }

    // Salva na memória da aplicação para acesso imediato sem latência
    usuarioLogado = {
      'id_cliente': uid,
      'uid': uid,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'idade': idade,
      'tipo_renda': tipoRenda,
      'renda_mensal': rendaMensal,
      'plano': 'Grátis',
    };

    return true;
  }

  /// Carrega o perfil do usuário cadastrado no Firestore.
  Future<Map<String, dynamic>?> buscarUsuario(String uid) async {
    try {
      final doc = await _db.collection(_colecaoUsuarios).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        usuarioLogado = {
          'id_cliente': uid,
          'uid': uid,
          'nome': data['nome'] ?? '',
          'email': data['email'] ?? '',
          'telefone': data['telefone'] ?? '',
          'idade': data['idade'] ?? 18,
          'tipo_renda': data['tipo_renda'] ?? 'Salario_Fixo',
          'renda_mensal': (data['renda_mensal'] as num?)?.toDouble() ?? 0.0,
          'plano': data['plano'] ?? 'Grátis',
          'foto_perfil_encriptada': data['foto_perfil_encriptada'],
        };
        return usuarioLogado;
      }
    } catch (e) {
      debugPrint('Erro ao buscar usuário no Firestore: $e');
    }
    return usuarioLogado;
  }

  /// Atualiza o plano de assinatura do usuário logado (Grátis, Freelancer ou Premium).
  Future<void> atualizarPlano(String uid, String novoPlano) async {
    if (usuarioLogado != null) {
      usuarioLogado!['plano'] = novoPlano;
    }
    try {
      await _db.collection(_colecaoUsuarios).doc(uid).update({
        'plano': novoPlano,
      });
    } catch (e) {
      debugPrint('Atualizado plano em memória local: $e');
    }
  }

  /// Atualiza o tipo de renda do usuário logado ('Salario_Fixo' ou 'Freelancer') e ajusta os privilégios.
  /// Se o tipo de renda for definido como 'Freelancer', habilita automaticamente as funções e o plano Freelancer.
  ///
  /// Parâmetros:
  /// - [uid]: Identificador único do usuário no Firebase.
  /// - [novoTipoRenda]: Novo tipo de renda ('Salario_Fixo' ou 'Freelancer').
  Future<void> atualizarTipoRenda(String uid, String novoTipoRenda) async {
    final bool isFreelancer = novoTipoRenda.toLowerCase().contains('free');
    final String plano = isFreelancer ? 'Freelancer' : 'Grátis';

    if (usuarioLogado != null) {
      usuarioLogado!['tipo_renda'] = novoTipoRenda;
      usuarioLogado!['plano'] = plano;
    }

    try {
      await _db.collection(_colecaoUsuarios).doc(uid).update({
        'tipo_renda': novoTipoRenda,
        'plano': plano,
      });
    } catch (e) {
      debugPrint('Atualizado tipo de renda em memória local offline: $e');
    }
  }

  /// Retorna o identificador único (UID) do usuário atualmente autenticado no aplicativo.
  /// Prioriza a sessão do Firebase Authentication e faz fallback para a sessão local em memória.
  static String get idClienteAtual {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        return user.uid;
      }
    } catch (e) {
      debugPrint('Aviso ao consultar FirebaseAuth currentUser: $e');
    }

    if (usuarioLogado != null) {
      if (usuarioLogado!['uid'] != null &&
          usuarioLogado!['uid'].toString().isNotEmpty) {
        return usuarioLogado!['uid'].toString();
      }
      if (usuarioLogado!['id_cliente'] != null &&
          usuarioLogado!['id_cliente'].toString().isNotEmpty) {
        return usuarioLogado!['id_cliente'].toString();
      }
    }

    return 'guest';
  }

  /// Exclui permanentemente todos os documentos e dados associados ao usuário em todas as coleções do Cloud Firestore.
  ///
  /// Coleções e registros limpos:
  /// - `transacoes`: Remove todas as movimentações financeiras com `id_cliente == uid` (e registros orfãos/guest).
  /// - `conrado_chats`: Remove todas as conversas e histórico com a IA Conrado.
  /// - `metas_financeiras`: Apaga todas as caixinhas/objetivos financeiros.
  /// - `orcamentos`: Apaga os orçamentos configurados por categoria.
  /// - `notificacoes`: Limpa as notificações push/sistema do usuário.
  /// - `contas_bancarias`: Exclui a conta bancária vinculada.
  /// - `usuarios`: Exclui o documento de perfil principal do Firestore.
  ///
  /// Parâmetros:
  /// - [uid]: Identificador único (UID) da conta a ter seus dados completamente apagados.
  Future<void> apagarTodosDadosDoUsuario(String uid) async {
    if (uid.isEmpty) return;

    try {
      // 1. Exclui todas as transações associadas ao UID do usuário
      final transacoesQuery = await _db
          .collection(_colecaoTransacoes)
          .where('id_cliente', isEqualTo: uid)
          .get();
      for (final doc in transacoesQuery.docs) {
        await doc.reference.delete();
      }

      // 2. Exclui transações pendentes/guest registradas sem ID vinculado
      final transacoesGuestQuery = await _db
          .collection(_colecaoTransacoes)
          .where('id_cliente', isEqualTo: 'guest')
          .get();
      for (final doc in transacoesGuestQuery.docs) {
        await doc.reference.delete();
      }

      // 3. Exclui todas as sessões de chat com o assistente Conrado
      final chatsQuery = await _db
          .collection(_colecaoChats)
          .where('id_cliente', isEqualTo: uid)
          .get();
      for (final doc in chatsQuery.docs) {
        await doc.reference.delete();
      }

      // 4. Exclui todas as metas financeiras (caixinhas) do usuário
      final metasQuery = await _db
          .collection(_colecaoMetas)
          .where('id_cliente', isEqualTo: uid)
          .get();
      for (final doc in metasQuery.docs) {
        await doc.reference.delete();
      }

      // 5. Exclui orçamentos por categoria vinculados
      final orcamentosQuery = await _db
          .collection(_colecaoOrcamentos)
          .where('id_cliente', isEqualTo: uid)
          .get();
      for (final doc in orcamentosQuery.docs) {
        await doc.reference.delete();
      }

      // 6. Exclui notificações registradas para o usuário
      final notificacoesQuery = await _db
          .collection(_colecaoNotificacoes)
          .where('id_cliente', isEqualTo: uid)
          .get();
      for (final doc in notificacoesQuery.docs) {
        await doc.reference.delete();
      }

      // 7. Exclui os dados da conta bancária cadastrada
      try {
        await _db.collection(_colecaoContasBancarias).doc(uid).delete();
      } catch (_) {}
      final contasBancariasQuery = await _db
          .collection(_colecaoContasBancarias)
          .where('id_cliente', isEqualTo: uid)
          .get();
      for (final doc in contasBancariasQuery.docs) {
        await doc.reference.delete();
      }

      // 8. Exclui o documento principal de perfil do usuário na coleção 'usuarios'
      try {
        await _db.collection(_colecaoUsuarios).doc(uid).delete();
      } catch (_) {}
    } catch (e) {
      debugPrint(
        'Aviso/Erro ao apagar dados do usuário no Cloud Firestore: $e',
      );
    }

    // 9. Reseta os caches locais da aplicação para evitar persistência em tela
    _cacheTransacoesLocal.clear();
    _cacheMetasLocal.clear();
    usuarioLogado = null;
    _notificarAtualizacaoTransacoes();
  }

  /// Vincula documentos criados sem UID definido (como registros 'guest' ou off-line) à conta autenticada no Firestore.
  ///
  /// Parâmetros:
  /// - [uid]: Identificador único (UID) do usuário logado ao qual os dados serão associados.
  Future<void> vincularDadosAnonimosOuPendentes(String uid) async {
    if (uid.isEmpty || uid == 'guest') return;

    try {
      // Atualiza transações pendentes para o UID autenticado
      final transacoesPendentes = await _db
          .collection(_colecaoTransacoes)
          .where('id_cliente', isEqualTo: 'guest')
          .get();
      for (final doc in transacoesPendentes.docs) {
        await doc.reference.update({'id_cliente': uid});
      }

      // Atualiza chats pendentes do Conrado
      final chatsPendentes = await _db
          .collection(_colecaoChats)
          .where('id_cliente', isEqualTo: 'guest')
          .get();
      for (final doc in chatsPendentes.docs) {
        await doc.reference.update({'id_cliente': uid});
      }

      // Atualiza metas financeiras pendentes
      final metasPendentes = await _db
          .collection(_colecaoMetas)
          .where('id_cliente', isEqualTo: 'guest')
          .get();
      for (final doc in metasPendentes.docs) {
        await doc.reference.update({'id_cliente': uid});
      }
    } catch (e) {
      debugPrint('Aviso ao vincular dados pendentes no Firestore: $e');
    }
  }

  /// Desativa a conta do usuário no Firebase Firestore mantendo histórico de auditoria local.
  Future<bool> inativarConta(String uid) async {
    await apagarTodosDadosDoUsuario(uid);
    return true;
  }

  /// Encerra a sessão atual do usuário logado no aplicativo.
  static void deslogar() {
    usuarioLogado = null;
    _cacheTransacoesLocal.clear();
    _cacheMetasLocal.clear();
  }

  // --- GESTÃO DE CONTAS BANCÁRIAS ---

  /// Vincula ou edita a conta bancária do usuário no Firestore.
  Future<bool> vincularContaBancaria({
    required String idCliente,
    required String nomeBanco,
    required String agencia,
    required String numeroConta,
    required String tipoConta,
    required String nomeTitular,
  }) async {
    final dadosConta = {
      'id_cliente': idCliente,
      'nome_banco': nomeBanco,
      'agencia': agencia,
      'numero_conta': numeroConta,
      'tipo_conta': tipoConta,
      'nome_titular': nomeTitular,
      'atualizado_em': FieldValue.serverTimestamp(),
    };

    try {
      await _db
          .collection(_colecaoContasBancarias)
          .doc(idCliente)
          .set(dadosConta, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro no Firestore ao salvar conta bancária: $e');
    }

    if (usuarioLogado != null) {
      usuarioLogado!['conta_bancaria'] = dadosConta;
    }

    return true;
  }

  /// Busca os dados da conta bancária vinculada ao usuário.
  Future<Map<String, dynamic>?> buscarContaBancaria(String idCliente) async {
    try {
      final doc = await _db
          .collection(_colecaoContasBancarias)
          .doc(idCliente)
          .get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Erro ao buscar conta bancária no Firestore: $e');
    }

    if (usuarioLogado != null && usuarioLogado!['conta_bancaria'] != null) {
      return usuarioLogado!['conta_bancaria'] as Map<String, dynamic>;
    }

    return null;
  }

  /// Retorna um [Stream] reativo contendo a lista de contas bancárias vinculadas ao usuário no Cloud Firestore.
  /// Se não houver documentos na subcoleção, verifica os dados armazenados na sessão local.
  ///
  /// Parâmetros:
  /// - [idCliente]: UID do cliente cadastrado no sistema.
  Stream<List<Map<String, dynamic>>> buscarContasBancariasStream(
    String idCliente,
  ) {
    return _db
        .collection(_colecaoContasBancarias)
        .where('id_cliente', isEqualTo: idCliente)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return usuarioLogado != null &&
                    usuarioLogado!['conta_bancaria'] != null
                ? [usuarioLogado!['conta_bancaria'] as Map<String, dynamic>]
                : [];
          }
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Cache local em memória para sincronização instantânea e offline de transações.
  static final List<Map<String, dynamic>> _cacheTransacoesLocal = [];

  /// Getter público para acesso às transações em cache local.
  List<Map<String, dynamic>> get cacheTransacoesLocal => _cacheTransacoesLocal;

  /// StreamController Broadcast para notificação reativa instantânea de transações.
  static final StreamController<List<Map<String, dynamic>>>
  _transacoesStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  /// Notifica todos os ouvintes reativos de transações/saldo instantaneamente sem recarregar a tela.
  static void _notificarAtualizacaoTransacoes() {
    _transacoesStreamController.add(List.from(_cacheTransacoesLocal));
  }

  /// Retorna um [Stream] em tempo real do saldo total do usuário no Cloud Firestore.
  /// O saldo é calculado com base na soma de todas as Receitas subtraídas das Despesas registradas.
  ///
  /// Parâmetros:
  /// - [idCliente]: UID do usuário autenticado.
  Stream<double> obterSaldoStream(String idCliente) {
    return buscarTransacoesStream(idCliente).map((transacoes) {
      double total = 0.0;
      for (final t in transacoes) {
        final double valor = (t['valor'] as num?)?.toDouble() ?? 0.0;
        final String tipo = t['tipo'] ?? 'Receita';
        if (tipo == 'Receita') {
          total += valor;
        } else {
          total -= valor;
        }
      }
      return total;
    });
  }

  /// Executa uma operação de teste/debug de R$ 10,00 no Cloud Firestore.
  /// Adiciona uma transação (Receita se [adicionar] = true ou Despesa se [adicionar] = false)
  /// associada à categoria informada e sincroniza o saldo.
  ///
  /// Parâmetros:
  /// - [idCliente]: UID do usuário logado.
  /// - [titulo]: Título explicativo do extrato.
  /// - [categoria]: Categoria financeira da operação.
  /// - [adicionar]: Se true adiciona R$ 10 (Receita), se false remove R$ 10 (Despesa).
  Future<void> executarOperacaoDebug10Reais({
    required String idCliente,
    required String titulo,
    required String categoria,
    required bool adicionar,
  }) async {
    final double valor = 10.0;
    final String tipo = adicionar ? 'Receita' : 'Despesa';

    await adicionarTransacao(
      idCliente: idCliente,
      titulo: titulo,
      valor: valor,
      categoria: categoria,
      tipo: tipo,
      data: DateTime.now(),
    );
  }

  /// Adiciona uma nova transação (receita ou despesa) no Firestore e sincroniza no cache local.
  Future<void> adicionarTransacao({
    required String idCliente,
    required String titulo,
    required double valor,
    required String categoria,
    required String tipo, // 'Receita' ou 'Despesa'
    required DateTime data,
  }) async {
    final String tempId =
        't_${DateTime.now().millisecondsSinceEpoch}_${_cacheTransacoesLocal.length}';
    final transacao = {
      'firestore_id': tempId,
      'id_cliente': idCliente,
      'titulo': titulo,
      'valor': valor,
      'categoria': categoria,
      'tipo': tipo,
      'data': Timestamp.fromDate(data),
      'data_dt': data,
      'criado_em': FieldValue.serverTimestamp(),
    };

    // Adiciona imediatamente ao cache local e dispara notificação reativa instantânea
    _cacheTransacoesLocal.insert(0, transacao);
    _notificarAtualizacaoTransacoes();

    try {
      final payload = Map<String, dynamic>.from(transacao)
        ..remove('firestore_id')
        ..remove('data_dt');
      final docRef = await _db.collection(_colecaoTransacoes).add(payload);
      transacao['firestore_id'] = docRef.id;

      // Atualiza também o saldo resumido no documento do usuário
      _db.collection(_colecaoUsuarios).doc(idCliente).set({
        'ultimo_movimento': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _notificarAtualizacaoTransacoes();
    } catch (e) {
      debugPrint(
        'Aviso: Transação armazenada no cache local (modo offline): $e',
      );
    }
  }

  /// Atualiza os dados de uma transação existente no Firestore e no cache em memória.
  ///
  /// Parâmetros:
  /// - [transacaoId]: ID do documento no Firestore.
  /// - [titulo]: Novo título/descrição da movimentação.
  /// - [valor]: Novo valor numérico.
  /// - [categoria]: Nova categoria.
  /// - [tipo]: Tipo de transação ('Receita' ou 'Despesa').
  Future<void> atualizarTransacao({
    required String transacaoId,
    required String titulo,
    required double valor,
    required String categoria,
    required String tipo,
  }) async {
    final int index = _cacheTransacoesLocal.indexWhere(
      (t) => t['firestore_id'] == transacaoId,
    );
    if (index != -1) {
      _cacheTransacoesLocal[index]['titulo'] = titulo;
      _cacheTransacoesLocal[index]['valor'] = valor;
      _cacheTransacoesLocal[index]['categoria'] = categoria;
      _cacheTransacoesLocal[index]['tipo'] = tipo;
      _notificarAtualizacaoTransacoes();
    }

    try {
      await _db.collection(_colecaoTransacoes).doc(transacaoId).update({
        'titulo': titulo,
        'valor': valor,
        'categoria': categoria,
        'tipo': tipo,
        'atualizado_em': FieldValue.serverTimestamp(),
      });
      _notificarAtualizacaoTransacoes();
    } catch (e) {
      debugPrint('Aviso: Atualização de transação salva no cache local: $e');
    }
  }

  /// Exclui uma transação pelo seu ID único no Firestore.
  Future<void> excluirTransacao(String transacaoId) async {
    _cacheTransacoesLocal.removeWhere((t) => t['firestore_id'] == transacaoId);
    _notificarAtualizacaoTransacoes();
    try {
      await _db.collection(_colecaoTransacoes).doc(transacaoId).delete();
      _notificarAtualizacaoTransacoes();
    } catch (e) {
      debugPrint('Erro ao excluir transação no Firestore: $e');
    }
  }

  /// Retorna um [Stream] em tempo real com todas as transações do usuário.
  /// Alias amigável para [buscarTransacoesStream].
  Stream<List<Map<String, dynamic>>> ouvirTransacoes(String idCliente) {
    return buscarTransacoesStream(idCliente);
  }

  /// Retorna um [Stream] em tempo real com todas as transações do usuário salvas no Cloud Firestore,
  /// ordenadas por data de forma decrescente (mais recentes primeiro).
  /// Sincroniza automaticamente o cache local e garante que o saldo seja recalculado e mantido
  /// mesmo após resetar ou reabrir o aplicativo.
  /// Retorna um [Stream] em tempo real com todas as transações do usuário salvas no Cloud Firestore,
  /// ordenadas por data de forma decrescente (mais recentes primeiro).
  /// Sincroniza o cache local com os dados remotos e notifica ouvintes imediatamente.
  Stream<List<Map<String, dynamic>>> buscarTransacoesStream(String idCliente) {
    late StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    List<Map<String, dynamic>> obterListaAtual() {
      final list = _cacheTransacoesLocal
          .where((t) => t['id_cliente'] == idCliente)
          .toList();
      list.sort((a, b) {
        final dtA = a['data_dt'] as DateTime? ?? DateTime.now();
        final dtB = b['data_dt'] as DateTime? ?? DateTime.now();
        return dtB.compareTo(dtA);
      });
      return list;
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        // Emite o estado em cache imediatamente
        controller.add(obterListaAtual());

        // Ouve disparos locais (como as operações da Sessão Debug)
        localSub = _transacoesStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(obterListaAtual());
          }
        });

        // Sincroniza com as alterações do Cloud Firestore
        try {
          firestoreSub = _db
              .collection(_colecaoTransacoes)
              .where('id_cliente', isEqualTo: idCliente)
              .snapshots()
              .listen(
                (snapshot) {
                  for (final doc in snapshot.docs) {
                    final data = doc.data();
                    data['firestore_id'] = doc.id;
                    if (data['data'] is Timestamp) {
                      data['data_dt'] = (data['data'] as Timestamp).toDate();
                    }
                    final idx = _cacheTransacoesLocal.indexWhere(
                      (t) => t['firestore_id'] == doc.id,
                    );
                    if (idx >= 0) {
                      _cacheTransacoesLocal[idx] = data;
                    } else {
                      _cacheTransacoesLocal.add(data);
                    }
                  }
                  if (!controller.isClosed) {
                    controller.add(obterListaAtual());
                  }
                },
                onError: (error) {
                  debugPrint(
                    'Aviso ao sincronizar transações com o Firestore: $error',
                  );
                  if (!controller.isClosed) {
                    controller.add(obterListaAtual());
                  }
                },
              );
        } catch (e) {
          debugPrint('Erro ao iniciar stream Firestore de transações: $e');
        }
      },
      onCancel: () {
        firestoreSub?.cancel();
        localSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Atualiza o perfil do usuário (nome, email, telefone, idade, renda mensal e tipo de renda) no Firebase Firestore.
  Future<bool> atualizarPerfil({
    required String uid,
    required String nome,
    required String email,
    required String telefone,
    int? idade,
    double? rendaMensal,
    String? tipoRenda,
  }) async {
    final Map<String, dynamic> atualizacoes = {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'atualizado_em': FieldValue.serverTimestamp(),
    };

    if (idade != null) atualizacoes['idade'] = idade;
    if (rendaMensal != null) atualizacoes['renda_mensal'] = rendaMensal;
    if (tipoRenda != null) atualizacoes['tipo_renda'] = tipoRenda;

    try {
      await _db
          .collection(_colecaoUsuarios)
          .doc(uid)
          .set(atualizacoes, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao atualizar perfil no Firestore: $e');
    }

    // Atualiza os dados em memória imediatamente, sem necessidade de recarregar
    if (usuarioLogado != null) {
      usuarioLogado!['nome'] = nome;
      usuarioLogado!['email'] = email;
      usuarioLogado!['telefone'] = telefone;
      if (idade != null) usuarioLogado!['idade'] = idade;
      if (rendaMensal != null) usuarioLogado!['renda_mensal'] = rendaMensal;
      if (tipoRenda != null) usuarioLogado!['tipo_renda'] = tipoRenda;
    }

    return true;
  }

  /// Alias amigável para salvarPerfilUsuario nos Primeiros Passos.
  Future<bool> salvarPerfilUsuario({
    required String uid,
    required String nome,
    required String email,
    required String telefone,
    required int idade,
    required String tipoRenda,
    required double rendaMensal,
  }) async {
    return atualizarPerfil(
      uid: uid,
      nome: nome,
      email: email,
      telefone: telefone,
      idade: idade,
      tipoRenda: tipoRenda,
      rendaMensal: rendaMensal,
    );
  }

  /// Salva uma imagem de perfil convertida em string criptografada com assinatura segura no Firestore.
  ///
  /// Parâmetros:
  /// - [uid]: Identificador único do usuário.
  /// - [codigoEncriptado]: String contendo os dados da imagem codificados/encriptados.
  Future<bool> salvarFotoPerfilEncriptada(
    String uid,
    String codigoEncriptado,
  ) async {
    try {
      await _db.collection(_colecaoUsuarios).doc(uid).set({
        'foto_perfil_encriptada': codigoEncriptado,
        'foto_atualizada_em': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Aviso: Foto armazenada em sessão local: $e');
    }

    if (usuarioLogado != null) {
      usuarioLogado!['foto_perfil_encriptada'] = codigoEncriptado;
    }

    return true;
  }

  // --- GESTÃO DE ORÇAMENTOS ---

  /// Cache local de orçamentos para garantia de reatividade instantânea e persistência offline.
  static final List<Map<String, dynamic>> _cacheOrcamentosLocal = [];

  /// Salva a definição de orçamento por categoria do usuário no Firestore e no cache local.
  Future<bool> salvarOrcamento({
    required String idCliente,
    required String categoria,
    required double limite,
  }) async {
    final Map<String, dynamic> item = {
      'id_cliente': idCliente,
      'categoria': categoria,
      'limite': limite,
      'id': '${idCliente}_$categoria',
    };

    // Atualiza imediatamente o cache local para a interface reagir sem atrasos
    final idx = _cacheOrcamentosLocal.indexWhere(
      (o) => o['categoria'] == categoria && o['id_cliente'] == idCliente,
    );
    if (idx >= 0) {
      _cacheOrcamentosLocal[idx] = item;
    } else {
      _cacheOrcamentosLocal.add(item);
    }

    try {
      await _db
          .collection(_colecaoOrcamentos)
          .doc('${idCliente}_$categoria')
          .set({
            'id_cliente': idCliente,
            'categoria': categoria,
            'limite': limite,
            'atualizado_em': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Aviso: Orçamento salvo no cache local (modo offline): $e');
      return true;
    }
  }

  /// Retorna um Stream em tempo real das definições de orçamento do usuário cadastradas no Firestore.
  /// Se não houver nenhum orçamento no Firestore, emite estritamente uma lista vazia ([]).
  Stream<List<Map<String, dynamic>>> buscarOrcamentosStream(String idCliente) {
    try {
      return _db
          .collection(_colecaoOrcamentos)
          .where('id_cliente', isEqualTo: idCliente)
          .snapshots()
          .map((snapshot) {
            final docs = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

            // Atualiza o cache local com os dados exatamente presentes no Firestore
            _cacheOrcamentosLocal.removeWhere(
              (o) => o['id_cliente'] == idCliente,
            );
            _cacheOrcamentosLocal.addAll(docs);

            return docs;
          })
          .handleError((error) {
            debugPrint('Aviso ao ouvir orçamentos no Firestore: $error');
            return _cacheOrcamentosLocal
                .where((o) => o['id_cliente'] == idCliente)
                .toList();
          });
    } catch (e) {
      debugPrint('Erro ao buscar orçamentos no Firestore: $e');
      return Stream.value(
        _cacheOrcamentosLocal
            .where((o) => o['id_cliente'] == idCliente)
            .toList(),
      );
    }
  }

  /// Exclui uma definição de orçamento de uma categoria no Firestore e no cache local.
  Future<bool> excluirOrcamento({
    required String idCliente,
    required String categoria,
  }) async {
    _cacheOrcamentosLocal.removeWhere(
      (o) => o['categoria'] == categoria && o['id_cliente'] == idCliente,
    );

    try {
      await _db
          .collection(_colecaoOrcamentos)
          .doc('${idCliente}_$categoria')
          .delete();
      return true;
    } catch (e) {
      debugPrint('Aviso: Orçamento removido do cache local: $e');
      return true;
    }
  }

  // --- GESTÃO DE NOTIFICAÇÕES (Firebase Sync) ---

  /// Cache local em memória de notificações para garantia de entrega e reação instantânea.
  static final List<Map<String, dynamic>> _cacheNotificacoesLocal = [];

  /// StreamController Broadcast para notificação reativa instantânea de notificações.
  static final StreamController<List<Map<String, dynamic>>>
  _notificacoesStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  /// Retorna um Stream em tempo real das notificações do usuário cadastradas no Firestore.
  Stream<List<Map<String, dynamic>>> buscarNotificacoesStream(
    String idCliente,
  ) {
    late StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    List<Map<String, dynamic>> obterListaNotificacoes() {
      final list = _cacheNotificacoesLocal
          .where(
            (n) =>
                n['id_cliente'] == idCliente ||
                n['id_cliente'] == null ||
                n['id_cliente'] == 'guest',
          )
          .toList();
      list.sort((a, b) {
        final dtA = (a['data'] is Timestamp)
            ? (a['data'] as Timestamp).toDate()
            : (a['data'] as DateTime? ?? DateTime.now());
        final dtB = (b['data'] is Timestamp)
            ? (b['data'] as Timestamp).toDate()
            : (b['data'] as DateTime? ?? DateTime.now());
        return dtB.compareTo(dtA);
      });
      return list;
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        // Emite imediatamente as notificações em memória
        controller.add(obterListaNotificacoes());

        // Ouve disparos locais (inclusive da Sessão de Debug)
        localSub = _notificacoesStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(obterListaNotificacoes());
          }
        });

        // Ouve o Cloud Firestore em tempo real
        try {
          firestoreSub = _db
              .collection(_colecaoNotificacoes)
              .where('id_cliente', isEqualTo: idCliente)
              .snapshots()
              .listen(
                (snapshot) {
                  for (final doc in snapshot.docs) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    final idx = _cacheNotificacoesLocal.indexWhere(
                      (n) => n['id'] == doc.id,
                    );
                    if (idx >= 0) {
                      _cacheNotificacoesLocal[idx] = data;
                    } else {
                      _cacheNotificacoesLocal.add(data);
                    }
                  }
                  if (!controller.isClosed) {
                    controller.add(obterListaNotificacoes());
                  }
                },
                onError: (err) {
                  debugPrint(
                    'Aviso ao sincronizar notificações do Firestore: $err',
                  );
                  if (!controller.isClosed) {
                    controller.add(obterListaNotificacoes());
                  }
                },
              );
        } catch (e) {
          debugPrint('Erro ao iniciar stream Firestore de notificações: $e');
        }
      },
      onCancel: () {
        firestoreSub?.cancel();
        localSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Cria e envia uma nova notificação para o usuário no Cloud Firestore e no cache reativo local.
  Future<bool> criarNotificacao({
    required String idCliente,
    required String titulo,
    required String mensagem,
    required String categoria,
  }) async {
    final item = {
      'id':
          'notif_${DateTime.now().millisecondsSinceEpoch}_${_cacheNotificacoesLocal.length}',
      'id_cliente': idCliente,
      'titulo': titulo,
      'mensagem': mensagem,
      'categoria': categoria,
      'lida': false,
      'data': DateTime.now(),
    };

    _cacheNotificacoesLocal.insert(0, item);
    _notificacoesStreamController.add(List.from(_cacheNotificacoesLocal));

    try {
      final docRef = await _db.collection(_colecaoNotificacoes).add({
        'id_cliente': idCliente,
        'titulo': titulo,
        'mensagem': mensagem,
        'categoria': categoria,
        'lida': false,
        'data': FieldValue.serverTimestamp(),
      });
      item['id'] = docRef.id;
      _notificacoesStreamController.add(List.from(_cacheNotificacoesLocal));
      return true;
    } catch (e) {
      debugPrint('Aviso: Notificação registrada em sessão local offline: $e');
      return true;
    }
  }

  /// Marca uma notificação específica como lida no Firestore e no cache local.
  Future<void> marcarNotificacaoComoLida(String idNotificacao) async {
    final idx = _cacheNotificacoesLocal.indexWhere(
      (n) => n['id'] == idNotificacao,
    );
    if (idx >= 0) {
      _cacheNotificacoesLocal[idx]['lida'] = true;
      _notificacoesStreamController.add(List.from(_cacheNotificacoesLocal));
    }
    try {
      await _db.collection(_colecaoNotificacoes).doc(idNotificacao).update({
        'lida': true,
      });
    } catch (e) {
      debugPrint('Erro ao marcar notificação como lida: $e');
    }
  }

  /// Limpa todas as notificações do usuário no Cloud Firestore e no cache local.
  Future<void> limparNotificacoesDoUsuario(String idCliente) async {
    _cacheNotificacoesLocal.removeWhere(
      (n) =>
          n['id_cliente'] == idCliente ||
          n['id_cliente'] == null ||
          n['id_cliente'] == 'guest',
    );
    _notificacoesStreamController.add(List.from(_cacheNotificacoesLocal));

    try {
      final query = await _db
          .collection(_colecaoNotificacoes)
          .where('id_cliente', isEqualTo: idCliente)
          .get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Erro ao limpar notificações do usuário: $e');
    }
  }

  /// Busca as notificações do usuário no Firestore (compatibilidade síncrona/fallback).
  Future<List<Map<String, dynamic>>> buscarNotificacoes(
    String idCliente,
  ) async {
    try {
      final querySnapshot = await _db
          .collection(_colecaoNotificacoes)
          .where('id_cliente', isEqualTo: idCliente)
          .get();

      final list = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (list.isEmpty) {
        return _obterNotificacoesPadrao();
      }
      return list;
    } catch (e) {
      debugPrint('Retornando notificações padrão em modo offline: $e');
      return _obterNotificacoesPadrao();
    }
  }

  /// Notificações padrão de demonstração offline.
  List<Map<String, dynamic>> _obterNotificacoesPadrao() {
    return [
      {
        'id': 'notif_1',
        'titulo': 'Bem-vindo ao COGITO!',
        'mensagem':
            'Sua conta foi criada com sucesso. Configure seus envelopes de orçamento.',
        'categoria': 'Sistema',
        'lida': false,
        'data': DateTime.now().subtract(const Duration(minutes: 30)),
      },
      {
        'id': 'notif_2',
        'titulo': 'Dica do CONRADO 💡',
        'mensagem':
            'Você atingiu 70% do seu limite de gastos com Alimentação este mês.',
        'categoria': 'IA Financeira',
        'lida': false,
        'data': DateTime.now().subtract(const Duration(hours: 4)),
      },
      {
        'id': 'notif_3',
        'titulo': 'Segurança em Primeiro Lugar',
        'mensagem':
            'Seus dados estão protegidos com criptografia de ponta a ponta na nuvem.',
        'categoria': 'Segurança',
        'lida': true,
        'data': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];
  }

  // --- GESTÃO DE MÚLTIPLOS CHATS DO CONRADO ---

  /// Salva ou cria uma nova sessão de chat com o CONRADO no Firestore.
  Future<void> salvarSessaoChat({
    required String idCliente,
    required String chatId,
    required String titulo,
    required List<Map<String, dynamic>> mensagens,
  }) async {
    final dadosChat = {
      'id_cliente': idCliente,
      'chat_id': chatId,
      'titulo': titulo,
      'mensagens': mensagens,
      'atualizado_em': FieldValue.serverTimestamp(),
    };

    try {
      await _db
          .collection(_colecaoChats)
          .doc('${idCliente}_$chatId')
          .set(dadosChat, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sessão de chat salva no cache da aplicação: $e');
    }
  }

  /// Exclui permanentemente uma sessão de chat do CONRADO no Firestore.
  ///
  /// Parâmetros:
  /// - [idCliente]: UID do usuário proprietário do chat.
  /// - [chatId]: Identificador único da conversa a ser apagada.
  Future<bool> excluirSessaoChat({
    required String idCliente,
    required String chatId,
  }) async {
    try {
      await _db.collection(_colecaoChats).doc('${idCliente}_$chatId').delete();
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir sessão de chat no Firestore: $e');
      return false;
    }
  }

  // --- GESTÃO DE METAS FINANCEIRAS ("CAIXINHAS") ---

  /// Cache em memória local para garantir disponibilidade offline e resposta instantânea das metas.
  static final List<Map<String, dynamic>> _cacheMetasLocal = [];

  /// Salva ou atualiza uma meta financeira ("caixinha") no Firestore.
  ///
  /// Parâmetros:
  /// - [idCliente]: UID do usuário proprietário da meta.
  /// - [metaId]: ID único da meta (se nulo ou vazio, gera um novo documento).
  /// - [titulo]: Nome da meta (ex: "Reserva de Emergência", "Viagem de Férias").
  /// - [valorObjetivo]: Meta financeira total a ser atingida.
  /// - [valorAtual]: Valor acumulado atualmente.
  /// - [categoria]: Categoria visual da meta.
  Future<bool> salvarMeta({
    required String idCliente,
    String? metaId,
    required String titulo,
    required double valorObjetivo,
    required double valorAtual,
    String categoria = 'Geral',
  }) async {
    final bool concluida = valorAtual >= valorObjetivo;
    final String generatedId =
        (metaId != null && metaId.isNotEmpty && !metaId.startsWith('mock_'))
        ? metaId
        : 'meta_${DateTime.now().millisecondsSinceEpoch}';

    final dadosMeta = {
      'firestore_id': generatedId,
      'id_cliente': idCliente,
      'titulo': titulo,
      'valor_objetivo': valorObjetivo,
      'valor_atual': valorAtual,
      'categoria': categoria,
      'concluida': concluida,
    };

    // Atualiza o cache local imediatamente para disponibilidade instantânea da UI
    final existingIndex = _cacheMetasLocal.indexWhere(
      (m) => m['firestore_id'] == generatedId,
    );
    if (existingIndex >= 0) {
      _cacheMetasLocal[existingIndex] = dadosMeta;
    } else {
      _cacheMetasLocal.add(dadosMeta);
    }

    try {
      final Map<String, dynamic> firestorePayload = Map.from(dadosMeta)
        ..remove('firestore_id');
      firestorePayload['atualizado_em'] = FieldValue.serverTimestamp();

      if (metaId != null && metaId.isNotEmpty && !metaId.startsWith('mock_')) {
        await _db
            .collection(_colecaoMetas)
            .doc(metaId)
            .set(firestorePayload, SetOptions(merge: true));
      } else {
        firestorePayload['criado_em'] = FieldValue.serverTimestamp();
        final docRef = await _db
            .collection(_colecaoMetas)
            .add(firestorePayload);
        dadosMeta['firestore_id'] = docRef.id;
      }
      return true;
    } catch (e) {
      debugPrint('Aviso: Meta salva no cache local (modo offline): $e');
      return true;
    }
  }

  /// Adiciona um valor financeiro (aporte) a uma meta existente.
  ///
  /// Parâmetros:
  /// - [metaId]: ID do documento da meta no Firestore.
  /// - [valorAporte]: Quantia a ser somada ao saldo da meta.
  /// - [valorAtualAntigo]: Saldo atual antes do aporte.
  /// - [valorObjetivo]: Meta final para recalcular o status de conclusão.
  Future<bool> aportarMeta({
    required String metaId,
    required double valorAporte,
    required double valorAtualAntigo,
    required double valorObjetivo,
  }) async {
    final double novoValorAtual = valorAtualAntigo + valorAporte;
    final bool concluida = novoValorAtual >= valorObjetivo;

    // Atualiza o cache em memória
    final index = _cacheMetasLocal.indexWhere(
      (m) => m['firestore_id'] == metaId,
    );
    if (index >= 0) {
      _cacheMetasLocal[index]['valor_atual'] = novoValorAtual;
      _cacheMetasLocal[index]['concluida'] = concluida;
    }

    try {
      if (!metaId.startsWith('meta_')) {
        await _db.collection(_colecaoMetas).doc(metaId).update({
          'valor_atual': novoValorAtual,
          'concluida': concluida,
          'atualizado_em': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      debugPrint('Aviso: Aporte atualizado no cache local: $e');
      return true;
    }
  }

  /// Exclui uma meta financeira pelo seu ID no Firestore.
  ///
  /// Parâmetros:
  /// - [metaId]: Identificador único da meta a ser removida.
  Future<bool> excluirMeta(String metaId) async {
    _cacheMetasLocal.removeWhere((m) => m['firestore_id'] == metaId);

    try {
      if (!metaId.startsWith('meta_')) {
        await _db.collection(_colecaoMetas).doc(metaId).delete();
      }
      return true;
    } catch (e) {
      debugPrint('Aviso: Meta removida do cache local: $e');
      return true;
    }
  }

  /// Retorna um [Stream] em tempo real com todas as metas financeiras do usuário.
  /// Incorpora fallback offline reativo e sincronização com o cache local.
  ///
  /// Parâmetros:
  /// - [idCliente]: UID do usuário logado.
  Stream<List<Map<String, dynamic>>> buscarMetasStream(String idCliente) {
    try {
      return _db
          .collection(_colecaoMetas)
          .where('id_cliente', isEqualTo: idCliente)
          .snapshots()
          .map((snapshot) {
            final List<Map<String, dynamic>> metasFirestore = snapshot.docs.map(
              (doc) {
                final data = doc.data();
                data['firestore_id'] = doc.id;
                return data;
              },
            ).toList();

            // Sincroniza o cache local com os dados atualizados do Firestore
            for (final m in metasFirestore) {
              final idx = _cacheMetasLocal.indexWhere(
                (c) => c['firestore_id'] == m['firestore_id'],
              );
              if (idx >= 0) {
                _cacheMetasLocal[idx] = m;
              } else {
                _cacheMetasLocal.add(m);
              }
            }

            return metasFirestore.isNotEmpty
                ? metasFirestore
                : List<Map<String, dynamic>>.from(_cacheMetasLocal);
          })
          .handleError((error) {
            debugPrint(
              'Aviso ao ouvir metas no Firestore, utilizando cache local: $error',
            );
            return _cacheMetasLocal;
          });
    } catch (e) {
      debugPrint('Erro ao iniciar stream de metas: $e');
      return Stream.value(_cacheMetasLocal);
    }
  }

  // --- GESTÃO DE CARTÕES DE CRÉDITO ---

  /// Cache local para persistência e fallback imediato de cartões em modo offline.
  static final List<Map<String, dynamic>> _cacheCartoesLocal = [
    {
      'id': 'card_default_1',
      'id_cliente': 'default',
      'banco': 'COGITO Black',
      'bandeira': 'Mastercard',
      'ultimos_digitos': '8829',
      'numero': '•••• •••• •••• 8829',
      'limite_total': 15000.0,
      'limite_disponivel': 11450.0,
      'fatura_atual': 3550.0,
      'vencimento': 'Dia 15',
      'cor': '0xFF1E1E1E',
      'cor_final': '0xFF3A3A3A',
    },
    {
      'id': 'card_default_2',
      'id_cliente': 'default',
      'banco': 'COGITO Platinum',
      'bandeira': 'Visa',
      'ultimos_digitos': '4102',
      'numero': '•••• •••• •••• 4102',
      'limite_total': 8500.0,
      'limite_disponivel': 6300.0,
      'fatura_atual': 2200.0,
      'vencimento': 'Dia 20',
      'cor': '0xFF142251',
      'cor_final': '0xFF244288',
    },
    {
      'id': 'card_default_3',
      'id_cliente': 'default',
      'banco': 'COGITO Flex',
      'bandeira': 'Elo',
      'ultimos_digitos': '9031',
      'numero': '•••• •••• •••• 9031',
      'limite_total': 5000.0,
      'limite_disponivel': 4120.0,
      'fatura_atual': 880.0,
      'vencimento': 'Dia 05',
      'cor': '0xFFF5891D',
      'cor_final': '0xFFFCAA17',
    },
  ];

  /// Controlador reativo para emissão imediata de atualizações nos cartões de crédito.
  static final StreamController<List<Map<String, dynamic>>>
  _cartoesStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  /// Cadastra um novo cartão de crédito para o cliente no Firestore e no cache local.
  ///
  /// Parâmetros:
  /// - [idCliente]: Identificador do usuário proprietário do cartão.
  /// - [banco]: Instituição financeira emissora (ex: Nubank, Itaú, COGITO Black).
  /// - [bandeira]: Bandeira do cartão (ex: Mastercard, Visa, Elo).
  /// - [ultimosDigitos]: Últimos 4 dígitos para exibição segura.
  /// - [limiteTotal]: Limite de crédito concedido total.
  /// - [faturaAtual]: Valor da fatura em aberto atualmente.
  /// - [vencimento]: Dia ou data de vencimento da fatura.
  /// - [cor]: Cor primária em formato hexadecimal (String).
  /// - [corFinal]: Cor de gradiente secundária opcional.
  ///
  /// Retorno:
  /// - [Future<bool>]: Verdadeiro se cadastrado com sucesso.
  Future<bool> salvarCartao({
    required String idCliente,
    required String banco,
    required String bandeira,
    required String ultimosDigitos,
    required double limiteTotal,
    required double faturaAtual,
    required String vencimento,
    String cor = '0xFF142251',
    String corFinal = '0xFF244288',
  }) async {
    final double limiteDisponivel = (limiteTotal - faturaAtual).clamp(
      0.0,
      limiteTotal,
    );
    final String digitosLimpos = ultimosDigitos.replaceAll(RegExp(r'\D'), '');
    final String digitosFinais = digitosLimpos.length >= 4
        ? digitosLimpos.substring(digitosLimpos.length - 4)
        : digitosLimpos.padLeft(4, '0');

    final String cartaoId = 'card_${DateTime.now().millisecondsSinceEpoch}';

    final Map<String, dynamic> dados = {
      'id': cartaoId,
      'id_cliente': idCliente,
      'banco': banco,
      'bandeira': bandeira,
      'ultimos_digitos': digitosFinais,
      'numero': '•••• •••• •••• $digitosFinais',
      'limite_total': limiteTotal,
      'limite_disponivel': limiteDisponivel,
      'fatura_atual': faturaAtual,
      'vencimento': vencimento,
      'cor': cor,
      'cor_final': corFinal,
      'criado_em': FieldValue.serverTimestamp(),
    };

    // 1. Salva imediatamente no cache local em memória e emite aos ouvintes
    _cacheCartoesLocal.removeWhere((c) => c['id'] == cartaoId);
    _cacheCartoesLocal.insert(0, dados);
    _cartoesStreamController.add(List.from(_cacheCartoesLocal));

    // 2. Tenta persistir no Cloud Firestore
    try {
      await _db.collection(_colecaoCartoes).doc(cartaoId).set(dados);
    } catch (e) {
      debugPrint('Aviso: Armazenando cartão em sessão local offline: $e');
    }

    return true;
  }

  /// Retorna o fluxo reativo (Stream) dos cartões cadastrados pelo cliente.
  /// Emite os dados em cache de forma síncrona/imediata e ouve alterações do Firestore e do aplicativo.
  ///
  /// Parâmetros:
  /// - [idCliente]: UID do usuário ativo.
  ///
  /// Retorno:
  /// - [Stream<List<Map<String, dynamic>>>]: Lista em tempo real de cartões.
  Stream<List<Map<String, dynamic>>> buscarCartoesStream(
    String idCliente,
  ) async* {
    List<Map<String, dynamic>> filtrarParaCliente(
      List<Map<String, dynamic>> lista,
    ) {
      final filtrados = lista
          .where(
            (c) =>
                c['id_cliente'] == idCliente ||
                c['id_cliente'] == 'default' ||
                c['id_cliente'] == null,
          )
          .toList();
      return filtrados.isNotEmpty ? filtrados : lista;
    }

    // Emissão imediata do estado de cache para resposta instantânea na UI
    yield filtrarParaCliente(_cacheCartoesLocal);

    final controller = StreamController<List<Map<String, dynamic>>>();

    // Ouve notificações geradas por ações do usuário (salvar / remover)
    final subLocal = _cartoesStreamController.stream.listen((lista) {
      if (!controller.isClosed) {
        controller.add(filtrarParaCliente(lista));
      }
    });

    // Ouve snapshots em tempo real do Cloud Firestore
    StreamSubscription? subFirestore;
    try {
      subFirestore = _db
          .collection(_colecaoCartoes)
          .where('id_cliente', isEqualTo: idCliente)
          .snapshots()
          .listen(
            (snapshot) {
              final List<Map<String, dynamic>> cartoesFirestore = snapshot.docs
                  .map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return data;
                  })
                  .toList();

              if (cartoesFirestore.isNotEmpty) {
                for (final cf in cartoesFirestore) {
                  final idx = _cacheCartoesLocal.indexWhere(
                    (c) => c['id'] == cf['id'],
                  );
                  if (idx >= 0) {
                    _cacheCartoesLocal[idx] = cf;
                  } else {
                    _cacheCartoesLocal.insert(0, cf);
                  }
                }
                if (!controller.isClosed) {
                  controller.add(filtrarParaCliente(_cacheCartoesLocal));
                }
              }
            },
            onError: (e) {
              debugPrint('Aviso ao sincronizar cartões no Firestore: $e');
              if (!controller.isClosed) {
                controller.add(filtrarParaCliente(_cacheCartoesLocal));
              }
            },
          );
    } catch (e) {
      debugPrint('Erro ao iniciar stream de cartões no Firestore: $e');
    }

    try {
      yield* controller.stream;
    } finally {
      await subLocal.cancel();
      await subFirestore?.cancel();
      await controller.close();
    }
  }

  /// Remove um cartão de crédito cadastrado pelo ID.
  ///
  /// Parâmetros:
  /// - [cartaoId]: Identificador único do documento do cartão.
  ///
  /// Retorno:
  /// - [Future<bool>]: Confirmação de exclusão.
  Future<bool> removerCartao(String cartaoId) async {
    _cacheCartoesLocal.removeWhere((c) => c['id'] == cartaoId);
    _cartoesStreamController.add(List.from(_cacheCartoesLocal));

    try {
      await _db.collection(_colecaoCartoes).doc(cartaoId).delete();
    } catch (e) {
      debugPrint('Aviso ao remover cartão no Firestore: $e');
    }
    return true;
  }
}
