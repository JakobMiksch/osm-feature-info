FROM alpine/git:v2.45.2 AS repo-downloader

# Clone osm2pgsql-themepark repo
ARG REPO_URL=https://github.com/osm2pgsql-dev/osm2pgsql-themepark.git
ARG COMMIT_HASH=b26afa5
ARG TARGET_PATH_REPO=/osm2pgsql-themepark
RUN git clone ${REPO_URL} ${TARGET_PATH_REPO} && \
    cd ${TARGET_PATH_REPO} && \
    git checkout ${COMMIT_HASH} && \
    rm -rf .git

FROM iboates/osm2pgsql:2.0.0

ENV LUA_PATH /osm2pgsql-themepark/lua/?.lua;;

COPY --from=repo-downloader /osm2pgsql-themepark /osm2pgsql-themepark
