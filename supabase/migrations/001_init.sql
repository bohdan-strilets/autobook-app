-- =============================================================================
-- 001_init.sql — AutoBook MVP
-- ENUMS, TABLES, INDEXES, CONSTRAINTS only
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ENUMS
-- -----------------------------------------------------------------------------

CREATE TYPE user_status AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE workspace_type AS ENUM ('personal', 'team');
CREATE TYPE workspace_role AS ENUM ('owner', 'member');

CREATE TYPE event_type AS ENUM (
  'FUEL',
  'SERVICE',
  'DOCUMENT',
  'EXPENSE',
  'TIRE_CHANGE',
  'TRIP',
  'PURCHASE',
  'SALE'
);

CREATE TYPE service_category AS ENUM (
  'MAINTENANCE',
  'REPAIR',
  'CARE',
  'ACCESSORIES',
  'OTHER'
);

CREATE TYPE document_type_enum AS ENUM ('OC', 'AC', 'TUV', 'OTHER');
CREATE TYPE subscription_plan AS ENUM ('FREE', 'PRO');
CREATE TYPE subscription_provider AS ENUM ('APPLE', 'GOOGLE', 'MANUAL');
CREATE TYPE subscription_status AS ENUM ('ACTIVE', 'EXPIRED', 'CANCELED', 'TRIAL');

CREATE TYPE fuel_type_enum AS ENUM ('petrol', 'diesel', 'lpg', 'hybrid', 'ev');
CREATE TYPE transmission_enum AS ENUM ('manual', 'automatic');
CREATE TYPE drive_type_enum AS ENUM ('fwd', 'rwd', 'awd');

CREATE TYPE mileage_source AS ENUM ('timeline_event', 'manual', 'import');

CREATE TYPE media_type AS ENUM ('image', 'video', 'document');

CREATE TYPE ai_status AS ENUM ('pending', 'processing', 'done', 'failed');

-- -----------------------------------------------------------------------------
-- CORE: users (extends Supabase auth.users via public.users profile)
-- -----------------------------------------------------------------------------

CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  avatar_media_id UUID,
  status user_status NOT NULL DEFAULT 'active',
  locale TEXT NOT NULL DEFAULT 'en',
  timezone TEXT NOT NULL DEFAULT 'UTC',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- -----------------------------------------------------------------------------
-- WORKSPACES
-- -----------------------------------------------------------------------------

CREATE TABLE workspaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type workspace_type NOT NULL DEFAULT 'personal',
  owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_workspaces_owner ON workspaces(owner_user_id);

CREATE TABLE workspace_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role workspace_role NOT NULL DEFAULT 'member',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, user_id)
);

CREATE INDEX idx_workspace_members_workspace ON workspace_members(workspace_id);
CREATE INDEX idx_workspace_members_user ON workspace_members(user_id);

-- -----------------------------------------------------------------------------
-- MEDIA (referenced by users.avatar_media_id and others)
-- -----------------------------------------------------------------------------

CREATE TABLE media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type media_type NOT NULL,
  mime_type TEXT NOT NULL,
  original_name TEXT,
  storage_key TEXT NOT NULL,
  size_bytes BIGINT,
  width INTEGER,
  height INTEGER,
  duration_seconds NUMERIC(10, 2),
  checksum TEXT,
  is_public BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_media_owner ON media(owner_user_id);
CREATE INDEX idx_media_storage_key ON media(storage_key);

