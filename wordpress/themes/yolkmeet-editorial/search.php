<?php get_header(); ?>
<section>
    <header class="article-header">
        <?php yolkmeet_editorial_breadcrumbs(); ?>
        <p class="eyebrow"><?php esc_html_e('Search', 'yolkmeet-editorial'); ?></p>
        <h1><?php printf(esc_html__('Results for %s', 'yolkmeet-editorial'), esc_html(get_search_query())); ?></h1>
        <?php get_search_form(); ?>
    </header>
    <?php if (have_posts()) : ?>
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
    <?php else : ?>
        <p><?php esc_html_e('No matching notes yet. Try a broader workflow, tool, or automation topic.', 'yolkmeet-editorial'); ?></p>
    <?php endif; ?>
</section>
<?php get_footer(); ?>
