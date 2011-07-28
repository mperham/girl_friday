Changes
================

HEAD
---------

* Remove use of weakrefs to track queue instances, use ObjectSpace
  instead.
* Add support for Batch operations, providing an easy way to fan out
  operations and then collect results when completed.
* [jc00ke](https://github.com/jc00ke) added WorkQueue.immediate! and WorkQueue.queue! to switch background processing off and back on respectively. Nice to use when testing.

0.9.1
---------

* Lazy initialize the worker actors to avoid dead thread problems with Unicorn forking processes.
* Add initial pass at girl\_friday Rack server (see wiki).  It's awful looking, trust me, help wanted.


0.9.0
---------

* Initial release
