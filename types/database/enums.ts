export type UserStatus = 'active' | 'suspended' | 'deleted'
export type WorkspaceType = 'personal' | 'team'
export type WorkspaceRole = 'owner' | 'member'

export type EventType =
  | 'FUEL'
  | 'SERVICE'
  | 'DOCUMENT'
  | 'EXPENSE'
  | 'TIRE_CHANGE'
  | 'TRIP'
  | 'PURCHASE'
  | 'SALE'

export type ServiceCategory = 'MAINTENANCE' | 'REPAIR' | 'CARE' | 'ACCESSORIES' | 'OTHER'

export type DocumentTypeEnum = 'OC' | 'AC' | 'TUV' | 'OTHER'
export type SubscriptionPlan = 'FREE' | 'PRO'
export type SubscriptionProvider = 'APPLE' | 'GOOGLE' | 'MANUAL'
export type SubscriptionStatus = 'ACTIVE' | 'EXPIRED' | 'CANCELED' | 'TRIAL'

export type FuelTypeEnum = 'petrol' | 'diesel' | 'lpg' | 'hybrid' | 'ev'
export type TransmissionEnum = 'manual' | 'automatic'
export type DriveTypeEnum = 'fwd' | 'rwd' | 'awd'

export type MileageSource = 'timeline_event' | 'manual' | 'import'

export type MediaType = 'image' | 'video' | 'document'

export type AiStatus = 'pending' | 'processing' | 'done' | 'failed'

export interface JsonMap {
  [key: string]: unknown
}
