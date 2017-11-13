module OpenStudio
  module Workflow
    module Util
      module IO
        def is_windows?
          win_patterns = [
            /bccwin/i,
            /cygwin/i,
            /djgpp/i,
            /mingw/i,
            /mswin/i,
            /wince/i
          ]

          case RUBY_PLATFORM
          when *win_patterns
            return true
          else
            return false
          end
        end

        def popen_command(command)
          result = command
          if is_windows?
            result = command.tr('/', '\\')
          end
          return result
        end
      end
    end
  end
end
