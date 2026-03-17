import type { MediaType } from '../enums'

export interface MediaRow {
  id: string
  owner_user_id: string
  type: MediaType
  mime_type: string
  original_name: string | null
  storage_key: string
  size_bytes: number | null
  width: number | null
  height: number | null
  duration_seconds: number | null
  checksum: string | null
  is_public: boolean
  created_at: string
}

export interface MediaInsert {
  id?: string
  owner_user_id: string
  type: MediaType
  mime_type: string
  original_name?: string | null
  storage_key: string
  size_bytes?: number | null
  width?: number | null
  height?: number | null
  duration_seconds?: number | null
  checksum?: string | null
  is_public?: boolean
  created_at?: string
}

export interface MediaVariantRow {
  id: string
  media_id: string
  type: MediaType
  storage_key: string
  width: number | null
  height: number | null
  size_bytes: number | null
  created_at: string
}
