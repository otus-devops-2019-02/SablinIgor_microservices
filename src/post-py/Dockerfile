FROM frolvlad/alpine-python3

WORKDIR /app
ADD . /app

RUN apk add --no-cache build-base gcc  python2-dev python3-dev \
    && pip install -r /app/requirements.txt \
    && apk del build-base gcc python2-dev python3-dev

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]