ALTER TABLE users
  ADD CONSTRAINT fk_users_avatar_media
  FOREIGN KEY (avatar_media_id) REFERENCES media(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- VEHICLE: cars
-- -----------------------------------------------------------------------------

CREATE TABLE cars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  generation TEXT,
  year INTEGER NOT NULL,
  vin TEXT,
  plate_number TEXT,
  fuel_type fuel_type_enum NOT NULL,
  transmission transmission_enum,
  drive_type drive_type_enum,
  color TEXT,
  purchase_date DATE,
  purchase_price NUMERIC(12, 2),
  purchase_mileage INTEGER,
  sale_date DATE,
  sale_price NUMERIC(12, 2),
  sale_mileage INTEGER,
  description TEXT,
  current_mileage INTEGER NOT NULL DEFAULT 0 CHECK (current_mileage >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_cars_workspace ON cars(workspace_id);
CREATE INDEX idx_cars_deleted ON cars(workspace_id) WHERE deleted_at IS NULL;

-- -----------------------------------------------------------------------------
-- STATIONS (optional, for timeline_events.service_station_id)
-- -----------------------------------------------------------------------------

CREATE TABLE stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT,
  address TEXT,
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),
  phone TEXT,
  website TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_stations_user ON stations(user_id);

-- -----------------------------------------------------------------------------
-- EVENTS: timeline_events
-- -----------------------------------------------------------------------------

CREATE TABLE timeline_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  car_id UUID NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_station_id UUID REFERENCES stations(id) ON DELETE SET NULL,
  type event_type NOT NULL,
  title TEXT,
  description TEXT,
  event_date DATE NOT NULL,
  mileage INTEGER NOT NULL CHECK (mileage >= 0),
  cost NUMERIC(12, 2) CHECK (cost IS NULL OR cost >= 0),
  currency TEXT DEFAULT 'PLN' CHECK (char_length(currency) = 3),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_timeline_events_car_date ON timeline_events(car_id, event_date DESC);
CREATE INDEX idx_timeline_events_car_id ON timeline_events(car_id);
CREATE INDEX idx_timeline_events_created_by ON timeline_events(created_by_user_id);

-- -----------------------------------------------------------------------------
-- Sub-logs: fuel_logs, service_logs, documents
-- -----------------------------------------------------------------------------

CREATE TABLE fuel_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timeline_event_id UUID NOT NULL REFERENCES timeline_events(id) ON DELETE CASCADE UNIQUE,
  liters NUMERIC(10, 2) NOT NULL CHECK (liters > 0),
  price_per_liter NUMERIC(10, 4) NOT NULL CHECK (price_per_liter >= 0),
  fuel_type fuel_type_enum,
  station_name TEXT,
  station_address TEXT,
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_fuel_logs_timeline_event ON fuel_logs(timeline_event_id);

CREATE TABLE service_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timeline_event_id UUID NOT NULL REFERENCES timeline_events(id) ON DELETE CASCADE UNIQUE,
  category service_category NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_service_logs_timeline_event ON service_logs(timeline_event_id);

CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timeline_event_id UUID NOT NULL REFERENCES timeline_events(id) ON DELETE CASCADE UNIQUE,
  type document_type_enum NOT NULL,
  issue_date DATE,
  expire_date DATE,
  file_media_id UUID REFERENCES media(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_documents_timeline_event ON documents(timeline_event_id);
CREATE INDEX idx_documents_expire ON documents(expire_date) WHERE expire_date IS NOT NULL;

-- -----------------------------------------------------------------------------
-- MILEAGE: mileage_logs
-- -----------------------------------------------------------------------------

CREATE TABLE mileage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  car_id UUID NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  timeline_event_id UUID REFERENCES timeline_events(id) ON DELETE SET NULL,
  mileage INTEGER NOT NULL CHECK (mileage >= 0),
  date DATE NOT NULL,
  source mileage_source NOT NULL DEFAULT 'timeline_event',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_mileage_logs_car_timeline ON mileage_logs (car_id, timeline_event_id) WHERE timeline_event_id IS NOT NULL;
CREATE INDEX idx_mileage_logs_car_date ON mileage_logs(car_id, date DESC);
CREATE INDEX idx_mileage_logs_car_id ON mileage_logs(car_id);

-- -----------------------------------------------------------------------------
-- REMINDERS
-- -----------------------------------------------------------------------------

CREATE TABLE reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  car_id UUID NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  due_mileage INTEGER CHECK (due_mileage IS NULL OR due_mileage >= 0),
  is_completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_reminders_car_due ON reminders(car_id, due_date);
CREATE INDEX idx_reminders_car_id ON reminders(car_id);
CREATE INDEX idx_reminders_due_date ON reminders(due_date) WHERE is_completed = false;

-- -----------------------------------------------------------------------------
-- MEDIA JUNCTION: car_media, event_media, media_variants
-- -----------------------------------------------------------------------------

CREATE TABLE media_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  media_id UUID NOT NULL REFERENCES media(id) ON DELETE CASCADE,
  type media_type NOT NULL,
  storage_key TEXT NOT NULL,
  width INTEGER,
  height INTEGER,
  size_bytes BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_media_variants_media ON media_variants(media_id);

CREATE TABLE car_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  car_id UUID NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  media_id UUID NOT NULL REFERENCES media(id) ON DELETE CASCADE,
  position INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (car_id, media_id)
);

CREATE INDEX idx_car_media_car ON car_media(car_id);
CREATE INDEX idx_car_media_media ON car_media(media_id);

CREATE TABLE event_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timeline_event_id UUID NOT NULL REFERENCES timeline_events(id) ON DELETE CASCADE,
  media_id UUID NOT NULL REFERENCES media(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (timeline_event_id, media_id)
);

CREATE INDEX idx_event_media_event ON event_media(timeline_event_id);
CREATE INDEX idx_event_media_media ON event_media(media_id);

-- -----------------------------------------------------------------------------
-- AI
-- -----------------------------------------------------------------------------

CREATE TABLE ai_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  car_id UUID REFERENCES cars(id) ON DELETE SET NULL,
  provider TEXT NOT NULL,
  model TEXT NOT NULL,
  task_type TEXT,
  prompt TEXT,
  input_data JSONB,
  media_id UUID REFERENCES media(id) ON DELETE SET NULL,
  parameters JSONB,
  status ai_status NOT NULL DEFAULT 'pending',
  retry_count INTEGER NOT NULL DEFAULT 0,
  max_retries INTEGER NOT NULL DEFAULT 3,
  error_message TEXT,
  latency_ms INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ
);

