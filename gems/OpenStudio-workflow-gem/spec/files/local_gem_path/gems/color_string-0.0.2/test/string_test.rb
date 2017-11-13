$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'color_string'

class StringTest < Minitest::Test
  def test_leaves_uncolored_text_unchanged
    assert_equal 'Hello World',
                 'Hello World'.color
  end

  def test_colors_single_words
    assert_equal "\033[34mHello\033[0m",
                 '[blue]Hello'.color
  end

  def test_ignores_unknown_codes
    assert_equal "say [hi]Hello \033[31mWorld\033[0m",
                 'say [hi]Hello [red]World'.color
  end

  def test_colors_phrases
    assert_equal "\033[34mHello   \033[0m\033[31mWorld\033[0m",
                 '[blue]Hello   [red]World'.color
  end
end
