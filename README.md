# Motivation

Simple DSL for use in classes to motivate a user towards a goal.  An example
goal might be "Complete Profile", or "Setup Project".

This was heavily inspired by [progression](https://github.com/mguterl/progression).

I switched primarily because I wanted to use specific classes rather than inject into
an existing model namespace, and extend the DSL some.

## Installation

Add this line to your application's Gemfile:

    gem 'motivation'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install motivation

## Usage

Create a motivational class and `include Motivation`.

```ruby
require "motivation"

Profile = Struct.new(:twitter_name, :age, :tweets) do
  attr_accessor :cached_tweets_count
end

class ProfileMotivation
  include Motivation

  # Aliases profile to subject for clarity in steps
  subject :profile

  # Create a simple check.  This defines the predicate `#setup_twitter?`
  check(:setup_twitter) { profile.twitter_name.to_s.length > 0 }

  # Define a step by name then create a check
  step :enter_age
  check { profile.age.to_i > 0 }

  # Define a completetion block.  This is useful if you your
  # check is heavy and you want to use a cached result.  This
  # will define a method `#complete_tweets_added
  step :tweets_added
  check { cached_tweets_count.to_i > 0 || profile.tweets.length > 0 }
  complete { profile.cached_tweets_count = profile.tweets.length.to_i }
end

profile = Profile.new(nil, 42, [1,2,3])
motivation = ProfileMotivation.new(profile)
motivation.setup_twitter? #=> false
profile.twitter_name = "JohnDoe"
motivation.setup_twitter? #=> true

motivation.complete_tweets_added
```

Note that the `check` and `complete` blocks will not tolerate early returns, you
will get a `LocalJumpError`.  If you want to simplify your DSL definitions, you can
just call methods, including privates, in your ProfileMotivation class itself.

You can also iterate over checks for a motivation instance:

```ruby
motivation.each_check do |check|
  puts check.name
  puts check.completed?
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
