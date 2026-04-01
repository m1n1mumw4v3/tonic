import { AnimatedEntrance } from "./animated-entrance";

interface SectionHeadingProps {
  label?: string;
  headline: string;
  subheadline?: string;
  align?: "center" | "left";
}

export function SectionHeading({
  label,
  headline,
  subheadline,
  align = "center",
}: SectionHeadingProps) {
  const alignment = align === "center" ? "text-center" : "text-left";

  return (
    <div className={`${alignment} mb-12 md:mb-16`}>
      {label && (
        <AnimatedEntrance>
          <p className="text-[13px] font-semibold uppercase tracking-[1.5px] text-text-secondary mb-3">
            {label}
          </p>
        </AnimatedEntrance>
      )}
      <AnimatedEntrance delay={0.1}>
        <h2 className="text-[28px] md:text-[36px] font-light text-text-primary leading-tight">
          {headline}
        </h2>
      </AnimatedEntrance>
      {subheadline && (
        <AnimatedEntrance delay={0.2}>
          <p className="text-[16px] text-text-secondary mt-4 max-w-2xl mx-auto leading-relaxed">
            {subheadline}
          </p>
        </AnimatedEntrance>
      )}
    </div>
  );
}
