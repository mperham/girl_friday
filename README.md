girl_friday
====================

Have a task you want to get done sometime soon but don't want to do it yourself?  Give it to your [girl friday](http://en.wikipedia.org/wiki/Girl_Friday)!

girl_friday is a Ruby library for performing asynchronous tasks.  Often times you don't want to block a web response by performing some task, like sending an email, so you can just use this gem to perform it in the background.  It works with any Ruby application, including Rails 3 applications.


Installation
------------------

We recommend using [JRuby](http://jruby.org) or [Rubinius](http://rubini.us) with girl_friday.  Both are excellent options for executing Ruby these days.

    gem install girl_friday

Open your Rails application's Gemfile and add:

    gem 'girl_friday'


Usage
--------------------

Put girl_friday in your Gemfile:

    gem 'girl_friday'

In your Rails app, create a `config/initializers/queues.rb` which defines your queues:

    QUEUE = GirlFriday::WorkQueue.new('user_email') do |msg|
      UserMailer.registration_email(msg).deliver
    end

In your controller action or model, you can call `#push(msg)`

    QUEUE.push(:type => 'registration_email', :user => { :email => @user.email, :name => @user.name }))

The msg parameter to push is just a Hash whose contents are completely up to you.

Your message processing block should **NOT** access any instance data or variables outside of the block.  That's shared mutable state and dangerous to touch!  I also strongly recommend your queue processor block be **VERY** short, ideally just a method call or two.  You can unit test those methods easily but not the processor block itself.


Error Handling
--------------------

Your processor block can raise any error; don't worry about needing a begin..rescue block.  Each queue contains a supervisor who will log any exceptions (to stderr or Hoptoad Notifier) and restart a new worker.


More Detail
--------------------

But why not use any of the zillions of other async solutions (Resque, dj, etc)?  Because girl\_friday is easier and more efficient than those solutions: girl_friday runs in your Rails process and uses the actor pattern for safe concurrency.  Because it runs in the same process, you don't have to monitor a separate set of processes, deploy a separate codebase, buy extra memory for those processes, etc.

You do need to write thread-safe code.  This is not hard to do: the actor pattern means that you get a message and process that message.  There is no shared data which requires locks and could lead to deadlock in your application code.  Because girl\_friday does use Threads under the covers, you do need to ensure that your VM can execute Threads efficiently: today this means JRuby or Rubinius.  **To be clear: this gem will work but not scale well on Ruby 1.9.**



Thanks
--------------------

[Carbon Five](http://carbonfive.com), I write and maintain girl_friday on their clock.

This gem contains a copy of the Rubinius Actor API, modified to work on any Ruby VM.  Thanks to Evan Phoenix, MenTaLguY and the Rubinius project for permission to use and distribute this code.


Author
--------------------

Mike Perham, [@mperham](https://twitter.com/mperham), [mikeperham.com](http://mikeperham.com)