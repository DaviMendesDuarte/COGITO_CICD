import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/features/conrado/services/conrado_api_service.dart';
import 'package:cogito/features/plans/plans_page.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modelo de dados que representa uma mensagem trocada no chat com o CONRADO.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        text: map['text'] ?? '',
        isUser: map['isUser'] ?? false,
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Modelo de dados que representa uma sessão individual de chat com o CONRADO.
class ChatSession {
  final String id;
  String titulo;
  final List<ChatMessage> mensagens;

  ChatSession({
    required this.id,
    required this.titulo,
    List<ChatMessage>? mensagens,
  }) : mensagens = mensagens ?? [];
}

/// Tela de Chat Interativo com o assistente virtual CONRADO.
/// No Plano Grátis, limita a interação ao envio de mensagens prontas pré-selecionadas do dia a dia.
/// Nos Planos Freelancer e Premium, libera a digitação de texto livre e ilimitado.
class ConradoChatPage extends StatefulWidget {
  final String? chatId;
  final String? tituloChat;

  const ConradoChatPage({
    super.key,
    this.chatId,
    this.tituloChat,
  });

  @override
  ConradoChatPageState createState() => ConradoChatPageState();
}

/// Estado público da [ConradoChatPage].
class ConradoChatPageState extends State<ConradoChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ConradoApiService _apiService = ConradoApiService();
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Lista de mensagens da conversa ativa.
  final List<ChatMessage> _mensagens = [];

  /// Indica se o CONRADO está gerando uma resposta (digitação ativa).
  bool _isTyping = false;

  /// Nome do plano do usuário logado ("Grátis", "Freelancer" ou "Premium").
  String _planoUsuario = 'Grátis';

  /// Sugestões rápidas de perguntas prontas para o dia a dia.
  final List<String> _quickSuggestions = [
    '📊 Status do FGTS e Saque Aniversário',
    '💰 Como funciona o cálculo do 13º Salário?',
    '🏖️ Como planejar o orçamento das Férias?',
    'Como criar uma reserva de emergência?',
    'Dicas para economizar este mês',
    'Como organizar minhas despesas?',
    'O que é a regra 50-30-20?',
  ];

  @override
  void initState() {
    super.initState();
    _carregarPlanoEUltimasMensagens();
  }

  /// Recarrega as informações do plano e inicializa a conversa com mensagem de boas-vindas.
  void _carregarPlanoEUltimasMensagens() {
    final usuario = FirebaseFirestoreService.usuarioLogado;
    if (usuario != null && usuario['plano'] != null) {
      _planoUsuario = usuario['plano'];
    }

    // Inicializa com a mensagem de boas-vindas do Conrado
    if (_mensagens.isEmpty) {
      _mensagens.add(
        ChatMessage(
          text: 'Olá! Sou o CONRADO, seu assistente de inteligência financeira do COGITO! 🧠💡\n\n'
              '${_planoUsuario == 'Grátis' ? 'No seu Plano Grátis, selecione uma das perguntas prontas abaixo para conversarmos no dia a dia!' : 'Como posso ajudar você a organizar seu dinheiro e atingir suas metas hoje?'}',
          isUser: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Salva a conversa no Firestore.
  void _salvarSessaoFirestore() {
    final String uid = FirebaseFirestoreService.idClienteAtual;
    final String cId = widget.chatId ?? 'chat_principal';
    final String cTitulo = widget.tituloChat ?? 'Conversa com CONRADO';

    _firestoreService.salvarSessaoChat(
      idCliente: uid,
      chatId: cId,
      titulo: cTitulo,
      mensagens: _mensagens.map((m) => m.toMap()).toList(),
    );
  }

  /// Envia a mensagem (seja via texto livre ou mensagem pronta).
  Future<void> _handleSendMessage([String? predefinedMessage]) async {
    final bool isGratis = _planoUsuario == 'Grátis';

    // Se for plano Grátis e tentar enviar texto livre sem mensagem pronta, bloqueia e sugere upgrade
    if (isGratis && predefinedMessage == null) {
      _exibirAlertaUpgradePlano();
      return;
    }

    final String textToSend = predefinedMessage ?? _inputController.text.trim();
    if (textToSend.isEmpty || _isTyping) return;

    if (predefinedMessage == null) {
      _inputController.clear();
    }

    setState(() {
      _mensagens.add(ChatMessage(text: textToSend, isUser: true));
      _isTyping = true;
    });

    _scrollToBottom();

    final String aiResponse = await _apiService.sendMessage(textToSend);

    if (!mounted) return;

    setState(() {
      _mensagens.add(ChatMessage(text: aiResponse, isUser: false));
      _isTyping = false;
    });

    _scrollToBottom();
    _salvarSessaoFirestore();
  }

  /// Exibe diálogo/alerta incentivando o upgrade para os planos Freelancer ou Premium.
  void _exibirAlertaUpgradePlano() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.primaryYellow, size: 28),
            SizedBox(width: 10),
            Text('Recurso dos Planos Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'No Plano Grátis você pode enviar todas as mensagens prontas do dia a dia. Para digitar qualquer pergunta livremente com o CONRADO, faça upgrade para o plano Freelancer ou Premium!',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDI', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlanosPage()),
              ).then((_) {
                setState(() {
                  _carregarPlanoEUltimasMensagens();
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('VER PLANOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.primaryBlue),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Column(
          children: [
            // Cabeçalho personalizado da conversa
            _buildHeader(context),

            // Lista de mensagens trocadas
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _mensagens.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _mensagens.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  final message = _mensagens[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Carrossel de Mensagens Prontas
            _buildQuickSuggestions(),

            // Barra inferior de texto
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho superior do chat com botão de voltar e tag do plano.
  Widget _buildHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final String titulo = widget.tituloChat ?? 'Conversa com CONRADO';

    return Container(
      padding: EdgeInsets.fromLTRB(10, topPadding + 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryOrange,
              child: Image.asset(
                'assets/images/conrado/conrado_hi.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.psychology, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: TextStyles.fontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _planoUsuario == 'Grátis' ? Colors.orange.shade800 : Colors.green.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _planoUsuario,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                    SizedBox(width: 6),
                    Text(
                      'CONRADO IA • Online',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 22),
            tooltip: 'Exportar Conversa',
            onPressed: _exibirModalExportarConversa,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
            tooltip: 'Apagar Conversa',
            onPressed: () async {
              final String titulo = widget.tituloChat ?? 'esta conversa';
              final bool? confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Apagar Conversa'),
                    ],
                  ),
                  content: Text('Deseja realmente apagar "$titulo"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Apagar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                final String uid = FirebaseFirestoreService.idClienteAtual;
                final String cId = widget.chatId ?? 'chat_principal';

                await _firestoreService.excluirSessaoChat(idCliente: uid, chatId: cId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversa apagada.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    final String formattedTime =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryBlue,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        color: isUser ? Colors.white70 : Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryOrange,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryBlue,
            child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'CONRADO está digitando...',
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a lista horizontal de Mensagens Prontas para o dia a dia.
  Widget _buildQuickSuggestions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_planoUsuario == 'Grátis')
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                'Perguntas Prontas (Plano Grátis):',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
              ),
            ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _quickSuggestions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    label: Text(
                      suggestion,
                      style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _handleSendMessage(suggestion),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a barra de entrada de texto. Se for Plano Grátis, desabilita digitação livre e exibe aviso.
  Widget _buildInputBar() {
    final bool isGratis = _planoUsuario == 'Grátis';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isGratis ? _exibirAlertaUpgradePlano : null,
                child: AbsorbPointer(
                  absorbing: isGratis,
                  child: TextField(
                    controller: _inputController,
                    enabled: !isGratis,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: isGratis
                          ? 'Selecione uma mensagem pronta acima (Plano Grátis)'
                          : 'Pergunte algo ao CONRADO...',
                      hintStyle: TextStyle(
                        color: isGratis ? AppColors.primaryOrange : Colors.grey,
                        fontSize: 13,
                        fontWeight: isGratis ? FontWeight.bold : FontWeight.normal,
                      ),
                      filled: true,
                      fillColor: isGratis ? const Color(0xFFFFF3E0) : AppColors.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: isGratis ? Colors.grey.shade400 : AppColors.primaryBlue,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  if (isGratis) {
                    _exibirAlertaUpgradePlano();
                  } else {
                    _handleSendMessage();
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exibe modal para escolher o formato de exportação da conversa com o CONRADO.
  void _exibirModalExportarConversa() {
    if (_mensagens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma mensagem na conversa para exportar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.psychology, color: AppColors.primaryOrange, size: 24),
                  SizedBox(width: 8),
                  Text('Exportar Conversa CONRADO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Exportando ${_mensagens.length} mensagens trocadas nesta sessão:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.blue, size: 28),
                title: const Text('Transcrição Completa (.TXT)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Histórico cronológico de perguntas e respostas em texto puro'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processarExportacaoConversa('TXT', _gerarTextoConversa());
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 28),
                title: const Text('Relatório de Consultoria IA (.PDF / Texto)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Relatório executivo estruturado com diagnósticos e insights'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processarExportacaoConversa('PDF / Relatório Formatado', _gerarRelatorioConversa());
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.code_outlined, color: Colors.purple, size: 28),
                title: const Text('Dados Estruturados (.JSON)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Formato técnico de dados com timestamps e autor de cada mensagem'),
                onTap: () {
                  Navigator.pop(ctx);
                  _processarExportacaoConversa('JSON', _gerarJsonConversa());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Gera a transcrição em texto puro da conversa.
  String _gerarTextoConversa() {
    final buffer = StringBuffer();
    final String titulo = widget.tituloChat ?? 'Conversa com CONRADO IA';
    final agora = DateTime.now();

    buffer.writeln('====================================================');
    buffer.writeln('          COGITO - TRANSCRIÇÃO DE CONSULTORIA IA');
    buffer.writeln('====================================================');
    buffer.writeln('Título da Sessão: $titulo');
    buffer.writeln('Exportado em: ${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year} às ${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}');
    buffer.writeln('Total de Mensagens: ${_mensagens.length}');
    buffer.writeln('----------------------------------------------------\n');

    for (final m in _mensagens) {
      final String autor = m.isUser ? 'VOCÊ' : 'CONRADO IA';
      final String dataHora = '${m.timestamp.day.toString().padLeft(2, '0')}/${m.timestamp.month.toString().padLeft(2, '0')} ${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}';
      buffer.writeln('[$dataHora] $autor:');
      buffer.writeln('${m.text}\n');
    }

    buffer.writeln('====================================================');
    return buffer.toString();
  }

  /// Gera relatório executivo formatado com insights.
  String _gerarRelatorioConversa() {
    final buffer = StringBuffer();
    final String titulo = widget.tituloChat ?? 'Consultoria Financeira com CONRADO IA';
    final agora = DateTime.now();

    buffer.writeln('====================================================');
    buffer.writeln('      COGITO INTELIGÊNCIA FINANCEIRA - RELATÓRIO');
    buffer.writeln('====================================================');
    buffer.writeln('Tópico: $titulo');
    buffer.writeln('Data da Análise: ${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year}');
    buffer.writeln('Plano Utilizado: $_planoUsuario');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('DIAGNÓSTICOS & RESPOSTAS DO CONRADO:\n');

    int counter = 1;
    for (int i = 0; i < _mensagens.length; i++) {
      final m = _mensagens[i];
      if (m.isUser) {
        buffer.writeln('Tópico $counter: "${m.text}"');
        if (i + 1 < _mensagens.length && !_mensagens[i + 1].isUser) {
          buffer.writeln('• Resposta CONRADO: ${_mensagens[i + 1].text}\n');
        }
        counter++;
      }
    }

    buffer.writeln('====================================================');
    return buffer.toString();
  }

  /// Gera JSON estruturado da conversa.
  String _gerarJsonConversa() {
    final list = _mensagens.map((m) => m.toMap()).toList();
    final String titulo = widget.tituloChat ?? 'Conversa CONRADO';
    final jsonItems = list.map((m) => '    {"autor": "${(m['isUser'] as bool) ? 'Usuario' : 'Conrado'}", "texto": "${m['text'].toString().replaceAll('\n', '\\n').replaceAll('"', '\\"')}", "timestamp": "${m['timestamp']}"}').join(',\n');

    return '''{
  "aplicativo": "COGITO",
  "sessao_titulo": "$titulo",
  "gerado_em": "${DateTime.now().toIso8601String()}",
  "total_mensagens": ${list.length},
  "mensagens": [
$jsonItems
  ]
}''';
  }

  /// Copia o arquivo exportado para a área de transferência e abre pop-up de pré-visualização.
  void _processarExportacaoConversa(String formato, String conteudo) {
    Clipboard.setData(ClipboardData(text: conteudo));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Conversa Exportada ($formato)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('A transcrição foi copiada para a Área de Transferência. Você pode colar onde desejar ou visualizar o conteúdo abaixo:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF2F4F7), borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                child: Text(conteudo, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: conteudo));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transcrição do $formato copiada novamente!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.white, size: 18),
              label: const Text('Copiar Novamente', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}
