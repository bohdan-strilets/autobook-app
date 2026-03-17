import type { WorkspaceRole, WorkspaceType } from '../enums'

export interface WorkspaceRow {
  id: string
  name: string
  type: WorkspaceType
  owner_user_id: string
  created_at: string
}

export interface WorkspaceInsert {
  id?: string
  name: string
  type?: WorkspaceType
  owner_user_id: string
  created_at?: string
}

export interface WorkspaceMemberRow {
  id: string
  workspace_id: string
  user_id: string
  role: WorkspaceRole
  created_at: string
}

export interface WorkspaceMemberInsert {
  id?: string
  workspace_id: string
  user_id: string
  role?: WorkspaceRole
  created_at?: string
}
