FROM docker.io/bitnami/moodle:5.0

USER root

# Install required packages for localization support, MariaDB client, and theme installation
RUN apt-get update && apt-get install -y \
    locales \
    mariadb-client \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Accept build arguments for locales
# ARG EXTRA_LOCALES

# Generate the requested locales - ensure Vietnamese and Japanese are enabled
# RUN sed -i -e 's/# vi_VN.UTF-8 UTF-8/vi_VN.UTF-8 UTF-8/' /etc/locale.gen && \
#     sed -i -e 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen && \
#     locale-gen

# Copy SQL script, import script and theme application script
# COPY sample_data.sql /opt/bitnami/sample_data.sql
# COPY import-sample-data.sh /opt/bitnami/scripts/import-sample-data.sh
# COPY apply-theme.sh /opt/bitnami/scripts/apply-theme.sh
# RUN chmod +x /opt/bitnami/scripts/import-sample-data.sh && \
#     chmod +x /opt/bitnami/scripts/apply-theme.sh

# Download and install the Academi theme
# RUN mkdir -p /opt/bitnami/moodle/theme/academi && \
#     wget -q -O /tmp/academi.zip https://github.com/lmsace/academi/releases/download/v5.0.1/theme_academi_v-5.0.zip && \
#     unzip -q /tmp/academi.zip -d /tmp && \
#     cp -r /tmp/academi/* /opt/bitnami/moodle/theme/academi/ && \
#     rm -rf /tmp/academi /tmp/academi.zip && \
#     chown -R 1001:1001 /opt/bitnami/moodle/theme/academi

# Switch back to non-root user for better security
# USER 1001
