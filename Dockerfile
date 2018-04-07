FROM ruby:2.5

ENV LANG C.UTF-8

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["prod"]
ENTRYPOINT ["bundle", "exec", "rake"]
