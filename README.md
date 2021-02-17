Redmine limited_visibility plugin
======================

Give limited visibility on issues inside a project

Installation
------------

Requirements:

    ruby >= 2.1.0
    redmine_base_deface plugin

This plugin is compatible with Redmine 2.1.0+.

Please apply general instructions for plugins [here](http://www.redmine.org/wiki/redmine/Plugins).

First download the source or clone the plugin and put it in the "plugins/" directory of your redmine instance. Note that this is crucial that the directory is named redmine_limited_visibility !

Then execute:

    $ bundle install
    $ rake redmine:plugins

And finally restart your Redmine instance.

Tests status
------------

|Plugin branch| Redmine Version   | Test Status      |
|-------------|-------------------|------------------|
|master       | 4.1.1             | [![Tests 4.1.1][1]][5] |  
|master       | 4.0.7             | [![Tests 4.0.7][2]][5] |
|master       | master            | [![Tests master][3]][5]|

[1]: https://github.com/jbbarth/redmine_limited_visibility/workflows/Tests%204.1.1/badge.svg
[2]: https://github.com/jbbarth/redmine_limited_visibility/workflows/Tests%204.0.7/badge.svg
[3]: https://github.com/jbbarth/redmine_limited_visibility/workflows/Tests%20master/badge.svg
[5]: https://github.com/jbbarth/redmine_limited_visibility/actions

Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
