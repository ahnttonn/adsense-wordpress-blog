<?php get_header(); ?>
<section class="home-layout">
    <div>
        <header class="article-header">
            <p class="eyebrow"><?php esc_html_e('Topic hub', 'yolkmeet-editorial'); ?></p>
            <h1><?php the_archive_title(); ?></h1>
            <?php the_archive_description('<p class="dek">', '</p>'); ?>
        </header>
        <ul class="post-list">
            <?php while (have_posts()) : the_post(); ?>
                <li>
                    <article class="story-card">
                        <h2><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
                        <?php yolkmeet_editorial_post_meta(); ?>
                        <p><?php echo esc_html(yolkmeet_editorial_excerpt()); ?></p>
                    </article>
                </li>
            <?php endwhile; ?>
        </ul>
        <?php yolkmeet_editorial_render_ad_slot('infeed'); ?>
    </div>
    <aside class="rail">
        <section class="rail-panel">
            <h2><?php esc_html_e('Pillar guides and glossary', 'yolkmeet-editorial'); ?></h2>
            <p><?php esc_html_e('Start with pillar guides, then compare tools, pricing, alternatives, and workflow recipes.', 'yolkmeet-editorial'); ?></p>
        </section>
    </aside>
</section>
<?php get_footer(); ?>
