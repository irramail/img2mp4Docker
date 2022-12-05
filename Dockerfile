FROM ubuntu 

RUN apt-get update && apt-get install -y \
	nginx \
	redis-server \
	imagemagick \
	ffmpeg \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /root

COPY . .
COPY ./html/* /var/www/html/

CMD ["./run.sh"]
