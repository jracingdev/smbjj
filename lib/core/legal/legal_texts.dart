import '../constants.dart';

/// Textos legais do app CT SM BJJ (LGPD e uso do serviço).
class LegalTexts {
  LegalTexts._();

  static const termosTitulo = 'Termos e Condições de Uso';
  static const privacidadeTitulo = 'Política de Privacidade';

  static String get dataAtualizacao => '11 de junho de 2026';

  static String get termos => '''
Última atualização: $dataAtualizacao

1. ACEITAÇÃO
Ao criar conta, acessar ou utilizar o aplicativo e site CT SM BJJ ("App"), você declara ter lido, compreendido e aceito estes Termos e Condições de Uso e a Política de Privacidade.

2. QUEM SOMOS
O App é operado por $professorNome, responsável pela academia CT SM BJJ, $academiaCredenciada ($academiaCredencial), com sede no Rio de Janeiro/RJ, Brasil.

3. OBJETO DO SERVIÇO
O App destina-se à gestão da academia e relacionamento com alunos, incluindo, entre outras funções: cadastro, turmas, presença, mensalidades, avisos, medalhas, loja de produtos e comunicação com a equipe.

4. ELEGIBILIDADE E CONTA
4.1. O usuário deve fornecer informações verdadeiras e mantê-las atualizadas.
4.2. Menores de 18 anos devem utilizar o App com conhecimento e responsabilidade de pais ou responsáveis legais.
4.3. O login pode ser feito por e-mail e senha ou Google, conforme disponibilidade na plataforma.
4.4. Você é responsável pela confidencialidade da sua senha e por atividades realizadas na sua conta.

5. CADASTRO NA ACADEMIA
Após criar a conta no App, o aluno pode complementar dados na academia. A matrícula e a validação do cadastro dependem de aprovação do professor/administrador.

6. LOJA E COMPRAS
6.1. O site principal (smbjj.com.br) exibe a loja para visitantes; alunos e equipe acessam o app completo após login.
6.2. Visitantes podem comprar informando nome e contato; alunos logados compram com dados vinculados ao cadastro.
6.3. Preços, prazos e condições exibidos no App podem ser alterados sem aviso prévio, respeitados pedidos já confirmados.

7. PAGAMENTOS
Pagamentos podem ocorrer via PIX, Mercado Pago ou outros meios indicados no App. Transações com Mercado Pago seguem também os termos da respectiva plataforma.

8. CONDUTA DO USUÁRIO
É proibido: usar o App para fins ilícitos; tentar acessar dados de terceiros sem autorização; interferir no funcionamento do sistema; publicar conteúdo ofensivo ou que viole direitos de terceiros.

9. PROPRIEDADE INTELECTUAL
Marcas, logotipos, layout e conteúdos do App pertencem à CT SM BJJ ou a seus licenciadores. O uso não autorizado é vedado.

10. DISPONIBILIDADE E LIMITAÇÃO
O App é fornecido "como está". Empregamos esforços razoáveis para manter o serviço disponível, mas não garantimos operação ininterrupta. A academia não se responsabiliza por indisponibilidades de internet, serviços de terceiros ou caso fortuito.

11. SUSPENSÃO E ENCERRAMENTO
Podemos suspender ou encerrar contas em caso de violação destes Termos, fraude ou determinação legal. O usuário pode solicitar exclusão da conta conforme a Política de Privacidade.

12. ALTERAÇÕES
Estes Termos podem ser atualizados. A data da última versão será indicada no App. O uso continuado após alterações constitui aceitação.

13. LEGISLAÇÃO E FORO
Aplica-se a legislação brasileira. Fica eleito o foro da comarca do Rio de Janeiro/RJ, salvo disposição legal em contrário.

14. CONTATO
Dúvidas sobre estes Termos: $developerEmail · WhatsApp $professorTelefoneExibicao.

---

TERMO DE APTIDÃO FÍSICA E RESPONSABILIDADE

Declaro que li e concordo com os termos abaixo:

✓ Estou em condições físicas e de saúde adequadas para a prática de Jiu-Jitsu.

✓ Declaro não possuir doença, lesão, limitação física ou qualquer condição médica pré-existente que impeça ou contraindique minha participação nos treinamentos.

✓ Comprometo-me a informar imediatamente à equipe ou aos instrutores caso haja qualquer alteração em meu estado de saúde.

✓ Tenho ciência de que a prática do Jiu-Jitsu envolve contato físico e riscos inerentes à atividade esportiva, incluindo quedas, contusões, torções e outras lesões.

✓ Assumo total responsabilidade pelas informações prestadas e pela minha participação nas atividades, isentando a Marinho Team Jiu-Jitsu, seus professores e colaboradores de responsabilidade por problemas de saúde ou condições médicas não informadas previamente.

✓ Declaro ser maior de 18 anos ou possuir autorização de meu responsável legal para participar das atividades.

Ao marcar a opção "Li e Concordo" no cadastro, declaro que as informações acima são verdadeiras e que aceito integralmente os termos desta declaração. O sistema registra automaticamente seu nome, e-mail, data, hora e endereço IP do aceite para fins de comprovação.
''';

