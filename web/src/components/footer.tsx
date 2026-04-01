import Link from "next/link";
import Image from "next/image";

export function Footer() {
  return (
    <footer className="bg-bg-dark text-bg-deepest">
      {/* Spectrum bar */}
      <div className="bg-spectrum h-[3px]" />

      <div className="mx-auto max-w-6xl px-6 py-16">
        <div className="flex flex-col md:flex-row md:justify-between gap-12">
          {/* Logo & tagline */}
          <div>
            <Image
              src="/images/estus-logo-01.png"
              alt="Estus"
              width={80}
              height={24}
              className="h-6 w-auto brightness-0 invert mb-4"
            />
          </div>

          <div className="flex gap-[80px]">
{/* Company */}
          <div className="">
            <h3 className="text-[16px] font-semibold uppercase tracking-[1.5px] text-text-secondary mb-4">
              Company
            </h3>
            <ul className="space-y-3">
              <li>
                <Link
                  href="/about"
                  className="text-[16px] text-text-tertiary hover:text-bg-deepest transition-colors"
                >
                  About
                </Link>
              </li>
              <li>
                <Link
                  href="/blog"
                  className="text-[16px] text-text-tertiary hover:text-bg-deepest transition-colors"
                >
                  Blog
                </Link>
              </li>
            </ul>
          </div>

          {/* Legal */}
          <div className="">
            <h3 className="text-[16px] font-semibold uppercase tracking-[1.5px] text-text-secondary mb-4">
              Legal
            </h3>
            <ul className="space-y-3">
              <li>
                <a
                  href="#"
                  className="text-[16px] text-text-tertiary hover:text-bg-deepest transition-colors"
                >
                  Privacy Policy
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-[16px] text-text-tertiary hover:text-bg-deepest transition-colors"
                >
                  Terms of Service
                </a>
              </li>
            </ul>
          </div>
          </div>
        </div>

        {/* Bottom row */}
        <div className="mt-16 pt-6 border-t border-white/10 text-[13px] text-text-tertiary">
          &copy; {new Date().getFullYear()} Estus. All rights reserved.
        </div>
      </div>
    </footer>
  );
}
