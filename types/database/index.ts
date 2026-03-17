export * from './enums'
export * from './tables'
export * from './views'

import type {
  AiStatus,
  DocumentTypeEnum,
  DriveTypeEnum,
  EventType,
  FuelTypeEnum,
  MediaType,
  MileageSource,
  ServiceCategory,
  SubscriptionPlan,
  SubscriptionProvider,
  SubscriptionStatus,
  TransmissionEnum,
  UserStatus,
  WorkspaceRole,
  WorkspaceType,
} from './enums'
import type {
  AiRequestRow,
  AiResponseRow,
  AiUsageRow,
  CarInsert,
  CarMediaRow,
  CarRow,
  DocumentRow,
  EventMediaRow,
  FuelLogRow,
  MediaInsert,
  MediaRow,
  MediaVariantRow,
  MileageLogRow,
  ReminderRow,
  ServiceLogRow,
  StationRow,
  SubscriptionRow,
  TimelineEventInsert,
  TimelineEventRow,
  UserInsert,
  UserRow,
  UserSettingsRow,
  WorkspaceInsert,
  WorkspaceMemberInsert,
  WorkspaceMemberRow,
  WorkspaceRow,
} from './tables'
import type { CarStatsRow } from './views'

export interface Database {
  public: {
    Tables: {
      users: { Row: UserRow; Insert: UserInsert; Update: Partial<UserInsert> }
      workspaces: {
        Row: WorkspaceRow
        Insert: WorkspaceInsert
        Update: Partial<WorkspaceInsert>
      }
      workspace_members: {
        Row: WorkspaceMemberRow
        Insert: WorkspaceMemberInsert
        Update: Partial<WorkspaceMemberInsert>
      }
      media: { Row: MediaRow; Insert: MediaInsert; Update: Partial<MediaInsert> }
      cars: { Row: CarRow; Insert: CarInsert; Update: Partial<CarInsert> }
      stations: {
        Row: StationRow
        Insert: Omit<StationRow, 'id' | 'created_at' | 'updated_at'> & {
          id?: string
          created_at?: string
          updated_at?: string
        }
        Update: Partial<StationRow>
      }
      timeline_events: {
        Row: TimelineEventRow
        Insert: TimelineEventInsert
        Update: Partial<TimelineEventInsert>
      }
      fuel_logs: {
        Row: FuelLogRow
        Insert: Omit<FuelLogRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<FuelLogRow>
      }
      service_logs: {
        Row: ServiceLogRow
        Insert: Omit<ServiceLogRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<ServiceLogRow>
      }
      documents: {
        Row: DocumentRow
        Insert: Omit<DocumentRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<DocumentRow>
      }
      mileage_logs: {
        Row: MileageLogRow
        Insert: Omit<MileageLogRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<MileageLogRow>
      }
      reminders: {
        Row: ReminderRow
        Insert: Omit<ReminderRow, 'id' | 'created_at' | 'updated_at'> & {
          id?: string
          created_at?: string
          updated_at?: string
        }
        Update: Partial<ReminderRow>
      }
      media_variants: {
        Row: MediaVariantRow
        Insert: Omit<MediaVariantRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<MediaVariantRow>
      }
      car_media: {
        Row: CarMediaRow
        Insert: Omit<CarMediaRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<CarMediaRow>
      }
      event_media: {
        Row: EventMediaRow
        Insert: Omit<EventMediaRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<EventMediaRow>
      }
      ai_requests: {
        Row: AiRequestRow
        Insert: Omit<AiRequestRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<AiRequestRow>
      }
      ai_responses: {
        Row: AiResponseRow
        Insert: Omit<AiResponseRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<AiResponseRow>
      }
      ai_usage: {
        Row: AiUsageRow
        Insert: Omit<AiUsageRow, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<AiUsageRow>
      }
      subscriptions: {
        Row: SubscriptionRow
        Insert: Omit<SubscriptionRow, 'id' | 'created_at' | 'updated_at'> & {
          id?: string
          created_at?: string
          updated_at?: string
        }
        Update: Partial<SubscriptionRow>
      }
      user_settings: {
        Row: UserSettingsRow
        Insert: Omit<UserSettingsRow, 'id' | 'created_at' | 'updated_at'> & {
          id?: string
          created_at?: string
          updated_at?: string
        }
        Update: Partial<UserSettingsRow>
      }
      car_stats: { Row: CarStatsRow; Insert: never; Update: never }
    }
    Views: Record<string, never>
    Functions: Record<string, unknown>
    Enums: {
      user_status: UserStatus
      workspace_type: WorkspaceType
      workspace_role: WorkspaceRole
      event_type: EventType
      service_category: ServiceCategory
      document_type_enum: DocumentTypeEnum
      subscription_plan: SubscriptionPlan
      subscription_provider: SubscriptionProvider
      subscription_status: SubscriptionStatus
      fuel_type_enum: FuelTypeEnum
      transmission_enum: TransmissionEnum
      drive_type_enum: DriveTypeEnum
      mileage_source: MileageSource
      media_type: MediaType
      ai_status: AiStatus
    }
  }
}
