import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de Notificações do aplicativo COGITO.
/// Exibe alertas do sistema, dicas da IA CONRADO e avisos sobre limites de orçamentos em tempo real.
class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  /// Instância do serviço Firebase Firestore.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Marca todas as notificações exibidas como lidas no Firestore.
  void _marcarTodasComoLidas(List<Map<String, dynamic>> notificacoes) {
    for (var n in notificacoes) {
      if (n['id'] != null) {
        _firestoreService.marcarNotificacaoComoLida(n['id'].toString());
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas as notificações foram marcadas como lidas.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Limpa todas as notificações do usuário logado no Firestore.
  void _limparNotificacoes() {
    final usuario = FirebaseFirestoreService.usuarioLogado;
    final uid = usuario?['uid'] ?? usuario?['id_cliente'] ?? 'guest';
    _firestoreService.limparNotificacoesDoUsuario(uid.toString());
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseFirestoreService.idClienteAtual;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.primaryBlue),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.buscarNotificacoesStream(uid),
        builder: (context, snapshot) {
          final List<Map<String, dynamic>> notificacoes = snapshot.data ?? [];
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;

          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Notificações',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              actions: [
                if (notificacoes.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (val) {
                      if (val == 'marcar_lidas')
                        _marcarTodasComoLidas(notificacoes);
                      if (val == 'limpar') _limparNotificacoes();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'marcar_lidas',
                        child: Row(
                          children: [
                            Icon(
                              Icons.done_all,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Marcar todas como lidas'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'limpar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Limpar tudo'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : notificacoes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notificacoes.length,
                    itemBuilder: (context, index) {
                      final item = notificacoes[index];
                      return _buildNotificationCard(item);
                    },
                  ),
          );
        },
      ),
    );
  }

  /// Constrói o estado vazio quando não há notificações disponíveis.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 64,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhuma notificação por aqui',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Você está em dia! Quando houver novidades sobre seu orçamento ou dicas do CONRADO, elas aparecerão nesta tela.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o card individual de notificação com ícone de categoria e marcação de leitura.
  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final bool lida = item['lida'] ?? false;
    final String categoria = item['categoria'] ?? 'Sistema';
    final String titulo = item['titulo'] ?? 'Notificação';
    final String mensagem = item['mensagem'] ?? '';
    final String idNotif = item['id']?.toString() ?? '';

    IconData iconData = Icons.notifications_active_outlined;
    Color iconColor = AppColors.primaryBlue;

    if (categoria == 'IA Financeira') {
      iconData = Icons.psychology_outlined;
      iconColor = AppColors.primaryOrange;
    } else if (categoria == 'Segurança') {
      iconData = Icons.shield_outlined;
      iconColor = Colors.green;
    }

    return Dismissible(
      key: Key(
        idNotif.isNotEmpty
            ? idNotif
            : DateTime.now().microsecondsSinceEpoch.toString(),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        if (idNotif.isNotEmpty) {
          _firestoreService.marcarNotificacaoComoLida(idNotif);
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          if (!lida && idNotif.isNotEmpty) {
            _firestoreService.marcarNotificacaoComoLida(idNotif);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lida
                ? Colors.white
                : AppColors.primaryBlue.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: lida
                  ? Colors.grey.shade200
                  : AppColors.primaryBlue.withValues(alpha: 0.3),
              width: lida ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone da Categoria
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Conteúdo da Notificação
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            titulo,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: lida
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: AppColors.secundaryBlue,
                            ),
                          ),
                        ),
                        if (!lida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mensagem,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      categoria,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
