# Advanced File Selection System

This project is a web application built with React and Vite.

## Docker Compose Setup

To run this project using Docker Compose, follow these steps:

1. Make sure you have Docker and Docker Compose installed on your system.

2. Clone this repository to your local machine.

3. Navigate to the project directory in your terminal.

4. Run the following command to start the application:

   ```
   docker-compose up
   ```

   This will build the Docker image (if not already built) and start the containers defined in the `docker-compose.yml` file.

5. Once the containers are up and running, you can access the application by opening a web browser and navigating to `http://localhost:5173`.

6. To stop the application and remove the containers, use the following command:

   ```
   docker-compose down
   ```

## Development

For local development without Docker:

1. Install dependencies:

   ```
   npm install
   ```

2. Start the development server:

   ```
   npm run dev
   ```

3. Open your browser and visit `http://localhost:5173`.

## Building for Production

To build the application for production:

```
npm run build
```

This will generate a production-ready build in the `dist` directory.