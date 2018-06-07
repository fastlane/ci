FROM node:carbon
RUN npm install --prod
FROM ruby:2.3

ENV LANG C.UTF-8

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

COPY Gemfile Gemfile.lock Rakefile ./
COPY . .
RUN bundle install

CMD ["docker:prod_test"]
ENTRYPOINT ["bundle", "exec", "rake"]
EXPOSE 8080