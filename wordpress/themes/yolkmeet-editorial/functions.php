<?php

if (!defined('ABSPATH')) {
    exit;
}

function yolkmeet_editorial_setup(): void
{
    add_theme_support('title-tag');
    add_theme_support('post-thumbnails');
    add_theme_support('html5', ['search-form', 'comment-form', 'comment-list', 'gallery', 'caption', 'style', 'script']);
    add_theme_support('responsive-embeds');
    add_theme_support('align-wide');

    register_nav_menus([
        'primary' => __('Primary navigation', 'yolkmeet-editorial'),
        'topics' => __('Topic navigation', 'yolkmeet-editorial'),
        'footer' => __('Footer navigation', 'yolkmeet-editorial'),
    ]);
}
add_action('after_setup_theme', 'yolkmeet_editorial_setup');

function yolkmeet_editorial_assets(): void
{
    wp_dequeue_style('global-styles');
    wp_dequeue_style('classic-theme-styles');
    wp_enqueue_style('yolkmeet-editorial-style', get_stylesheet_uri(), [], wp_get_theme()->get('Version'));
}
add_action('wp_enqueue_scripts', 'yolkmeet_editorial_assets');

function yolkmeet_editorial_footer_scripts(): void
{
    ?>
    <script>
    document.querySelectorAll('pre').forEach(function (block) {
        if (block.previousElementSibling && block.previousElementSibling.classList.contains('code-copy')) {
            return;
        }
        var button = document.createElement('button');
        button.type = 'button';
        button.className = 'code-copy';
        button.textContent = 'Copy';
        button.addEventListener('click', function () {
            navigator.clipboard.writeText(block.textContent || '');
            button.textContent = 'Copied';
            setTimeout(function () { button.textContent = 'Copy'; }, 1400);
        });
        block.parentNode.insertBefore(button, block);
    });
    </script>
    <?php
}
add_action('wp_footer', 'yolkmeet_editorial_footer_scripts', 20);

remove_action('wp_enqueue_scripts', 'wp_enqueue_global_styles');
remove_action('wp_footer', 'wp_enqueue_global_styles', 1);
remove_action('wp_body_open', 'wp_global_styles_render_svg_filters');

function yolkmeet_editorial_adsense_verification(): void
{
    if (is_admin()) {
        return;
    }

    echo '<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-1424742974208042" crossorigin="anonymous"></script>' . "\n";
}
add_action('wp_head', 'yolkmeet_editorial_adsense_verification', 20);

function yolkmeet_editorial_excerpt(string $fallback = ''): string
{
    $excerpt = get_the_excerpt();
    if ($excerpt !== '') {
        return wp_strip_all_tags($excerpt);
    }

    if ($fallback !== '') {
        return wp_strip_all_tags($fallback);
    }

    return wp_trim_words(wp_strip_all_tags(get_the_content()), 32);
}

function yolkmeet_editorial_primary_category_name(): string
{
    $categories = get_the_category();
    if ($categories === []) {
        return __('Field guide', 'yolkmeet-editorial');
    }

    return $categories[0]->name;
}

function yolkmeet_editorial_breadcrumbs(): void
{
    $items = [
        sprintf('<a href="%s">%s</a>', esc_url(home_url('/')), esc_html__('Home', 'yolkmeet-editorial')),
    ];

    if (is_single()) {
        $category = get_the_category()[0] ?? null;
        if ($category instanceof WP_Term) {
            $items[] = sprintf(
                '<a href="%s">%s</a>',
                esc_url(get_category_link($category)),
                esc_html($category->name)
            );
        }
        $items[] = sprintf('<span aria-current="page">%s</span>', esc_html(get_the_title()));
    } elseif (is_page()) {
        $items[] = sprintf('<span aria-current="page">%s</span>', esc_html(get_the_title()));
    } elseif (is_archive()) {
        $items[] = sprintf('<span aria-current="page">%s</span>', esc_html(wp_strip_all_tags(get_the_archive_title())));
    } elseif (is_search()) {
        $items[] = sprintf('<span aria-current="page">%s</span>', esc_html__('Search', 'yolkmeet-editorial'));
    }

    printf(
        '<nav class="breadcrumb" aria-label="%1$s">%2$s</nav>',
        esc_attr__('Breadcrumb', 'yolkmeet-editorial'),
        implode('<span aria-hidden="true">/</span>', $items)
    );
}

function yolkmeet_editorial_reading_time(): string
{
    $word_count = str_word_count(wp_strip_all_tags(get_the_content()));
    $minutes = max(1, (int) ceil($word_count / 220));
    return sprintf(_n('%d min read', '%d min read', $minutes, 'yolkmeet-editorial'), $minutes);
}

function yolkmeet_editorial_render_ad_slot(string $position, bool $mobile_safe = false): void
{
    $slot = sanitize_html_class($position);
    $classes = 'ad-slot ad-' . $slot;
    if ($mobile_safe) {
        $classes .= ' ad-slot--mobile-safe';
    }
    printf(
        '<aside class="%1$s" aria-label="%2$s"><span>%3$s</span></aside>',
        esc_attr($classes),
        esc_attr__('Advertisement placeholder', 'yolkmeet-editorial'),
        esc_html(sprintf(__('Advertisement reserved: %s', 'yolkmeet-editorial'), $position))
    );
}

function yolkmeet_editorial_post_meta(): void
{
    printf(
        '<div class="post-meta"><span>%1$s</span><span>%2$s</span><span>%3$s</span></div>',
        esc_html(get_the_date('M j, Y')),
        esc_html(yolkmeet_editorial_reading_time()),
        esc_html__('Tested editorial format', 'yolkmeet-editorial')
    );
}

function yolkmeet_editorial_related_posts(): WP_Query
{
    $category_ids = wp_get_post_categories(get_the_ID());
    $args = [
        'post__not_in' => [get_the_ID()],
        'posts_per_page' => 3,
        'ignore_sticky_posts' => true,
    ];

    if ($category_ids !== []) {
        $args['category__in'] = $category_ids;
    }

    return new WP_Query($args);
}
