if [ ! -d /usr/local/Homebrew/.git ]; then
  echo "==> Installing Homebrew ..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew doctor
else
  echo "==> Homebrew is already installed"
fi

echo "==> Installing node and npm ..."
brew install node

echo "==> Installing Bundler ..."
sudo gem install bundler -NV

echo "==> Installing all dependencies ..."
cd /fastlane-ci
bundle install
npm install
npm run build
