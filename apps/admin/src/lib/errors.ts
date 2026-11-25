import { ApiError } from "@gudmeal/api-client";

/**
 * What to show when saving settings failed. The API refuses a save (409 `conflict`) when the settings changed after
 * this page loaded them, so one person's change is never undone by someone else's older copy.
 */
export function settingsError(error: unknown): string {
  if (error instanceof ApiError && error.status === 409 && error.code === "conflict") {
    return "Someone else changed the settings. Reload and try again.";
  }
  return error instanceof Error ? error.message : "Something went wrong";
}
