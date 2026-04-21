import { SectionHeading } from "./section-heading";
import { FAQItem } from "./faq-item";

const faqs = [
  {
    question: "Is it free to try?",
    answer:
      "Yes. Estus includes a 7-day free trial with full access to all features. After that, it\u2019s $79.99/year or $12.99/month. You can cancel anytime.",
  },
  {
    question: "How is my plan personalized?",
    answer:
      "During onboarding, we collect 15+ data points \u2014 your health goals, age, sex, diet, exercise habits, medications, allergies, stress level, and baseline wellness scores. Our recommendation engine uses all of this to score, rank, and safety-filter 53 evidence-backed supplements for your specific profile.",
  },
  {
    question: "Is my data private?",
    answer:
      "Yes. Your health data \u2014 profile, supplement plan, check-ins, and wellness scores \u2014 is stored locally on your device. The only network connections are sign-in and a read-only link to our supplement knowledge base.",
  },
  {
    question: "Are the recommendations evidence-based?",
    answer:
      "Every supplement in Estus is mapped to health goals with an evidence weight: Strong (backed by meta-analyses), Moderate (supported by clinical trials), or Emerging (mechanistic evidence). We don\u2019t recommend anything without research backing.",
  },
  {
    question: "What about drug interactions?",
    answer:
      "Estus screens your plan against 98 common medications for known interactions. If a supplement conflicts with something you take, it\u2019s automatically removed or flagged with a specific warning.",
  },
  {
    question: "Is Estus available on Android?",
    answer:
      "Not yet. Estus is currently available on iPhone (iOS 17+). Android is on our roadmap.",
  },
];

export function FAQSection() {
  return (
    <section className="py-20 md:py-28 bg-bg-surface">
      <div className="mx-auto max-w-3xl px-6">
        <SectionHeading label="FAQ" headline="Common questions" />

        <div>
          {faqs.map((faq, i) => (
            <FAQItem
              key={faq.question}
              question={faq.question}
              answer={faq.answer}
              delay={i * 0.08}
            />
          ))}
        </div>
      </div>
    </section>
  );
}
