import type {
  DriveTypeEnum,
  FuelTypeEnum,
  MileageSource,
  TransmissionEnum,
} from '../enums'

export interface CarRow {
  id: string
  workspace_id: string
  brand: string
  model: string
  generation: string | null
  year: number
  vin: string | null
  plate_number: string | null
  fuel_type: FuelTypeEnum
  transmission: TransmissionEnum | null
  drive_type: DriveTypeEnum | null
  color: string | null
  purchase_date: string | null
  purchase_price: number | null
  purchase_mileage: number | null
  sale_date: string | null
  sale_price: number | null
  sale_mileage: number | null
  description: string | null
  current_mileage: number
  created_at: string
  updated_at: string
  deleted_at: string | null
}

export interface CarInsert {
  id?: string
  workspace_id: string
  brand: string
  model: string
  generation?: string | null
  year: number
  vin?: string | null
  plate_number?: string | null
  fuel_type: FuelTypeEnum
  transmission?: TransmissionEnum | null
  drive_type?: DriveTypeEnum | null
  color?: string | null
  purchase_date?: string | null
  purchase_price?: number | null
  purchase_mileage?: number | null
  sale_date?: string | null
  sale_price?: number | null
  sale_mileage?: number | null
  description?: string | null
  current_mileage?: number
  created_at?: string
  updated_at?: string
  deleted_at?: string | null
}

export interface StationRow {
  id: string
  user_id: string
  name: string
  type: string | null
  address: string | null
  latitude: number | null
  longitude: number | null
  phone: string | null
  website: string | null
  created_at: string
  updated_at: string
}

export interface MileageLogRow {
  id: string
  car_id: string
  timeline_event_id: string | null
  mileage: number
  date: string
  source: MileageSource
  created_at: string
}

export interface ReminderRow {
  id: string
  car_id: string
  type: string
  title: string
  description: string | null
  due_date: string | null
  due_mileage: number | null
  is_completed: boolean
  completed_at: string | null
  created_at: string
  updated_at: string
}

export interface CarMediaRow {
  id: string
  car_id: string
  media_id: string
  position: number
  created_at: string
}
