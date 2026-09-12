import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço de integração com API de Inteligência Artificial para o assistente CONRADO.
/// Suporta envio de prompts para a API REST do Gemini e possui mecanismo de respostas
/// contextuais de contingência (fallback) em finanças pessoais para funcionamento offline.
class ConradoApiService {
  /// Chave de API opcional para chamadas à Gemini API (pode ser configurada pelo desenvolvedor/usuário).
  final String? apiKey;

  /// URL da API REST do modelo Gemini 1.5 Flash.
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Instrução do sistema para definir a personalidade, restrições e o foco do CONRADO.
  static const String _systemInstruction =
      'Você é o CONRADO, assistente virtual inteligente e especialista exclusivo em finanças pessoais '
      'e gestão orçamentária do aplicativo COGITO (Controle de Orçamentos e Gestão Inteligente, Técnico e Objetivo). '
      'REGRAS RÍGIDAS DE COMPORTAMENTO:\n'
      '1. Foco em Finanças: Suas respostas devem priorizar temas financeiros, planejamento, economias e orçamentos.\n'
      '2. Usuário Mal-educado ou Ofensivo: Se o usuário for rude, falar palavrões, ofender ou demonstrar má educação, fique visivelmente estressado (😤) e exija ser tratado com respeito antes de qualquer atendimento.\n'
      '3. Perguntas Não Relacionadas a Finanças: Se o usuário fizer QUALQUER pergunta que não seja de finanças, recuse responder e declare explicitamente que você só responde a dúvidas financeiras.';

  ConradoApiService({this.apiKey});

