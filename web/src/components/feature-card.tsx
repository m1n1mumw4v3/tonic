import { AnimatedEntrance } from "./animated-entrance";

interface FeatureCardProps {
  icon: string;
  title: string;
  description: string;
  delay?: number;
}

export function FeatureCard({ icon, title, description, delay = 0 }: FeatureCardProps) {
  return (
    <AnimatedEntrance delay={delay}>
      <div className="bg-bg-surface rounded-lg p-8 shadow-card">
        <div className="text-[32px] mb-4">{icon}</div>
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
