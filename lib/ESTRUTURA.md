# Estrutura do código

```
lib/
├── main.dart                     → inicia o Firebase, restaura a sessão e abre o app
├── app/
│   ├── app.dart                  → widget raiz (tema, rotas, tela inicial)
│   ├── rotas.dart                → nomes das rotas (Rotas.home, Rotas.chat...)
│   └── navegacao.dart            → abrirChat, abrirDetalhes, irParaInicio, sair
├── config/
│   ├── firebase_options.dart     → chaves do Firebase
│   ├── constantes.dart           → mensagens rápidas, tipos de ocorrência, mapa
│   └── tema.dart                 → cores e tema visual
├── modelos/
│   ├── perfil.dart               → dados do usuário logado
│   └── endereco_cep.dart         → endereço vindo do CEP
├── servicos/                     → REGRAS DE NEGÓCIO + Firebase (sem tela)
│   ├── sessao.dart               → usuário logado, login/logout, tela inicial
│   ├── comunidade_servico.dart   → criar/validar códigos de comunidade
│   ├── localizacao_servico.dart  → CEP (ViaCEP) e posição no mapa (OpenStreetMap)
│   └── ocorrencia_servico.dart   → abrir, conversar, assumir e encerrar ocorrências
├── utils/
│   ├── avisos.dart               → mostrarAviso (SnackBar)
│   ├── erros_auth.dart           → mensagens de erro de login
│   ├── formatadores.dart         → datas e endereços
│   └── ordenacao.dart            → ordenar documentos por data
├── widgets/                      → componentes reutilizáveis
│   ├── comuns/                   → Centralizado, EstadoVazio, EtiquetaStatus, IconeOcorrencia
│   ├── mapa/                     → MapaBase, mapa do morador, mapa do guarda, modal do chamado
│   ├── dialogos.dart             → confirmar saída / encerramento
│   ├── campo_codigo_comunidade.dart
│   ├── form_endereco.dart        → formulário de endereço por CEP
│   └── cartao_codigo_comunidade.dart
└── telas/
    ├── autenticacao/             → login, cadastro
    ├── comunidade/               → entrar em uma comunidade
    ├── perfil/                   → meu perfil
    ├── morador/                  → início, registrar ocorrência, pânico, histórico
    ├── guarda/                   → início, chamados
    └── ocorrencia/               → detalhes e chat (usados pelos dois perfis)
```

## Regra de dependência

`telas` → `widgets` → `servicos` → `modelos` / `config`

- As **telas** só montam a interface e chamam os serviços.
- Os **serviços** não conhecem telas: só regras de negócio e Firebase.
- A navegação usa **rotas nomeadas** (`app/rotas.dart`), então nenhuma tela
  importa outra tela diretamente.
