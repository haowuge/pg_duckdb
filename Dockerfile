# 基于已存在的 pg_duckdb 镜像（假设 :18-main 已包含 PG 18 + pg_duckdb）
FROM pgduckdb/pgduckdb:18-main

USER root

# 1. 安装构建依赖（仅用于 pgjwt）、系统工具、locale、Perl 库等
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trixie-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        # 系统工具
        htop \
        wget \
        ca-certificates \
        net-tools \
        git \
        # 编译 pgjwt 所需
        build-essential \
        libssl-dev \
        postgresql-server-dev-18 \
        # FDW 运行时依赖（即使扩展是预编译的，运行仍需客户端库）
        freetds-bin \
        libmysqlclient21 \
        # Perl 支持
        libdbi-perl \
        libanyevent-dbd-pg-perl \
        # Locale
        locales && \
    # 启用并生成 zh_CN.UTF-8
    sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# 2. 设置中文环境
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 3. 安装所有 PostgreSQL 扩展（尽可能用 APT）
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        postgresql-18-extra-window-functions \
        postgresql-18-first-last-agg \
        postgresql-18-pgaudit \
        postgresql-18-pgauditlogtofile \
        postgresql-18-pgvector \
        postgresql-18-repack \
        postgresql-18-tds-fdw \
        postgresql-18-mysql-fdw \
        postgresql-18-set-user \
        postgresql-18-plpgsql-check \
        postgresql-18-cron \
        postgresql-18-http && \
    rm -rf /var/lib/apt/lists/*

# 4. 手动编译安装 pgjwt（因无官方 APT 包）
RUN cd /tmp && \
    git clone https://github.com/michelp/pgjwt.git && \
    cd pgjwt && \
    make && make install && \
    cd / && rm -rf /tmp/pgjwt

# 5. 清理构建依赖（可选，减小镜像体积）
RUN apt remove -y --purge build-essential git postgresql-server-dev-18 libssl-dev && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# 6. 配置 PostgreSQL
# 注意：只有 pg_duckdb 和 pgaudit 需要 shared_preload_libraries
RUN echo "shared_preload_libraries = 'pg_duckdb, pgaudit'" >> /usr/share/postgresql/postgresql.conf.sample && \
    echo "wal_level = logical" >> /usr/share/postgresql/postgresql.conf.sample

# 切回 postgres 用户
USER postgres
