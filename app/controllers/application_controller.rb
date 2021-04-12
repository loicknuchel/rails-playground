class ApplicationController < ActionController::Base
  include Auth::Authed
  around_action :log

  private

  def log
    id = request.uuid
    start = Time.now
    yield
    stop = Time.now
    puts "Request #{id} ran in #{stop - start} sec"
  end
end
