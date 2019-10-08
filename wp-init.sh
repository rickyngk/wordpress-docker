RUN sed -i "/WP_DEBUG.*/a define('FS_METHOD', 'direct');" /var/www/html/wp-config.php 
RUN chown -R www-data:www-data /var/www/html/wp-content/themes
RUN chown -R www-data:www-data /var/www/html/wp-content/plugins
RUN mkdir -p /var/www/html/wp-content/uploads/
RUN chown -R www-data:www-data /var/www/html/wp-content/uploads/
# execute apache
exec "apache2-foreground"

