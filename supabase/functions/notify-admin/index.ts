// Edge Function: envia push FCM (HTTP v1) para todos os admins.
// Triggers: Database Webhooks em INSERT de public.alunos / public.pedidos
// Secrets: FIREBASE_SERVICE_ACCOUNT (JSON da service account)
// Opcional: FCM_WEBHOOK_SECRET (se definido, exige header x-webhook-secret)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as jose from 'https://esm.sh/jose@5.2.0'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = (Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '').trim()
const webhookSecret = (Deno.env.get('FCM_WEBHOOK_SECRET') ?? '').trim()
const saRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? ''

type ServiceAccount = {
  project_id: string
  client_email: string
  private_key: string
}

type PushPayload = {
  tipo: 'aluno' | 'pedido' | 'teste'
  titulo: string
  mensagem: string
}

let cachedToken: { value: string; exp: number } | null = null

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

/** Chaves privilegiadas aceitas (legacy service_role + novos sb_secret_*). */
function acceptedServiceKeys(): string[] {
  const keys = new Set<string>()
  if (serviceRoleKey) keys.add(serviceRoleKey)
  try {
    const raw = Deno.env.get('SUPABASE_SECRET_KEYS') ?? ''
    if (raw) {
      const parsed = JSON.parse(raw) as Record<string, unknown>
      for (const v of Object.values(parsed)) {
        if (typeof v === 'string' && v.trim()) keys.add(v.trim())
      }
    }
  } catch {
    // ignore JSON invalido
  }
  return [...keys]
}

function extractBearer(req: Request): string {
  const auth = (req.headers.get('Authorization') ?? '').trim()
  const m = /^Bearer\s+(.+)$/i.exec(auth)
  return (m?.[1] ?? '').trim()
}

function authorized(req: Request): boolean {
  const accepted = acceptedServiceKeys()
  const bearer = extractBearer(req)
  if (bearer && accepted.includes(bearer)) return true

  // Database Webhooks / smoke test tambem podem mandar a chave em apikey.
  const apikey = (req.headers.get('apikey') ?? '').trim()
  if (apikey && accepted.includes(apikey)) return true

  if (webhookSecret) {
    const h = (req.headers.get('x-webhook-secret') ?? '').trim()
    if (h && h === webhookSecret) return true
  }
  return false
}

function authDebug(req: Request) {
  const accepted = acceptedServiceKeys()
  const bearer = extractBearer(req)
  const apikey = (req.headers.get('apikey') ?? '').trim()
  return {
    hasAuthorization: Boolean((req.headers.get('Authorization') ?? '').trim()),
    hasApikey: Boolean(apikey),
    hasWebhookSecretHeader: Boolean((req.headers.get('x-webhook-secret') ?? '').trim()),
    serviceKeysConfigured: accepted.length,
    bearerLen: bearer.length,
    apikeyLen: apikey.length,
    bearerMatch: Boolean(bearer && accepted.includes(bearer)),
    apikeyMatch: Boolean(apikey && accepted.includes(apikey)),
  }
}

function parseWebhookOrManual(body: Record<string, unknown>): PushPayload | null {
  // Invoke manual / teste
  if (typeof body.tipo === 'string' && (body.titulo || body.mensagem)) {
    return {
      tipo: (body.tipo as PushPayload['tipo']) || 'teste',
      titulo: String(body.titulo ?? 'CT SM BJJ'),
      mensagem: String(body.mensagem ?? body.body ?? ''),
    }
  }

  // Formato Database Webhook Supabase
  const table = String(body.table ?? '')
  const type = String(body.type ?? body.eventType ?? '')
  const record = (body.record ?? body.new ?? {}) as Record<string, unknown>
  if (type && type.toUpperCase() !== 'INSERT') return null

  if (table === 'alunos') {
    const nome = String(record.nome ?? 'Aluno')
    const primeiro = nome.trim().split(/\s+/)[0] || nome
    return {
      tipo: 'aluno',
      titulo: 'Novo cadastro de aluno',
      mensagem: `${primeiro} aguarda validação.`,
    }
  }

  if (table === 'pedidos') {
    const aluno = String(record.aluno_nome ?? 'Cliente')
    const produto = String(record.produto_nome ?? 'produto')
    return {
      tipo: 'pedido',
      titulo: 'Nova venda na loja',
      mensagem: `${aluno} pediu ${produto}.`,
    }
  }

  return null
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  if (cachedToken && cachedToken.exp > now + 60) return cachedToken.value

  const pk = sa.private_key.replace(/\\n/g, '\n')
  const privateKey = await jose.importPKCS8(pk, 'RS256')
  const jwt = await new jose.SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(privateKey)

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  const data = await res.json()
  if (!data.access_token) {
    throw new Error(`OAuth FCM falhou: ${JSON.stringify(data)}`)
  }
  cachedToken = { value: data.access_token as string, exp: now + 3500 }
  return cachedToken.value
}

