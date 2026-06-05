<?php get_header(); ?>
<?php while (have_posts()) : the_post(); ?>
<article class="article-main">
    <header class="article-header">
        <?php yolkmeet_editorial_breadcrumbs(); ?>
        <p class="eyebrow"><?php esc_html_e('Publication page', 'yolkmeet-editorial'); ?></p>
        <h1><?php the_title(); ?></h1>
    </header>
    <div class="article-content">
        <?php the_content(); ?>
    </div>
</article>
<?php endwhile; ?>
<?php get_footer(); ?>
