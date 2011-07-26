girl\_friday
====================

Have a task you want to get done sometime soon but don't want to do it yourself?  Give it to girl\_friday!  From wikipedia:

> The term Man Friday has become an idiom, still in mainstream usage, to describe an especially faithful servant or
> one's best servant or right-hand man. The female equivalent is Girl Friday. The title of the movie His Girl Friday
> alludes to it and may have popularized it.

girl\_friday is a Ruby library for performing asynchronous tasks.  Often times you don't want to block a web response by performing some task, like sending an email, so you can just use this gem to perform it in the background.  It works with any Ruby application, including Rails 3 applications.


Installation
------------------

We recommend using [JRuby 1.6+](http://jruby.org) or [Rubinius 2.0+](http://rubini.us) with girl\_friday.  Both are excellent options for executing Ruby these days.

    gem install girl_friday

girl\_friday does not support Ruby 1.8 (MRI) because of its poor threading support.  Ruby 1.9 will work reasonably well if you use gems that release the GIL for network I/O (mysql2 is a good example of this, do **not** use the original mysql gem).


Usage
--------------------

Put girl\_friday in your Gemfile:

    gem 'girl_friday'

In your Rails app, create a `config/initializers/girl_friday.rb` which defines your queues:

    EMAIL_QUEUE = GirlFriday::WorkQueue.new(:user_email, :size => 3) do |msg|
      UserMailer.registration_email(msg).deliver
    end
    IMAGE_QUEUE = GirlFriday::WorkQueue.new(:image_crawler, :size => 7) do |msg|
      ImageCrawler.process(msg)
    end

:size is the number of workers to spin up and defaults to 5.  Keep in mind, ActiveRecord defaults to a connection pool size of 5 so if your workers are accessing the database you'll want to ensure that the connection pool is large enough by modifying `config/database.yml`.

In your controller action or model, you can call `#push(msg)`

    EMAIL_QUEUE.push(:email => @user.email, :name => @user.name)

The msg parameter to push is just a Hash whose contents are completely up to you.

Your message processing block should **not** access any instance data or variables outside of the block.  That's shared mutable state and dangerous to touch!  I also strongly recommend your queue processor block be **VERY** short, ideally just a method call or two.  You can unit test those methods easily but not the processor block itself.

You can tell girl\_friday to process immediately by setting ```$queue_work = false``` in your tests, just like ```Delayed::Worker.delay_jobs = false```.
You must do this in your test or spec helper file before you require your code/girl\_friday. For example, when using RSpec:

spec/spec_helper.rb

    $queue_work = false
    require "my_lib"
    require "rspec"
    ...

Then when you push items into a queue they will be immediately processed & returned. Works with callbacks too.
You can see this in action in [this example app](https://github.com/jc00ke/girl_friday_immediate_processing_example).

More Detail
--------------------

Please see the [girl\_friday wiki](https://github.com/mperham/girl_friday/wiki) for more detail and advanced options and tuning.  You'll find details on queue persistence with Redis, implementing clean shutdown, querying runtime metrics and SO MUCH MORE!


Thanks
--------------------

[Carbon Five](http://carbonfive.com), I write and maintain girl\_friday on their clock.

This gem contains a copy of the Rubinius Actor API, modified to work on any Ruby VM.  Thanks to Evan Phoenix, MenTaLguY and the Rubinius project for permission to use and distribute this code.


Author
--------------------

Mike Perham, [@mperham](https://twitter.com/mperham), [mikeperham.com](http://mikeperham.com)
