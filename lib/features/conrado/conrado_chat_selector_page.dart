import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/features/conrado/conrado_chat_page.dart';
import 'package:cogito/features/plans/plans_page.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela Hub de Seleção de Chats do CONRADO.
/// Exibida como a tela inicial ao acessar a aba do CONRADO no menu inferior.
/// Permite visualizar todas as conversas salvas, iniciar novos chats ou escolher tópicos pré-definidos.
class ConradoChatSelectorPage extends StatefulWidget {
  const ConradoChatSelectorPage({super.key});

  @override
  State<ConradoChatSelectorPage> createState() => _ConradoChatSelectorPageState();
}

class _ConradoChatSelectorPageState extends State<ConradoChatSelectorPage> {
  /// Lista local de sessões de chat.
  final List<Map<String, dynamic>> _chatSessions = [
    {
      'id': 'chat_1',
      'titulo': 'Planejamento Financeiro',
      'ultimaMensagem': 'Olá! Como posso ajudar você a organizar seu dinheiro hoje?',
      'mensagensCount': 4,
      'atualizadoEm': 'Hoje, 14:30',
      'iconColor': AppColors.primaryBlue,
    },
    {
      'id': 'chat_2',
      'titulo': 'Modo Freelancer & Job',
      'ultimaMensagem': 'Dica: Calcule seu valor hora considerando seus custos fixos.',
      'mensagensCount': 8,
      'atualizadoEm': 'Ontem',
      'iconColor': AppColors.primaryOrange,
    },
  ];

  /// Plano atual do usuário logado.
  String _planoUsuario = 'Grátis';

  @override
  void initState() {
    super.initState();
    _carregarPlanoUsuario();
  }

  /// Recarrega as informações do plano do usuário logado no Firestore.
  void _carregarPlanoUsuario() {
    final usuario = FirebaseFirestoreService.usuarioLogado;
    if (usuario != null && usuario['plano'] != null) {
      setState(() {
        _planoUsuario = usuario['plano'];
      });
    }
  }

  /// Cria um novo chat e abre a tela de conversa individual.
  void _criarNovoChat([String? tituloInicial]) {
    final String novoId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    final String titulo = tituloInicial ?? 'Conversa ${_chatSessions.length + 1}';

    setState(() {
      _chatSessions.add({
        'id': novoId,
        'titulo': titulo,
        'ultimaMensagem': 'Nova conversa iniciada.',
        'mensagensCount': 1,
        'atualizadoEm': 'Agora',
        'iconColor': _chatSessions.length % 2 == 0 ? AppColors.primaryBlue : AppColors.primaryOrange,
      });
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConradoChatPage(chatId: novoId, tituloChat: titulo),
      ),
    ).then((_) => _carregarPlanoUsuario());
  }

  /// Instância do serviço Firebase Firestore.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Exclui uma sessão de chat da lista e do Firestore com confirmação.
  Future<void> _excluirChat(int index) async {
    final chat = _chatSessions[index];
    final String chatId = chat['id'] ?? '';
    final usuario = FirebaseFirestoreService.usuarioLogado;
    final String uid = (usuario?['uid'] ?? usuario?['id_cliente'] ?? 'guest').toString();

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
        content: Text('Deseja realmente apagar a conversa "${chat['titulo']}"?'),
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
      await _firestoreService.excluirSessaoChat(idCliente: uid, chatId: chatId);
      setState(() {
        _chatSessions.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversa apagada com sucesso.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.primaryBlue),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Column(
          children: [
            // Cabeçalho azul com avatar do CONRADO e tag do plano
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botão Destaque: Novo Chat
                    _buildNewChatButton(),

                    const SizedBox(height: 20),

                    // Carrossel de Tópicos Sugeridos
                    const Text(
                      'Tópicos Recomendados',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(height: 10),
                    _buildSuggestedTopics(),

                    const SizedBox(height: 22),

                    // Cabeçalho da Lista de Conversas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Suas Conversas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${_chatSessions.length} ativas',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Lista de Cards de Chats
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _chatSessions.length,
                      itemBuilder: (context, index) {
                        final chat = _chatSessions[index];
                        return _buildChatSessionCard(chat, index);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho superior do Hub do Conrado.
  Widget _buildHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryOrange,
                  child: Image.asset(
                    'assets/images/conrado/conrado_hi.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.psychology, color: Colors.white, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONRADO IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: TextStyles.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                        const SizedBox(width: 6),
                        const Text(
                          'Assistente de Inteligência Financeira',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tag de Plano Atual com atalho para Planos
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlanosPage()),
                  ).then((_) => _carregarPlanoUsuario());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _planoUsuario == 'Grátis' ? AppColors.primaryOrange : Colors.green.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _planoUsuario,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói o botão principal para iniciar um novo chat com o Conrado.
  Widget _buildNewChatButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _criarNovoChat(),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text(
          'NOVA CONVERSA COM O CONRADO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
        ),
      ),
    );
  }

  /// Constrói o carrossel horizontal de tópicos recomendados para iniciar chats temáticos.
  Widget _buildSuggestedTopics() {
    final topicos = [
      {'titulo': '💰 Reserva de Emergência', 'cor': Colors.blue},
      {'titulo': '📊 Orçamento 50-30-20', 'cor': Colors.green},
      {'titulo': '💼 Precificação Freelance', 'cor': Colors.purple},
      {'titulo': '🚀 Dicas de Economia', 'cor': Colors.orange},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: topicos.map((t) {
          final String title = t['titulo'] as String;
          final Color color = t['cor'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _criarNovoChat(title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim()),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Constrói o card individual de cada sessão de conversa ativa.
  Widget _buildChatSessionCard(Map<String, dynamic> chat, int index) {
    final String id = chat['id'];
    final String titulo = chat['titulo'];
    final String ultimaMsg = chat['ultimaMensagem'];
    final String dataStr = chat['atualizadoEm'];
    final Color iconColor = chat['iconColor'] ?? AppColors.primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConradoChatPage(chatId: id, tituloChat: titulo),
            ),
          ).then((_) => _carregarPlanoUsuario());
        },
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(Icons.chat_bubble_outline_rounded, color: iconColor, size: 22),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
            ),
            Text(
              dataStr,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            ultimaMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () => _excluirChat(index),
          tooltip: 'Excluir conversa',
        ),
      ),
    );
  }
}
