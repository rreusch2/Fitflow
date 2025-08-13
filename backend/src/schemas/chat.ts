import { z } from 'zod';

export const CreateChatSessionSchema = z.object({
  title: z.string().optional()
});

export const CreateChatMessageSchema = z.object({
  content: z.string().min(1).max(10000)
});

export const ChatMessageSchema = z.object({
  id: z.string().uuid(),
  session_id: z.string().uuid(),
  role: z.enum(['user', 'assistant']),
  content: z.string(),
  tokens_in: z.number().optional(),
  tokens_out: z.number().optional(),
  provider: z.string().optional(),
  created_at: z.string().datetime()
});

export const ChatSessionSchema = z.object({
  id: z.string().uuid(),
  user_id: z.string().uuid(),
  title: z.string(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
  last_message_at: z.string().datetime(),
  messages: z.array(ChatMessageSchema).optional()
});
