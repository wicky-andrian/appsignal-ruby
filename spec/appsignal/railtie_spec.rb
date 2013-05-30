require 'spec_helper'
require 'action_controller/railtie'
require 'appsignal/railtie'

describe Appsignal::Railtie do
  it "should log to the in memory log before init" do
    Appsignal.logger.error('Log something before init')
    Appsignal.in_memory_log.string.should include('Log something before init')
  end

  context "after initializing the app" do
    before(:all) { MyApp::Application.initialize! }

    it "should start logging to file and have written the in memory log" do
      Appsignal.logger.should be_instance_of(Logger)
      File.open(log_file).read.should include(
        'Log something before init'
      )
    end

    it "should have set the appsignal subscriber" do
      if defined? ActiveSupport::Notifications::Fanout::Subscribers::Timed
        # Rails 4
        Appsignal.subscriber.
          should be_a ActiveSupport::Notifications::Fanout::Subscribers::Timed
      else
        # Rails 3
        Appsignal.subscriber.
          should be_a ActiveSupport::Notifications::Fanout::Subscriber
      end
    end

    it "should have added the listener middleware for exceptions" do
      MyApp::Application.middleware.to_a.should include Appsignal::Listener
    end

    context "non action_controller event" do
      it "should call add_event for non action_controller event" do
        current = mock(:current)
        current.should_receive(:add_event)
        Appsignal::Transaction.should_receive(:current).twice.
          and_return(current)
      end

      after { ActiveSupport::Notifications.instrument 'query.mongoid' }
    end

    context "action_controller event" do
      it "should call set_process_action_event for action_controller event" do
        current = mock(:current)
        current.should_receive(:set_process_action_event)
        current.should_receive(:add_event)
        Appsignal::Transaction.should_receive(:current).exactly(3).times.
          and_return(current)
      end

      after do
        ActiveSupport::Notifications.
          instrument 'process_action.action_controller'
      end
    end

    context "event that starts with a bang" do
      it "should not be processed" do
        Appsignal::Transaction.should_not_receive(:current)
      end

      after do
        ActiveSupport::Notifications.
          instrument '!render_template'
      end
    end
  end
end
