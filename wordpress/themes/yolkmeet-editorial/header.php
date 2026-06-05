<?php if (!defined('ABSPATH')) { exit; } ?>
<!doctype html>
<html <?php language_attributes(); ?>>
<head>
    <meta charset="<?php bloginfo('charset'); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<header class="site-header">
    <div class="site-shell">
        <div class="masthead">
            <a class="site-brand" href="<?php echo esc_url(home_url('/')); ?>" rel="home">
                <span class="site-brand__name"><?php bloginfo('name'); ?></span>
                <span class="site-brand__deck"><?php bloginfo('description'); ?></span>
            </a>
            <nav class="site-nav" aria-label="<?php esc_attr_e('Primary navigation', 'yolkmeet-editorial'); ?>">
                <?php
                wp_nav_menu([
                    'theme_location' => 'primary',
                    'container' => false,
                    'fallback_cb' => false,
                    'items_wrap' => '%3$s',
                    'depth' => 1,
                ]);
                ?>
            </nav>
        </div>
        <nav class="topic-strip" aria-label="<?php esc_attr_e('Topic navigation', 'yolkmeet-editorial'); ?>">
            <?php
            wp_nav_menu([
                'theme_location' => 'topics',
                'container' => false,
                'fallback_cb' => false,
                'items_wrap' => '%3$s',
                'depth' => 1,
            ]);
            ?>
        </nav>
    </div>
</header>
<main class="site-shell page-grid">
