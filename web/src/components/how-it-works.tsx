import { SectionHeading } from "./section-heading";
import { StepCard } from "./step-card";

const steps = [
  {
    title: "Share your goals",
    description:
      "Tell us about your health goals, lifestyle, diet, medications, and allergies. We collect 15+ data points to understand your body.",
  },
  {
    title: "Get your plan",
    description:
      "Our engine evaluates 53 supplements against your profile, checks for drug interactions, and ranks each one by clinical evidence.",
  },
  {
    title: "Track & improve",
    description:
      "Daily check-ins across five wellness dimensions reveal patterns. Your plan adapts as your data grows.",
  },
];

export function HowItWorks() {
  return (
    <section className="py-20 md:py-28">
      <div className="mx-auto max-w-6xl px-6">
        <SectionHeading
          label="How It Works"
          headline="Three steps to a plan built for you"
        />

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {steps.map((step, i) => (
            <StepCard
              key={step.title}
              stepNumber={i + 1}
              title={step.title}
              description={step.description}
              delay={i * 0.15}
            />
          ))}
        </div>
      </div>
    </section>
  );
}
