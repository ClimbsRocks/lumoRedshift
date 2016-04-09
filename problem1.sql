WITH mau AS (
  SELECT COUNT(DISTINCT(owner)) AS mau
  FROM activity_data
  WHERE extract(month from act_time_local) = 10
)
SELECT DATE_TRUNC('day', act_time_local) AS local_date, COUNT(DISTINCT(owner)) AS dau, mau.mau
FROM activity_data, mau
WHERE extract(month from act_time_local) = 10
GROUP BY local_date, mau.mau
ORDER BY local_date;
