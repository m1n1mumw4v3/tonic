import { AnimatedEntrance } from "./animated-entrance";

interface FeatureCardProps {
  icon: string;
  title: string;
  description: string;
  delay?: number;
}

export function FeatureCard({ icon, title, description, delay = 0 }: FeatureCardProps) {
  return (
    <AnimatedEntrance delay={delay} className="h-full">
      <div className="bg-bg-surface rounded-[26px] p-8 shadow-card h-full">
        <div className="text-[32px] mb-4">{icon}</div>
        <h3 className="text-[20px] font-normal text-text-primary mb-2">
          {title}
        </h3>
        <p className="text-[16px] text-text-secondary leading-relaxed">
          {description}
        </p>
      </div>
    </AnimatedEntrance>
  );
}
