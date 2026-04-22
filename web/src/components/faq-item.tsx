"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { AnimatedEntrance } from "./animated-entrance";

interface FAQItemProps {
  question: string;
  answer: string;
  delay?: number;
}

export function FAQItem({ question, answer, delay = 0 }: FAQItemProps) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <AnimatedEntrance delay={delay}>
      <div className="border-b border-border-default">
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="w-full flex items-center justify-between py-5 text-left cursor-pointer"
        >
          <span className="text-[18px] font-normal text-text-primary pr-4">
            {question}
          </span>
          <motion.span
            animate={{ rotate: isOpen ? 180 : 0 }}
            transition={{ duration: 0.2, ease: "easeInOut" }}
            className="text-text-tertiary text-[20px] shrink-0"
          >
            &#x25BE;
          </motion.span>
        </button>
        <AnimatePresence>
          {isOpen && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: "auto", opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              transition={{ duration: 0.25, ease: "easeInOut" }}
              className="overflow-hidden"
            >
              <p className="text-[16px] text-text-secondary leading-relaxed pb-5">
                {answer}
              </p>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </AnimatedEntrance>
  );
}
