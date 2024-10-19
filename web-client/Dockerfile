
# WARNING: ONLY FOR DEVELOPMENT - DO NOT RUN IN PRODUCTION !!1!
FROM node:20

WORKDIR /app

COPY package.json package.json
COPY package-lock.json package-lock.json
RUN npm ci

COPY . .

RUN npm run build

EXPOSE 4173

CMD ["npm", "run", "preview"]
