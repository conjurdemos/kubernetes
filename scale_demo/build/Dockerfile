FROM alpine

RUN apk add --update bash && rm -rf /var/cache/apk/* 
RUN apk add --update curl && rm -rf /var/cache/apk/*
COPY webapp1.sh /root/webapp1.sh
RUN chmod +x /root/webapp1.sh

# On container startup: run the app
CMD exec /root/webapp1.sh
