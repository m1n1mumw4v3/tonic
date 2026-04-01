import type { MDXComponents } from "mdx/types";

export function useMDXComponents(components: MDXComponents): MDXComponents {
  return {
    h1: ({ children }) => (
      <h1 className="text-[32px] font-light text-text-primary mb-6 mt-12 first:mt-0">
        {children}
      </h1>
    ),
    h2: ({ children }) => (
      <h2 className="text-[28px] font-light text-text-primary mb-4 mt-10">
        {children}
      </h2>
    ),
    h3: ({ children }) => (
      <h3 className="text-[20px] font-semibold text-text-primary mb-3 mt-8">
        {children}
      </h3>
    ),
    p: ({ children }) => (
      <p className="text-[16px] leading-relaxed text-text-primary mb-4">
        {children}
      </p>
    ),
    a: ({ href, children }) => (
      <a href={href} className="text-info underline underline-offset-2 hover:opacity-80 transition-opacity">
        {children}
      </a>
    ),
    blockquote: ({ children }) => (
      <blockquote className="border-l-[3px] border-accent-clarity pl-4 my-6 text-text-secondary italic">
        {children}
      </blockquote>
    ),
    code: ({ children }) => (
      <code className="font-mono text-[14px] bg-bg-elevated rounded-sm px-1.5 py-0.5">
        {children}
      </code>
    ),
    pre: ({ children }) => (
      <pre className="bg-bg-dark text-bg-deepest rounded-md p-4 overflow-x-auto my-6 text-[14px] font-mono">
        {children}
      </pre>
    ),
    ul: ({ children }) => (
      <ul className="list-disc list-inside mb-4 space-y-1 text-text-primary">
        {children}
      </ul>
    ),
    ol: ({ children }) => (
      <ol className="list-decimal list-inside mb-4 space-y-1 text-text-primary">
        {children}
      </ol>
    ),
    hr: () => <hr className="border-border-default my-8" />,
    ...components,
  };
}
