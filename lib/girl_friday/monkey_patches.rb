if RUBY_ENGINE == 'rbx' && (Rubinius::VERSION < '1.2.4' || Rubinius::VERSION == '1.2.4dev')
  puts "Loading rubinius actor monkeypatches" if $testing
  class Actor

    # Monkeypatch so this works with Rubinius 1.2.3 (latest).
    # 1.2.4 should have the necessary fix included.
    def notify_exited(actor, reason)
      exit_message = nil
      @lock.receive
      begin
        return self unless @alive
        @links.delete(actor)
        if @trap_exit
          exit_message = DeadActorError.new(actor, reason)
        elsif reason
          @interrupts << DeadActorError.new(actor, reason)
          if @filter
            @filter = nil
            @ready << nil
          end
        end
      ensure
        @lock << nil
      end
      send exit_message if exit_message
      self
    end
  
  end

end