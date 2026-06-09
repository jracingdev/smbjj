import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  // MP envia GET para verificar o endpoint durante o cadastro
  if (req.method === 'GET') {
    return new Response('OK', { status: 200 })
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const body = await req.json()

    // MP notifica vários tipos de evento — só nos interessa payment
    const topic = body?.topic ?? body?.type
    const paymentId = body?.data?.id ?? body?.id

    if (topic !== 'payment' || !paymentId) {
      return new Response('Ignored', { status: 200 })
    }

    const db = createClient(supabaseUrl, serviceRoleKey)

    // Busca o token MP salvo no banco
    const { data: cfg } = await db
      .from('financeiro_config')
      .select('mp_access_token')
      .eq('id', 1)
      .single()

    const mpToken = cfg?.mp_access_token
    if (!mpToken) {
      return new Response('MP token not configured', { status: 200 })
    }

    // Consulta os detalhes do pagamento na API do MP
    const mpRes = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
      headers: { Authorization: `Bearer ${mpToken}` },
    })

    if (!mpRes.ok) {
      return new Response('MP API error', { status: 200 })
    }

    const payment = await mpRes.json()
    const status = payment?.status
    const preferenciaId = payment?.preference_id

    if (status !== 'approved' || !preferenciaId) {
      return new Response('Not approved', { status: 200 })
    }

    // Busca a mensalidade com esse preference_id
    const { data: mensalidade } = await db
      .from('mensalidades')
      .select('id, status')
      .eq('mp_preferencia_id', preferenciaId)
      .eq('status', 'pendente')
      .maybeSingle()

    if (!mensalidade) {
      return new Response('Mensalidade not found or already paid', { status: 200 })
    }

    // Marca como paga
    const hoje = new Date().toISOString().split('T')[0]
    await db.from('mensalidades').update({
      status: 'pago',
      data_pagamento: hoje,
      updated_at: new Date().toISOString(),
    }).eq('id', mensalidade.id)

    console.log(`✅ Mensalidade ${mensalidade.id} marcada como paga via webhook MP (payment ${paymentId})`)

    return new Response('OK', { status: 200 })
  } catch (err) {
    console.error('Webhook error:', err)
    return new Response('Internal error', { status: 500 })
  }
})
