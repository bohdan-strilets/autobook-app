export interface CarStatsRow {
  car_id: string
  current_mileage: number
  first_mileage: number
  total_distance_km: number
  total_fuel_liters: number
  total_fuel_cost: number
  total_service_cost: number
  total_document_cost: number
  total_cost: number
  average_fuel_consumption: number | null
  cost_per_km: number | null
  last_updated_at: string
}
