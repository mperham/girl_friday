Changes
================

HEAD
---------

* Remove use of weakrefs to track queue instances, use ObjectSpace
  instead.
* Add support for Batch operations, providing an easy way to fan out
  operations and then collect results when completed.
* Added WorkQueue.immediate! and WorkQueue.queue! to switch background processing off and back on respectively. Nice to use when testing.
* Added some ajax updates to the girl\_friday status server.
* Changed WorkQueue.immediate! and WorkQueue.queue! to be idempotent operations, can also now be invoked in any order

0.9.1
---------

* Lazy initialize the worker actors to avoid dead thread problems with Unicorn forking processes.
* Add initial pass at girl\_friday Rack server (see wiki).  It's awful looking, trust me, help wanted.


0.9.0
---------

* Initial release