  /// Envia uma mensagem do usuário para o CONRADO e retorna a resposta gerada pela IA.
  /// Caso ocorra erro de conexão ou a API Key não esteja configurada, retorna uma resposta inteligente de contingência.
  Future<String> sendMessage(String userMessage) async {
    // Se não houver chave de API definida, utiliza o fallback contextual instantâneo.
    if (apiKey == null || apiKey!.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1000)); // Simula tempo de resposta de rede
      return _getFallbackResponse(userMessage);
    }

    try {
      // Monta a requisição HTTP POST para a API do Gemini
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemInstruction': {
            'parts': [
              {'text': _systemInstruction}
            ]
          },
          'contents': [
            {
              'parts': [
                {'text': userMessage}
              ]
            }
          ]
        }),
      );

      // Trata resposta de sucesso (200 OK)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? textResponse =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (textResponse != null && textResponse.isNotEmpty) {
          return textResponse.trim();
        }
      }

      // Em caso de erro na resposta da API, aciona o fallback inteligente
      return _getFallbackResponse(userMessage);
    } catch (e) {
      // Em caso de falha de conexão de rede, aciona o fallback
      return _getFallbackResponse(userMessage);
    }
  }

  /// Gera respostas financeiras úteis e regras de comportamento de contingência (fallback)
  /// quando a API estiver indisponível ou sem chave configurada.
  String _getFallbackResponse(String message) {
    final String query = message.toLowerCase().trim();

    // 1. Verificação de desrespeito / grosseria / palavrões -> Reação estressada do CONRADO 😤
    final List<String> termosOfensivos = [
      'burro', 'idiota', 'lixo', 'inútil', 'chato', 'otário', 'palhaço',
      'cale a boca', 'cala a boca', 'cala boca', 'merda', 'caralho', 'porra',
      'fdp', 'imbecil', 'babaca', 'vai te cata', 'vai se foder', 'lixo de app'
    ];

    for (final termo in termosOfensivos) {
      if (query.contains(termo)) {
        return '😤 Ei! Por favor, me trate com mais respeito e educação!\n\n'
            'Eu sou o CONRADO, seu assistente financeiro no COGITO. Estou aqui para te ajudar com seu dinheiro, '
            'mas não aceito ofensas ou má educação. Vamos manter a conversa respeitosa? Respire fundo e me pergunte de novo com educação!';
      }
    }

    // 2. Auxílio Financeiro Especializado - FGTS & Saque Aniversário
    if (query.contains('fgts') || query.contains('aniversário') || query.contains('aniversario') || query.contains('saque')) {
      return '📊 **Auxílio de Status do FGTS & Saque Aniversário**\n\n'
          '• **O que é o FGTS?** O empregador deposita mensalmente 8% do seu salário bruto em uma conta vinculada na Caixa Econômica.\n'
          '• **Saque-Aniversário:** Permite retirar anualmente uma porcentagem do saldo no mês do seu aniversário (ex: de 5% a 50% + parcela adicional de R\$ 50 a R\$ 2.900).\n'
          '• **Atenção:** Ao aderir ao Saque-Aniversário, em caso de demissão sem justa causa, você saca apenas a multa rescisória de 40%, não o saldo total imediato!\n\n'
          'Dica COGITO: Use o saldo do Saque-Aniversário apenas para quitar dívidas de juros altos ou para reforçar sua Reserva de Emergência!';
    }

    // 3. Auxílio Financeiro Especializado - Décimo Terceiro Salário (13º)
    if (query.contains('décimo') || query.contains('decimo') || query.contains('13') || query.contains('décimo terceiro')) {
      return '💰 **Auxílio e Cálculo do 13º Salário**\n\n'
          'O Décimo Terceiro é dividido em duas parcelas para trabalhadores regidos pela CLT:\n'
          '• **1ª Parcela (Paga até 30 de Novembro):** Corresponde a exatos 50% do seu salário bruto mensal, sem qualquer desconto de INSS ou Imposto de Renda.\n'
          '• **2ª Parcela (Paga até 20 de Dezembro):** É calculada com base no salário bruto total, descontando o valor já pago na 1ª parcela e aplicando as alíquotas oficiais de INSS e IRRF.\n\n'
          '💡 **Estratégia COGITO:** Reserve ao menos 40% do seu 13º para quitar IPTU, IPVA ou despesas de início de ano, evitando surpresas em janeiro!';
    }

    // 4. Auxílio Financeiro Especializado - Planejamento Financeiro de Férias
    if (query.contains('férias') || query.contains('ferias') || query.contains('viagem') || query.contains('viajar')) {
      return '🏖️ **Planejamento Financeiro para Férias**\n\n'
          'Ao tirar férias, você recebe seu salário adiantado + o **1/3 Constitucional de Férias** (com descontos de INSS e IRRF).\n\n'
          '⚠️ **Alerta Importante:** Lembre-se de que no mês seguinte ao retorno das férias você NÃO receberá salário integral (pois já foi adiantado)!\n\n'
          '**Passos para umas férias sem dívidas no COGITO:**\n'
          '1. Defina o orçamento total da viagem com antecedência;\n'
          '2. Separe o 1/3 extra das férias exclusivamente para os gastos do passeio;\n'
          '3. Guarde o valor do salário adiantado em uma conta separada para pagar as contas básicas do mês do seu retorno.';
    }

    // 5. Consultas financeiras gerais (Reserva, Economia, Dívidas, Orçamento, Saudações)
    if (query.contains('reserva') || query.contains('emergência')) {
      return 'Uma reserva de emergência ideal deve cobrir de 3 a 6 meses do seu custo de vida mensal! '
          'Recomendo guardá-la em aplicações de liquidez diária, como Tesouro Selic ou CDBs de 100% do CDI no COGITO.';
    } else if (query.contains('economizar') || query.contains('guardar') || query.contains('poupar')) {
      return 'Para economizar de forma eficiente com o COGITO, tente a regra 50-30-20:\n'
          '• 50% para necessidades básicas (aluguel, contas);\n'
          '• 30% para desejos pessoais (lazer, compras);\n'
          '• 20% para prioridades financeiras (investimentos e reserva).';
    } else if (query.contains('dívida') || query.contains('divida') || query.contains('cartão') || query.contains('cartao')) {
      return 'Para quitar dívidas mais rápido:\n'
          '1. Mapeie todas as dívidas e juros cobrados;\n'
          '2. Priorize pagar as dívidas com juros mais altos (ex: cartão de crédito);\n'
          '3. Tente renegociar descontos para pagamento à vista.';
    } else if (query.contains('orçamento') || query.contains('orcamento') || query.contains('meta')) {
      return 'No COGITO, registrar cada pequena despesa diariamente é a chave para o controle! '
          'Analise seus gastos por categoria no final de cada semana para identificar onde cortar excessos.';
    } else if (query.contains('olá') || query.contains('ola') || query.contains('oi') || query.contains('bom dia') || query.contains('boa tarde') || query.contains('boa noite')) {
      return 'Olá! Sou o CONRADO, seu especialista exclusivo em gestão financeira no COGITO. '
          'Como posso te ajudar a organizar seu dinheiro, FGTS, 13º Salário ou planejamento de férias hoje?';
    }

    // 6. Recusa direta para qualquer pergunta fora do âmbito financeiro
    final List<String> termosFinanceiros = [
      'dinheiro', 'saldo', 'finança', 'financa', 'conta', 'banco', 'cartão', 'cartao',
      'fgts', '13', 'décimo', 'decimo', 'férias', 'ferias', 'orçamento', 'orcamento',
      'investimento', 'reserva', 'economizar', 'poupar', 'guardar', 'dívida', 'divida',
      'gasto', 'despesa', 'receita', 'salário', 'salario', 'renda', 'pix', 'boleto',
      'lucro', 'juros', 'imposto', 'irrf', 'inss', 'clt', 'freelance', 'autônomo', 'autonomo',
      'meta', 'caixinha', 'cogito', 'olá', 'ola', 'oi', 'ajuda'
    ];

    bool eFinanceiro = false;
    for (final termo in termosFinanceiros) {
      if (query.contains(termo)) {
        eFinanceiro = true;
        break;
      }
    }

    if (!eFinanceiro) {
      return '💡 **Aviso do CONRADO:**\n'
          'Desculpe, mas eu sou o CONRADO e fui programado para responder **exclusivamente** sobre Finanças Pessoais, Orçamentos, FGTS, 13º Salário e Planejamento Financeiro no COGITO. Eu não respondo a perguntas fora do âmbito financeiro.';
    }

    // Fallback padrão para dúvidas financeiras gerais
    return 'Entendi! Para te ajudar melhor no COGITO, me dê mais detalhes sobre sua dúvida financeira (ex: FGTS, 13º Salário, Férias, Reserva de Emergência, Dívidas ou Orçamentos)! 💡';
  }
}
