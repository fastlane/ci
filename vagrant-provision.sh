echo 'export PATH=$HOME/.gem/ruby/2.3.0/bin:$PATH' >> ~/.bash_profile
source ~/.bash_profile

if [ ! -d /usr/local/Homebrew/.git ]; then
  echo "==> Installing Homebrew ..."
  try_count=1

  while ! /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null; do
    if [ $try_count -eq 5 ]; then
      echo "==> Attempt #$[$try_count] at installing Homebrew failed"
      exit 1
    fi

    sleep 5
    echo "==> Attempt #$[$try_count] at installing Homebrew failed, trying again..."
    try_count=$[$try_count + 1]
  done

  brew doctor
else
  echo "==> Homebrew is already installed"
fi

echo "==> Installing node and npm ..."
brew install node

echo "==> Installing Bundler ..."
gem install bundler --user-install --no-document --verbose

echo "==> Installing all dependencies ..."
cd /fastlane-ci
bundle install
npm install
npm run build
