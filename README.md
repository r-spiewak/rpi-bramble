# rpi-bramble

See the GitHub Pages [here](https://r-spiewak.github.io/rpi-bramble/).

## Build Instructions

The following steps are necessary to build the site locally.

### Requirements

This site is built with [Jekyll](https://jekyllrb.com/docs/installation/ubuntu/), a Ruby gem. It requires:
- [Ruby](https://www.ruby-lang.org/en/downloads/) version 2.7.0, including all development headers (check your Ruby version using `ruby -v`)
- [RubyGems](https://rubygems.org/pages/download) (check your Gems version using `gem -v`)
- [GCC](https://gcc.gnu.org/install/) and [Make](https://www.gnu.org/software/make/) (check versions using `gcc -v`,`g++ -v`, and `make -v`)

Steps:
1. Install Jekyll prerequisites:
```
sudo apt-get install ruby-full build-essential zlib1g-dev
```
2. Set up a gem installation directory for your user account:
```
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
3. install Jekyll and Bundler:
```
gem install jekyll bundler
```

### Build

Run the following from the root of the repo:
```
bundle install
bundle exec jekyll build --trace
```

### Serve

To serve the site locally (and automatically rebuild on any changes), run the following:
```
bundle exec jekyll serve --livereload --host localhost --port 4444
```

### Troubleshooting

1. If build errors persist even if there is nothing referring to those variables (and/or the file no longer has that many lines for which the build error produces the failing line reference), run `bundle exec jekyll clean` and rebuild. Also try manuall removing the `.jekyll_cache` directory.
