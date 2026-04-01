"use client";

import { motion } from "framer-motion";
import Link from "next/link";

interface CTAButtonProps {
  children: React.ReactNode;
  href?: string;
  variant?: "primary" | "secondary" | "ghost" | "hero";
  className?: string;
  onClick?: () => void;
}

export function CTAButton({
  children,
  href,
  variant = "primary",
  className = "",
  onClick,
}: CTAButtonProps) {
  const variants = {
    primary:
      "bg-text-primary text-bg-deepest font-semibold",
    secondary:
      "border-[1.5px] border-text-primary text-text-primary bg-transparent font-semibold",
    ghost: "text-text-secondary bg-transparent font-medium",
    hero: "bg-white/20 text-white border border-white/60 backdrop-blur-sm font-medium",
  };

  const base = `inline-flex items-center justify-center h-[52px] rounded-md px-8 text-[16px] tracking-[0.32px] transition-transform ${variants[variant]}`;

  const Component = href ? motion(Link) : motion.button;

  return (
    <Component
      href={href || ""}
      onClick={onClick}
      className={`${base} ${variant === "hero" ? "rounded-full" : ""} ${className}`}
      whileHover={{ scale: 0.97 }}
      whileTap={{ scale: 0.95 }}
      transition={{ duration: 0.15 }}
    >
      {children}
    </Component>
  );
}
