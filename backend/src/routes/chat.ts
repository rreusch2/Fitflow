import { FastifyInstance } from 'fastify';
import { CreateChatMessageSchema, CreateChatSessionSchema } from '../schemas/chat';
import { AIService } from '../services/ai';
import { randomUUID } from 'crypto';
import { zodToJsonSchema } from 'zod-to-json-schema';

export async function chatRoutes(server: FastifyInstance) {
  const aiService = new AIService();

  // Create new chat session
  server.post('/sessions', {
    schema: {
      body: zodToJsonSchema(CreateChatSessionSchema)
    }
  }, async (request, reply) => {
    const userId = request.user!.id;
    const { title } = request.body;

    const sessionId = randomUUID();
    const now = new Date().toISOString();

    const { data: session, error } = await server.supabase
      .from('chat_sessions')
      .insert({
        id: sessionId,
        user_id: userId,
        title: title || 'New Chat',
        created_at: now,
        updated_at: now,
        last_message_at: now
      })
      .select()
      .single();

    if (error) {
      server.log.error('Error creating chat session:', error);
      return reply.code(500).send({ error: 'Failed to create chat session' });
    }

    return { session };
  });

  // Get chat sessions for user
  server.get('/sessions', async (request, reply) => {
    const userId = request.user!.id;

    const { data: sessions, error } = await server.supabase
      .from('chat_sessions')
      .select('*')
      .eq('user_id', userId)
      .order('last_message_at', { ascending: false });

    if (error) {
      server.log.error('Error fetching chat sessions:', error);
      return reply.code(500).send({ error: 'Failed to fetch chat sessions' });
    }

    return { sessions: sessions || [] };
  });

  // Get specific chat session with messages
  server.get('/sessions/:sessionId', async (request, reply) => {
    const userId = request.user!.id;
    const { sessionId } = request.params as { sessionId: string };

    // Get session
    const { data: session, error: sessionError } = await server.supabase
      .from('chat_sessions')
      .select('*')
      .eq('id', sessionId)
      .eq('user_id', userId)
      .single();

    if (sessionError) {
      server.log.error('Error fetching chat session:', sessionError);
      return reply.code(404).send({ error: 'Chat session not found' });
    }

    // Get messages
    const { data: messages, error: messagesError } = await server.supabase
      .from('chat_messages')
      .select('*')
      .eq('session_id', sessionId)
      .order('created_at', { ascending: true });

    if (messagesError) {
      server.log.error('Error fetching chat messages:', messagesError);
      return reply.code(500).send({ error: 'Failed to fetch messages' });
    }

    return {
      session: {
        ...session,
        messages: messages || []
      }
    };
  });

  // Send message to chat session (supports SSE streaming)
  server.post('/sessions/:sessionId/messages', {
    schema: {
      body: zodToJsonSchema(CreateChatMessageSchema)
    }
  }, async (request, reply) => {
    const userId = request.user!.id;
    const { sessionId } = request.params as { sessionId: string };
    const { content } = request.body;

    // Verify session belongs to user
    const { data: session, error: sessionError } = await server.supabase
      .from('chat_sessions')
      .select('id')
      .eq('id', sessionId)
      .eq('user_id', userId)
      .single();

    if (sessionError || !session) {
      return reply.code(404).send({ error: 'Chat session not found' });
    }

    // Check if client wants SSE streaming
    const acceptHeader = request.headers.accept;
    const wantsStream = acceptHeader?.includes('text/event-stream');

    try {
      // Save user message
      const userMessageId = randomUUID();
      await server.supabase
        .from('chat_messages')
        .insert({
          id: userMessageId,
          session_id: sessionId,
          role: 'user',
          content,
          created_at: new Date().toISOString()
        });

      if (wantsStream) {
        // Set up SSE streaming
        reply.raw.writeHead(200, {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Cache-Control'
        });

        // Get user context for AI
        const { data: preferences } = await server.supabase
          .from('user_preferences')
          .select('*')
          .eq('user_id', userId)
          .single();

        // Stream AI response
        const aiResponse = await aiService.streamChatCompletion({
          sessionId,
          userId,
          message: content,
          preferences: preferences || {},
          onToken: (token: string) => {
            reply.raw.write(`data: ${JSON.stringify({ delta: token })}\n\n`);
          }
        });

        // Save AI response
        const assistantMessageId = randomUUID();
        await server.supabase
          .from('chat_messages')
          .insert({
            id: assistantMessageId,
            session_id: sessionId,
            role: 'assistant',
            content: aiResponse.content,
            tokens_in: aiResponse.tokensIn,
            tokens_out: aiResponse.tokensOut,
            provider: aiResponse.provider,
            created_at: new Date().toISOString()
          });

        // Update session timestamp
        await server.supabase
          .from('chat_sessions')
          .update({ 
            last_message_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('id', sessionId);

        // Send final message
        reply.raw.write(`data: ${JSON.stringify({ 
          done: true, 
          message: {
            id: assistantMessageId,
            role: 'assistant',
            content: aiResponse.content,
            created_at: new Date().toISOString()
          }
        })}\n\n`);

        reply.raw.end();
      } else {
        // Regular JSON response
        const { data: preferences } = await server.supabase
          .from('user_preferences')
          .select('*')
          .eq('user_id', userId)
          .single();

        const aiResponse = await aiService.chatCompletion({
          sessionId,
          userId,
          message: content,
          preferences: preferences || {}
        });

        // Save AI response
        const assistantMessageId = randomUUID();
        const { data: message, error } = await server.supabase
          .from('chat_messages')
          .insert({
            id: assistantMessageId,
            session_id: sessionId,
            role: 'assistant',
            content: aiResponse.content,
            tokens_in: aiResponse.tokensIn,
            tokens_out: aiResponse.tokensOut,
            provider: aiResponse.provider,
            created_at: new Date().toISOString()
          })
          .select()
          .single();

        if (error) {
          server.log.error('Error saving assistant message:', error);
          return reply.code(500).send({ error: 'Failed to save message' });
        }

        // Update session timestamp
        await server.supabase
          .from('chat_sessions')
          .update({ 
            last_message_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('id', sessionId);

        return { message };
      }
    } catch (error) {
      server.log.error('Error in chat completion:', error);
      return reply.code(500).send({ error: 'Failed to process message' });
    }
  });
}
