Changes
================

HEAD
---------

* Remove use of weakrefs to track queue instances, use ObjectSpace
  instead.
* Add support for Batch operations, providing an easy way to fan out
  operations and then collect results when completed.

0.9.1
---------

* Lazy initialize the worker actors to avoid dead thread problems with Unicorn forking processes.
* Add initial pass at girl_friday Rack server (see wiki).  It's awful looking, trust me, help wanted.


0.9.0
---------

* Initial release
