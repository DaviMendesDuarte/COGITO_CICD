import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/button_styles.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/features/auth/login_page.dart';
import 'package:cogito/features/onboarding/first_steps_page.dart';
import 'package:cogito/services/firebase_auth_service.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de Cadastro de novos usuários simplificada (apenas E-mail, Senha e Confirmar Senha).
/// Integrada ao Firebase Auth e Firestore, direcionando para a tela de Primeiros Passos após o cadastro.
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  /// Chave global do formulário para validação dos campos.
  final _formKey = GlobalKey<FormState>();

  /// Controladores dos campos de texto (Nome e Sobrenome, E-mail, Senha e Confirmar Senha).
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  /// Flags de visibilidade de senha e estado de carregamento.
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  /// Instância do serviço Firebase Auth.
  final FirebaseAuthService _firebaseService = FirebaseAuthService();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  /// Realiza o processo de cadastro do cliente no Firebase Authentication e salva perfil no Firestore.
  /// Ao concluir, redireciona o novo usuário para a tela de Primeiros Passos.
  Future<void> _efetuarCadastro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String nomeCompleto = _nomeController.text.trim();
    final String email = _emailController.text.trim();
    final String senha = _senhaController.text;

    try {
      // Efetua a criação da conta no Firebase Authentication e grava perfil padrão no Firestore
      final usuario = await _firebaseService.cadastrarComEmailESenha(
        email: email,
        senha: senha,
        nome: nomeCompleto.isNotEmpty ? nomeCompleto : 'Usuário COGITO',
        telefone: '',
        idade: 18,
        tipoRenda: 'Salario_Fixo',
        rendaMensal: 0.0,
      );

      if (!mounted) return;

      if (usuario != null || FirebaseFirestoreService.usuarioLogado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso! Bem-vindo(a) ao COGITO.'),
            backgroundColor: Colors.green,
          ),
        );

        // Redireciona para a tela de Primeiros Passos
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PrimeirosPassosPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Realiza o cadastro/login com a conta Google via Firebase Authentication.
  Future<void> _cadastrarComGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usuario = await _firebaseService.signInWithGoogle();

      if (!mounted) return;

      if (usuario != null) {
        FirebaseFirestoreService.usuarioLogado =
            FirebaseAuthService.extrairDadosUsuarioGoogle(usuario);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bem-vindo(a), ${usuario.displayName ?? 'usuário'}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Redireciona para a tela de Primeiros Passos após o cadastro social
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PrimeirosPassosPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao entrar com Google: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.white),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: const Text(
            'Cadastro COGITO',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.primaryBlue,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Image.asset(
                      'assets/images/conrado/conrado_hi.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Crie sua conta',
                    style: TextStyles.welcomeTitle,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Informe seu e-mail e crie uma senha para se cadastrar',
                    textAlign: TextAlign.center,
                    style: TextStyles.welcomeDescription,
                  ),

                  const SizedBox(height: 28),

                  // Campo 1: Nome e Sobrenome
                  TextFormField(
                    controller: _nomeController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: _buildInputDecoration(
                      'Nome e Sobrenome',
                      Icons.person_outline,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe seu nome e sobrenome';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Campo 2: E-mail
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      'E-mail',
                      Icons.email_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o e-mail';
                      }
                      if (!v.contains('@')) {
                        return 'Informe um e-mail válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Campo 2: Senha
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _obscurePassword,
                    decoration:
                        _buildInputDecoration(
                          'Senha',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'A senha deve ter no mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Campo 3: Confirmar Senha
                  TextFormField(
                    controller: _confirmarSenhaController,
                    obscureText: _obscureConfirmPassword,
                    decoration:
                        _buildInputDecoration(
                          'Confirmar Senha',
                          Icons.lock_reset_outlined,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                    validator: (v) {
                      if (v != _senhaController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Botão de Cadastrar
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _efetuarCadastro,
                      style: ButtonStyles.primary.copyWith(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CADASTRAR',
                              style: TextStyles.buttonPrimary,
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Botão de Cadastro com Google
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _cadastrarComGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'G',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Cadastrar com Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Já possui uma conta? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Faça Login',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: AppColors.primaryBlue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
    );
  }
}
