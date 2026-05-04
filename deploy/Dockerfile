# Hugo Extended (PaperMod / Sass). Pin to a digest in production if you need reproducible builds.
FROM ghcr.io/hugomods/hugo:exts AS hugo

WORKDIR /src

COPY . .

RUN test -d themes/papermod/layouts || (echo "ERROR: themes/papermod missing. On the host run: git submodule update --init --recursive" && exit 1)

RUN hugo --minify --gc

FROM nginx:1.27-alpine

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=hugo /src/public /usr/share/nginx/html
