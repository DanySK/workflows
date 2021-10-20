#!/usr/bin/env ruby
regex = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-((0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$/
version = `git describe --tags --abbrev=0 || echo "0.1.0"`.strip
match_data = regex.match(version)
unless match_data then
  puts "Error: #{version} does not seem SemVer-compatible"
  exit 1
end
major, minor, patch = match_data.captures
puts "Major: #{major}"
puts "Minor: #{minor}"
puts "Patch: #{patch}"
update_version = ARGV[0]
pre_release_tag = ARGV[1]

def count_commits(head)
  count = `git log --oneline "#{head}" | wc -l`.strip
  puts "Commits from #{head}: #{count}"
  count.to_i
end

version = case update_version
  when 'major' then "#{count_commits('HEAD')}.0.0"
  when 'minor' then "#{major}.#{count_commits(major == "0" ? 'HEAD' : "#{major}.0.0..")}.0"
  when 'patch' then "#{major}.#{minor}.#{count_commits("#{major}.#{minor}.0..")}"
  when 'pre-release' then
    latest_stable = "#{major}.#{minor}.#{patch}"
    "#{latest_stable}-#{pre_release_tag}#{count_commits("#{latest_stable}..")}"
  else
    puts "Invalid update-version #{update_version}. Supported values are: 'patch' (default), 'minor', 'major', or 'pre-release'."
    exit 2
end

if version =~ regex then
  puts "This version is: #{version}"
  puts "::set-output name=version::#{version}"
else
  puts "The computed version is not a valid SemVer: this is likely a bug."
  exit 3
end
