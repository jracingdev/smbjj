// ============================================================
// CT SM BJJ — Constantes do App
// ============================================================

const String appVersion = '1.3.9';
const String appBuild = '24';
const String appName = 'CT SM BJJ';

// Academia
const String academiaFundacao = '2018';
const String academiaCredenciada = 'ACADEMIA CREDENCIADA GF TEAM';
const String academiaCredencial = 'CREDENCIADA 229';
const String professorNome = 'SANDRO DE OLIVEIRA MORAES';
const String professorGraduacao = 'FAIXA PRETA 2° GRAUS';
const String professorRegistro = 'CBJJ/IBJJF 144559';
const String professorTelefone = '5521975396996'; // WhatsApp (código país + DDD + número)

// Pagamento
const String pixKey = 'sandroiraja@gmail.com';
const String pixNome = 'Sandro Iraja';

/// Google Sign-In nativo (Android/iOS). Mesmo Client ID do Supabase → Auth → Google.
/// Build: --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
const String googleWebClientIdEnv = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '276798866114-q4s5b17hfk4ftsu3ag5hht2gu9f273r6.apps.googleusercontent.com',
);

// Desenvolvedor
const String developerNome = 'JRacing Dev';
const String developerUrl = 'https://jracing.dev.br';
const String developerEmail = 'contato@jracing.dev.br';
