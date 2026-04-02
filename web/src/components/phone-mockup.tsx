"use client";

import Image from "next/image";

export function PhoneMockup() {
  return (
    <div
      className="relative mx-auto w-[280px] md:w-[320px] max-h-[440px] md:max-h-[500px] overflow-hidden"
      style={{
        maskImage: "linear-gradient(to bottom, black 50%, transparent 100%)",
        WebkitMaskImage: "linear-gradient(to bottom, black 50%, transparent 100%)",
      }}
    >
      {/* Outer clip to ensure clean rounded shape, no square corners */}
      <div className="rounded-t-[40px] overflow-hidden">
        {/* iPhone bezel */}
        <div className="relative bg-[#1a1a1a] p-[8px] pb-0">
          {/* Screen */}
          <div className="relative rounded-t-[32px] overflow-hidden">
            <Image
              src="/images/app-screenshot.png"
              alt="Estus app home screen"
              width={393}
              height={852}
              className="w-full h-auto"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
