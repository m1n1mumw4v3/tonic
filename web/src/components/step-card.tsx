import { AnimatedEntrance } from "./animated-entrance";

interface StepCardProps {
  stepNumber: number;
  title: string;
  description: string;
  delay?: number;
}

export function StepCard({ stepNumber, title, description, delay = 0 }: StepCardProps) {
  return (
    <AnimatedEntrance delay={delay}>
      <div className="bg-bg-surface rounded-lg p-8 shadow-card">
        <div className="font-mono text-[40px] font-light text-text-tertiary mb-4 leading-none">
          {String(stepNumber).padStart(2, "0")}
        </div>
        <h3 className="text-[20px] font-semibold text-text-primary mb-2">
          {title}
        </h3>
        <p className="text-[16px] text-text-secondary leading-relaxed">
          {description}
        </p>
      </div>
    </AnimatedEntrance>
  );
}
