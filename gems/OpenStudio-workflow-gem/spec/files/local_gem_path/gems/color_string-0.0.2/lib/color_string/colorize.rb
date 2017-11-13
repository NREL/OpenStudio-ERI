module ColorString
  class Colorize
    REGEX = /\[[a-z0-9_-]+\]/i
    CODES = {
      'default'       => '39',

      # Attributes
      'bold'          => '1',
      'dim'           => '2',
      'underline'     => '4',
      'blink_slow'    => '5',
      'blink_fast'    => '6',
      'invert'        => '7',
      'hidden'        => '8',

      # Reset to reset everything to their defaults
      'reset'         => '0',
      'reset_bold'    => '21',

      # Foreground Colors
      'black'         => '30',
      'red'           => '31',
      'green'         => '32',
      'yellow'        => '33',
      'blue'          => '34',
      'magenta'       => '35',
      'cyan'          => '36',
      'light_gray'    => '37',
      'dark_gray'     => '90',
      'light_red'     => '91',
      'light_green'   => '92',
      'light_yellow'  => '93',
      'light_blue'    => '94',
      'light_magenta' => '95',
      'light_cyan'    => '96',
      'white'         => '97'
    }.freeze

    def initialize(string)
      @string = string
    end

    def color
      return string if matches.empty?

      colored = string.match(REGEX).pre_match
      matches.each_with_index do |match, index|
        next_match =
          if match.length > index + 1
            matches[index + 1]
          end

        color = match.delete('[]')
        code = code_for(color)

        offset = string.index(match)
        start_of_next =
          if next_match
            string.index(next_match)
          else
            offset + match.length
          end
        words =
          if next_match
            string[offset...start_of_next]
          else
            string[offset...string.length]
          end

        if code
          words_without_code = words.gsub(match, '')
          colored << "\033[#{code}m#{words_without_code}\033[0m"
        else
          colored << words
        end
      end
      colored
    end

    private

    attr_reader :string

    def matches
      string.scan(REGEX)
    end

    def code_for(color)
      CODES.fetch(color, nil)
    end
  end
end
