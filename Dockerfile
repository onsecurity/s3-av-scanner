FROM ubuntu:16.04
ENV AWS_ACCESS_KEY_ID changeme
ENV AWS_SECRET_ACCESS_KEY changeme
ENV AWS_DEFAULT_REGION changeme
ENV S3_FILES_DIRECTORY "/files/"
ENV S3_BUCKET ""
ENV CHECK_DELAY 60
ENV DEBUG "0"

RUN apt-get update && \
    apt-get install -y unrar clamav awscli
COPY ./run.sh /application/run.sh
WORKDIR /application
CMD ["/application/run.sh"]