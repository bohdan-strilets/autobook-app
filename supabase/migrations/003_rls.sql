-- =============================================================================
-- 003_rls.sql — AutoBook MVP
-- ENABLE RLS + helper function + policies only
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ENABLE RLS on all tables
-- -----------------------------------------------------------------------------

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE media ENABLE ROW LEVEL SECURITY;
ALTER TABLE cars ENABLE ROW LEVEL SECURITY;
ALTER TABLE stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE mileage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE car_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Helper: user is member of workspace (any role)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION user_workspace_ids(auth_uid UUID)
RETURNS SETOF UUID AS $$
  SELECT workspace_id FROM public.workspace_members WHERE user_id = auth_uid
  UNION
  SELECT id FROM public.workspaces WHERE owner_user_id = auth_uid;
$$ LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public;

-- -----------------------------------------------------------------------------
-- POLICIES
-- -----------------------------------------------------------------------------

-- users: own row only
CREATE POLICY users_select_own ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY users_update_own ON users FOR UPDATE USING (id = auth.uid());
CREATE POLICY users_insert_own ON users FOR INSERT WITH CHECK (id = auth.uid());

-- workspaces: access if owner or member
CREATE POLICY workspaces_select ON workspaces FOR SELECT
  USING (owner_user_id = auth.uid() OR id IN (SELECT user_workspace_ids(auth.uid())));
CREATE POLICY workspaces_insert ON workspaces FOR INSERT WITH CHECK (owner_user_id = auth.uid());
CREATE POLICY workspaces_update ON workspaces FOR UPDATE
  USING (owner_user_id = auth.uid());
CREATE POLICY workspaces_delete ON workspaces FOR DELETE USING (owner_user_id = auth.uid());

-- workspace_members: access if in workspace
CREATE POLICY workspace_members_select ON workspace_members FOR SELECT
  USING (workspace_id IN (SELECT user_workspace_ids(auth.uid())));
CREATE POLICY workspace_members_insert ON workspace_members FOR INSERT
  WITH CHECK (workspace_id IN (SELECT user_workspace_ids(auth.uid())));
CREATE POLICY workspace_members_update ON workspace_members FOR UPDATE
  USING (workspace_id IN (SELECT user_workspace_ids(auth.uid())));
CREATE POLICY workspace_members_delete ON workspace_members FOR DELETE
  USING (workspace_id IN (SELECT user_workspace_ids(auth.uid())));

-- media: owner only
CREATE POLICY media_select ON media FOR SELECT USING (owner_user_id = auth.uid());
CREATE POLICY media_insert ON media FOR INSERT WITH CHECK (owner_user_id = auth.uid());
CREATE POLICY media_update ON media FOR UPDATE USING (owner_user_id = auth.uid());
CREATE POLICY media_delete ON media FOR DELETE USING (owner_user_id = auth.uid());

-- cars: workspace access
CREATE POLICY cars_select ON cars FOR SELECT
  USING (workspace_id IN (SELECT user_workspace_ids(auth.uid())));
CREATE POLICY cars_insert ON cars FOR INSERT
  WITH CHECK (workspace_id IN (SELECT user_workspace_ids(auth.uid())));
CREATE POLICY cars_update ON cars FOR UPDATE
  USING (workspace_id IN (SELECT user_workspace_ids(auth.uid())));
CREATE POLICY cars_delete ON cars FOR DELETE
  USING (workspace_id IN (SELECT user_workspace_ids(auth.uid())));

-- stations: owner only
CREATE POLICY stations_select ON stations FOR SELECT USING (user_id = auth.uid());
CREATE POLICY stations_insert ON stations FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY stations_update ON stations FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY stations_delete ON stations FOR DELETE USING (user_id = auth.uid());

-- timeline_events: via car -> workspace
CREATE POLICY timeline_events_select ON timeline_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM cars c
      WHERE c.id = timeline_events.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY timeline_events_insert ON timeline_events FOR INSERT
  WITH CHECK (
    created_by_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM cars c
      WHERE c.id = timeline_events.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY timeline_events_update ON timeline_events FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM cars c
      WHERE c.id = timeline_events.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY timeline_events_delete ON timeline_events FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM cars c
      WHERE c.id = timeline_events.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );

