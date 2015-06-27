if exists('g:loaded_vim_wayback_machine')
  finish                       
endif
let g:loaded_vim_wayback_machine = 1

ruby << EOF
module VimWaybackMachine
  VERSION = "0.1.0"

  def self.boot
    @engine = Engine.new
    @engine.start!
  end
  
  def self.move
    @engine.move!
  end
  
  def self.quit
    @engine.stop!
  end

  class Engine
    def initialize
      @history   = VimWaybackMachine::History.new(VIM.evaluate('g:current_file'))
      @navigator = VimWaybackMachine::Navigator.new(@history)
    end

    def start!
      stash!
    end

    def move!
      if @navigator.position_changed?
        move_to @history[@navigator.position-1]
        @navigator.refresh_target
      end
    end

    def stop!
      rollback!
      @navigator.quit
    end

    def move_to(entry)
      `git reset --hard #{entry.sha}`
    end

    def stash!
      @stash = `git stash -u`
    end

    def rollback!
      move_to @history[0]
      `git stash pop` unless @stash.include?("No local changes to save")
    end

  end

  class History < Array
    SIZE = 200

    def initialize (current_file = nil)
      super raw_entries(current_file).map { |entry| Entry.new *entry }
    end

    class Entry < Struct.new(:sha, :name, :time, :comment)
      def to_s
        "#{sha} | #{name} (#{time}) - #{comment}"
      end
    end

    private
    def raw_entries(current_file)
      `git log --pretty=format:'%h|%an|%cr|%s'  -#{SIZE} #{current_file ? "-- "+current_file : ""}`.split("\n").map do |entry|
        entry.sub(/\A\s*\*\s*/, "").split("|")
      end
    end

  end

  class Navigator
    UPDATE_TIME=1000

    def initialize(history)
      @last_position = 1
      @target_window = $curwin
      @history = history
      @window = create_window
      @buffer = setup_buffer
      render
    end

    def position_changed?
      @last_position != @window.cursor[0]
    end

    def position
      @last_position = @window.cursor[0]
    end

    def refresh_target
      save_cursor = @target_window.cursor if @target_window
      VIM::command ":windo e"
      @target_window.cursor = save_cursor if @target_window
    end

    def quit
      VIM::command ":au! CursorHold <buffer>"
      refresh_target
    end

    private
    def create_window
      file_name = VIM::evaluate 'tempname()'
      VIM::command ":below 5sp #{file_name}.wbm"
      $curwin
    end
    
    def setup_buffer
      VIM::command 'setlocal nowrap'
      VIM::command 'setlocal nospell'
      VIM::command "setlocal ft=waybackmachine"
      VIM::command "setlocal updatetime=#{UPDATE_TIME}"
      VIM::command ":au CursorHold <buffer> nested ruby VimWaybackMachine.move" 
      VIM::command ':au QuitPre <buffer> nested ruby VimWaybackMachine.quit'
      $curbuf
    end

    def render
      @history.each do |entry|
        @buffer.append(@buffer.count - 1, entry.to_s)
      end
      VIM::command 'w!'
      VIM::command 'setlocal nomodifiable'
      VIM::command 'setlocal readonly'
    end

  end
end

EOF

function! VimWaybackMachine()
  let g:current_file = expand("%")
  ruby VimWaybackMachine.boot
endfunction

if !exists('g:yourplugin_map_prefix')
    let g:yourplugin_map_prefix = '<leader>'
endif

execute "nnoremap"  g:yourplugin_map_prefix."w"  ":call VimWaybackMachine()<CR>"

command! -bar -narg=* WaybackMachine call VimWaybackMachine()
