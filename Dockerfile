# Use Node.js base image for the build stage
FROM node:20-buster as builder

# Set working directory and copy the application
WORKDIR /juice-shop
COPY . .

# Install production dependencies and prepare the application
RUN npm install --omit=dev --unsafe-perm \
    && npm dedupe --omit=dev \
    && rm -rf frontend/node_modules frontend/.angular frontend/src/assets \
    && mkdir logs && chown -R 65532 logs \
    && chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/ \
    && chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/ \
    && rm -f data/chatbot/botDefaultTrainingData.json ftp/legal.md i18n/*.json

# Generate SBOM
ARG CYCLONEDX_NPM_VERSION=latest
RUN npm install -g @cyclonedx/cyclonedx-npm@$CYCLONEDX_NPM_VERSION && npm run sbom

# Use distroless image for the runtime stage
FROM gcr.io/distroless/nodejs20-debian11

# Metadata
LABEL maintainer="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.title="OWASP Juice Shop" \
    org.opencontainers.image.description="Probably the most modern and sophisticated insecure web application" \
    org.opencontainers.image.authors="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.vendor="Open Worldwide Application Security Project" \
    org.opencontainers.image.documentation="https://help.owasp-juice.shop" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version="17.1.1" \
    org.opencontainers.image.url="https://owasp-juice.shop"

# Set working directory and copy the application from the builder
WORKDIR /juice-shop
COPY --from=builder /juice-shop .

# Run the application as a non-root user
USER 65532
EXPOSE 3000
CMD ["/juice-shop/build/app.js"]

#-------------------------------------------------------------------------------------------------------------------------------------------


# FROM node:20-buster as installer
# COPY . /juice-shop
# WORKDIR /juice-shop
# RUN npm i -g typescript ts-node
# RUN npm install --omit=dev --unsafe-perm
# RUN npm dedupe --omit=dev
# RUN rm -rf frontend/node_modules
# RUN rm -rf frontend/.angular
# RUN rm -rf frontend/src/assets
# RUN mkdir logs
# RUN chown -R 65532 logs
# RUN chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/
# RUN chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/
# RUN rm data/chatbot/botDefaultTrainingData.json || true
# RUN rm ftp/legal.md || true
# RUN rm i18n/*.json || true

# ARG CYCLONEDX_NPM_VERSION=latest
# RUN npm install -g @cyclonedx/cyclonedx-npm@$CYCLONEDX_NPM_VERSION
# RUN npm run sbom

# # workaround for libxmljs startup error
# FROM node:20-buster as libxmljs-builder
# WORKDIR /juice-shop
# RUN apt-get update && apt-get install -y build-essential python3
# COPY --from=installer /juice-shop/node_modules ./node_modules
# RUN rm -rf node_modules/libxmljs/build && \
#   cd node_modules/libxmljs && \
#   npm run build

# FROM gcr.io/distroless/nodejs20-debian11
# ARG BUILD_DATE
# ARG VCS_REF
# LABEL maintainer="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
#     org.opencontainers.image.title="OWASP Juice Shop" \
#     org.opencontainers.image.description="Probably the most modern and sophisticated insecure web application" \
#     org.opencontainers.image.authors="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
#     org.opencontainers.image.vendor="Open Worldwide Application Security Project" \
#     org.opencontainers.image.documentation="https://help.owasp-juice.shop" \
#     org.opencontainers.image.licenses="MIT" \
#     org.opencontainers.image.version="17.1.1" \
#     org.opencontainers.image.url="https://owasp-juice.shop" \
#     org.opencontainers.image.source="https://github.com/juice-shop/juice-shop" \
#     org.opencontainers.image.revision=$VCS_REF \
#     org.opencontainers.image.created=$BUILD_DATE
# WORKDIR /juice-shop
# COPY --from=installer --chown=65532:0 /juice-shop .
# COPY --chown=65532:0 --from=libxmljs-builder /juice-shop/node_modules/libxmljs ./node_modules/libxmljs
# USER 65532
# EXPOSE 3000
# CMD ["/juice-shop/build/app.js"]
