import type { SubscriptionPlan, SubscriptionProvider, SubscriptionStatus } from '../enums'

export interface SubscriptionRow {
  id: string
  user_id: string
  plan: SubscriptionPlan
  status: SubscriptionStatus
  provider: SubscriptionProvider | null
  external_subscription_id: string | null
  started_at: string | null
  expires_at: string | null
  created_at: string
  updated_at: string
}

export interface UserSettingsRow {
  id: string
  user_id: string
  currency: string
  distance_unit: string
  fuel_unit: string
  language: string
  theme: string
  notifications_push: boolean
  notifications_email: boolean
  created_at: string
  updated_at: string
}
