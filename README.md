# 📱 COGITO

[![COGITO CI - Continuous Integration & Quality Gate](https://github.com/DaviMendesDuarte/COGITO_CICD/actions/workflows/ci.yml/badge.svg)](https://github.com/DaviMendesDuarte/COGITO_CICD/actions/workflows/ci.yml)
[![COGITO CD - Continuous Delivery & Distribution](https://github.com/DaviMendesDuarte/COGITO_CICD/actions/workflows/cd.yml/badge.svg)](https://github.com/DaviMendesDuarte/COGITO_CICD/actions/workflows/cd.yml)

**COGITO** (*Controle de Orçamentos e Gestão Inteligente, Técnico e Objetivo*) é uma aplicação mobile desenvolvida em **Flutter** para gestão e planejamento financeiro pessoal, integrando autenticação segura, banco de dados em tempo real com **Firebase (Auth e Cloud Firestore)** e suporte do assistente financeiro inteligente **CONRADO**.

---

## 🚀 Pipeline de CI/CD & Quality Gate

Este repositório adota um fluxo profissional de Integração Contínua (CI) e Entrega Contínua (CD) automatizado via **GitHub Actions**:

- **CI (Quality Gate)**: Executa validação de formatação (`dart format`), análise estática (`flutter analyze`), auditoria de vazamento de segredos com **Gitleaks**, testes unitários com cobertura (`flutter test --coverage`) e compilação de verificação (`flutter build apk --debug`). Merges em branches principais exigem aprovação do **Quality Gate**.
- **CD (Entrega & Releases)**: Compila automaticamente pacotes Release (APK e App Bundle AAB) com cálculo de integridade SHA-256 e suporte a assinatura via GitHub Secrets, publicando versões oficiais nas **GitHub Releases**.

📖 **Consulte a documentação completa em [docs/ci_cd.md](docs/ci_cd.md)**.

---

## 🛠️ Tecnologias Principais

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK 3.11+)
- **Backend & Cloud**: Firebase Authentication, Cloud Firestore, Google Sign-In
- **Inteligência Artificial**: API Gemini Flash com mecanismo de contingência offline
- **Gráficos & Métricas**: `fl_chart`
- **Biometria & Segurança**: `local_auth`

---

## 💻 Execução Local

### Pré-requisitos
- Flutter SDK (versão estável 3.24+)
- Android Studio / Android SDK configurado

### Comandos
```bash
# 1. Obter dependências
flutter pub get

# 2. Executar análise estática
flutter analyze

# 3. Executar testes unitários
flutter test --coverage

# 4. Iniciar aplicação em modo desenvolvimento
flutter run
```
