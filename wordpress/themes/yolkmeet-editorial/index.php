<?php get_header(); ?>
<?php
$operator_topics = [
    [
        'slug' => 'ai-tool-comparisons',
        'label' => __('Tool Comparisons', 'yolkmeet-editorial'),
        'description' => __('Pricing checks, alternatives, fit notes, and switching tradeoffs.', 'yolkmeet-editorial'),
    ],
    [
        'slug' => 'ai-workflow-automation',
        'label' => __('Workflow Automation', 'yolkmeet-editorial'),
        'description' => __('Repeatable systems, approval steps, and practical automation stacks.', 'yolkmeet-editorial'),
    ],
    [
        'slug' => 'ai-research-playbooks',
        'label' => __('Research Playbooks', 'yolkmeet-editorial'),
        'description' => __('Source-aware research workflows, checks, and reusable investigation steps.', 'yolkmeet-editorial'),
    ],
    [
        'slug' => 'ai-marketing-ops',
        'label' => __('Marketing Ops', 'yolkmeet-editorial'),
        'description' => __('Campaign operations, reporting loops, and lightweight content systems.', 'yolkmeet-editorial'),
    ],
    [
        'slug' => 'ai-prompt-systems',
        'label' => __('Prompt Systems', 'yolkmeet-editorial'),
        'description' => __('Reusable prompt libraries, checking patterns, and ready-to-use templates.', 'yolkmeet-editorial'),
    ],
];
?>
<section class="home-layout">
    <div>
        <?php if (have_posts()) : ?>
            <?php the_post(); ?>
            <article class="lead-story">
                <p class="eyebrow"><?php esc_html_e('Field guide', 'yolkmeet-editorial'); ?></p>
                <h1><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h1>
                <?php yolkmeet_editorial_post_meta(); ?>
                <p class="dek"><?php echo esc_html(yolkmeet_editorial_excerpt()); ?></p>
            </article>
            <section class="topic-discovery" aria-labelledby="topic-discovery-heading">
                <p class="eyebrow"><?php esc_html_e('Operator Tech Map', 'yolkmeet-editorial'); ?></p>
                <h2 id="topic-discovery-heading"><?php esc_html_e('Browse by topic', 'yolkmeet-editorial'); ?></h2>
                <div class="topic-grid">
                    <?php foreach ($operator_topics as $topic) : ?>
                        <?php
                        $category = get_category_by_slug($topic['slug']);
                        $topic_url = $category instanceof WP_Term ? get_category_link($category) : home_url('/category/' . $topic['slug'] . '/');
                        $count = $category instanceof WP_Term ? (int) $category->count : 0;
                        ?>
                        <a class="topic-link" href="<?php echo esc_url($topic_url); ?>">
                            <span><?php echo esc_html($topic['label']); ?></span>
                            <small>
                                <?php echo esc_html($topic['description']); ?>
                                <?php if ($count > 0) : ?>
                                    <?php printf(esc_html(_n('%d guide', '%d guides', $count, 'yolkmeet-editorial')), $count); ?>
                                <?php endif; ?>
                            </small>
                        </a>
                    <?php endforeach; ?>
                </div>
            </section>
            <ul class="post-list">
                <?php while (have_posts()) : the_post(); ?>
                    <li>
                        <article class="story-card">
                            <p class="eyebrow"><?php echo esc_html(yolkmeet_editorial_primary_category_name()); ?></p>
                            <h2><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
                            <?php yolkmeet_editorial_post_meta(); ?>
                            <p><?php echo esc_html(yolkmeet_editorial_excerpt()); ?></p>
                        </article>
                    </li>
                <?php endwhile; ?>
            </ul>
        <?php else : ?>
            <article class="lead-story">
                <p class="eyebrow"><?php esc_html_e('Coming soon', 'yolkmeet-editorial'); ?></p>
                <h1><?php esc_html_e('Operator-tech guides are being prepared.', 'yolkmeet-editorial'); ?></h1>
                <p class="dek"><?php esc_html_e('YOLKMEET tracks source-aware operator-tech guides, automation playbooks, and workflow comparisons.', 'yolkmeet-editorial'); ?></p>
            </article>
        <?php endif; ?>
    </div>
    <aside class="rail">
        <section class="rail-panel">
            <h2><?php esc_html_e('Operator Tech Map', 'yolkmeet-editorial'); ?></h2>
            <p><?php esc_html_e('Tool comparisons, workflow automation, research playbooks, marketing operations, and prompt systems are tracked as separate reading paths.', 'yolkmeet-editorial'); ?></p>
        </section>
        <section class="rail-panel">
            <h2><?php esc_html_e('Topics', 'yolkmeet-editorial'); ?></h2>
            <ul class="taxonomy-list">
                <?php wp_list_categories(['title_li' => '', 'number' => 8]); ?>
            </ul>
        </section>
    </aside>
</section>
<?php get_footer(); ?>
