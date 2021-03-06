#!/bin/bash -ex

cd /app

if [ -d "/rails_conf/" ]
then
    ln -sf /rails_conf/* ./config/
fi

mkdir -p tmp/pids/
rm -f tmp/pids/*.pid

bin/rake db:migrate

if [ "$RAILS_ENV" == "development" ]; then
  exec foreman start
else
  if [ -f "commit_id.txt" ]
  then
    cp commit_id.txt public/
  fi

  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi
