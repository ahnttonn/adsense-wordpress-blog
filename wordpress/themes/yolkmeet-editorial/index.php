<?php get_header(); ?>
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
            <ul class="post-list">
                <?php $organic_count = 0; ?>
                <?php while (have_posts()) : the_post(); ?>
                    <?php $organic_count++; ?>
                    <li>
                        <article class="story-card">
                            <p class="eyebrow"><?php echo esc_html(yolkmeet_editorial_primary_category_name()); ?></p>
                            <h2><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
                            <?php yolkmeet_editorial_post_meta(); ?>
                            <p><?php echo esc_html(yolkmeet_editorial_excerpt()); ?></p>
                        </article>
                    </li>
                    <?php if ($organic_count === 6) : ?>
                        <li><?php yolkmeet_editorial_render_ad_slot('homepage feed after six organic items'); ?></li>
                    <?php endif; ?>
                <?php endwhile; ?>
            </ul>
            <?php if ($organic_count < 6) : ?>
                <?php yolkmeet_editorial_render_ad_slot('infeed'); ?>
            <?php endif; ?>
        <?php else : ?>
            <article class="lead-story">
                <p class="eyebrow"><?php esc_html_e('Launch desk', 'yolkmeet-editorial'); ?></p>
                <h1><?php esc_html_e('AI automation guides are being prepared.', 'yolkmeet-editorial'); ?></h1>
                <p class="dek"><?php esc_html_e('Yolkmeet is setting up source-aware guides, comparisons, and workflow notes.', 'yolkmeet-editorial'); ?></p>
            </article>
        <?php endif; ?>
    </div>
    <aside class="rail">
        <section class="rail-panel">
            <h2><?php esc_html_e('Comparison Hub', 'yolkmeet-editorial'); ?></h2>
            <p><?php esc_html_e('Tool alternatives, pricing checks, workflow fit, and testing notes will be grouped here.', 'yolkmeet-editorial'); ?></p>
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
