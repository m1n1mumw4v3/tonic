"use client";

import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Link from "next/link";
import Image from "next/image";

export function Navigation() {
  const [overDark, setOverDark] = useState(false);
  const [hidden, setHidden] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const lastScrollY = useRef(0);

  useEffect(() => {
    const hero = document.querySelector("[data-hero]");
    if (!hero) return;
    const observer = new IntersectionObserver(
      ([entry]) => setOverDark(entry.isIntersecting),
      { rootMargin: "-1px 0px -95% 0px" }
    );
    observer.observe(hero);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    const handleScroll = () => {
      const y = window.scrollY;
      if (y < 100) {
        setHidden(false);
      } else {
        setHidden(y > lastScrollY.current);
      }
      lastScrollY.current = y;
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  useEffect(() => {
    if (menuOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [menuOpen]);

  return (
    <>
      <nav className={`fixed top-0 left-0 right-0 z-50 flex justify-center px-6 pt-4 transition-transform duration-300 ${hidden && !menuOpen ? "-translate-y-full" : "translate-y-0"}`}>
        <div className="flex items-center justify-between w-full max-w-6xl">
          <Link href="/" className="flex-shrink-0">
            <Image
              src="/images/estus-logo-01.png"
              alt="Estus"
              width={64}
              height={20}
              className={`h-5 w-auto transition-all duration-300 ${overDark ? "brightness-0 invert" : ""}`}
            />
          </Link>

          {/* Desktop glass pill */}
          <div className="hidden md:flex items-center gap-1 bg-white/40 backdrop-blur-xl border border-white/50 rounded-full px-1.5 py-1.5 shadow-[0_1px_8px_rgba(0,0,0,0.06),inset_0_1px_0_rgba(255,255,255,0.5)]">
            <Link
              href="/about"
              className={`text-[16px] font-medium rounded-full px-4 py-1.5 transition-all duration-300 ${overDark ? "text-white hover:bg-white/20" : "text-text-primary/70 hover:text-text-primary hover:bg-white/50"}`}
            >
              About
            </Link>
            <Link
              href="/blog"
              className={`text-[16px] font-medium rounded-full px-4 py-1.5 transition-all duration-300 ${overDark ? "text-white hover:bg-white/20" : "text-text-primary/70 hover:text-text-primary hover:bg-white/50"}`}
            >
              Blog
            </Link>
            <a
              href="#"
              className={`rounded-full px-4 py-1.5 text-[16px] font-semibold hover:scale-[0.97] active:scale-[0.95] transition-all duration-300 ${overDark ? "bg-white text-text-primary" : "bg-text-primary text-bg-deepest"}`}
            >
              Download App
            </a>
          </div>

          {/* Mobile hamburger */}
          <button
            onClick={() => setMenuOpen(!menuOpen)}
            className="md:hidden flex flex-col justify-center items-center w-10 h-10 gap-1.5"
            aria-label={menuOpen ? "Close menu" : "Open menu"}
          >
            <motion.span
              animate={menuOpen ? { rotate: 45, y: 6 } : { rotate: 0, y: 0 }}
              className="block w-5 h-[1.5px] bg-text-primary origin-center"
              transition={{ duration: 0.2 }}
            />
            <motion.span
              animate={menuOpen ? { opacity: 0 } : { opacity: 1 }}
              className="block w-5 h-[1.5px] bg-text-primary"
              transition={{ duration: 0.15 }}
            />
            <motion.span
              animate={
                menuOpen ? { rotate: -45, y: -6 } : { rotate: 0, y: 0 }
              }
              className="block w-5 h-[1.5px] bg-text-primary origin-center"
              transition={{ duration: 0.2 }}
            />
          </button>
        </div>
      </nav>

      {/* Mobile menu overlay */}
      <AnimatePresence>
        {menuOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-40 bg-bg-deepest pt-20"
          >
            <div className="flex flex-col items-center gap-8 pt-12">
              {[
                { href: "/about", label: "About" },
                { href: "/blog", label: "Blog" },
              ].map((link, i) => (
                <motion.div
                  key={link.href}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.1, duration: 0.3, ease: "easeOut" }}
                >
                  <Link
                    href={link.href}
                    onClick={() => setMenuOpen(false)}
                    className="text-[28px] font-light text-text-primary"
                  >
                    {link.label}
                  </Link>
                </motion.div>
              ))}
              <motion.div
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2, duration: 0.3, ease: "easeOut" }}
              >
                <a
                  href="#"
                  className="bg-text-primary text-bg-deepest rounded-full px-8 py-3 text-[16px] font-semibold"
                >
                  Download
                </a>
              </motion.div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
