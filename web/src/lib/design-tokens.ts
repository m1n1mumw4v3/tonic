export const tokens = {
  colors: {
    spectrum: ["#8F3B43", "#C25D93", "#6A93DE", "#96953F", "#E0B23D"] as const,
    orbYellowInner: "#E0B23D",
    orbYellowOuter: "#96953F",
    orbPinkInner: "#C25D93",
    orbPinkOuter: "#8F3B43",
    darkCard: "#0D0D0D",
  },
  animation: {
    staggerChildren: 0.15,
    entrance: { duration: 0.5, ease: "easeOut" as const },
    spring: { type: "spring" as const, duration: 0.5, damping: 20, stiffness: 100 },
  },
} as const;
