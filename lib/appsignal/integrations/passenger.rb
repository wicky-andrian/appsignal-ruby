if defined?(::PhusionPassenger)
  Appsignal.logger.info('Loading Passenger integration')

  ::PhusionPassenger.on_event(:stopping_worker_process) do
    Appsignal.stop
  end
end