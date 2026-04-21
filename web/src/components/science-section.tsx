import { SectionHeading } from "./section-heading";
import { AnimatedEntrance } from "./animated-entrance";

const points = [
  {
    title: "53 evidence-backed supplements",
    description:
      "Every supplement is mapped to specific health goals with weighted clinical evidence — Strong, Moderate, or Emerging.",
    color: "#6A93DE",
  },
  {
    title: "Screened against 98 medications",
    description:
      "Drug interactions, contraindications, and nutrient depletions are checked automatically before anything enters your plan.",
    color: "#8F3B43",
  },
  {
    title: "Personalized from 15+ health factors",
    description:
      "Age, sex, diet, exercise, stress, medications, allergies, and baseline wellness scores all shape your recommendations.",
    color: "#C25D93",
  },
  {
    title: "Safety-first filtering",
    description:
      "Pregnancy, breastfeeding, allergies, and drug-class rules remove anything that isn't safe for your specific profile.",
    color: "#96953F",
  },
];

export function ScienceSection() {
  return (
    <section className="py-20 md:py-28 bg-bg-surface">
      <div className="mx-auto max-w-6xl px-6">
        <SectionHeading
          label="Our Approach"
          headline="Built on evidence, not hype"
          subheadline="Every recommendation is scored, ranked, and safety-checked by our evidence-weighted engine."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {points.map((point, i) => (
            <AnimatedEntrance key={point.title} delay={i * 0.1}>
              <div className="bg-bg-deepest rounded-lg p-8 shadow-card flex gap-4">
                <div
                  className="mt-1.5 w-3 h-3 rounded-full shrink-0"
                  style={{ backgroundColor: point.color }}
                />
                <div>
                  <h3 className="text-[18px] font-semibold text-text-primary mb-1">
                    {point.title}
                  </h3>
                  <p className="text-[15px] text-text-secondary leading-relaxed">
                    {point.description}
                  </p>
                </div>
              </div>
            </AnimatedEntrance>
          ))}
        </div>
      </div>
    </section>
  );
}
