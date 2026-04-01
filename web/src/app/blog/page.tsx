import Link from "next/link";
import { getAllPosts } from "@/lib/mdx";
import { AnimatedEntrance } from "@/components/animated-entrance";
import { SectionHeading } from "@/components/section-heading";

export default function BlogIndex() {
  const posts = getAllPosts();

  return (
    <div className="pt-28 pb-20">
      <div className="mx-auto max-w-4xl px-6">
        <SectionHeading
          label="Blog"
          headline="Insights & Resources"
          subheadline="Ideas, research, and practical advice for building a smarter supplement routine."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {posts.map((post, i) => (
            <AnimatedEntrance key={post.slug} delay={i * 0.1}>
              <Link
                href={`/blog/${post.slug}`}
                className="block bg-bg-surface rounded-md shadow-card p-6 hover:shadow-elevated transition-shadow group"
              >
                {/* Tags */}
                <div className="flex gap-2 mb-3">
                  {post.tags.map((tag) => (
                    <span
                      key={tag}
                      className="text-[11px] font-mono uppercase tracking-[1.2px] text-accent-immunity bg-accent-immunity/10 rounded-full px-2.5 py-1"
                    >
                      {tag}
                    </span>
                  ))}
                </div>

                <h2 className="text-[20px] font-semibold text-text-primary mb-2 group-hover:text-accent-immunity transition-colors">
                  {post.title}
                </h2>

                <p className="text-[14px] text-text-secondary leading-relaxed mb-4">
                  {post.description}
                </p>

                <div className="text-[13px] text-text-tertiary">
                  {new Date(post.date).toLocaleDateString("en-US", {
                    year: "numeric",
                    month: "long",
                    day: "numeric",
                  })}
                  {" · "}
                  {post.author}
                </div>
              </Link>
            </AnimatedEntrance>
          ))}
        </div>

        {posts.length === 0 && (
          <p className="text-center text-text-secondary">
            No posts yet. Check back soon.
          </p>
        )}
      </div>
    </div>
  );
}
