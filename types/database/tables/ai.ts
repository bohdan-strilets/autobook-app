import type { AiStatus, JsonMap } from '../enums'

export interface AiRequestRow {
  id: string
  user_id: string
  workspace_id: string
  car_id: string | null
  provider: string
  model: string
  task_type: string | null
  prompt: string | null
  input_data: JsonMap | null
  media_id: string | null
  parameters: JsonMap | null
  status: AiStatus
  retry_count: number
  max_retries: number
  error_message: string | null
  latency_ms: number | null
  created_at: string
  finished_at: string | null
}

export interface AiResponseRow {
  id: string
  request_id: string
  output_text: string | null
  output_json: JsonMap | null
  confidence: number | null
  raw_response: JsonMap | null
  created_at: string
}

export interface AiUsageRow {
  id: string
  request_id: string
  provider: string
  model: string
  prompt_tokens: number
  completion_tokens: number
  total_tokens: number
  cost_usd: number | null
  created_at: string
}
