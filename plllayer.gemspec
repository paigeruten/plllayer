Gem::Specification.new do |s|
  s.name = "plllayer"
  s.version = "0.0.2"
  s.date = "2013-01-31"
  s.summary = "An audio playback library for Ruby."
  s.description = "plllayer is an audio playback library for Ruby. It is a Ruby interface to some external media player, such as mplayer."
  s.author = "Jeremy Ruten"
  s.email = "jeremy.ruten@gmail.com"
  s.homepage = "http://github.com/yjerem/plllayer"
  s.license = "MIT"
  s.required_ruby_version = ">= 1.9.2"

  s.files = ["Gemfile", "Gemfile.lock", "LICENSE", "plllayer.gemspec"]
  s.files += Dir["lib/**/*.rb"]

  %w(bundler open4).each do |gem_name|
    s.add_runtime_dependency gem_name
  end

  %w(rake rspec).each do |gem_name|
    s.add_development_dependency gem_name
  end
end