  static String get privacidade => '''
Última atualização: $dataAtualizacao

Esta Política descreve como a CT SM BJJ trata dados pessoais no App e no site, em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018 — LGPD).

1. CONTROLADOR
Controlador dos dados: $professorNome / CT SM BJJ.
Contato do encarregado/DPO: $developerEmail · WhatsApp $professorTelefoneExibicao.

2. DADOS QUE COLETAMOS
Podemos tratar:
• Identificação: nome, e-mail, telefone/WhatsApp, foto, data de nascimento, documentos quando informados no cadastro.
• Academia: turmas, faixa/grau, presença, medalhas, avisos lidos.
• Financeiro: mensalidades, status de pagamento, preferências de cobrança.
• Loja: pedidos, produtos, endereço de entrega quando informado, histórico de compras.
• Visitantes da loja pública: nome, e-mail, telefone e observações fornecidos na compra.
• Técnicos: identificadores de sessão, logs de autenticação, versão do app e dados necessários ao funcionamento.
• Biometria (opcional): credenciais armazenadas localmente no dispositivo para login rápido — não enviamos impressões digitais ao servidor.

3. FINALIDADES
• Gestão de alunos, turmas e comunicação institucional.
• Controle de presença, graduação e eventos da academia.
• Cobrança de mensalidades e integração com Mercado Pago.
• Processamento de pedidos da loja.
• Segurança, autenticação e melhoria do App.
• Cumprimento de obrigações legais.

4. BASES LEGAIS (LGPD)
Execução de contrato ou procedimentos preliminares; legítimo interesse (gestão da academia e segurança); consentimento quando aplicável (ex.: biometria, comunicações opcionais); cumprimento de obrigação legal.

5. COMPARTILHAMENTO
Dados podem ser processados por:
• Supabase (hospedagem de banco de dados e autenticação).
• Google (login com conta Google).
• Mercado Pago (pagamentos online).
• GitHub Pages (hospedagem da versão web pública).
Não vendemos dados pessoais. Compartilhamos apenas o necessário para operar o serviço ou quando exigido por lei.

6. ARMAZENAMENTO E SEGURANÇA
Adotamos medidas técnicas e organizacionais adequadas, incluindo autenticação, controle de acesso (RLS) e comunicação criptografada quando aplicável. Nenhum sistema é 100% seguro; em caso de incidente relevante, adotaremos medidas e comunicações conforme a LGPD.

7. RETENÇÃO
Mantemos os dados enquanto a conta estiver ativa ou enquanto necessário para as finalidades descritas, obrigações legais e exercício de direitos. Após exclusão solicitada, eliminaremos ou anonimizaremos dados, salvo retenção legal.

8. SEUS DIREITOS
Você pode solicitar: confirmação de tratamento; acesso; correção; anonimização, bloqueio ou eliminação; portabilidade; informação sobre compartilhamento; revogação de consentimento, quando cabível.
Pedidos: $developerEmail ou WhatsApp $professorTelefoneExibicao.

9. CRIANÇAS E ADOLESCENTES
Dados de menores são tratados no contexto da relação com a academia e com envolvimento dos responsáveis legais quando necessário.

10. COOKIES E ARMAZENAMENTO LOCAL
A versão web pode usar armazenamento local e service worker para funcionamento. Preferências como "lembrar senha" e alertas ficam no dispositivo via mecanismos seguros do sistema.

11. TRANSFERÊNCIA INTERNACIONAL
Provedores como Supabase e Google podem processar dados em servidores fora do Brasil, com salvaguardas contratuais e medidas de segurança compatíveis com a LGPD.

12. ALTERAÇÕES
Esta Política pode ser atualizada. A data da versão vigente será exibida no App.

13. CONTATO
$developerNome · $developerEmail · $developerUrl
''';

}
