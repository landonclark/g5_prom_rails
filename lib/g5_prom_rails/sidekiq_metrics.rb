require 'sidekiq/api'

module G5PromRails::SidekiqMetrics
  extend ActiveSupport::Concern

  def initialize_sidekiq
    @processed_counter = G5PromRails::SettableCounter.new(
      :sidekiq_processed,
      "jobs processed"
    )
    per_application.register(@processed_counter)
    @failed_counter = G5PromRails::SettableCounter.new(
      :sidekiq_failed,
      "jobs failed"
    )
    per_application.register(@failed_counter)

    @retry_gauge = per_application.gauge(
      :sidekiq_retry,
      "jobs to be retried"
    )
    @queues_gauge = per_application.gauge(
      :sidekiq_queued,
      "job queue lengths"
    )
  end

  def update_sidekiq_statistics
    stats = Sidekiq::Stats.new
    @processed_counter.set(app_hash, stats.processed)
    @failed_counter.set(app_hash, stats.failed)
    @retry_gauge.set(app_hash, stats.retry_size)

    Sidekiq::Stats::Queues.new.lengths.each do |queue, length|
      @queues_gauge.set(app_hash(queue: queue), length)
    end
  end
end
