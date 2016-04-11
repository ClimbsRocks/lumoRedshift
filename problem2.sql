-- calculate the number of coach buzzes per user per day in December
WITH coach_buzzes AS (
  SELECT COUNT(*) AS buzzes, owner, DATE_TRUNC('day', act_time_local)::date AS local_date
  FROM activity_data
  WHERE act_type = 'C_CVBUZZ' AND extract(mon from act_time_local) = 12
  GROUP BY owner, local_date
), 
-- calculate good posture time per user per day in December
good_posture_time AS (
  -- calculate how much time a user spent in good posture, in 5 minute chunks
  WITH good_posture_chunks AS (
    SELECT SUM(act_value) / 100 * 5 AS good_posture_time, act_time_local, owner
    FROM activity_data
    WHERE act_type IN ('SG','STG','CG') AND extract(mon from act_time_local) = 12
    GROUP BY act_time_local, owner
  )

  -- now aggregate up to the day level for each user
  SELECT SUM(good_posture_time) AS good_posture_time, owner, DATE_TRUNC('day', act_time_local)::date AS local_date
  FROM good_posture_chunks
  GROUP BY owner, local_date
)

-- obviously, Redshift doesn't support corr. The next iteration of developing this query would be to go through and calculate the correlation manually. Obviously it would be quicker to copy/paste the data into a quick postgres table and calculate the correlation from there as a one-off, but I prefer writing reproducible/maintainable code over one-offs. 
SELECT corr(coach_buzzes.buzzes, good_posture_time.good_posture_time), good_posture_time.owner, good_posture_time.local_date
FROM good_posture_time
INNER JOIN coach_buzzes ON good_posture_time.owner = coach_buzzes.owner AND good_posture_time.local_date = coach_buzzes.local_date
LIMIT 100000;
