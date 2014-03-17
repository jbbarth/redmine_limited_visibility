Redmine limited_visibility plugin
======================

Give limited visibility on issues inside a project

Status
------

This plugin is under active development for now, but it's ALPHA quality software and should not be
used in production.

Features/progress
-----------------

- (done) engine for managing viewing permissions at issue level
- (done) add basic UI for managing the plugin in issues/form and roles/form
- (TODO) add ability for users to view a single issue if they know its id ; maybe make it optional (for now the plugin manages /strict/ visibility on issues)
- (TODO) mark roles as elligible for this behaviour ; non-marked role would be technical and won't appear anywhere in selection UIs
- (TODO) add categories for fast roles selection (?)

Installation
------------

This plugin is compatible with Redmine 2.1.0+.

Please apply general instructions for plugins [here](http://www.redmine.org/wiki/redmine/Plugins).

First download the source or clone the plugin and put it in the "plugins/" directory of your redmine instance. Note that this is crucial that the directory is named redmine_limited_visibility !

Then execute:

    $ bundle install
    $ rake redmine:plugins

And finally restart your Redmine instance.


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
