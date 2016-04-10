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
-- calculate which "streak_group" each day falls into for each owner
streak_groups_by_day AS (
  -- if we subtract the date the Lumo Lift launched from the date of the activity, we get an integer
  -- each date that is in the same streak will have this same integer, plus the number of rows that date is within the streak
  -- so if we partition by the owner, and then order by the date, the row number within that partition can be used to calculate which "streak_group" each activity falls into
  SELECT owner, local_date, local_date - '2014-01-01'::date - row_number() OVER (PARTITION BY owner ORDER BY local_date) AS streak_group
  FROM positive_days
), 

-- calculate the length of each streak, grouped by user
streak_lengths_by_user AS (
  SELECT owner, streak_group, COUNT(streak_group) AS streak_length
  FROM streak_groups_by_day
  GROUP BY owner, streak_group
  HAVING COUNT(streak_group) > 1
  ORDER BY owner
)

-- finish by simply taking the count of streaks, and the max length of a streak

SELECT owner, COUNT(*) AS n_streaks, MAX(streak_length) AS longest_streak
FROM streak_lengths_by_user
GROUP BY owner;
