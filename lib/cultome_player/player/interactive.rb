module CultomePlayer::Player
  module Interactive
    def begin_session
      @in_session = true
      display "Cultome Player v#{CultomePlayer::VERSION}"

      while in_session?
        begin
          r = execute read_command("cultome> ")
          show_response(r)
        rescue Exception => e
          display e.message
        end
      end
    end

    def in_session?
      @in_session ||= false
    end

    def terminate_session
      @in_session = false
    end

    private

    def show_response(r)
      if r.respond_to?(:response_type)
        res_obj = r.send(r.response_type)
        if res_obj.respond_to?(:each)
          res_obj.each.with_index do |elem, idx|
            display "#{(idx + 1).to_s.ljust(3)} | #{elem.to_s}"
          end
        elsif res_obj.class == String
          display res_obj.to_s
        else
          display "(((#{res_obj.to_s})))"
        end

      elsif r.respond_to?(:message)
        display r.message
      else
        display "!!!#{r}!!!"
      end
    end

  end
end
