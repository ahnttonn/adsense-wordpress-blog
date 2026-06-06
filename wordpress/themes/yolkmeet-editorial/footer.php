<?php if (!defined('ABSPATH')) { exit; } ?>
</main>
<footer class="site-footer">
    <div class="site-shell footer-grid">
        <div>
            <strong><?php bloginfo('name'); ?></strong>
            <p><?php esc_html_e('Practical operator-tech field guides, automation playbooks, workflow comparisons, and source-aware editorial standards.', 'yolkmeet-editorial'); ?></p>
        </div>
        <nav aria-label="<?php esc_attr_e('Footer navigation', 'yolkmeet-editorial'); ?>">
            <?php
            wp_nav_menu([
                'theme_location' => 'footer',
                'container' => false,
                'fallback_cb' => false,
                'items_wrap' => '%3$s',
                'depth' => 1,
            ]);
            ?>
        </nav>
    </div>
</footer>
<?php wp_footer(); ?>
</body>
</html>
