# ColorString

`color_string` is a Ruby library for outputting colored strings to a console
using a simple inline syntax in your string to specify the color to print as.

For example, the string `[blue]hello [red]world` would output the text `hello
world` in two colors.

Inspired by Mitchell Hashimoto's [`colorstring`](https://github.com/mitchellh/colorstring)

## Installation

Add this line to your application's Gemfile:

    gem 'color_string'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install color_string

## Usage

```ruby
"[red]Hello [blue]World!".color # => "\e[31mHello \e[0m\e[34mWorld\e[0m"
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/color_string/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
