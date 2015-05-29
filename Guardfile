guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^libraries/(.+)\.rb$}) { |m| "spec/unit/#{m[1]}_spec.rb" }
  watch(%r{^spec/unit/(.+)_spec\.rb$})
  watch(%r{^spec/functional/(.+)_spec\.rb$})
  watch('spec/spec_helper.rb') { 'spec' }
end
