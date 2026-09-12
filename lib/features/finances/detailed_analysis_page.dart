import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de Análise de Gastos e Relatórios Unificados do COGITO.
/// Centraliza todos os relatórios financeiros, estatísticas de entradas/saídas,
/// distribuição por categoria, gráfico comparativo mensal e diagnósticos do CONRADO IA.
class AnaliseDetalhadaPage extends StatefulWidget {
  const AnaliseDetalhadaPage({super.key});

  @override
  State<AnaliseDetalhadaPage> createState() => _AnaliseDetalhadaPageState();
}

class _AnaliseDetalhadaPageState extends State<AnaliseDetalhadaPage> {
  /// Instância do serviço Firebase Firestore para consulta reativa dos dados de transações.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Filtro de período selecionado ("Este mês" por padrão).
  String _selectedPeriodo = 'Este mês';

  /// Extrai com segurança a data [DateTime] de um registro de transação.
  DateTime _extrairData(Map<String, dynamic> t) {
    if (t['data_dt'] is DateTime) {
      return t['data_dt'] as DateTime;
    }
    if (t['data'] is Timestamp) {
      return (t['data'] as Timestamp).toDate();
    }
    if (t['data'] is String) {
      try {
        return DateTime.parse(t['data'] as String);
      } catch (_) {}
    }
    if (t['data_criacao'] is Timestamp) {
      return (t['data_criacao'] as Timestamp).toDate();
    }
    return DateTime.now();
  }

  /// Filtra a lista de transações conforme o período selecionado no Combo Box.
  List<Map<String, dynamic>> _filtrarTransacoesPorPeriodo(List<Map<String, dynamic>> transacoes) {
    final agora = DateTime.now();

    return transacoes.where((t) {
      final DateTime dt = _extrairData(t);

      switch (_selectedPeriodo) {
        case 'Este mês':
          return dt.year == agora.year && dt.month == agora.month;
        case 'Últimos 3 meses':
          final limite = DateTime(agora.year, agora.month - 3, agora.day);
          return dt.isAfter(limite) || dt.isAtSameMomentAs(limite);
        case 'Este ano':
          return dt.year == agora.year;
        case 'Todo o período':
        default:
          return true;
      }
    }).toList();
  }

  /// Constrói o Combo Box estilizado com ícones e sombra suave para filtragem de período.
  Widget _buildFiltroComboBox() {
    final Map<String, IconData> opcoesComIcones = {
      'Este mês': Icons.today_rounded,
      'Últimos 3 meses': Icons.date_range_rounded,
      'Este ano': Icons.calendar_month_rounded,
      'Todo o período': Icons.history_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriodo,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryBlue,
              size: 22,
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          elevation: 8,
          items: opcoesComIcones.entries.map((entry) {
            final isSelected = entry.key == _selectedPeriodo;
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.value,
                    size: 18,
                    color: isSelected ? AppColors.primaryBlue : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (novoVal) {
            if (novoVal != null) {
              setState(() {
                _selectedPeriodo = novoVal;
              });
            }
          },
        ),
      ),
    );
  }

