-- =============================================================================
-- 002_triggers.sql — AutoBook MVP
-- All functions and triggers only (no views; car_stats lives in 004_views.sql)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Constraint: mileage must not decrease per car
-- -----------------------------------------------------------------------------

-- Mileage is globally monotonic per car: new value cannot be less than any existing one (no date-based logic).
CREATE OR REPLACE FUNCTION check_mileage_not_decrease()
RETURNS TRIGGER AS $$
DECLARE
  prev_mileage INTEGER;
BEGIN
  SELECT MAX(mileage) INTO prev_mileage
  FROM mileage_logs
  WHERE car_id = NEW.car_id
    AND id IS DISTINCT FROM NEW.id;
  IF prev_mileage IS NOT NULL AND NEW.mileage < prev_mileage THEN
    RAISE EXCEPTION 'Mileage cannot decrease: car % had % km, new value % is lower', NEW.car_id, prev_mileage, NEW.mileage;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_mileage_not_decrease
  BEFORE INSERT OR UPDATE ON mileage_logs
  FOR EACH ROW EXECUTE FUNCTION check_mileage_not_decrease();

-- On timeline_events INSERT → insert into mileage_logs
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sync_mileage_log_on_timeline_event()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO mileage_logs (car_id, timeline_event_id, mileage, date, source)
  VALUES (NEW.car_id, NEW.id, NEW.mileage, NEW.event_date, 'timeline_event');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_timeline_event_mileage_sync
  AFTER INSERT ON timeline_events
  FOR EACH ROW EXECUTE FUNCTION sync_mileage_log_on_timeline_event();

-- Keep mileage_logs in sync when timeline_events are updated (mileage / event_date) or deleted.

CREATE OR REPLACE FUNCTION sync_mileage_log_on_timeline_event_update()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE mileage_logs
  SET mileage = NEW.mileage,
      date = NEW.event_date
  WHERE timeline_event_id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_timeline_event_update_mileage_sync
  AFTER UPDATE OF mileage, event_date ON timeline_events
  FOR EACH ROW EXECUTE FUNCTION sync_mileage_log_on_timeline_event_update();

CREATE OR REPLACE FUNCTION sync_mileage_log_on_timeline_event_delete()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM mileage_logs
  WHERE timeline_event_id = OLD.id;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_timeline_event_delete_mileage_sync
  AFTER DELETE ON timeline_events
  FOR EACH ROW EXECUTE FUNCTION sync_mileage_log_on_timeline_event_delete();

-- -----------------------------------------------------------------------------
-- Update car current_mileage from MAX(mileage_logs.mileage) — single source of truth.
-- Recalc on any insert/update/delete in mileage_logs so edits (e.g. lower mileage) are reflected.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_car_current_mileage()
RETURNS TRIGGER AS $$
DECLARE
  v_car_id UUID;
  v_max_mileage INTEGER;
BEGIN
  v_car_id := COALESCE(NEW.car_id, OLD.car_id);
  SELECT MAX(mileage) INTO v_max_mileage
  FROM mileage_logs
  WHERE car_id = v_car_id;
  UPDATE cars
  SET current_mileage = COALESCE(v_max_mileage, 0), updated_at = now()
  WHERE id = v_car_id;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_mileage_log_update_car_mileage
  AFTER INSERT OR UPDATE OF mileage ON mileage_logs
  FOR EACH ROW EXECUTE FUNCTION update_car_current_mileage();

CREATE TRIGGER trigger_mileage_log_delete_update_car_mileage
  AFTER DELETE ON mileage_logs
  FOR EACH ROW EXECUTE FUNCTION update_car_current_mileage();

-- -----------------------------------------------------------------------------
-- Auth: sync auth.users → public.users + create workspace + workspace_members (owner)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_workspace_id UUID;
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO workspaces (name, owner_user_id)
  VALUES ('My Workspace', NEW.id)
  RETURNING id INTO new_workspace_id;

  INSERT INTO workspace_members (workspace_id, user_id, role)
  VALUES (new_workspace_id, NEW.id, 'owner')
  ON CONFLICT (workspace_id, user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- -----------------------------------------------------------------------------
-- updated_at triggers
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER cars_updated_at BEFORE UPDATE ON cars FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER stations_updated_at BEFORE UPDATE ON stations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER timeline_events_updated_at BEFORE UPDATE ON timeline_events FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER reminders_updated_at BEFORE UPDATE ON reminders FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER user_settings_updated_at BEFORE UPDATE ON user_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
