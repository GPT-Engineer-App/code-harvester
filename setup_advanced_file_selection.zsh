#!/bin/zsh

# Advanced File Selection System Setup Script

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create a directory for the project
mkdir -p advanced_file_selection_system
cd advanced_file_selection_system

# Create docker-compose.yml file
cat << EOF > docker-compose.yml
version: '3.8'

services:
  minio:
    image: minio/minio
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"

  fastapi:
    build: .
    ports:
      - "8004:8004"
    volumes:
      - ./app:/app
    depends_on:
      - minio

volumes:
  minio_data:
EOF

# Create Dockerfile
cat << EOF > Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ./app .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8004"]
EOF

# Create requirements.txt
cat << EOF > requirements.txt
fastapi==0.68.0
uvicorn==0.15.0
python-multipart==0.0.5
minio==7.1.0
spacy==3.1.3
nltk==3.6.3
babel==2.9.1
astroid==2.8.0
elasticsearch==7.15.0
EOF

# Create app directory and main FastAPI file
mkdir -p app
cat << EOF > app/main.py
from fastapi import FastAPI, UploadFile, File
from minio import Minio
from minio.error import S3Error
import os
import zipfile
import tempfile

app = FastAPI()

# Initialize MinIO client
minio_client = Minio(
    "minio:9000",
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False
)

@app.post("/upload")
async def upload_codebase(file: UploadFile = File(...)):
    try:
        # Create a temporary directory to extract the zip file
        with tempfile.TemporaryDirectory() as temp_dir:
            zip_path = os.path.join(temp_dir, file.filename)
            
            # Save the uploaded file
            with open(zip_path, "wb") as buffer:
                buffer.write(await file.read())
            
            # Extract the zip file
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(temp_dir)
            
            # Upload extracted files to MinIO
            for root, _, files in os.walk(temp_dir):
                for filename in files:
                    file_path = os.path.join(root, filename)
                    object_name = os.path.relpath(file_path, temp_dir)
                    minio_client.fput_object("codebase", object_name, file_path)
        
        return {"message": "Codebase uploaded and processed successfully"}
    except S3Error as exc:
        return {"error": f"MinIO S3 error: {exc}"}
    except Exception as exc:
        return {"error": f"An error occurred: {exc}"}

@app.get("/query")
async def query_codebase(query: str):
    # Placeholder for query implementation
    return {"message": f"Query received: {query}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8004)
EOF

# Create a simple React frontend
mkdir -p frontend
cat << EOF > frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Advanced File Selection System</title>
    <script src="https://unpkg.com/react@17/umd/react.development.js"></script>
    <script src="https://unpkg.com/react-dom@17/umd/react-dom.development.js"></script>
    <script src="https://unpkg.com/babel-standalone@6/babel.min.js"></script>
</head>
<body>
    <div id="root"></div>
    <script type="text/babel">
        function App() {
            const [file, setFile] = React.useState(null);
            const [query, setQuery] = React.useState('');
            const [message, setMessage] = React.useState('');

            const handleFileUpload = async (e) => {
                e.preventDefault();
                if (!file) {
                    setMessage('Please select a file');
                    return;
                }
                const formData = new FormData();
                formData.append('file', file);
                try {
                    const response = await fetch('http://localhost:8004/upload', {
                        method: 'POST',
                        body: formData,
                    });
                    const data = await response.json();
                    setMessage(data.message || data.error);
                } catch (error) {
                    setMessage('An error occurred during upload');
                }
            };

            const handleQuery = async (e) => {
                e.preventDefault();
                try {
                    const response = await fetch(`http://localhost:8004/query?query=${encodeURIComponent(query)}`);
                    const data = await response.json();
                    setMessage(data.message || data.error);
                } catch (error) {
                    setMessage('An error occurred during query');
                }
            };

            return (
                <div>
                    <h1>Advanced File Selection System</h1>
                    <form onSubmit={handleFileUpload}>
                        <input type="file" onChange={(e) => setFile(e.target.files[0])} />
                        <button type="submit">Upload Codebase</button>
                    </form>
                    <form onSubmit={handleQuery}>
                        <input type="text" value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Enter your query" />
                        <button type="submit">Query Codebase</button>
                    </form>
                    {message && <p>{message}</p>}
                </div>
            );
        }

        ReactDOM.render(<App />, document.getElementById('root'));
    </script>
</body>
</html>
EOF

# Start the services
docker-compose up -d

echo "Advanced File Selection System setup complete!"
echo "MinIO is running on http://localhost:9001"
echo "FastAPI server is running on http://localhost:8004"
echo "You can access the web interface by opening frontend/index.html in your browser"

# Install Python dependencies for local development
pip install -r requirements.txt

# Download spaCy English model
python -m spacy download en_core_web_sm

# Download NLTK data
python -c "import nltk; nltk.download('punkt'); nltk.download('averaged_perceptron_tagger'); nltk.download('wordnet')"

echo "Local Python environment set up complete!"