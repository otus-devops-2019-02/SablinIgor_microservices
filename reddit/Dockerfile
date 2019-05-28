FROM ruby:2.2.10

ENV APP_HOME /app
WORKDIR $APP_HOME

ADD . $APP_HOME
RUN bundle install 

CMD ["puma"]
