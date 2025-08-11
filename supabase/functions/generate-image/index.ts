// Supabase Edge Function: POST /functions/v1/generate-image
// Body: { topic: string, vibe: string }
// Returns: { imageUrl: string }

import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

type Input = { topic?: string; vibe?: string }

export default Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  try {
    const { topic = 'mindset', vibe = 'calm' } = (await req.json()) as Input
    const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')
    if (!OPENAI_API_KEY) {
      return new Response(JSON.stringify({ error: 'Missing OPENAI_API_KEY' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    const prompt = `Cinematic abstract background for ${topic}, ${vibe} vibe, subtle gradients, depth, NO text, high detail, 1024x1024`

    const resp = await fetch('https://api.openai.com/v1/images/generations', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-image-1',
        prompt,
        size: '1024x1024',
        quality: 'high',
      }),
    })

    if (!resp.ok) {
      const errText = await resp.text()
      return new Response(JSON.stringify({ error: errText }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    const data = await resp.json()
    const url = data?.data?.[0]?.url
    if (!url) {
      return new Response(JSON.stringify({ error: 'No image URL in response' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    return new Response(JSON.stringify({ imageUrl: url }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})


