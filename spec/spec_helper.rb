ENV["RAILS_ENV"] ||= 'test'

require "rspec/rails"
require "sidekiq/testing"

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    ActionMailer::Base.deliveries.clear

    Sidekiq::Worker.clear_all

    case example.metadata[:sidekiq]
    when :fake
      Sidekiq::Testing.fake!
    when :inline
      Sidekiq::Testing.inline!
    when :feature
      Sidekiq::Testing.inline!
    else
      Sidekiq::Testing.fake!
    end
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
