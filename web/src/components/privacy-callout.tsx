import { AnimatedEntrance } from "./animated-entrance";

export function PrivacyCallout() {
  return (
    <section className="py-20 md:py-28">
      <div className="mx-auto max-w-4xl px-6 text-center">
        <AnimatedEntrance>
          <svg
            width="40"
            height="40"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="mx-auto mb-6 text-text-tertiary"
          >
            <path d="M12 2l7 4v5c0 5.25-3.5 9.74-7 11-3.5-1.26-7-5.75-7-11V6l7-4z" />
          </svg>
        </AnimatedEntrance>
        <AnimatedEntrance delay={0.1}>
          <h2 className="text-[28px] md:text-[36px] font-light text-text-primary leading-tight mb-4">
            Your health data stays on your device
          </h2>
        </AnimatedEntrance>
        <AnimatedEntrance delay={0.2}>
          <p className="text-[16px] text-text-secondary leading-relaxed max-w-2xl mx-auto mb-6">
            Health data is personal. Your profile, supplement plan, check-ins,
            and wellness scores are stored locally on your iPhone — not in the
            cloud. No third-party sharing, ever.
          </p>
        </AnimatedEntrance>
      </div>
    </section>
  );
}
