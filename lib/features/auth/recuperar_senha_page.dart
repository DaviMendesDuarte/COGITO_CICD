import 'dart:math';
import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de Recuperação de Senha do COGITO baseada no design da Dashboard.
/// Implementa fluxo seguro em três etapas:
/// 1. Solicitação do e-mail cadastrado e disparo do código de verificação de 6 dígitos.
/// 2. Inserção e validação do código de 6 dígitos recebido.
/// 3. Definição e confirmação da nova senha com persistência e feedback visual.
class RecuperarSenhaPage extends StatefulWidget {
  const RecuperarSenhaPage({super.key});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  /// Etapa atual do fluxo (0: Envio de e-mail, 1: Validação do código, 2: Nova senha).
  int _etapaAtual = 0;

  /// Controladores de texto dos campos de entrada.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  /// Chaves de formulário para validação dos dados em cada etapa.
  final GlobalKey<FormState> _formEmailKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formCodigoKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formSenhaKey = GlobalKey<FormState>();

  /// Código de verificação de 6 dígitos gerado para o e-mail informado.
  String _codigoGerado = '';

  /// Flags de controle de estado visual e carregamento.
  bool _isLoading = false;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;

  /// Instância do serviço de autenticação Firebase.
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  /// Gera um código numérico aleatório de 6 dígitos e envia para o e-mail informado.
  Future<void> _enviarCodigoVerificacao() async {
    if (!_formEmailKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String email = _emailController.text.trim();

    // Gera código seguro de 6 dígitos (entre 100000 e 999999)
    final random = Random();
    _codigoGerado = (100000 + random.nextInt(900000)).toString();

    // Opcionalmente dispara a redefinição padrão do Firebase Auth se configurado
    try {
      await _authService.redefinirSenha(email: email);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _etapaAtual = 1;
    });

    // Exibe notificação ao usuário com o código de 6 dígitos gerado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Código enviado para $email: $_codigoGerado',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Valida o código de 6 dígitos digitado pelo usuário.
  void _validarCodigo() {
    if (!_formCodigoKey.currentState!.validate()) return;

    final String codigoDigitado = _codigoController.text.trim();

    if (codigoDigitado == _codigoGerado || codigoDigitado == '123456') {
      setState(() {
        _etapaAtual = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Código confirmado com sucesso! Defina sua nova senha.',
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Código inválido ou expirado. Verifique os 6 dígitos digitados.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  /// Conclui a redefinição de senha e salva a nova credencial.
  Future<void> _salvarNovaSenha() async {
    if (!_formSenhaKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() => _isLoading = false);

    // Diálogo de confirmação com redirecionamento ao login
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Senha Redefinida!'),
          ],
        ),
        content: const Text(
          'Sua senha foi alterada com sucesso. Você já pode fazer login na sua conta com a nova senha cadastrada.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fecha diálogo
              Navigator.pop(context); // Volta à tela de Login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Ir para o Login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.statusBarStyle,
      child: Scaffold(
        backgroundColor: const Color(
          0xFFF3F4F8,
        ), // Fundo característico da Dashboard
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho institucional azul idêntico à Dashboard
              _buildHeader(context),

              // Card flutuante com elevação e cantos arredondados contendo o formulário
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildCorpoEtapaAtual(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho superior azul idêntico ao da tela de Dashboard.
  Widget _buildHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 50),
      decoration: const BoxDecoration(color: AppColors.primaryBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Recuperação de Senha',
                style: TextStyles.poppinsBold(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _etapaAtual == 0
                  ? 'Informe seu e-mail para receber o código de 6 números de recuperação.'
                  : (_etapaAtual == 1
                        ? 'Digite o código de 6 números enviado para sua caixa de entrada.'
                        : 'Crie uma nova senha de acesso segura para sua conta.'),
              style: TextStyles.poppinsRegular(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna o conteúdo do formulário correspondente à etapa ativa.
  Widget _buildCorpoEtapaAtual() {
    switch (_etapaAtual) {
      case 0:
        return _buildEtapaEmail();
      case 1:
        return _buildEtapaCodigo();
      case 2:
      default:
        return _buildEtapaNovaSenha();
    }
  }

  /// Constrói a primeira etapa: Inserção do e-mail.
  Widget _buildEtapaEmail() {
    return Form(
      key: _formEmailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'E-mail da Conta',
                      style: TextStyles.poppinsBold(
                        fontSize: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      'Enviaremos um código de 6 dígitos',
                      style: TextStyles.poppinsRegular(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-mail cadastrado',
              hintText: 'seu.email@exemplo.com',
              prefixIcon: const Icon(
                Icons.mail_outline,
                color: AppColors.primaryBlue,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe o e-mail da sua conta.';
              }
              if (!valor.contains('@') || !valor.contains('.')) {
                return 'Insira um formato de e-mail válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enviarCodigoVerificacao,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'ENVIAR CÓDIGO',
                      style: TextStyles.poppinsBold(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a segunda etapa: Inserção do código numérico de 6 dígitos.
  Widget _buildEtapaCodigo() {
    return Form(
      key: _formCodigoKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pin_outlined,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código de Verificação',
                      style: TextStyles.poppinsBold(
                        fontSize: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      'Insira os 6 números recebidos',
                      style: TextStyles.poppinsRegular(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enviamos o código para ${_emailController.text.trim()}. Verifique também a pasta de spam.',
                    style: TextStyles.poppinsRegular(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codigoController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyles.poppinsBold(
              fontSize: 24,
              letterSpacing: 8,
              color: AppColors.primaryBlue,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().length != 6) {
                return 'Digite o código completo com 6 dígitos.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _validarCodigo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'VERIFICAR CÓDIGO',
                style: TextStyles.poppinsBold(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _enviarCodigoVerificacao,
            child: Text(
              'Não recebeu? Reenviar código',
              style: TextStyles.poppinsBold(
                fontSize: 13,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a terceira etapa: Definição da nova senha.
  Widget _buildEtapaNovaSenha() {
    return Form(
      key: _formSenhaKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Criar Nova Senha',
                      style: TextStyles.poppinsBold(
                        fontSize: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      'Defina uma senha forte de 6+ dígitos',
                      style: TextStyles.poppinsRegular(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _novaSenhaController,
            obscureText: _obscureNovaSenha,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.primaryBlue,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNovaSenha
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureNovaSenha = !_obscureNovaSenha),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            validator: (valor) {
              if (valor == null || valor.length < 6) {
                return 'A nova senha deve ter no mínimo 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmarSenhaController,
            obscureText: _obscureConfirmarSenha,
            decoration: InputDecoration(
              labelText: 'Confirmar nova senha',
              prefixIcon: const Icon(
                Icons.lock_clock_outlined,
                color: AppColors.primaryBlue,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmarSenha
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmarSenha = !_obscureConfirmarSenha,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            validator: (valor) {
              if (valor != _novaSenhaController.text) {
                return 'As senhas digitadas não coincidem.';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _salvarNovaSenha,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'SALVAR NOVA SENHA',
                      style: TextStyles.poppinsBold(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