  /// Exibe Pop-Up Modal com os detalhes completos do Gráfico de Categorias.
  void _exibirModalGraficoCategorias(BuildContext context, Map<String, double> categoriasMap, double totalSaidas) {
    final List<PieChartSectionData> secoes = [];
    final List<Color> cores = [
      AppColors.primaryBlue,
      AppColors.primaryOrange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
    ];

    int idx = 0;
    categoriasMap.forEach((cat, valor) {
      final double pct = totalSaidas > 0 ? (valor / totalSaidas * 100) : 0;
      final Color cor = cores[idx % cores.length];
      secoes.add(
        PieChartSectionData(
          color: cor,
          value: valor > 0 ? valor : 1,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 45,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
      idx++;
    });

    if (secoes.isEmpty) {
      secoes.add(PieChartSectionData(color: Colors.grey, value: 100, title: '100%', radius: 45));
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(22),
          constraints: const BoxConstraints(maxHeight: 540),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pie_chart, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detalhamento por Categoria',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: secoes,
                      centerSpaceRadius: 35,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                if (categoriasMap.isEmpty)
                  const Text('Nenhum gasto registrado neste período.', style: TextStyle(color: Colors.grey))
                else
                  ...categoriasMap.entries.map((e) {
                    final int i = categoriasMap.keys.toList().indexOf(e.key);
                    final Color cor = cores[i % cores.length];
                    final double pct = totalSaidas > 0 ? (e.value / totalSaidas * 100) : 0;
                    return _buildCategoriaDetailItem(e.key, 'R\$ ${e.value.toStringAsFixed(2)}', '${pct.toStringAsFixed(0)}%', cor);
                  }),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dica do CONRADO: Acompanhar seus maiores envelopes de gastos reduz em até 30% despesas impulsivas.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Classe auxiliar interna para agrupar totais de gastos dos últimos meses.
  List<Map<String, dynamic>> _calcularEvolucaoUltimos4Meses(List<Map<String, dynamic>> todasTransacoes) {
    final agora = DateTime.now();
    final List<Map<String, dynamic>> mesesData = [];
    final nomesMeses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final nomesCompletos = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

    // Coleta os últimos 4 meses em ordem cronológica (de 3 meses atrás até o atual)
    for (int i = 3; i >= 0; i--) {
      final mesRef = DateTime(agora.year, agora.month - i, 1);
      final int mes = mesRef.month;
      final int ano = mesRef.year;

      double totalGastoMes = 0.0;
      for (final t in todasTransacoes) {
        final DateTime dt = _extrairData(t);
        if (dt.year == ano && dt.month == mes && t['tipo'] == 'Despesa') {
          totalGastoMes += (t['valor'] as num?)?.toDouble() ?? 0.0;
        }
      }

      mesesData.add({
        'sigla': nomesMeses[mes - 1],
        'nomeCompleto': '${nomesCompletos[mes - 1]}${i == 0 ? ' (Mês Atual)' : ''}',
        'ano': ano,
        'totalGasto': totalGastoMes,
      });
    }

    // Calcula variação percentual em relação ao mês anterior
    for (int i = 0; i < mesesData.length; i++) {
      if (i == 0) {
        mesesData[i]['variacao'] = 'Estável';
      } else {
        final double anterior = mesesData[i - 1]['totalGasto'] as double;
        final double atual = mesesData[i]['totalGasto'] as double;
        if (anterior == 0) {
          mesesData[i]['variacao'] = atual > 0 ? '+ 100%' : '0%';
        } else {
          final double pct = ((atual - anterior) / anterior) * 100;
          final String prefix = pct >= 0 ? '+ ' : '- ';
          mesesData[i]['variacao'] = '$prefix${pct.abs().toStringAsFixed(0)}%';
        }
      }
    }

    return mesesData;
  }

  /// Exibe Pop-Up Modal com os detalhes completos do Gráfico de Evolução Mensal.
  void _exibirModalGraficoEvolucao(BuildContext context, List<Map<String, dynamic>> evolucaoMeses) {
    double maxGasto = 100.0;
    for (final m in evolucaoMeses) {
      final double g = m['totalGasto'] as double;
      if (g > maxGasto) maxGasto = g;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(22),
          constraints: const BoxConstraints(maxHeight: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bar_chart, color: AppColors.primaryOrange),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Evolução Mensal de Gastos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final int idx = value.toInt();
                              if (idx >= 0 && idx < evolucaoMeses.length) {
                                return Text(
                                  evolucaoMeses[idx]['sigla'].toString(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(evolucaoMeses.length, (idx) {
                        final double valor = evolucaoMeses[idx]['totalGasto'] as double;
                        final bool isAtual = idx == evolucaoMeses.length - 1;
                        return BarChartGroupData(
                          x: idx,
                          barRods: [
                            BarChartRodData(
                              toY: valor > 0 ? valor : 5,
                              color: isAtual ? AppColors.primaryOrange : AppColors.primaryBlue.withValues(alpha: 0.4 + (idx * 0.15)),
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                ...evolucaoMeses.map((m) {
                  final String nome = m['nomeCompleto'];
                  final double val = m['totalGasto'] as double;
                  final String varPct = m['variacao'];
                  return _buildEvolucaoMonthItem(
                    nome,
                    'R\$ ${val.toStringAsFixed(2).replaceAll('.', ',')}',
                    varPct,
                  );
                }),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, color: AppColors.primaryOrange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sua evolução mensal é atualizada automaticamente a cada lançamento de transação no COGITO.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Item visual auxiliar para a lista de categorias no modal.
  Widget _buildCategoriaDetailItem(String nome, String valor, String pct, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(pct, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  /// Item visual auxiliar para comparativo mensal no modal.
  Widget _buildEvolucaoMonthItem(String mes, String valor, String varPct) {
    final bool isPos = varPct.startsWith('+');
    final Color corVar = varPct == 'Estável' || varPct == '0%' ? Colors.grey : (isPos ? Colors.red : Colors.green);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(mes, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Row(
            children: [
              Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 10),
              Text(varPct, style: TextStyle(color: corVar, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String idCliente = FirebaseFirestoreService.idClienteAtual;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.primaryBlue),
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(context),
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Análise de Gastos & Relatórios',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.buscarTransacoesStream(idCliente),
          builder: (context, snapshot) {
            final List<Map<String, dynamic>> transacoesBrutas = snapshot.data ?? [];

            // Aplica a filtragem reativa pelo período selecionado no Combo Box
            final List<Map<String, dynamic>> transacoes = _filtrarTransacoesPorPeriodo(transacoesBrutas);
            final List<Map<String, dynamic>> evolucaoMeses = _calcularEvolucaoUltimos4Meses(transacoesBrutas);

            double totalEntradas = 0.0;
            double totalSaidas = 0.0;
            final Map<String, double> categoriasMap = {};

            for (final t in transacoes) {
              final double val = (t['valor'] as num?)?.toDouble() ?? 0.0;
              final String tipo = t['tipo'] ?? 'Receita';
              final String cat = t['categoria'] ?? 'Outros';

              if (tipo == 'Receita') {
                totalEntradas += val;
              } else {
                totalSaidas += val;
                categoriasMap[cat] = (categoriasMap[cat] ?? 0.0) + val;
              }
            }

            final double balancoLiquido = totalEntradas - totalSaidas;
            final double mediaDiaria = totalSaidas > 0 ? (totalSaidas / 30) : 0.0;

            String maiorCategoriaNome = 'Nenhuma';
            double maiorCategoriaValor = 0.0;
            categoriasMap.forEach((k, v) {
              if (v > maiorCategoriaValor) {
                maiorCategoriaValor = v;
                maiorCategoriaNome = k;
              }
            });

            final List<PieChartSectionData> secoesCategorias = [];
            final List<Color> coresPie = [
              AppColors.primaryBlue,
              AppColors.primaryOrange,
              Colors.purple,
              Colors.teal,
              Colors.pink,
              Colors.amber,
            ];

            int cIndex = 0;
            categoriasMap.forEach((cat, valor) {
              final double pct = totalSaidas > 0 ? (valor / totalSaidas * 100) : 0;
              secoesCategorias.add(
                PieChartSectionData(
                  color: coresPie[cIndex % coresPie.length],
                  value: valor > 0 ? valor : 1,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 25,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              );
              cIndex++;
            });

            if (secoesCategorias.isEmpty) {
              secoesCategorias.add(
                PieChartSectionData(color: Colors.grey.shade300, value: 1, title: '0%', radius: 25),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro de Período dos Relatórios com Combo Box estilizado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Período do Relatório:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue),
                      ),
                      _buildFiltroComboBox(),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Banner Superior Informativo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.analytics_rounded, size: 40, color: AppColors.primaryYellow),
                        const SizedBox(height: 10),
                        const Text(
                          'Relatório Inteligente de Gastos',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Balanço do Período: R\$ ${balancoLiquido.toStringAsFixed(2).replaceAll('.', ',')}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SEÇÃO DE RESUMO DE BALANÇO (Entradas vs Saídas)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_upward_rounded, color: Colors.green, size: 18),
                                  SizedBox(width: 6),
                                  Text('Entradas', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'R\$ ${totalEntradas.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_downward_rounded, color: Colors.red, size: 18),
                                  SizedBox(width: 6),
                                  Text('Saídas', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'R\$ ${totalSaidas.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Gráficos & Distribuição (Tempo Real)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 12),

                  // SEÇÃO DE GRÁFICOS LADO A LADO (ROW COM EXPANDED)
                  Row(
                    children: [
                      // GRÁFICO 1: PIZZA (CATEGORIAS)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _exibirModalGraficoCategorias(context, categoriasMap, totalSaidas),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.pie_chart_outline, color: AppColors.primaryBlue, size: 18),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Categorias',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 110,
                                  child: PieChart(
                                    PieChartData(
                                      sections: secoesCategorias,
                                      centerSpaceRadius: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Ver detalhes ➔',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // GRÁFICO 2: BARRAS (EVOLUÇÃO MENSAL)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _exibirModalGraficoEvolucao(context, evolucaoMeses),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bar_chart, color: AppColors.primaryOrange, size: 18),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Evolução',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryOrange),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 110,
                                  child: BarChart(
                                    BarChartData(
                                      borderData: FlBorderData(show: false),
                                      gridData: const FlGridData(show: false),
                                      titlesData: const FlTitlesData(show: false),
                                      barGroups: List.generate(evolucaoMeses.length, (idx) {
                                        final double v = evolucaoMeses[idx]['totalGasto'] as double;
                                        final bool isAtual = idx == evolucaoMeses.length - 1;
                                        return BarChartGroupData(
                                          x: idx,
                                          barRods: [
                                            BarChartRodData(
                                              toY: v > 0 ? (v / 100).clamp(1.0, 100.0) : 2,
                                              color: isAtual ? AppColors.primaryOrange : AppColors.primaryBlue.withValues(alpha: 0.4 + (idx * 0.15)),
                                              width: 10,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Ver histórico ➔',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // SEÇÃO DE RELATÓRIOS EXECUTIVOS RECOMENDADOS & DIAGNÓSTICO CONRADO
                  const Text(
                    'Relatórios & Diagnóstico CONRADO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildRelatorioRow('Média Diária de Gastos', 'R\$ ${mediaDiaria.toStringAsFixed(2).replaceAll('.', ',')} / dia', Icons.today, Colors.blue),
                        const Divider(height: 20),
                        _buildRelatorioRow('Maior Categoria', '$maiorCategoriaNome (R\$ ${maiorCategoriaValor.toStringAsFixed(2).replaceAll('.', ',')})', Icons.restaurant, Colors.orange),
                        const Divider(height: 20),
                        _buildRelatorioRow('Projeção de Economia Potencial', 'R\$ ${(totalEntradas * 0.15).toStringAsFixed(2).replaceAll('.', ',')} no mês', Icons.savings, Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Constrói cada linha dos relatórios executivos recomendados.
  Widget _buildRelatorioRow(String titulo, String valor, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