CREATE INDEX idx_ai_requests_user ON ai_requests(user_id);
CREATE INDEX idx_ai_requests_workspace ON ai_requests(workspace_id);
CREATE INDEX idx_ai_requests_created ON ai_requests(created_at DESC);

CREATE TABLE ai_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES ai_requests(id) ON DELETE CASCADE UNIQUE,
  output_text TEXT,
  output_json JSONB,
  confidence NUMERIC(5, 4),
  raw_response JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ai_responses_request ON ai_responses(request_id);

CREATE TABLE ai_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES ai_requests(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  model TEXT NOT NULL,
  prompt_tokens INTEGER NOT NULL CHECK (prompt_tokens >= 0),
  completion_tokens INTEGER NOT NULL CHECK (completion_tokens >= 0),
  total_tokens INTEGER NOT NULL CHECK (total_tokens >= 0),
  cost_usd NUMERIC(12, 6) CHECK (cost_usd IS NULL OR cost_usd >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ai_usage_request ON ai_usage(request_id);
CREATE INDEX idx_ai_usage_created ON ai_usage(created_at);

-- -----------------------------------------------------------------------------
-- SUBSCRIPTIONS
-- -----------------------------------------------------------------------------

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  plan subscription_plan NOT NULL DEFAULT 'FREE',
  status subscription_status NOT NULL DEFAULT 'ACTIVE',
  provider subscription_provider,
  external_subscription_id TEXT,
  started_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_expires ON subscriptions(expires_at) WHERE status = 'ACTIVE';

-- -----------------------------------------------------------------------------
-- SETTINGS
-- -----------------------------------------------------------------------------

CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  currency TEXT NOT NULL DEFAULT 'PLN' CHECK (char_length(currency) = 3),
  distance_unit TEXT NOT NULL DEFAULT 'km',
  fuel_unit TEXT NOT NULL DEFAULT 'l',
  language TEXT NOT NULL DEFAULT 'en',
  theme TEXT NOT NULL DEFAULT 'system',
  notifications_push BOOLEAN NOT NULL DEFAULT true,
  notifications_email BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_settings_user ON user_settings(user_id);
