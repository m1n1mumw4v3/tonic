import { AnimatedEntrance } from "@/components/animated-entrance";
import { SectionHeading } from "@/components/section-heading";
import { CTAButton } from "@/components/cta-button";

const values = [
  {
    color: "#8F3B43",
    title: "Personal, not generic",
    description:
      "We believe health is deeply individual. Cookie-cutter supplement stacks don't work because no two bodies are the same.",
  },
  {
    color: "#6A93DE",
    title: "Evidence over hype",
    description:
      "Every recommendation is grounded in research. We don't follow trends — we follow the science.",
  },
  {
    color: "#E0B23D",
    title: "Progress, not perfection",
    description:
      "Small, consistent improvements compound into real change. We help you build sustainable habits, not quick fixes.",
  },
];

export default function About() {
  return (
    <div className="pt-28 pb-20">
      {/* Hero */}
      <section className="mx-auto max-w-4xl px-6 text-center mb-20 md:mb-28">
        <AnimatedEntrance>
          <p className="text-[18px] text-text-primary leading-relaxed max-w-xl mx-auto">
            We believe everyone deserves a supplement plan built for their body —
            not someone else&apos;s. Estus exists to make personalized wellness
            accessible, trackable, and grounded in evidence.
          </p>
        </AnimatedEntrance>
      </section>

      {/* Mission */}
      <section className="py-20 md:py-28 bg-bg-surface">
        <div className="mx-auto max-w-4xl px-6">
          <SectionHeading
            label="Our Mission"
            headline="Better health through better data"
          />
          <AnimatedEntrance>
            <p className="text-[16px] text-text-secondary leading-relaxed max-w-2xl mx-auto text-center">
              The supplement industry is noisy. There are thousands of products,
              conflicting claims, and no easy way to know what&apos;s right for
              you. Estus cuts through that noise with a simple idea: your body
              already has the answers — you just need to listen.
            </p>
          </AnimatedEntrance>
          <AnimatedEntrance delay={0.15}>
            <p className="text-[16px] text-text-secondary leading-relaxed max-w-2xl mx-auto text-center mt-4">
              By tracking five dimensions of wellness daily, we help you see
              patterns that were always there but never visible. And we use those
              patterns to build supplement plans that actually work for you.
            </p>
          </AnimatedEntrance>
        </div>
      </section>

      {/* Values */}
      <section className="py-20 md:py-28">
        <div className="mx-auto max-w-6xl px-6">
          <SectionHeading
            label="What We Believe"
            headline="Principles that guide everything we build"
          />

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {values.map((value, i) => (
              <AnimatedEntrance key={value.title} delay={i * 0.15}>
                <div className="bg-bg-surface rounded-lg p-8 shadow-card h-full">
                  <div
                    className="w-3 h-3 rounded-full mb-5"
                    style={{ backgroundColor: value.color }}
                  />
                  <h3 className="text-[20px] font-semibold text-text-primary mb-2">
                    {value.title}
                  </h3>
                  <p className="text-[14px] text-text-secondary leading-relaxed">
                    {value.description}
                  </p>
                </div>
              </AnimatedEntrance>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 md:py-28 bg-bg-surface">
        <div className="mx-auto max-w-2xl px-6 text-center">
          <AnimatedEntrance>
            <h2 className="text-[28px] md:text-[36px] font-light text-text-primary mb-4 leading-tight">
              Ready to start listening
              <br />
              to your body?
            </h2>
          </AnimatedEntrance>
          <AnimatedEntrance delay={0.15}>
            <p className="text-[16px] text-text-secondary mb-8">
              Download Estus and get a supplement plan that&apos;s truly yours.
            </p>
          </AnimatedEntrance>
          <AnimatedEntrance delay={0.3}>
            <CTAButton href="#">Download Estus</CTAButton>
          </AnimatedEntrance>
        </div>
      </section>
    </div>
  );
}
