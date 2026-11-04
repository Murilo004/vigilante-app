# 🛡️ Central de Segurança

Aplicativo em **Flutter** que conecta a **guarda do bairro** aos **moradores**.
O morador registra ocorrências ou aciona o botão de pânico. O guarda recebe o
chamado no mapa, conversa pelo chat e encerra quando resolve.

> 🎓 Projeto interdisciplinar desenvolvido na **Fatec Rio Preto** (2026)
> para as disciplinas de **Programação de Dispositivos Móveis** e
> **Laboratório de Engenharia de Software**.

---

## 👥 Equipe

| Integrante | GitHub |
|---|---|
| Murilo Sonsin Rálio | [Murilo004](https://github.com/Murilo004) |
| Isadora Bittinelli | [isadorabittinelli](https://github.com/isadorabittinelli) |
| Raquel Utiyama | [raquelutiyama](https://github.com/raquelutiyama) |
| Daniele Bianca | [DanieleBianca](https://github.com/DanieleBianca) |

---

## ✨ Funcionalidades

### Comunidades
- Cada **guarda** recebe um **código de comunidade** (ex.: `K7M2QX`) ao se cadastrar.
- O **morador** entra na comunidade com esse código.
- Cada guarda vê **só os chamados da comunidade dele**, e cada morador vê **só os alertas dos vizinhos da mesma comunidade**.

### Morador
- Cadastro com **endereço por CEP**: rua, bairro, cidade e UF são preenchidos sozinhos, e o morador digita só o número.
- **Registrar ocorrência**: movimentação suspeita, pessoa suspeita, veículo suspeito ou situação de risco.
- **Botão de pânico**: alerta prioritário para o guarda.
- **Mapa**: mostra a casa, os chamados abertos e os alertas dos vizinhos. Os ícones são só visuais, sem dados pessoais.
- **Chat** com o guarda: mensagens rápidas ou texto livre.
- **Histórico** das próprias ocorrências.

### Guarda
- **Mapa** com um ícone por chamado aberto. Ao tocar, abre o resumo: tipo, horário, morador e rua.
- **Contador** de chamados abertos, com destaque para o pânico.
- **Lista de chamados** (abertos e encerrados) e **detalhes** de cada um.
- **Chat** com o morador. O primeiro guarda que responde **assume** o chamado.
- **Encerrar** a ocorrência, o que fecha o chat e tira o ícone do mapa de todos.

### Perfil (os dois)
- Editar nome e endereço (por CEP).
- Morador: **trocar de comunidade** (só sem chamados abertos).
- Guarda: ver e **copiar o código** da comunidade.

### Privacidade
- Os vizinhos **não veem** nome nem número da casa de quem abriu o chamado.
- A posição nos alertas é **aproximada** (cerca de 100 m).
- As **regras do Firestore** (`firestore.rules`) garantem a separação entre as comunidades no servidor, e não só no app.

---

## 🧰 Tecnologias

| Uso | Tecnologia |
|---|---|
| App | [Flutter](https://flutter.dev) (Dart) |
| Login | Firebase Authentication (e-mail e senha) |
| Banco de dados e tempo real | Cloud Firestore |
| Mapa | [flutter_map](https://pub.dev/packages/flutter_map) + OpenStreetMap |
| CEP | [ViaCEP](https://viacep.com.br) |
| Endereço → coordenadas | Nominatim (OpenStreetMap) |

| Pacote | Versão | Para quê |
|---|---|---|
| `firebase_core` | ^5.1.0 | iniciar o Firebase |
| `firebase_auth` | ^7.0.1 | login e cadastro |
| `cloud_firestore` | ^7.1.0 | banco de dados em tempo real |
| `flutter_map` | ^8.3.2 | mapa |
| `latlong2` | ^0.10.1 | coordenadas do mapa |
| `http` | ^1.6.0 | ViaCEP e Nominatim |

As versões exatas instaladas ficam no `pubspec.lock`.

---

## ▶️ Como rodar

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) com **Dart 3.13.7 ou mais novo**
  (é a versão exigida no `pubspec.yaml`; confira com `flutter --version`).
- Google Chrome.
- No **Windows**: ativar o **Modo de Desenvolvedor**
  (`start ms-settings:developers`), que o Flutter exige para usar plugins.

### Passos

```bash
git clone <url-do-repositorio>
cd seguranca_app
flutter pub get
flutter run -d chrome
```

### Rodar no Android (opcional)

As pastas de plataforma (`android/`, `ios/`, `windows/`...) não vão para o
repositório. O Flutter recria a do Android a partir do `.metadata`:

```bash
flutter create --platforms=android .
flutter run
```

> Se o `flutter create` gerar o arquivo `test/widget_test.dart`, apague-o,
> porque ele usa um `MyApp` que não existe neste projeto.

---

## 🔥 Firebase

O app já está ligado ao projeto Firebase em `lib/config/firebase_options.dart`.

Para usar **outro** projeto Firebase:
1. Crie o projeto no [console do Firebase](https://console.firebase.google.com).
2. **Authentication** → ative **E-mail/senha**.
3. **Firestore Database** → crie o banco (região `southamerica-east1`).
4. **Firestore → Regras** → cole o conteúdo de `firestore.rules` e publique.
5. **Configurações do projeto → Seus apps → Web (`</>`)** → copie a configuração
   para `lib/config/firebase_options.dart`.

> A `apiKey` do Firebase Web **não é secreta**: ela só identifica o projeto.
> A proteção dos dados é feita pelas regras do Firestore.

### Coleções

| Coleção | Conteúdo |
|---|---|
| `comunidades/{codigo}` | guarda dono da comunidade |
| `usuarios/{uid}` | nome, papel (morador/guarda), comunidade, endereço, localização |
| `ocorrencias/{id}` | chamado completo (só o morador dono e o guarda leem) |
| `ocorrencias/{id}/mensagens` | chat do chamado |
| `alertas/{id}` | resumo sem dados pessoais (para os vizinhos verem no mapa) |

---

## 🧪 Testando

1. Cadastre um **guarda** e anote o **código** que aparece na tela inicial.
2. Em uma **janela anônima** (Ctrl+Shift+N), cadastre um **morador** com esse código.
   Para testar, use o CEP `15015-100` (São José do Rio Preto - SP).
3. Abra uma ocorrência com o morador. Ela aparece no mapa e na lista do guarda.
4. Converse pelo chat e encerre a ocorrência pelo guarda.

---

## 🗂️ Estrutura do código

```
lib/
├── main.dart                     → inicia o Firebase, restaura a sessão e abre o app
├── app/
│   ├── app.dart                  → widget raiz (tema, rotas, tela inicial)
│   ├── rotas.dart                → nomes das rotas (Rotas.home, Rotas.chat...)
│   └── navegacao.dart            → abrirChat, abrirDetalhes, irParaInicio, sair
├── config/
│   ├── firebase_options.dart     → configuração do Firebase
│   ├── constantes.dart           → mensagens rápidas, tipos de ocorrência, mapa
│   └── tema.dart                 → cores e tema visual
├── modelos/
│   ├── perfil.dart               → dados do usuário logado
│   └── endereco_cep.dart         → endereço vindo do CEP
├── servicos/                     → regras de negócio + Firebase (sem tela)
│   ├── sessao.dart               → usuário logado, login/logout, tela inicial
│   ├── comunidade_servico.dart   → criar e validar códigos de comunidade
│   ├── localizacao_servico.dart  → CEP (ViaCEP) e posição no mapa
│   └── ocorrencia_servico.dart   → abrir, conversar, assumir e encerrar ocorrências
├── utils/                        → avisos, erros de login, formatação, ordenação
├── widgets/                      → componentes reutilizáveis
│   ├── comuns/                   → Centralizado, EstadoVazio, EtiquetaStatus, IconeOcorrencia
│   ├── mapa/                     → mapa base, do morador, do guarda e modal do chamado
│   ├── dialogos.dart
│   ├── campo_codigo_comunidade.dart
│   ├── form_endereco.dart
│   └── cartao_codigo_comunidade.dart
└── telas/
    ├── autenticacao/             → login e cadastro
    ├── comunidade/               → entrar em uma comunidade
    ├── perfil/                   → meu perfil
    ├── morador/                  → início, registrar ocorrência, pânico, histórico
    ├── guarda/                   → início e chamados
    └── ocorrencia/               → detalhes e chat (usados pelos dois perfis)
```

### Regra de dependência

`telas` → `widgets` → `servicos` → `modelos` / `config`

- As **telas** montam a interface e chamam os serviços.
- Os **serviços** não conhecem telas: cuidam só das regras de negócio e do Firebase.
- A navegação usa **rotas nomeadas** (`app/rotas.dart`), então uma tela não importa outra diretamente.
