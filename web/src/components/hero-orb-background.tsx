"use client";

import { useEffect, useRef, useCallback } from "react";
import { motion, useAnimationControls, useReducedMotion } from "framer-motion";

function randomInRange(min: number, max: number) {
  return Math.random() * (max - min) + min;
}

function OrbLayer({
  colors,
  sizeFactor,
  reducedMotion,
}: {
  colors: { inner: string; outer: string };
  sizeFactor: number;
  reducedMotion: boolean;
}) {
  const controls = useAnimationControls();
  const timeoutRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  const drift = useCallback(() => {
    if (reducedMotion) return;
    controls.start({
      x: randomInRange(-180, 180),
      y: randomInRange(-180, 180),
      scale: randomInRange(0.7, 1.3),
      transition: {
        duration: randomInRange(3, 5.5),
        ease: "easeInOut",
      },
    });
    timeoutRef.current = setTimeout(drift, randomInRange(2500, 4000));
  }, [controls, reducedMotion]);

  useEffect(() => {
    drift();
    return () => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
    };
  }, [drift]);

  return (
    <motion.div
      animate={controls}
      className="absolute inset-0 flex items-center justify-center"
    >
      <div
        className="rounded-full"
        style={{
          width: `${sizeFactor * 160}%`,
          height: `${sizeFactor * 160}%`,
          background: `radial-gradient(circle, ${colors.inner}, ${colors.inner}, ${colors.outer}, ${colors.outer}80)`,
          filter: "blur(60px)",
        }}
      />
    </motion.div>
  );
}

export function HeroOrbBackground() {
  const reducedMotion = useReducedMotion() ?? false;
  const pinkControls = useAnimationControls();
  const timeoutRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  const colorCycle = useCallback(() => {
    if (reducedMotion) return;
    pinkControls.start({ opacity: 1, transition: { duration: 3.5, ease: "easeInOut" } });
    timeoutRef.current = setTimeout(() => {
      pinkControls.start({ opacity: 0, transition: { duration: 3.5, ease: "easeInOut" } });
      timeoutRef.current = setTimeout(colorCycle, 6000);
    }, 6000);
  }, [pinkControls, reducedMotion]);

  useEffect(() => {
    const startDelay = setTimeout(colorCycle, 5000);
    return () => {
      clearTimeout(startDelay);
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
    };
  }, [colorCycle]);

  return (
    <div className="absolute inset-0 overflow-hidden bg-bg-dark rounded-[inherit]">
      <OrbLayer
        colors={{ inner: "#E0B23D", outer: "#96953F" }}
        sizeFactor={1}
        reducedMotion={reducedMotion}
      />
      <motion.div
        animate={pinkControls}
        initial={{ opacity: 0 }}
        className="absolute inset-0"
      >
        <OrbLayer
          colors={{ inner: "#C25D93", outer: "#8F3B43" }}
          sizeFactor={0.95}
          reducedMotion={reducedMotion}
        />
      </motion.div>
    </div>
  );
}
