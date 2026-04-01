import { notFound } from "next/navigation";
import Link from "next/link";
import { getAllPosts, getPostSlugs } from "@/lib/mdx";

export function generateStaticParams() {
  return getPostSlugs().map((slug) => ({ slug }));
}

export const dynamicParams = false;

export default async function BlogPost({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const posts = getAllPosts();
  const post = posts.find((p) => p.slug === slug);

  if (!post) notFound();

  let MDXContent;
  try {
    MDXContent = (await import(`@/content/blog/${slug}.mdx`)).default;
  } catch {
    notFound();
  }

  return (
    <div className="pt-28 pb-20">
      <div className="mx-auto max-w-[720px] px-6">
        <Link
          href="/blog"
          className="inline-block text-[13px] text-text-secondary hover:text-text-primary transition-colors mb-8"
        >
          &larr; Back to blog
        </Link>

        <article>
          <header className="mb-10">
            <div className="flex gap-2 mb-4">
              {post.tags.map((tag) => (
                <span
                  key={tag}
                  className="text-[11px] font-mono uppercase tracking-[1.2px] text-accent-immunity bg-accent-immunity/10 rounded-full px-2.5 py-1"
                >
                  {tag}
                </span>
              ))}
            </div>

            <h1 className="text-[32px] font-light text-text-primary mb-3 leading-tight">
              {post.title}
            </h1>

            <div className="text-[13px] text-text-tertiary">
              {new Date(post.date).toLocaleDateString("en-US", {
                year: "numeric",
                month: "long",
                day: "numeric",
              })}
              {" · "}
              {post.author}
            </div>
          </header>

          <div className="prose-estus">
            <MDXContent />
          </div>
        </article>
      </div>
    </div>
  );
}
