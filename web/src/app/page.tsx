"use client";

import { motion, useReducedMotion } from "framer-motion";
import { HeroOrbBackground } from "@/components/hero-orb-background";
import { CTAButton } from "@/components/cta-button";
import { SectionHeading } from "@/components/section-heading";
import { FeatureCard } from "@/components/feature-card";
import { AnimatedEntrance } from "@/components/animated-entrance";
import { tokens } from "@/lib/design-tokens";
import { PhoneMockup } from "@/components/phone-mockup";

const dimensions = [
  { name: "Sleep", color: "#8F3B43", description: "Restfulness & recovery" },
  { name: "Energy", color: "#C25D93", description: "Vitality & stamina" },
  { name: "Clarity", color: "#6A93DE", description: "Focus & cognition" },
  { name: "Mood", color: "#96953F", description: "Balance & resilience" },
  { name: "Gut", color: "#E0B23D", description: "Digestion & comfort" },
];

export default function Home() {
  const reducedMotion = useReducedMotion();
  const instant = reducedMotion ? 0 : undefined;

  return (
    <>
      {/* ─── Hero ─── */}
      <section className="relative flex items-center justify-center px-6 pt-28 pb-6">
        <div data-hero className="relative w-full max-w-6xl rounded-xl md:rounded-[28px] overflow-hidden">
          <HeroOrbBackground />

          {/* Content overlay */}
          <div className="relative z-10 flex flex-col items-center text-center px-6 pt-24 md:pt-32 pb-0">
          {/* Headline */}
          <motion.h1
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              delay: instant ?? 0.8,
              duration: instant ?? 1.0,
              ease: "easeInOut",
            }}
            className="text-[36px] md:text-[52px] lg:text-[64px] font-light text-white leading-[1.08] tracking-[-0.02em] max-w-3xl text-balance"
          >
            The supplement plan your body&apos;s been asking for.
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              delay: instant ?? 1.4,
              duration: instant ?? 0.8,
              ease: "easeInOut",
            }}
            className="text-[15px] md:text-[17px] text-white/80 mt-6 max-w-2xl leading-relaxed font-normal text-balance"
          >
            Estus designs supplement plans tailored to your goals, daily tracking
            across five wellness dimensions, and recommendations that get smarter
            over time.
          </motion.p>

          {/* CTA */}
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              delay: instant ?? 2.0,
              duration: instant ?? 0.8,
              ease: "easeInOut",
            }}
            className="mt-10"
          >
            <CTAButton href="#" variant="hero" className="min-w-[200px]">
              Download App
            </CTAButton>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              delay: instant ?? 2.4,
              duration: instant ?? 1.0,
              ease: "easeInOut",
            }}
            className="mt-12"
          >
            <PhoneMockup />
          </motion.div>
          </div>
        </div>
      </section>



      {/* ─── Features ─── */}
      <section id="features" className="py-20 md:py-28 scroll-mt-16">
        <div className="mx-auto max-w-6xl px-6">
          <SectionHeading
            label="Features"
            headline="Everything you need, nothing you don't"
            subheadline="A smarter approach to supplements — personalized, tracked, and always improving."
          />

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <FeatureCard
              icon="✦"
              title="Personalized for You"
              description="Your plan is built from your goals, lifestyle, and health profile. No generic stacks — just what your body needs."
              delay={0}
            />
            <FeatureCard
              icon="◐"
              title="Track What Matters"
              description="Daily check-ins across five dimensions of wellness give you a clear picture of how you're feeling, day by day."
              delay={0.15}
            />
            <FeatureCard
              icon="↻"
              title="Gets Smarter Over Time"
              description="Your plan adjusts based on real patterns in your data. The longer you track, the better it gets."
              delay={0.3}
            />
          </div>
        </div>
      </section>

      {/* ─── Wellness Dimensions ─── */}
      <section className="py-20 md:py-28 bg-bg-surface">
        <div className="mx-auto max-w-6xl px-6">
          <SectionHeading
            label="Five Dimensions"
            headline="Wellness is more than one number"
            subheadline="Track the dimensions that matter most to how you feel every day."
          />

          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {dimensions.map((dim, i) => (
              <AnimatedEntrance key={dim.name} delay={i * 0.1}>
                <div className="relative overflow-hidden rounded-lg p-6 text-white aspect-square flex flex-col justify-end">
                  <div
                    className="absolute inset-0 opacity-90"
                    style={{ backgroundColor: dim.color }}
                  />
                  <div className="relative z-10">
                    <div className="text-[20px] font-semibold mb-1">
                      {dim.name}
                    </div>
                    <div className="text-[13px] text-white/80">
                      {dim.description}
                    </div>
                  </div>
                </div>
              </AnimatedEntrance>
            ))}
          </div>

          {/* Spectrum bar */}
          <AnimatedEntrance delay={0.5}>
            <div className="bg-spectrum h-[3px] rounded-full mt-8" />
          </AnimatedEntrance>
        </div>
      </section>


      {/* ─── Final CTA ─── */}
      <section className="relative py-20 md:py-28 overflow-hidden">
        <div className="absolute inset-0 bg-bg-dark" />

        {/* Subtle orb glow */}
        <div
          className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full opacity-30"
          style={{
            background: `radial-gradient(circle, ${tokens.colors.orbYellowInner}, ${tokens.colors.orbYellowOuter}, transparent)`,
            filter: "blur(80px)",
          }}
        />

        <div className="relative z-10 mx-auto max-w-4xl px-6 text-center">
          <AnimatedEntrance>
            <h2 className="text-[28px] md:text-[36px] font-light text-bg-deepest mb-4 leading-tight">
              Start feeling better,
              <br />
              one day at a time.
            </h2>
          </AnimatedEntrance>
          <AnimatedEntrance delay={0.15}>
            <p className="text-[16px] text-text-tertiary mb-8">
              Join thousands building healthier habits with personalized
              supplement plans.
            </p>
          </AnimatedEntrance>
          <AnimatedEntrance delay={0.3}>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <CTAButton
                href="#"
                variant="primary"
                className="!bg-white !text-text-primary hover:!bg-white/90"
              >
                Download App
              </CTAButton>
            </div>
          </AnimatedEntrance>
        </div>
      </section>
    </>
  );
}
