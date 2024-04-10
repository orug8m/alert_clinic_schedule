# Multi Stage Build 1st for build (bundler and headless-chromedriver)
FROM ruby:3.3-alpine as builder

WORKDIR /var/task

ADD Gemfile /var/task/Gemfile
ADD Gemfile.lock /var/task/Gemfile.lock

RUN bundle install

# Multi Stage Build 2nd for executional container
FROM ruby:3.3-alpine

WORKDIR /var/task

RUN apk add \
    chromium~=123.0.6312.105 \
    chromium-chromedriver~=123.0.6312.105 \
    tzdata

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY . .

ENTRYPOINT [ "ruby" ]
CMD [ "/var/task/app.rb" ]
