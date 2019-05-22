FROM alpine:3.9.4
RUN apk --no-cache add ruby ruby-dev ruby-bundler build-base

ENV APP_HOME /app
WORKDIR $APP_HOME

ADD . $APP_HOME
RUN bundle install 

CMD ["puma"]
