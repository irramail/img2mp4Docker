docker build -t someprocesses .

docker run --restart unless-stopped  -dp 8000:80 someprocesses
