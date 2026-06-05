<form role="search" method="get" class="search-form" action="<?php echo esc_url(home_url('/')); ?>">
    <label class="screen-reader-text" for="s"><?php esc_html_e('Search for:', 'yolkmeet-editorial'); ?></label>
    <input type="search" id="s" name="s" value="<?php echo esc_attr(get_search_query()); ?>" placeholder="<?php esc_attr_e('Search workflows, tools, and comparisons', 'yolkmeet-editorial'); ?>">
    <input type="submit" value="<?php esc_attr_e('Search', 'yolkmeet-editorial'); ?>">
</form>
