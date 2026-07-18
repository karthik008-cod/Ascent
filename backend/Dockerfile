FROM node:18-alpine

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy application code
COPY . .

# Expose port (Render sets PORT environment variable, defaulting to 3000)
EXPOSE 3000

# Start server
CMD ["npm", "start"]
