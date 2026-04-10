export type PreviewTheme = "light" | "dark"
export type PreviewDensity = "default" | "compact"

export function createPreviewState<TExtra extends Record<string, unknown>>(extra?: TExtra) {
  return {
    theme: "dark" as PreviewTheme,
    density: "default" as PreviewDensity,
    ...(extra ?? {}),
  }
}
