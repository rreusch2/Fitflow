-- Create function to get nutrition summary for a date range
CREATE OR REPLACE FUNCTION get_nutrition_summary(
  user_id_param UUID,
  start_date_param DATE,
  end_date_param DATE
)
RETURNS JSON AS $$
DECLARE
  summary JSON;
BEGIN
  WITH meal_totals AS (
    SELECT 
      COALESCE(SUM((totals->>'calories')::NUMERIC), 0) as total_calories,
      COALESCE(SUM((totals->>'protein')::NUMERIC), 0) as total_protein,
      COALESCE(SUM((totals->>'carbs')::NUMERIC), 0) as total_carbs,
      COALESCE(SUM((totals->>'fat')::NUMERIC), 0) as total_fat,
      COALESCE(SUM((totals->>'fiber')::NUMERIC), 0) as total_fiber,
      COALESCE(SUM((totals->>'sugar')::NUMERIC), 0) as total_sugar,
      COALESCE(SUM((totals->>'sodium')::NUMERIC), 0) as total_sodium,
      COUNT(*) as meals_logged,
      MAX(logged_at) as last_updated
    FROM meal_logs 
    WHERE user_id = user_id_param 
      AND logged_date_utc BETWEEN start_date_param AND end_date_param
  )
  SELECT json_build_object(
    'calories', COALESCE(total_calories, 0),
    'protein', COALESCE(total_protein, 0),
    'carbs', COALESCE(total_carbs, 0),
    'fat', COALESCE(total_fat, 0),
    'fiber', COALESCE(total_fiber, 0),
    'sugar', COALESCE(total_sugar, 0),
    'sodium', COALESCE(total_sodium, 0),
    'meals_logged', COALESCE(meals_logged, 0),
    'last_updated', COALESCE(last_updated, NOW())::TEXT
  ) INTO summary
  FROM meal_totals;
  
  RETURN summary;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_nutrition_summary(UUID, DATE, DATE) TO authenticated;

-- Create function to get nutrition goals with defaults
CREATE OR REPLACE FUNCTION get_or_create_nutrition_goals(user_id_param UUID)
RETURNS JSON AS $$
DECLARE
  goals JSON;
  user_health JSON;
  calculated_calories INTEGER;
BEGIN
  -- First try to get existing goals
  SELECT row_to_json(ng.*) INTO goals
  FROM nutrition_goals ng
  WHERE ng.user_id = user_id_param;
  
  -- If no goals exist, create defaults based on health profile
  IF goals IS NULL THEN
    -- Get user health profile for calculations
    SELECT row_to_json(hp.*) INTO user_health
    FROM health_profile hp
    WHERE hp.user_id = user_id_param;
    
    -- Calculate basic TDEE (simplified)
    calculated_calories := CASE 
      WHEN (user_health->>'sex') = 'male' THEN 2200
      WHEN (user_health->>'sex') = 'female' THEN 1800
      ELSE 2000
    END;
    
    -- Insert default goals
    INSERT INTO nutrition_goals (
      user_id,
      target_calories,
      target_macros,
      diet_preferences,
      exclusions,
      opt_in_daily_ai,
      preferred_timezone
    ) VALUES (
      user_id_param,
      calculated_calories,
      json_build_object(
        'protein', calculated_calories * 0.3 / 4,
        'carbs', calculated_calories * 0.4 / 4,
        'fat', calculated_calories * 0.3 / 9
      ),
      '{}',
      '[]',
      true,
      'UTC'
    ) RETURNING row_to_json(nutrition_goals.*) INTO goals;
  END IF;
  
  RETURN goals;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_or_create_nutrition_goals(UUID) TO authenticated;

-- Create function to log meals with automatic totals calculation
CREATE OR REPLACE FUNCTION log_meal_with_totals(
  user_id_param UUID,
  meal_type_param TEXT,
  items_param JSONB,
  source_param TEXT DEFAULT 'manual',
  notes_param TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  meal_id UUID := gen_random_uuid();
  calculated_totals JSONB;
  item JSONB;
  total_calories NUMERIC := 0;
  total_protein NUMERIC := 0;
  total_carbs NUMERIC := 0;
  total_fat NUMERIC := 0;
  total_fiber NUMERIC := 0;
BEGIN
  -- Calculate totals from items
  FOR item IN SELECT * FROM jsonb_array_elements(items_param)
  LOOP
    total_calories := total_calories + COALESCE((item->>'calories')::NUMERIC, 0);
    total_protein := total_protein + COALESCE((item->'macros'->>'protein')::NUMERIC, 0);
    total_carbs := total_carbs + COALESCE((item->'macros'->>'carbs')::NUMERIC, 0);
    total_fat := total_fat + COALESCE((item->'macros'->>'fat')::NUMERIC, 0);
    total_fiber := total_fiber + COALESCE((item->'macros'->>'fiber')::NUMERIC, 0);
  END LOOP;
  
  calculated_totals := json_build_object(
    'calories', total_calories,
    'protein', total_protein,
    'carbs', total_carbs,
    'fat', total_fat,
    'fiber', total_fiber
  );
  
  -- Insert meal log
  INSERT INTO meal_logs (
    id,
    user_id,
    logged_at,
    meal_type,
    items,
    totals,
    source,
    notes,
    logged_date_utc
  ) VALUES (
    meal_id,
    user_id_param,
    NOW(),
    meal_type_param,
    items_param,
    calculated_totals,
    source_param,
    notes_param,
    CURRENT_DATE
  );
  
  RETURN meal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION log_meal_with_totals(UUID, TEXT, JSONB, TEXT, TEXT) TO authenticated;

-- Create index for better performance on meal log queries
CREATE INDEX IF NOT EXISTS idx_meal_logs_user_date 
ON meal_logs(user_id, logged_date_utc DESC);

CREATE INDEX IF NOT EXISTS idx_meal_logs_user_logged_at 
ON meal_logs(user_id, logged_at DESC);

-- Create function to search food items with ranking
CREATE OR REPLACE FUNCTION search_food_items(
  user_id_param UUID,
  search_query TEXT,
  limit_param INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  brand TEXT,
  serving TEXT,
  calories INTEGER,
  macros JSONB,
  tags TEXT[],
  is_public BOOLEAN,
  source TEXT,
  relevance_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    fi.id,
    fi.name,
    fi.brand,
    fi.serving,
    fi.calories,
    fi.macros,
    fi.tags,
    fi.is_public,
    fi.source,
    -- Simple relevance scoring
    CASE 
      WHEN fi.name ILIKE search_query || '%' THEN 1.0
      WHEN fi.name ILIKE '%' || search_query || '%' THEN 0.8
      WHEN fi.brand ILIKE '%' || search_query || '%' THEN 0.6
      ELSE 0.4
    END as relevance_score
  FROM food_items fi
  WHERE (
    fi.name ILIKE '%' || search_query || '%' 
    OR fi.brand ILIKE '%' || search_query || '%'
    OR search_query = ANY(fi.tags)
  )
  AND (fi.user_id = user_id_param OR fi.is_public = true)
  ORDER BY relevance_score DESC, fi.name
  LIMIT limit_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION search_food_items(UUID, TEXT, INTEGER) TO authenticated;
