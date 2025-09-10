import { FastifyInstance } from 'fastify';

export async function fitnessRoutes(server: FastifyInstance) {
  
  // Log a completed workout session
  server.post('/workout-sessions', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const {
      workout_type,
      duration_minutes,
      exercises_completed,
      muscle_groups,
      notes
    } = request.body as any;

    try {
      const { data: session, error } = await server.supabase
        .from('workout_sessions')
        .insert({
          user_id: userId,
          workout_type: workout_type || 'manual',
          duration_minutes: duration_minutes,
          exercises_completed: exercises_completed || [],
          muscle_groups: muscle_groups || [],
          notes: notes,
          completed_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) {
        server.log.error({ err: error }, 'Error logging workout session');
        return reply.code(500).send({ error: 'Failed to log workout session' });
      }

      return reply.send({ session });
    } catch (error) {
      server.log.error({ err: error }, 'Error logging workout session');
      return reply.code(500).send({ error: 'Failed to log workout session' });
    }
  });

  // Get recent workout sessions
  server.get('/workout-sessions', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    try {
      const { data: sessions, error } = await server.supabase
        .from('workout_sessions')
        .select('*')
        .eq('user_id', userId)
        .order('completed_at', { ascending: false })
        .limit(50);

      if (error) {
        server.log.error({ err: error }, 'Error fetching workout sessions');
        return reply.code(500).send({ error: 'Failed to fetch workout sessions' });
      }

      return reply.send({ sessions: sessions || [] });
    } catch (error) {
      server.log.error({ err: error }, 'Error fetching workout sessions');
      return reply.code(500).send({ error: 'Failed to fetch workout sessions' });
    }
  });

  // Get weekly stats and progress metrics
  server.get('/weekly-stats', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    try {
      // Get sessions from last 7 days
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);

      const { data: recentSessions, error: sessionsError } = await server.supabase
        .from('workout_sessions')
        .select('*')
        .eq('user_id', userId)
        .gte('completed_at', weekAgo.toISOString());

      if (sessionsError) {
        server.log.error({ err: sessionsError }, 'Error fetching recent sessions');
        return reply.code(500).send({ error: 'Failed to fetch progress data' });
      }

      // Calculate weekly stats
      const sessions = recentSessions || [];
      const totalTime = sessions.reduce((sum, s) => sum + (s.duration_minutes || 0), 0);
      const avgDuration = sessions.length > 0 ? Math.round(totalTime / sessions.length) : 0;
      
      // Find most common muscle groups
      const muscleGroupCounts: Record<string, number> = {};
      sessions.forEach(session => {
        (session.muscle_groups || []).forEach((group: string) => {
          muscleGroupCounts[group] = (muscleGroupCounts[group] || 0) + 1;
        });
      });
      
      const favoritesMuscleGroups = Object.entries(muscleGroupCounts)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 3)
        .map(([group]) => group);

      // Calculate current streak (consecutive days with workouts)
      const { data: allSessions, error: allSessionsError } = await server.supabase
        .from('workout_sessions')
        .select('completed_at')
        .eq('user_id', userId)
        .order('completed_at', { ascending: false });

      let currentStreak = 0;
      if (!allSessionsError && allSessions) {
        const sessionDates = new Set(
          allSessions.map(s => new Date(s.completed_at).toDateString())
        );
        
        let checkDate = new Date();
        while (sessionDates.has(checkDate.toDateString())) {
          currentStreak++;
          checkDate.setDate(checkDate.getDate() - 1);
        }
      }

      const weeklyStats = {
        workouts_completed: sessions.length,
        total_time_minutes: totalTime,
        average_duration: avgDuration,
        favorites_muscle_groups: favoritesMuscleGroups
      };

      return reply.send({
        weekly_stats: weeklyStats,
        current_streak: currentStreak
      });
    } catch (error) {
      server.log.error({ err: error }, 'Error calculating weekly stats');
      return reply.code(500).send({ error: 'Failed to calculate progress stats' });
    }
  });
}
