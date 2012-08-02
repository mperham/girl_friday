Changes
================

0.10.0
---------

* Update connection_pool to latest
* Handle shutdown more gracefully, wait for work to be finished

0.9.7
---------

* Fix error handling (xshay)
* Add streaming batch support for adding elements to a batch one at a
  time rather than all at once.

0.9.6
---------

* Completely switch to connection\_pool for Redis backend.
  The Redis store no longer connects for you automatically, so it's mandatory to use
  connection\_pool.

0.9.5
---------

* Refactor thread usage so Queues can be properly shutdown and GC'd [GH-30]
* Use WeakRefs instead of ObjectSpace, as that plays better on JRuby.
* Can now pass a [connection\_pool](https://github.com/mperham/connection_pool) in as a Redis instance.
* Switch Redis.new to Redis.connect so a :url option can be passed in.
  Nice for using on Heroku with Redis To Go.
* Allow stacking of error handlers, fixes GH-11

0.9.4
---------

* You can now pass in an existing Redis instance - :store\_config => [{ :redis => $redis }]

0.9.3
---------

* Fix runtime error introduced in last release when running in Rails development environment

0.9.2
---------

* Remove use of weakrefs to track queue instances, use ObjectSpace
  instead.
* Add support for Batch operations, providing an easy way to fan out
  operations and then collect results when completed.
* Added WorkQueue.immediate! and WorkQueue.queue! to switch background processing off and back on respectively. Nice to use when testing. (jc00ke, ryanlecompte)
* Added some ajax updates to the girl\_friday status server. (jc00ke)

0.9.1
---------

* Lazy initialize the worker actors to avoid dead thread problems with Unicorn forking processes.
* Add initial pass at girl\_friday Rack server (see wiki).  It's awful looking, trust me, help wanted.


0.9.0
---------

* Initial release
