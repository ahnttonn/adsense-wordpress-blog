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
        <section id="quick-answer" class="quick-answer">
            <strong><?php esc_html_e('Quick answer', 'yolkmeet-editorial'); ?></strong>
            <p><?php echo esc_html(yolkmeet_editorial_excerpt(__('This guide summarizes the practical decision first, then shows the evidence and workflow details.', 'yolkmeet-editorial'))); ?></p>
        </section>
        <nav class="toc" aria-label="<?php esc_attr_e('Table of contents', 'yolkmeet-editorial'); ?>">
            <h2><?php esc_html_e('Table of contents', 'yolkmeet-editorial'); ?></h2>
            <ol>
                <li><a href="#quick-answer"><?php esc_html_e('Quick answer', 'yolkmeet-editorial'); ?></a></li>
                <li><a href="#article-body"><?php esc_html_e('Workflow details', 'yolkmeet-editorial'); ?></a></li>
                <li><a href="#source-notes"><?php esc_html_e('Evidence and citations', 'yolkmeet-editorial'); ?></a></li>
                <li><a href="#frequently-asked-questions"><?php esc_html_e('Frequently asked questions', 'yolkmeet-editorial'); ?></a></li>
                <li><a href="#update-log"><?php esc_html_e('Update log', 'yolkmeet-editorial'); ?></a></li>
            </ol>
        </nav>
        <div id="article-body" class="article-content">
            <?php the_content(); ?>
        </div>
        <section class="author-box">
            <h2><?php esc_html_e('Author and review note', 'yolkmeet-editorial'); ?></h2>
            <p><?php esc_html_e('By the YOLKMEET editorial desk. Reviewed for workflow clarity, source notes, and update assumptions before publication.', 'yolkmeet-editorial'); ?></p>
        </section>
        <section id="source-notes" class="source-note">
            <h2><?php esc_html_e('Source notes', 'yolkmeet-editorial'); ?></h2>
            <p><?php esc_html_e('Every guide should preserve tested inputs, source URLs, and assumptions so readers can verify the workflow before adopting it.', 'yolkmeet-editorial'); ?></p>
            <?php $source_urls = yolkmeet_editorial_post_source_urls(); ?>
            <?php if ($source_urls !== []) : ?>
                <ul class="citation-list">
                    <?php foreach ($source_urls as $source_url) : ?>
                        <li><a href="<?php echo esc_url($source_url); ?>"><?php echo esc_html($source_url); ?></a></li>
                    <?php endforeach; ?>
                </ul>
            <?php else : ?>
                <p class="source-note__empty"><?php esc_html_e('No external source URLs have been attached to this guide yet.', 'yolkmeet-editorial'); ?></p>
            <?php endif; ?>
        </section>
        <section id="frequently-asked-questions" class="faq-block">
            <h2><?php esc_html_e('Frequently asked questions', 'yolkmeet-editorial'); ?></h2>
            <?php foreach (yolkmeet_editorial_faq_items() as $faq_item) : ?>
                <details>
                    <summary><?php echo esc_html($faq_item['question']); ?></summary>
                    <p><?php echo esc_html($faq_item['answer']); ?></p>
                </details>
            <?php endforeach; ?>
        </section>
        <section id="update-log" class="update-log">
            <h2><?php esc_html_e('Update log', 'yolkmeet-editorial'); ?></h2>
            <p>
                <?php
                printf(
                    esc_html__('Launch baseline created with public crawler access and AdSense verification in place. Last WordPress update: %s. Future updates should record tool changes, pricing shifts, and retested steps.', 'yolkmeet-editorial'),
                    esc_html(get_the_modified_date('M j, Y'))
                );
                ?>
            </p>
        </section>
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
    </aside>
</article>
<?php endwhile; ?>
<?php get_footer(); ?>
