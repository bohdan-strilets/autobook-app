import type { DocumentTypeEnum, EventType, FuelTypeEnum, ServiceCategory } from '../enums'

export interface TimelineEventRow {
  id: string
  car_id: string
  created_by_user_id: string
  service_station_id: string | null
  type: EventType
  title: string | null
  description: string | null
  event_date: string
  mileage: number
  cost: number | null
  currency: string | null
  created_at: string
  updated_at: string
}

export interface TimelineEventInsert {
  id?: string
  car_id: string
  created_by_user_id: string
  service_station_id?: string | null
  type: EventType
  title?: string | null
  description?: string | null
  event_date: string
  mileage: number
  cost?: number | null
  currency?: string | null
  created_at?: string
  updated_at?: string
}

export interface FuelLogRow {
  id: string
  timeline_event_id: string
  liters: number
  price_per_liter: number
  fuel_type: FuelTypeEnum | null
  station_name: string | null
  station_address: string | null
  latitude: number | null
  longitude: number | null
  notes: string | null
  created_at: string
}

export interface ServiceLogRow {
  id: string
  timeline_event_id: string
  category: ServiceCategory
  description: string | null
  created_at: string
}

export interface DocumentRow {
  id: string
  timeline_event_id: string
  type: DocumentTypeEnum
  issue_date: string | null
  expire_date: string | null
  file_media_id: string | null
  notes: string | null
  created_at: string
}

export interface EventMediaRow {
  id: string
  timeline_event_id: string
  media_id: string
  created_at: string
}
