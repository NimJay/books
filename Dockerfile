FROM node:25-slim

# First, install all dependencies.
# Dependencies are less likely to change than the source code.
# Installing dependencies in an early Docker layer allows us to benefit from layer caching.

# Install preact-app (front-end) dependencies
RUN echo "🌈 Installing preact-app dependencies..."
WORKDIR /app/preact-app
COPY preact-app/package*.json ./
RUN npm install

# Install back-end dependencies
RUN echo "🌈 Installing back-end dependencies..."
WORKDIR /app/back-end
COPY back-end/package*.json ./
RUN npm install

# Build the preact-app (front-end)
RUN echo "🌈 Building preact-app..."
WORKDIR /app/preact-app
COPY preact-app/src src
COPY preact-app/public public
COPY preact-app/index.html index.html
COPY preact-app/tsconfig.json tsconfig.json
COPY preact-app/vite.config.ts vite.config.ts
RUN npm run build

# Build the back-end
RUN echo "🌈 Building back-end..."
WORKDIR /app/back-end
COPY back-end/ .
RUN npm run compile-typescript-no-watch

# Remove all TypeScript files"
WORKDIR /app/
RUN rm -r **/*.ts

# Remove the npm dependencies that are only used for development.
# Smaller the Docker container, the more secure it is.
RUN echo "🌈 Pruning npm dev dependencies..."
WORKDIR /app/back-end
RUN npm prune --production
WORKDIR /app/preact-app
RUN npm prune --production

# Start the back-end
RUN echo "🌈 Starting back-end..."
WORKDIR /app/back-end
CMD [ "node", "./build/server.js" ]