async function sendFcm(
  sa: ServiceAccount,
  accessToken: string,
  deviceToken: string,
  push: PushPayload,
): Promise<{ ok: boolean; status: number; body: string }> {
  const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`
  const message = {
    message: {
      token: deviceToken,
      notification: {
        title: push.titulo,
        body: push.mensagem,
      },
      data: {
        tipo: push.tipo,
        titulo: push.titulo,
        mensagem: push.mensagem,
      },
      android: {
        priority: 'HIGH',
        notification: {
          channel_id: 'smbjj_admin_alerts',
          sound: 'default',
          icon: 'ic_stat_smbjj',
          notification_priority: 'PRIORITY_MAX',
          default_vibrate_timings: true,
        },
      },
    },
  }

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(message),
  })
  const text = await res.text()
  return { ok: res.ok, status: res.status, body: text }
}

serve(async (req) => {
  if (req.method === 'GET') {
    return json({ ok: true, service: 'notify-admin' })
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  if (!authorized(req)) {
    console.error('notify-admin 401', authDebug(req))
    return json({
      error: 'Unauthorized',
      hint: 'Envie Authorization: Bearer <service_role|sb_secret> (ou apikey / x-webhook-secret)',
      debug: authDebug(req),
    }, 401)
  }

  if (!saRaw) {
    return json({
      error: 'FIREBASE_SERVICE_ACCOUNT secret não configurado',
      hint: 'Veja FCM_SETUP.md',
    }, 500)
  }

  let sa: ServiceAccount
  try {
    sa = JSON.parse(saRaw) as ServiceAccount
    if (!sa.project_id || !sa.client_email || !sa.private_key) {
      throw new Error('JSON incompleto')
    }
  } catch (e) {
    return json({ error: `FIREBASE_SERVICE_ACCOUNT inválido: ${e}` }, 500)
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: 'JSON inválido' }, 400)
  }

  const push = parseWebhookOrManual(body)
  if (!push) {
    return json({ ok: true, ignored: true, reason: 'evento não mapeado' })
  }

  const adminKey = serviceRoleKey || acceptedServiceKeys()[0]
  if (!adminKey) {
    return json({ error: 'Nenhuma service key no runtime da function' }, 500)
  }
  const db = createClient(supabaseUrl, adminKey)
  const { data: tokens, error } = await db
    .from('admin_fcm_tokens')
    .select('id, token, user_id, usuarios!inner(role)')
    .eq('usuarios.role', 'admin')

  // Fallback se o join filter falhar em algumas versões do PostgREST
  let list: { id: string; token: string }[] = []
  if (error || !tokens) {
    console.warn('join tokens falhou, fallback:', error?.message)
    const { data: admins } = await db.from('usuarios').select('id').eq('role', 'admin')
    const adminIds = (admins ?? []).map((a: { id: string }) => a.id)
    if (adminIds.length === 0) {
      return json({ ok: true, sent: 0, reason: 'nenhum admin' })
    }
    const { data: rows } = await db
      .from('admin_fcm_tokens')
      .select('id, token')
      .in('user_id', adminIds)
    list = rows ?? []
  } else {
    list = tokens.map((t: { id: string; token: string }) => ({ id: t.id, token: t.token }))
  }

  if (list.length === 0) {
    return json({ ok: true, sent: 0, reason: 'nenhum token FCM' })
  }

  let accessToken: string
  try {
    accessToken = await getAccessToken(sa)
  } catch (e) {
    return json({ error: `OAuth: ${e}` }, 500)
  }

  let sent = 0
  const errors: string[] = []
  for (const row of list) {
    try {
      const result = await sendFcm(sa, accessToken, row.token, push)
      if (result.ok) {
        sent++
      } else {
        errors.push(`${result.status}: ${result.body.slice(0, 200)}`)
        // Token inválido / desinstalado → limpa
        if (result.status === 404 || result.body.includes('UNREGISTERED') || result.body.includes('INVALID_ARGUMENT')) {
          await db.from('admin_fcm_tokens').delete().eq('id', row.id)
        }
      }
    } catch (e) {
      errors.push(String(e))
    }
  }

  console.log(`notify-admin ${push.tipo}: sent=${sent}/${list.length}`)
  return json({ ok: true, tipo: push.tipo, sent, total: list.length, errors: errors.slice(0, 5) })
})
