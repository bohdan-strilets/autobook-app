import type { UserStatus } from '../enums'

export interface UserRow {
  id: string
  email: string
  first_name: string | null
  last_name: string | null
  avatar_media_id: string | null
  status: UserStatus
  locale: string
  timezone: string
  created_at: string
  updated_at: string
}

export interface UserInsert {
  id: string
  email: string
  first_name?: string | null
  last_name?: string | null
  avatar_media_id?: string | null
  status?: UserStatus
  locale?: string
  timezone?: string
  created_at?: string
  updated_at?: string
}
