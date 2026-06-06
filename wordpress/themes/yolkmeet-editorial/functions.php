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
add_action('wp_head', 'yolkmeet_editorial_adsense_verification', 20); // adsense verification snippet in head

function yolkmeet_editorial_ga4_measurement_id(): string
{
    $measurement_id = defined('YOLKMEET_GA4_MEASUREMENT_ID') ? (string) YOLKMEET_GA4_MEASUREMENT_ID : '';
    if ($measurement_id === '') {
        $measurement_id = (string) get_option('_yolkmeet_ga4_measurement_id', '');
    }

    return trim($measurement_id);
}

function yolkmeet_editorial_analytics(): void
{
    if (is_admin()) {
        return;
    }

    $measurement_id = yolkmeet_editorial_ga4_measurement_id();
    if ($measurement_id === '') {
        return;
    }

    $measurement_id_js = wp_json_encode($measurement_id);
    echo "<script async src=\"https://www.googletagmanager.com/gtag/js?id=" . esc_attr($measurement_id) . "\"></script>\n";
    echo "<script>window.dataLayer = window.dataLayer || [];function gtag(){dataLayer.push(arguments);}gtag('js', new Date());gtag('config', " . $measurement_id_js . ", { 'anonymize_ip': true, 'allow_google_signals': false, 'allow_ad_personalization_signals': false });</script>\n";
}
add_action('wp_head', 'yolkmeet_editorial_analytics', 21);

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

function yolkmeet_editorial_post_source_urls(int $post_id = 0): array
{
    $post_id = $post_id > 0 ? $post_id : get_the_ID();
    $raw_urls = (string) get_post_meta($post_id, '_yolkmeet_source_urls', true);
    if ($raw_urls === '') {
        return [];
    }

    $urls = preg_split('/[\r\n,]+/', $raw_urls) ?: [];
    $clean_urls = [];
    foreach ($urls as $url) {
        $clean_url = esc_url_raw(trim($url));
        if ($clean_url !== '') {
            $clean_urls[$clean_url] = $clean_url;
        }
    }

    return array_values($clean_urls);
}

function yolkmeet_editorial_faq_items(): array
{
    $title = wp_strip_all_tags(get_the_title());
    $summary = yolkmeet_editorial_excerpt(__('Use this article to make the first decision, then verify the assumptions and source notes before adopting the workflow.', 'yolkmeet-editorial'));

    return [
        [
            'question' => sprintf(__('What is the fastest way to use %s?', 'yolkmeet-editorial'), $title),
            'answer' => $summary,
        ],
        [
            'question' => __('What should readers verify before copying the workflow?', 'yolkmeet-editorial'),
            'answer' => __('Check the source URLs, rerun the workflow with your own inputs, and record any pricing, policy, or tool changes that affect the recommendation.', 'yolkmeet-editorial'),
        ],
        [
            'question' => __('How does YOLKMEET keep the guide current?', 'yolkmeet-editorial'),
            'answer' => __('Each guide keeps a visible update note so changed assumptions, retests, and source revisions can be reviewed without hiding the editorial history.', 'yolkmeet-editorial'),
        ],
    ];
}

function yolkmeet_editorial_meta_description(): void
{
    if (!is_singular(['post', 'page'])) {
        return;
    }

    printf(
        '<meta name="description" content="%s">' . "\n",
        esc_attr(wp_trim_words(yolkmeet_editorial_excerpt(), 28, '...'))
    );
}
add_action('wp_head', 'yolkmeet_editorial_meta_description', 2);

function yolkmeet_editorial_robots(array $robots): array
{
    if (is_singular('post')) {
        $robots['max-snippet'] = -1;
        $robots['max-image-preview'] = 'large';
        $robots['max-video-preview'] = -1;
    }

    return $robots;
}
add_filter('wp_robots', 'yolkmeet_editorial_robots');

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

function yolkmeet_editorial_breadcrumb_schema(): array
{
    $items = [
        [
            '@type' => 'ListItem',
            'position' => 1,
            'name' => get_bloginfo('name'),
            'item' => home_url('/'),
        ],
    ];

    $position = 2;
    $category = get_the_category()[0] ?? null;
    if ($category instanceof WP_Term) {
        $items[] = [
            '@type' => 'ListItem',
            'position' => $position,
            'name' => $category->name,
            'item' => get_category_link($category),
        ];
        $position++;
    }

    $items[] = [
        '@type' => 'ListItem',
        'position' => $position,
        'name' => wp_strip_all_tags(get_the_title()),
        'item' => get_permalink(),
    ];

    return [
        '@context' => 'https://schema.org',
        '@type' => 'BreadcrumbList',
        'itemListElement' => $items,
    ];
}

function yolkmeet_editorial_article_schema(): void
{
    if (!is_singular('post')) {
        return;
    }

    $post_id = get_the_ID();
    $author_id = (int) get_post_field('post_author', $post_id);
    $source_urls = yolkmeet_editorial_post_source_urls($post_id);
    $article = [
        '@context' => 'https://schema.org',
        '@type' => 'BlogPosting',
        'mainEntityOfPage' => [
            '@type' => 'WebPage',
            '@id' => get_permalink($post_id),
        ],
        'headline' => wp_strip_all_tags(get_the_title($post_id)),
        'description' => yolkmeet_editorial_excerpt(),
        'datePublished' => get_the_date(DATE_W3C, $post_id),
        'dateModified' => get_the_modified_date(DATE_W3C, $post_id),
        'author' => [
            '@type' => 'Person',
            'name' => get_the_author_meta('display_name', $author_id) ?: get_bloginfo('name'),
        ],
        'publisher' => [
            '@type' => 'Organization',
            'name' => get_bloginfo('name'),
            'url' => home_url('/'),
        ],
        'articleSection' => yolkmeet_editorial_primary_category_name(),
        'isAccessibleForFree' => true,
    ];

    if (has_post_thumbnail($post_id)) {
        $image_url = get_the_post_thumbnail_url($post_id, 'full');
        if ($image_url !== false) {
            $article['image'] = [$image_url];
        }
    }

    if ($source_urls !== []) {
        $article['citation'] = $source_urls;
    }

    $faq_entities = [];
    foreach (yolkmeet_editorial_faq_items() as $item) {
        $faq_entities[] = [
            '@type' => 'Question',
            'name' => $item['question'],
            'acceptedAnswer' => [
                '@type' => 'Answer',
                'text' => $item['answer'],
            ],
        ];
    }

    $schema_graph = [
        $article,
        yolkmeet_editorial_breadcrumb_schema(),
        [
            '@context' => 'https://schema.org',
            '@type' => 'FAQPage',
            'mainEntity' => $faq_entities,
        ],
    ];

    echo '<script type="application/ld+json">' . wp_json_encode($schema_graph, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . '</script>' . "\n";
}
add_action('wp_head', 'yolkmeet_editorial_article_schema', 12);

function yolkmeet_editorial_reading_time(): string
{
    $word_count = str_word_count(wp_strip_all_tags(get_the_content()));
    $minutes = max(1, (int) ceil($word_count / 220));
    return sprintf(_n('%d min read', '%d min read', $minutes, 'yolkmeet-editorial'), $minutes);
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
