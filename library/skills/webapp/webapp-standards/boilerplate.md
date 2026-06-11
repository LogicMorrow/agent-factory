# Boilerplate — kluczowe pliki konfiguracyjne

Referencja dla `webapp-bootstrapper`. Zawiera dokładną zawartość plików które muszą być identyczne w każdym projekcie.

## Root `package.json`
```json
{
  "name": "<projekt>",
  "private": true,
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "dev": "turbo run dev",
    "build": "turbo run build",
    "typecheck": "turbo run typecheck",
    "lint": "turbo run lint",
    "format": "prettier --write \"**/*.{ts,tsx,md}\"",
    "format:check": "prettier --check \"**/*.{ts,tsx,md}\"",
    "test": "turbo run test",
    "test:coverage": "turbo run test:coverage",
    "validate": "turbo run typecheck lint test"
  },
  "devDependencies": {
    "turbo": "^2.3.0",
    "prettier": "^3.4.0",
    "typescript": "^5.7.0"
  }
}
```

## `turbo.json`
```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": [".next/**", "dist/**"] },
    "dev": { "cache": false, "persistent": true },
    "typecheck": { "dependsOn": ["^typecheck"] },
    "lint": {},
    "test": { "dependsOn": ["^build"] },
    "test:coverage": { "dependsOn": ["^build"], "outputs": ["coverage/**"] }
  }
}
```

## `tsconfig.base.json` (root — extend w każdym pakiecie)
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

## `apps/api/tsconfig.json`
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## `apps/api/package.json`
```json
{
  "name": "@<projekt>/api",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "typecheck": "tsc --noEmit",
    "lint": "eslint src --max-warnings 0",
    "test": "vitest run",
    "test:coverage": "vitest run --coverage"
  },
  "dependencies": {
    "hono": "^4.6.0",
    "@hono/node-server": "^1.13.0",
    "@hono/jwt": "^1.0.0",
    "bcryptjs": "^2.4.3",
    "@sentry/node": "^8.0.0",
    "@<projekt>/db": "*"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/node": "^22.0.0",
    "tsx": "^4.0.0",
    "vitest": "^2.1.0",
    "@vitest/coverage-v8": "^2.1.0"
  }
}
```

## `apps/web/package.json`
```json
{
  "name": "@<projekt>/web",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "typecheck": "tsc --noEmit",
    "lint": "next lint --max-warnings 0",
    "test": "vitest run",
    "test:coverage": "vitest run --coverage"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@tanstack/react-query": "^5.62.0",
    "zustand": "^5.0.0",
    "zod": "^3.23.0"
  }
}
```

## `packages/db/package.json`
```json
{
  "name": "@<projekt>/db",
  "main": "./src/index.ts",
  "scripts": {
    "typecheck": "tsc --noEmit",
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate dev",
    "db:push": "prisma db push",
    "db:studio": "prisma studio"
  },
  "dependencies": {
    "@prisma/client": "^5.22.0"
  },
  "devDependencies": {
    "prisma": "^5.22.0"
  }
}
```

## `packages/db/prisma/schema.prisma`
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(dbgenerated("gen_random_uuid")) @db.Uuid
  email     String   @unique
  password  String
  role      String   @default("user")
  createdAt DateTime @default(now) @db.Timestamptz
  updatedAt DateTime @updatedAt @db.Timestamptz

  @@index([email])
  @@map("users")
}
```

## `eslint.config.js` (root — flat config ESLint 9)
```js
import tseslint from 'typescript-eslint';
import importPlugin from 'eslint-plugin-import';

export default tseslint.config(
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  {
    plugins: { import: importPlugin },
    rules: {
      'import/order': ['error', {
        'groups': ['builtin', 'external', 'internal', 'parent', 'sibling'],
        'alphabetize': { order: 'asc' },
        'newlines-between': 'always',
      }],
      '@typescript-eslint/consistent-type-imports': 'error',
    },
    languageOptions: {
      parserOptions: { project: true },
    },
  },
);
```

## `.prettierrc`
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "all",
  "printWidth": 100,
  "endOfLine": "lf"
}
```

## `.husky/pre-commit`
```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"
npx lint-staged
```

## `.lintstagedrc.json`
```json
{
  "*.{ts,tsx}": ["prettier --write", "eslint --fix --max-warnings 0"],
  "*.{json,md}": ["prettier --write"]
}
```

## `docker-compose.dev.yml`
```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 5s
      timeout: 5s
      retries: 5

  api:
    build:
      context: ./apps/api
      dockerfile: Dockerfile.dev
    ports:
      - "${API_PORT:-3001}:3001"
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
    volumes:
      - ./apps/api:/app
      - /app/node_modules
    depends_on:
      db:
        condition: service_healthy

  web:
    build:
      context: ./apps/web
      dockerfile: Dockerfile.dev
    ports:
      - "${WEB_PORT:-3000}:3000"
    volumes:
      - ./apps/web:/app
      - /app/node_modules
    depends_on:
      - api

volumes:
  postgres_data:
```

## `apps/api/Dockerfile` (produkcyjny, multi-stage)
```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY --from=builder /app/dist ./dist
EXPOSE 3001
CMD ["node", "dist/index.js"]
```

## `.github/workflows/ci.yml`
```yaml
name: CI
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  ci:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run typecheck
      - run: npm run lint
      - run: npm run format:check
      - name: Run migrations
        run: npx prisma migrate deploy
        working-directory: packages/db
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test
      - name: Test with coverage
        run: npm run test:coverage
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test
```

## `.env.example`
```bash
# === BAZA DANYCH ===
DATABASE_URL=postgresql://USER:PASSWORD@localhost:5432/DB_NAME
POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_DB=

# === APLIKACJA ===
NODE_ENV=development
API_PORT=3001
WEB_PORT=3000
FRONTEND_URL=http://localhost:3000

# === JWT (min. 64 znaki — generuj: openssl rand -hex 32) ===
JWT_SECRET=
JWT_REFRESH_SECRET=

# === MONITORING ===
SENTRY_DSN=
```
