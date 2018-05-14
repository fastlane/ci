echo 'export PATH=$HOME/.gem/ruby/2.3.0/bin:$PATH' >> ~/.bash_profile
source ~/.bash_profile

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
gem install bundler --no-document --verbose

echo "==> Installing all dependencies ..."
cd /fastlane-ci
bundle install
npm install
npm run build
