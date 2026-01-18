/**
 * Types for .bmad/task-queue.yaml
 */

export interface Task {
  id: string;
  story_id: string;
  title: string;
  type: 'api' | 'backend' | 'frontend' | 'test' | 'devops' | 'e2e';
  estimated_minutes: number;
  status: 'pending' | 'in_progress' | 'done' | 'retrying' | 'blocked';
  depends_on: string[];
  outputs: string[];
  acceptance: string[];
  retries: number;
  max_retries: number;
  blocker_reason?: string;
  receipt?: TaskReceipt;
}

export interface TaskReceipt {
  work_summary: string;
  files_created: string[];
  files_modified: string[];
  tests_passed: boolean;
  commit_hash: string;
  notes?: string;
  duration_minutes: number;
}

export interface QualityGate {
  name: string;
  command: string;
  required: boolean;
  description: string;
}

export interface Summary {
  total_stories: number;
  total_tasks: number;
  estimated_hours: number;
  completed_tasks: number;
  blocked_tasks: number;
}

export interface Scratchpad {
  blockers: string[];
  decisions: string[];
  warnings: string[];
  learnings: string[];
}

export interface TaskQueue {
  version: string;
  project: string;
  sprint: number;
  created_at: string;
  summary: Summary;
  current_task: string | null;
  quality_gates: QualityGate[];
  execution_context: {
    last_updated: string | null;
    tests_status: 'passing' | 'failing' | 'unknown';
    recent_learnings: string[];
  };
  scratchpad: Scratchpad;
  tasks: Task[];
}

export interface Story {
  story_id: string;
  tasks: Task[];
  total_tasks: number;
  completed_tasks: number;
}

// Helper: Group tasks by story
export function groupTasksByStory(tasks: Task[]): Story[] {
  const storiesMap = new Map<string, Task[]>();

  for (const task of tasks) {
    if (!storiesMap.has(task.story_id)) {
      storiesMap.set(task.story_id, []);
    }
    storiesMap.get(task.story_id)!.push(task);
  }

  return Array.from(storiesMap.entries()).map(([story_id, tasks]) => ({
    story_id,
    tasks,
    total_tasks: tasks.length,
    completed_tasks: tasks.filter(t => t.status === 'done').length,
  }));
}

// Helper: Count unique stories
export function countStories(queue: TaskQueue): number {
  const uniqueStories = new Set(queue.tasks.map(t => t.story_id));
  return uniqueStories.size;
}

// Helper: Calculate total duration from receipts
export function calculateTotalDuration(tasks: Task[]): number {
  return tasks
    .filter(t => t.receipt?.duration_minutes)
    .reduce((sum, t) => sum + (t.receipt!.duration_minutes), 0);
}

// Helper: Get all commits from receipts
export function getCommitsFromTasks(tasks: Task[]): string[] {
  return tasks
    .filter(t => t.receipt?.commit_hash)
    .map(t => t.receipt!.commit_hash);
}