-- fuel_logs, service_logs, documents: via timeline_events -> car -> workspace
CREATE POLICY fuel_logs_select ON fuel_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = fuel_logs.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY fuel_logs_insert ON fuel_logs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = fuel_logs.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY fuel_logs_update ON fuel_logs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = fuel_logs.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY fuel_logs_delete ON fuel_logs FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = fuel_logs.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );

CREATE POLICY service_logs_select ON service_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = service_logs.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY service_logs_insert ON service_logs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = service_logs.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY service_logs_update ON service_logs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = service_logs.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY service_logs_delete ON service_logs FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = service_logs.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );

CREATE POLICY documents_select ON documents FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = documents.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY documents_insert ON documents FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = documents.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY documents_update ON documents FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = documents.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY documents_delete ON documents FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = documents.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );

-- mileage_logs: via car -> workspace
CREATE POLICY mileage_logs_select ON mileage_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = mileage_logs.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY mileage_logs_insert ON mileage_logs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = mileage_logs.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY mileage_logs_update ON mileage_logs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = mileage_logs.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY mileage_logs_delete ON mileage_logs FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = mileage_logs.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );

-- reminders: via car -> workspace
CREATE POLICY reminders_select ON reminders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = reminders.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY reminders_insert ON reminders FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = reminders.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY reminders_update ON reminders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = reminders.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY reminders_delete ON reminders FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = reminders.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );

-- media_variants: via media owner
CREATE POLICY media_variants_select ON media_variants FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM media m WHERE m.id = media_variants.media_id AND m.owner_user_id = auth.uid())
  );
CREATE POLICY media_variants_insert ON media_variants FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM media m WHERE m.id = media_variants.media_id AND m.owner_user_id = auth.uid())
  );
CREATE POLICY media_variants_update ON media_variants FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM media m WHERE m.id = media_variants.media_id AND m.owner_user_id = auth.uid())
  );
CREATE POLICY media_variants_delete ON media_variants FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM media m WHERE m.id = media_variants.media_id AND m.owner_user_id = auth.uid())
  );

-- car_media: via car -> workspace
CREATE POLICY car_media_select ON car_media FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = car_media.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY car_media_insert ON car_media FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = car_media.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY car_media_update ON car_media FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = car_media.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY car_media_delete ON car_media FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM cars c WHERE c.id = car_media.car_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );

-- event_media: via timeline_event -> car -> workspace
CREATE POLICY event_media_select ON event_media FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = event_media.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY event_media_insert ON event_media FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = event_media.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );
CREATE POLICY event_media_delete ON event_media FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM timeline_events te JOIN cars c ON c.id = te.car_id
      WHERE te.id = event_media.timeline_event_id AND c.workspace_id IN (SELECT user_workspace_ids(auth.uid()))
    )
  );

-- ai_requests, ai_responses, ai_usage: user-scoped
CREATE POLICY ai_requests_select ON ai_requests FOR SELECT USING (user_id = auth.uid());
CREATE POLICY ai_requests_insert ON ai_requests FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY ai_requests_update ON ai_requests FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY ai_requests_delete ON ai_requests FOR DELETE USING (user_id = auth.uid());
CREATE POLICY ai_responses_select ON ai_responses FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM ai_requests ar WHERE ar.id = ai_responses.request_id AND ar.user_id = auth.uid())
  );
CREATE POLICY ai_usage_select ON ai_usage FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM ai_requests ar WHERE ar.id = ai_usage.request_id AND ar.user_id = auth.uid())
  );

-- subscriptions, user_settings: own only
CREATE POLICY subscriptions_select ON subscriptions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY subscriptions_insert ON subscriptions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY subscriptions_update ON subscriptions FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY subscriptions_delete ON subscriptions FOR DELETE USING (user_id = auth.uid());
CREATE POLICY user_settings_select ON user_settings FOR SELECT USING (user_id = auth.uid());
CREATE POLICY user_settings_insert ON user_settings FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY user_settings_update ON user_settings FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY user_settings_delete ON user_settings FOR DELETE USING (user_id = auth.uid());
