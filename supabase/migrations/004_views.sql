-- =============================================================================
-- 004_views.sql — AutoBook MVP
-- Materialized view car_stats + refresh function (for cron / Edge Functions)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- MATERIALIZED VIEW: car_stats
-- -----------------------------------------------------------------------------

CREATE MATERIALIZED VIEW car_stats AS
SELECT
  c.id AS car_id,
  COALESCE(
    (SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date DESC, id DESC LIMIT 1),
    c.current_mileage,
    0
  )::INTEGER AS current_mileage,
  COALESCE(
    (SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date ASC, id ASC LIMIT 1),
    0
  ) AS first_mileage,
  COALESCE(
    (SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date DESC, id DESC LIMIT 1),
    c.current_mileage
  ) - COALESCE(
    (SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date ASC, id ASC LIMIT 1),
    0
  ) AS total_distance_km,
  (SELECT COALESCE(SUM(fl.liters), 0) FROM timeline_events te JOIN fuel_logs fl ON fl.timeline_event_id = te.id WHERE te.car_id = c.id) AS total_fuel_liters,
  (SELECT COALESCE(SUM(te.cost), 0) FROM timeline_events te JOIN fuel_logs fl ON fl.timeline_event_id = te.id WHERE te.car_id = c.id) AS total_fuel_cost,
  (SELECT COALESCE(SUM(te.cost), 0) FROM timeline_events te JOIN service_logs sl ON sl.timeline_event_id = te.id WHERE te.car_id = c.id) AS total_service_cost,
  (SELECT COALESCE(SUM(te.cost), 0) FROM timeline_events te JOIN documents d ON d.timeline_event_id = te.id WHERE te.car_id = c.id) AS total_document_cost,
  (SELECT COALESCE(SUM(te.cost), 0) FROM timeline_events te WHERE te.car_id = c.id) AS total_cost,
  CASE
    WHEN (SELECT COALESCE(SUM(fl.liters), 0) FROM timeline_events te JOIN fuel_logs fl ON fl.timeline_event_id = te.id WHERE te.car_id = c.id) > 0
     AND (
       COALESCE((SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date DESC, id DESC LIMIT 1), c.current_mileage) -
       COALESCE((SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date ASC, id ASC LIMIT 1), 0)
     ) > 0
    THEN (
      (SELECT SUM(fl.liters) FROM timeline_events te JOIN fuel_logs fl ON fl.timeline_event_id = te.id WHERE te.car_id = c.id) * 100.0
      / NULLIF(
        (SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date DESC, id DESC LIMIT 1) -
        (SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date ASC, id ASC LIMIT 1),
        1
      )
    )
    ELSE NULL
  END AS average_fuel_consumption,
  CASE
    WHEN (
      COALESCE((SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date DESC, id DESC LIMIT 1), c.current_mileage) -
      COALESCE((SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date ASC, id ASC LIMIT 1), 0)
    ) > 0
    THEN (
      (SELECT COALESCE(SUM(te.cost), 0) FROM timeline_events te WHERE te.car_id = c.id)
      / (
        (SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date DESC, id DESC LIMIT 1) -
        (SELECT mileage FROM mileage_logs ml WHERE ml.car_id = c.id ORDER BY date ASC, id ASC LIMIT 1)
      )
    )
    ELSE NULL
  END AS cost_per_km,
  now() AS last_updated_at
FROM cars c
WHERE c.deleted_at IS NULL;

CREATE UNIQUE INDEX idx_car_stats_car_id ON car_stats(car_id);

-- -----------------------------------------------------------------------------
-- Refresh function (call from cron / Edge Functions; no triggers)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION refresh_car_stats_safe()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY car_stats;
  EXCEPTION
    WHEN OTHERS THEN
      REFRESH MATERIALIZED VIEW car_stats;
  END;
END;
$$;
