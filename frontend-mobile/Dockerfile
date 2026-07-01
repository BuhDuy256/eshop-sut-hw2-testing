FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 8081 19000 19001

ENV EXPO_NO_TUNNEL=1

CMD ["npx", "expo", "start", "--localhost", "--no-dev", "--clear"]
