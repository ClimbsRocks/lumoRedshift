-- calculate all the days that count in a streak for a user
WITH positive_days AS (
  -- chunks of time with good posture
  WITH good_posture_chunks AS (
    SELECT SUM(act_value) / 100 * 5 AS good_posture_time, owner, act_time_local
    FROM activity_data
    WHERE act_type IN ('SG','STG','CG') AND act_time_local >= '2015-11-15' AND act_time_local < '2015-12-15'
    GROUP BY owner, act_time_local
  ),

  -- chunks of time with associated step counts
  step_count_chunks AS (
    SELECT act_value AS steps, owner, act_time_local
    FROM activity_data
    WHERE act_type = 'C_STEPS' AND act_time_local >= '2015-11-15' AND act_time_local < '2015-12-15' 
  )
  

  SELECT DATE_TRUNC('day', coalesce(good_posture_chunks.act_time_local, step_count_chunks.act_time_local))::date AS local_date, COALESCE(good_posture_chunks.owner, step_count_chunks.owner) AS owner, TRUE AS counts_for_streak
  FROM good_posture_chunks
  FULL OUTER JOIN step_count_chunks 
    ON good_posture_chunks.owner = step_count_chunks.owner 
    AND good_posture_chunks.act_time_local = step_count_chunks.act_time_local 
  GROUP BY local_date, COALESCE(good_posture_chunks.owner, step_count_chunks.owner)
  HAVING SUM(step_count_chunks.steps) >= 500 OR SUM(good_posture_chunks.good_posture_time) >= 30
  ORDER BY owner, local_date
), 













