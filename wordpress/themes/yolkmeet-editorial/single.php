<?php get_header(); ?>
<?php while (have_posts()) : the_post(); ?>
<article class="article-layout">
    <div class="article-main">
        <header class="article-header">
            <?php yolkmeet_editorial_breadcrumbs(); ?>
            <p class="eyebrow"><?php echo esc_html(yolkmeet_editorial_primary_category_name()); ?></p>
            <h1><?php the_title(); ?></h1>
            <?php yolkmeet_editorial_post_meta(); ?>
            <p class="dek"><?php echo esc_html(yolkmeet_editorial_excerpt()); ?></p>
        </header>
        <section class="quick-answer">
            <strong><?php esc_html_e('Quick answer', 'yolkmeet-editorial'); ?></strong>
            <p><?php echo esc_html(yolkmeet_editorial_excerpt(__('This guide summarizes the practical decision first, then shows the evidence and workflow details.', 'yolkmeet-editorial'))); ?></p>
        </section>
        <?php yolkmeet_editorial_render_ad_slot('top', true); ?>
        <div class="article-content">
            <?php the_content(); ?>
        </div>
        <?php yolkmeet_editorial_render_ad_slot('mid', true); ?>
        <section class="author-box">
            <h2><?php esc_html_e('Author and review note', 'yolkmeet-editorial'); ?></h2>
            <p><?php esc_html_e('By the Yolkmeet editorial desk. Reviewed for workflow clarity, source notes, and update assumptions before publication.', 'yolkmeet-editorial'); ?></p>
        </section>
        <section class="source-note">
            <h2><?php esc_html_e('Source notes', 'yolkmeet-editorial'); ?></h2>
            <p><?php esc_html_e('Every guide should preserve tested inputs, source URLs, and assumptions so readers can verify the workflow before adopting it.', 'yolkmeet-editorial'); ?></p>
        </section>
        <section class="update-log">
            <h2><?php esc_html_e('Update log', 'yolkmeet-editorial'); ?></h2>
            <p><?php esc_html_e('Launch baseline created with public crawler access and AdSense verification in place. Future updates should record tool changes, pricing shifts, and retested steps.', 'yolkmeet-editorial'); ?></p>
        </section>
        <?php yolkmeet_editorial_render_ad_slot('end', true); ?>
        <?php $related = yolkmeet_editorial_related_posts(); ?>
        <section class="related-posts">
            <h2><?php esc_html_e('Related reading', 'yolkmeet-editorial'); ?></h2>
            <?php if ($related->have_posts()) : ?>
                <ul class="post-list">
                    <?php while ($related->have_posts()) : $related->the_post(); ?>
                        <li><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></li>
                    <?php endwhile; wp_reset_postdata(); ?>
                </ul>
            <?php else : ?>
                <p><?php esc_html_e('Related workflow notes will appear here as the launch library grows.', 'yolkmeet-editorial'); ?></p>
            <?php endif; ?>
        </section>
    </div>
    <aside class="article-rail">
        <section class="rail-panel">
            <h2><?php esc_html_e('Reading map', 'yolkmeet-editorial'); ?></h2>
            <p><?php esc_html_e('Decision, setup notes, comparison table, source notes, and next actions.', 'yolkmeet-editorial'); ?></p>
        </section>
        <?php yolkmeet_editorial_render_ad_slot('rail'); ?>
    </aside>
</article>
<?php endwhile; ?>
<?php get_footer(); ?>
